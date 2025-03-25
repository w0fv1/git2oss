# gitw.ps1
# 此脚本检查系统是否已有 Git，如果没有则下载 PortableGit。
# 同时支持在任意位置指定 -Proxy 参数来设置代理，并让 Git 使用该代理，
# 剩余参数会传递给 Git 命令执行。

$ErrorActionPreference = "Stop"

# 手动解析参数，确保 -Proxy 参数可放在任意位置
$gitArgs = @()
$Proxy = $null
$i = 0
while ($i -lt $args.Count) {
    if ($args[$i] -ieq "-Proxy") {
        $i++
        if ($i -lt $args.Count) {
            $Proxy = $args[$i]
        }
    }
    else {
        $gitArgs += $args[$i]
    }
    $i++
}

if ($Proxy) {
    Write-Host "[Info] Using proxy: $Proxy"
}

# 配置变量
$GIT_URL = "https://github.com/git-for-windows/git/releases/download/v2.49.0.windows.1/PortableGit-2.49.0-64-bit.7z.exe"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$GIT_DIR = Join-Path $ScriptDir "PortableGit"
$GIT_EXE = Join-Path $GIT_DIR "PortableGit\bin\git.exe"
$ZIP_PATH = Join-Path $GIT_DIR "PortableGit.7z.exe"

# 检查是否已有系统 Git
$FOUND_GIT = Get-Command git -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1

if (-not $FOUND_GIT) {
    if (Test-Path $GIT_EXE) {
        $FOUND_GIT = $GIT_EXE
    }
    else {
        Write-Host "[Info] Git not found. Downloading PortableGit..."
        New-Item -ItemType Directory -Path $GIT_DIR -Force | Out-Null

        function Download-File {
            param (
                [string]$Url,
                [string]$OutFile
            )
            $params = @{
                Uri     = $Url
                OutFile = $OutFile
            }
            if ($Proxy) {
                $params["Proxy"] = $Proxy
            }
            Invoke-WebRequest @params
        }

        Download-File -Url $GIT_URL -OutFile $ZIP_PATH

        Write-Host "[Info] Extracting PortableGit..."
        & $ZIP_PATH -y -gm2 -InstallPath="$GIT_DIR\PortableGit" | Out-Null
        Remove-Item $ZIP_PATH -Force

        if (Test-Path $GIT_EXE) {
            Write-Host "[Info] Git downloaded and extracted successfully."
            $FOUND_GIT = $GIT_EXE
        }
        else {
            Write-Error "[Error] Failed to extract Git."
            exit 1
        }
    }
}
else {
    Write-Host "[Info] Found system Git at: $FOUND_GIT"
}

# 如果传入了代理，则设置环境变量，供 Git 使用
if ($Proxy) {
    $env:HTTP_PROXY = $Proxy
    $env:HTTPS_PROXY = $Proxy
}

# 执行 Git 命令并传入所有剩余参数
if ($gitArgs.Count -gt 0) {
    & $FOUND_GIT @gitArgs
}
else {
    & $FOUND_GIT --version
}
