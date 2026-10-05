# 正方形破甲 — 安装到本机 DSH
# 用法：在 square-armor 目录下执行 pwsh -File install.ps1
# 默认装 web profile；桌面端传 -Profile default

param(
  [string]$ProfileName = "web",
  [string]$DshHome = $(if ($env:DSH_HOME) { $env:DSH_HOME } else { "$env:USERPROFILE\.dsh" }),
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot
$pluginName = "square-armor"
$target = Join-Path $DshHome "plugins\$pluginName"
$profileJson = Join-Path $DshHome "profiles\$ProfileName\package.json"

if (-not (Test-Path $profileJson)) {
  Write-Host "找不到 profile：$profileJson" -ForegroundColor Red
  Write-Host "先启动一次该宿主让它生成 profile，再重跑本脚本。"
  exit 1
}

Write-Host "DSH_HOME : $DshHome"
Write-Host "Profile  : $ProfileName"
Write-Host "Plugin   : $pluginName"
if ($DryRun) { Write-Host "[DryRun] 只演示，不写盘" -ForegroundColor Yellow }

# 1. 复制插件到 plugins 目录
if ($DryRun) {
  Write-Host "[1/3] [DryRun] 将复制到 $target"
} else {
  if (Test-Path $target) { Remove-Item -Recurse -Force $target }
  Copy-Item -Recurse -Force $here $target
  Remove-Item -Recurse -Force (Join-Path $target "node_modules") -ErrorAction SilentlyContinue
  Write-Host "[1/3] 插件已复制到 $target"
}

# 2. 备份并改 profile package.json
$bak = "$profileJson.bak"
if (-not $DryRun) {
  if (-not (Test-Path $bak)) { Copy-Item $profileJson $bak }
  $pkg = Get-Content $profileJson -Raw | ConvertFrom-Json -AsHashtable
} else {
  $pkg = Get-Content $profileJson -Raw | ConvertFrom-Json -AsHashtable
}

if (-not $pkg.dependencies) { $pkg.dependencies = @{} }
if ($pkg.dependencies.ContainsKey($pluginName)) {
  Write-Host "      dependencies 已有 $pluginName，跳过" -ForegroundColor Yellow
} else {
  $pkg.dependencies[$pluginName] = "link:$target"
}

$bundles = $pkg.dsh.profile.bundles
if ($bundles -contains $pluginName) {
  Write-Host "      bundles 已有 $pluginName，跳过" -ForegroundColor Yellow
} else {
  $bundles += $pluginName
}

if (-not $DryRun) {
  $pkg | ConvertTo-Json -Depth 10 | Set-Content $profileJson -Encoding UTF8
}
Write-Host "[2/3] profile package.json 已更新（备份：$bak）"

# 3. pnpm install
$profileDir = Join-Path $DshHome "profiles\$ProfileName"
if ($DryRun) {
  Write-Host "[3/3] [DryRun] 跳过 pnpm install"
} else {
  Write-Host "[3/3] 执行 pnpm install ..."
  Push-Location $profileDir
  try {
    pnpm install
    if ($LASTEXITCODE -ne 0) { throw "pnpm install 失败（exit $LASTEXITCODE）" }
  } finally {
    Pop-Location
  }
}

Write-Host ""
Write-Host "完成。下一步：" -ForegroundColor Green
Write-Host "  1. 完全退出 dsh web（或对应宿主）"
Write-Host "  2. 重新打开，新开一轮对话，正方形 frame 即进入系统提示"
Write-Host "  卸载：pwsh -File uninstall.ps1 -ProfileName $ProfileName"
