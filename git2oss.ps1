# git2oss.ps1
# 从config.ini读取配置，并将Git仓库clone后上传至指定OSS Bucket

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigFile = Join-Path $ScriptDir "config.ini"
$SampleConfigFile = Join-Path $ScriptDir "config.sample.ini"

if (-not (Test-Path $ConfigFile)) {
    Write-Error "config.ini 配置文件不存在。请复制config.sample.ini并重命名为config.ini，然后修改配置。"
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
$Proxy = $config.Aliyun.Proxy

if (-not $RepoUrl -or -not $Bucket -or -not $AccessKeyId -or -not $AccessKeySecret -or -not $Endpoint) {
    Write-Error "配置文件中缺少必要参数。请检查config.ini"
    exit 1
}

# Clone仓库
$RepoName = Split-Path $RepoUrl -LeafBase
$ClonePath = Join-Path $ScriptDir $RepoName

if (Test-Path $ClonePath) {
    Write-Host "[Info] 存在旧仓库目录，先删除。"
    Remove-Item $ClonePath -Recurse -Force
}

Write-Host "[Info] 正在克隆仓库: $RepoUrl"
& "$ScriptDir\gitw.ps1" clone $RepoUrl $ClonePath

if (-not (Test-Path $ClonePath)) {
    Write-Error "[Error] 克隆仓库失败！"
    exit 1
}

# 准备ossutil命令
$OssUtilExe = Join-Path $ScriptDir "aliyun_ossutil.exe"
if (-not (Test-Path $OssUtilExe)) {
    Write-Error "aliyun_ossutil.exe 不存在，请在脚本目录放置ossutil二进制文件。"
    exit 1
}

$BucketUrl = "oss://$Bucket/"

$ossArgs = @("cp", "$ClonePath", "$BucketUrl", "-r", `
    "-i", $AccessKeyId, "-k", $AccessKeySecret, "-e", $Endpoint)

if ($Proxy) {
    $ossArgs += "--proxy"
    $ossArgs += $Proxy
    Write-Host "[Info] 使用代理: $Proxy"
}

Write-Host "[Info] 正在上传到OSS: $BucketUrl"
& $OssUtilExe @ossArgs

Write-Host "[Info] 仓库已成功上传至OSS。"