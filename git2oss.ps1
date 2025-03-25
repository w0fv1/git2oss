# git2oss.ps1
# 支持多任务：从config.ini读取多个Git仓库配置，并上传到对应OSS Bucket

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigFile = Join-Path $ScriptDir "config.ini"
$SampleConfigFile = Join-Path $ScriptDir "config.sample.ini"

if (-not (Test-Path $ConfigFile)) {
    Write-Error "[error] config.ini 配置文件不存在！请复制 config.sample.ini 并重命名为 config.ini，然后修改对应配置项。"
    exit 1
}

# 解析INI文件
function Get-IniContent($filePath) {
    $ini = @{}
    $section = ""
    foreach ($line in Get-Content $filePath) {
        if ($line -match "^\s*\[(.+)\]\s*$") {
            $section = $matches[1]
            $ini[$section] = @{}
        }
        elseif ($line -match "^\s*(\S+)\s*=\s*(.+)$") {
            $key, $value = $matches[1], $matches[2]
            $ini[$section][$key] = $value
        }
    }
    return $ini
}

$config = Get-IniContent $ConfigFile

# 通用 Aliyun 认证配置
$AccessKeyId = $config.Aliyun.AccessKeyId
$AccessKeySecret = $config.Aliyun.AccessKeySecret
$Proxy = $config.Aliyun.Proxy

if (-not $AccessKeyId -or -not $AccessKeySecret) {
    Write-Error "[error] config.ini 中缺少 Aliyun 认证参数。"
    exit 1
}

# 处理所有 [Task-*] 小节
$config.Keys | Where-Object { $_ -like "Task-*" } | ForEach-Object {
    $taskName = $_
    $task = $config[$taskName]

    $RepoUrl = $task.Repository
    $Bucket = $task.Bucket
    $Endpoint = $task.Endpoint
    $Region = $task.Region

    $missing = @()
    if (-not $RepoUrl) { $missing += "$taskName.Repository" }
    if (-not $Bucket) { $missing += "$taskName.Bucket" }
    if (-not $Endpoint) { $missing += "$taskName.Endpoint" }
    if (-not $Region) { $missing += "$taskName.Region" }

    if ($missing.Count -gt 0) {
        Write-Error "[error] config.ini 缺少参数：$($missing -join ', ')"
        return
    }
    Write-Host "[info] 正在进行 $taskName..."

    # Clone 仓库
    $RepoName = [IO.Path]::GetFileNameWithoutExtension($RepoUrl)
    $ClonePath = Join-Path $ScriptDir $RepoName

    if (Test-Path $ClonePath) {
        Write-Host "[info] 存在旧目录 $RepoName，正在删除..."
        Remove-Item $ClonePath -Recurse -Force
    }

    Write-Host "[info] [$taskName] 正在克隆仓库: $RepoUrl"
    & "$ScriptDir\gitw.ps1" clone $RepoUrl $ClonePath

    if (-not (Test-Path $ClonePath)) {
        Write-Error "[error] [$taskName] 克隆失败！"
        return
    }

    # 上传到 OSS
    $OssUtilExe = Join-Path $ScriptDir "aliyun_ossutil.exe"
    if (-not (Test-Path $OssUtilExe)) {
        Write-Error "[error] aliyun_ossutil.exe 未找到"
        exit 1
    }

    $BucketUrl = "oss://$Bucket/"
    $ossArgs = @(
        "cp", "$ClonePath", "$BucketUrl", "-r",
        "-i", $AccessKeyId, "-k", $AccessKeySecret, "-e", $Endpoint, "--region", $Region,
        "--exclude", ".git/*",
        "--force"
    )
    if ($Proxy) {
        $ossArgs += "--proxy"
        $ossArgs += $Proxy
        Write-Host "[info] 使用代理服务器: $Proxy"
    }

    Write-Host "[info] [$taskName] 正在上传到OSS: $BucketUrl"
    & $OssUtilExe @ossArgs

    if ($LASTEXITCODE -ne 0) {
        Write-Error "[error] [$taskName] 上传失败"
        return
    }
    Write-Host "[info] [$taskName] 上传成功！"

    # 添加到.gitignore
    $GitignorePath = Join-Path $ScriptDir ".gitignore"
    if (-not (Test-Path $GitignorePath)) {
        New-Item -Path $GitignorePath -ItemType File -Force | Out-Null
    }
    $ignoreContent = Get-Content $GitignorePath -ErrorAction SilentlyContinue
    if ($ignoreContent -notcontains $RepoName) {
        Write-Host "[info] 添加 $RepoName 到 .gitignore"
        Add-Content -Path $GitignorePath -Value "`r`n$RepoName"
    }
    else {
        Write-Host "[info] $RepoName 已在 .gitignore 中"
    }
}