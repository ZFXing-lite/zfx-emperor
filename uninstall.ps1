# 正方形破甲 — 卸载
# 用法：pwsh -File uninstall.ps1 -ProfileName web

param(
  [string]$ProfileName = "web",
  [string]$DshHome = $(if ($env:DSH_HOME) { $env:DSH_HOME } else { "$env:USERPROFILE\.dsh" })
)

$ErrorActionPreference = "Stop"
$pluginName = "square-armor"
$target = Join-Path $DshHome "plugins\$pluginName"
$profileJson = Join-Path $DshHome "profiles\$ProfileName\package.json"

if (Test-Path $profileJson) {
  $bak = "$profileJson.bak"
  if (Test-Path $bak) {
    Copy-Item $bak $profileJson -Force
    Write-Host "profile package.json 已从备份还原"
  } else {
    $pkg = Get-Content $profileJson -Raw | ConvertFrom-Json -AsHashtable
    $pkg.dependencies.Remove($pluginName) | Out-Null
    $pkg.dsh.profile.bundles = @($pkg.dsh.profile.bundles | Where-Object { $_ -ne $pluginName })
    $pkg | ConvertTo-Json -Depth 10 | Set-Content $profileJson -Encoding UTF8
    Write-Host "profile package.json 已移除 $pluginName（无备份，手工清理）"
  }
  Push-Location (Join-Path $DshHome "profiles\$ProfileName")
  try { pnpm install } finally { Pop-Location }
}

if (Test-Path $target) {
  Remove-Item -Recurse -Force $target
  Write-Host "插件目录已删除：$target"
}

Write-Host "卸载完成。重启宿主后正方形 frame 不再注入。" -ForegroundColor Green
