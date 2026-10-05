# ZFX Emperor — 一键推送（填 token 即用）
# 用法：
#   $env:GH_TOKEN = "ghp_你的token"        # 只放当前会话环境变量，不落盘
#   pwsh -File push.ps1
#
# 没有 token 就去生成：GitHub → Settings → Developer settings →
# Personal access tokens → Fine-grained tokens，勾 repo 读写即可。
# 用完立刻在 GitHub 上删掉这个 token。

param([string]$RepoName = "zfx-emperor")

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot

$token = $env:GH_TOKEN
if (-not $token) {
  Write-Host "没有 GH_TOKEN。先执行：`$env:GH_TOKEN = `"ghp_xxx`"" -ForegroundColor Red
  exit 1
}

# 1. 建仓（已存在则跳过）
$name = "ZFXing-lite"
$headers = @{
  Authorization  = "Bearer $token"
  Accept         = "application/vnd.github+json"
  "X-GitHub-Api-Version" = "2022-11-28"
}
$exists = $false
try {
  $r = Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$name/$RepoName" -Headers $headers
  $exists = $true
  Write-Host "仓库已存在：$r.full_name"
} catch {
  $body = @{ name = $RepoName; private = $true; description = "ZFX Emperor — DSH 原生破甲插件" } | ConvertTo-Json
  $r = Invoke-RestMethod -Method Post -Uri "https://api.github.com/user/repos" -Headers $headers -Body $body -ContentType "application/json"
  Write-Host "已创建私有仓库：$r.full_name"
}

# 2. 推送全部文件（token 走 extraHeader，不写进 remote URL / config）
git -C $here remote remove origin 2>$null
git -C $here remote add origin "https://github.com/$name/$RepoName.git"
git -C $here -c http.extraheader="AUTHORIZATION: Bearer $token" push -u origin HEAD:main

# 3. remote 保持干净，无凭据残留
git -C $here remote remove origin
Write-Host "推送完成。token 只在环境变量里，没落盘。" -ForegroundColor Green
Write-Host "用完记得去 GitHub 删掉 token。" -ForegroundColor Yellow
