# git2oss.ps1
# 从config.ini读取配置，并将Git仓库clone后上传至指定OSS Bucket

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

$RepoUrl = $config.Git.Repository
$Bucket = $config.OSS.Bucket
$AccessKeyId = $config.Aliyun.AccessKeyId
$AccessKeySecret = $config.Aliyun.AccessKeySecret
$Endpoint = $config.Aliyun.Endpoint
$Region = $config.Aliyun.Region
$Proxy = $config.Aliyun.Proxy

$missingConfigs = @()
if (-not $RepoUrl) { $missingConfigs += "Git.Repository" }
if (-not $Bucket) { $missingConfigs += "OSS.Bucket" }
if (-not $AccessKeyId) { $missingConfigs += "Aliyun.AccessKeyId" }
if (-not $AccessKeySecret) { $missingConfigs += "Aliyun.AccessKeySecret" }
if (-not $Endpoint) { $missingConfigs += "Aliyun.Endpoint" }
if (-not $Region) { $missingConfigs += "Aliyun.Region" }

if ($missingConfigs.Count -gt 0) {
    Write-Error "[error] config.ini 中缺少必要参数：$($missingConfigs -join ', ')。请补充后重试。"
    exit 1
}

# Clone仓库
$RepoName = [IO.Path]::GetFileNameWithoutExtension($RepoUrl)
$ClonePath = Join-Path $ScriptDir $RepoName

if (Test-Path $ClonePath) {
    Write-Host "[info] 存在旧仓库目录，正在删除..."
    Remove-Item $ClonePath -Recurse -Force
}

Write-Host "[info] 正在克隆仓库: $RepoUrl"
& "$ScriptDir\gitw.ps1" clone $RepoUrl $ClonePath

if (-not (Test-Path $ClonePath)) {
    Write-Error "[error] 克隆仓库失败！请检查仓库地址或网络状态。"
    exit 1
}

# 检查ossutil命令
$OssUtilExe = Join-Path $ScriptDir "aliyun_ossutil.exe"
if (-not (Test-Path $OssUtilExe)) {
    Write-Error "[error] aliyun_ossutil.exe 未找到，请将该程序放在脚本所在目录。"
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

Write-Host "[info] 正在上传到OSS: $BucketUrl"
& $OssUtilExe @ossArgs

if ($LASTEXITCODE -ne 0) {
    Write-Error "[error] 上传到OSS失败，请检查网络或OSS配置参数。"
    exit 1
}

Write-Host "[info] 仓库已成功上传至OSS。"


# 将克隆的文件夹名加入.gitignore（如果不存在的话）
$GitignorePath = Join-Path $ScriptDir ".gitignore"

if (-not (Test-Path $GitignorePath)) {
    Write-Host "[info] .gitignore 不存在，正在创建..."
    New-Item -Path $GitignorePath -ItemType File -Force | Out-Null
}

# 读取.gitignore文件并确保每行独立匹配
$ignoreContent = Get-Content $GitignorePath -ErrorAction SilentlyContinue

if ($ignoreContent -notcontains $RepoName) {
    Write-Host "[info] 正在将 $RepoName 加入到 .gitignore"
    Add-Content -Path $GitignorePath -Value "`r`n$RepoName"
}
else {
    Write-Host "[info] $RepoName 已存在于 .gitignore，无需修改。"
}
