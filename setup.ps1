# =============================================================================
# Bubble Hackathon 2026 — Team Setup (Windows)
#
# Usage (shared via internal Slack — the server IP is the secret):
#   & ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/bubble-hackathon-2026/setup/main/setup.ps1'))) SERVER_IP
#
# Only prerequisite: Claude Code. Node.js and Git are auto-installed via
# winget if missing. This is the Windows twin of setup.sh — the Mac version.
# =============================================================================

param(
    [string]$ServerIp = ''
)

$ErrorActionPreference = 'Continue'

$GITEA_ORG = 'hackathon'
$HACKATHON_DIR = Join-Path $env:USERPROFILE 'hackathon'

function Write-StepMsg($msg)  { Write-Host ""; Write-Host $msg -ForegroundColor White }
function Write-InfoMsg($msg)  { Write-Host "  + $msg" -ForegroundColor Green }
function Write-WarnMsg($msg)  { Write-Host "  ! $msg" -ForegroundColor Yellow }
function Write-FailMsg($msg)  { Write-Host "  x $msg" -ForegroundColor Red }

function Test-Cmd($name) { [bool](Get-Command $name -ErrorAction SilentlyContinue) }

function Refresh-Path {
    $machine = [System.Environment]::GetEnvironmentVariable('Path','Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('Path','User')
    $env:Path = ($machine, $user -join ';')
}

function Extract-ApiError($errorRecord) {
    try {
        $body = $errorRecord.ErrorDetails.Message
        if ($body) {
            $parsed = $body | ConvertFrom-Json
            if ($parsed.error) { return $parsed.error }
        }
    } catch {}
    return $errorRecord.Exception.Message
}

Write-Host ""
Write-Host "========================================" -ForegroundColor White
Write-Host "   Bubble Hackathon 2026 - Setup (Windows)" -ForegroundColor White
Write-Host "========================================" -ForegroundColor White

# --- Get server IP ---

if (-not $ServerIp) {
    Write-Host ""
    Write-Host "  Enter the hackathon server address (from the Slack message)."
    $ServerIp = Read-Host "  Server IP"
}

if (-not $ServerIp) {
    Write-FailMsg "Server IP is required."
    exit 1
}

# Strip protocol/port if someone pasted a full URL
$ServerIp = $ServerIp -replace '^https?://', ''
$ServerIp = $ServerIp.Split(':')[0]

$GiteaUrl    = "http://${ServerIp}:3000"
$Provisioner = "http://${ServerIp}:8080"

# --- Auto-install prerequisites ---

Write-StepMsg "Checking prerequisites..."

$hasWinget = Test-Cmd winget

# Git
if (Test-Cmd git) {
    Write-InfoMsg "Git"
} else {
    Write-WarnMsg "Git not found — installing..."
    if ($hasWinget) {
        winget install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
        Refresh-Path
    }
    if (Test-Cmd git) {
        Write-InfoMsg "Git installed"
    } else {
        Write-FailMsg "Couldn't auto-install Git."
        Write-Host "  Install it from https://git-scm.com/download/win and re-run this command."
        exit 1
    }
}

# Node.js
if (Test-Cmd node) {
    Write-InfoMsg "Node.js ($(node --version))"
} else {
    Write-WarnMsg "Node.js not found — installing (a permission dialog may appear; click Yes)..."
    if ($hasWinget) {
        winget install --id OpenJS.NodeJS.LTS -e --silent --accept-source-agreements --accept-package-agreements | Out-Null
        Refresh-Path
    }
    if (Test-Cmd node) {
        Write-InfoMsg "Node.js installed ($(node --version))"
    } else {
        Write-FailMsg "Couldn't auto-install Node.js."
        Write-Host "  Install the LTS version from https://nodejs.org and re-run this command."
        exit 1
    }
}

# Claude Code (optional pre-check; the script continues regardless)
if (Test-Cmd claude) {
    Write-InfoMsg "Claude Code"
} else {
    Write-WarnMsg "Claude Code not found — install after setup:"
    Write-Host "       irm https://claude.ai/install.ps1 | iex" -ForegroundColor Blue
}

# --- Check server reachability ---

Write-StepMsg "Connecting to hackathon server..."

try {
    $null = Invoke-WebRequest -Uri "$Provisioner/health" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    Write-InfoMsg "Server reachable"
} catch {
    Write-FailMsg "Cannot reach the hackathon server at $ServerIp"
    Write-Host "  Make sure you have the right IP from the Slack message."
    exit 1
}

# --- Identify the user ---

Write-StepMsg "Who are you?"
Write-Host ""
$userName  = Read-Host "  Your name (e.g., Jane Smith)"
$userEmail = Read-Host "  Your @bubble.io email"

# --- Verify identity via Slack DM ---

Write-StepMsg "Verifying your email..."

try {
    $null = Invoke-RestMethod -Method Post -Uri "$Provisioner/request-code" `
        -ContentType 'application/json' `
        -Body (@{ email = $userEmail } | ConvertTo-Json -Compress) `
        -ErrorAction Stop
} catch {
    Write-FailMsg (Extract-ApiError $_)
    exit 1
}

Write-InfoMsg "Check Slack — we just sent you a DM with a 6-digit code"
Write-Host ""
$verifyCode = Read-Host "  Enter the code"

# --- Create account (provisioner verifies the code) ---

Write-StepMsg "Setting up your account..."

try {
    $provisionResult = Invoke-RestMethod -Method Post -Uri "$Provisioner/provision" `
        -ContentType 'application/json' `
        -Body (@{ name = $userName; email = $userEmail; code = $verifyCode } | ConvertTo-Json -Compress) `
        -ErrorAction Stop
} catch {
    Write-FailMsg (Extract-ApiError $_)
    exit 1
}

$username  = $provisionResult.username
$userToken = $provisionResult.token

if (-not $userToken) {
    Write-FailMsg "Account setup failed. Contact a hackathon organizer."
    exit 1
}

Write-InfoMsg "Account ready: $username"

$serverHost = "${ServerIp}:3000"
# Inline creds in the clone URL bypass Windows Credential Manager caching,
# matching the rationale in setup.sh for macOS's osxkeychain helper.
$repoUrlBase = "http://${username}:${userToken}@${serverHost}/$GITEA_ORG"

git config --global user.name $userName 2>$null
git config --global user.email $userEmail 2>$null

Write-InfoMsg "Git configured"

# --- Helpers ---

function Slugify([string]$name) {
    $s = $name.ToLower()
    $s = $s -replace '\s+', '-'
    $s = $s -replace '[^a-z0-9-]', ''
    $s = $s -replace '-+', '-'
    $s = $s -replace '^-|-$', ''
    return $s
}

function Write-ClaudeSettings([string]$dir) {
    $claudeDir = Join-Path $dir '.claude'
    New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

    $settings = @'
{
  "autoMode": {
    "environment": [
      "This is a hackathon prototype repo on an internal Gitea server.",
      "Throwaway prototypes — no production code or customer data.",
      "No branch protection, no PR review — direct work on main is expected."
    ],
    "allow": [
      "Direct push to main in this repo is the expected workflow.",
      "npx vercel deployments are allowed — prototypes are meant to be shared via public demo URLs.",
      "npm install and npx for any package is part of normal hackathon iteration.",
      "git commit, push, pull, stash, rebase — all normal collaboration actions."
    ]
  },
  "permissions": {
    "defaultMode": "acceptEdits",
    "allow": [
      "Bash(git push:*)",
      "Bash(git pull:*)",
      "Bash(git commit:*)",
      "Bash(git add:*)",
      "Bash(git stash:*)",
      "Bash(git rebase:*)",
      "Bash(git merge:*)",
      "Bash(git checkout:*)",
      "Bash(git reset:*)",
      "Bash(npm:*)",
      "Bash(npx:*)"
    ]
  }
}
'@

    # UTF-8 without BOM — some tooling chokes on a BOM in JSON.
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText((Join-Path $claudeDir 'settings.local.json'), $settings, $utf8NoBom)

    $gitignorePath = Join-Path $dir '.gitignore'
    if (Test-Path $gitignorePath) {
        $gi = Get-Content $gitignorePath -Raw
        if ($gi -notmatch '\.claude/settings\.local\.json') {
            Add-Content -Path $gitignorePath -Value "`r`n# Claude Code per-user settings`r`n.claude/settings.local.json"
        }
    }
}

function Remove-DirForced([string]$path) {
    # Git's .pack files and pack-indices are marked read-only; clear attrs first.
    Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
        try { $_.Attributes = 'Normal' } catch {}
    }
    Remove-Item -Recurse -Force $path -ErrorAction SilentlyContinue
}

# --- New team or join ---

Write-StepMsg "What would you like to do?"
Write-Host "  1) Start a new team"
Write-Host "  2) Join an existing team"
Write-Host ""
$choice = Read-Host "  Enter 1 or 2"

$teamSlug = ''

# --- Create new team ---

if ($choice -eq '1') {
    Write-Host ""
    while ($true) {
        $rawName = Read-Host "  Team name"
        $teamSlug = Slugify $rawName
        if (-not $teamSlug) {
            Write-FailMsg "Enter a name using letters, numbers, or hyphens."
            continue
        }

        $createErr = $null
        try {
            $null = Invoke-RestMethod -Method Post -Uri "$Provisioner/create-team" `
                -ContentType 'application/json' `
                -Body (@{ team = $teamSlug; username = $username } | ConvertTo-Json -Compress) `
                -ErrorAction Stop
        } catch {
            $createErr = Extract-ApiError $_
        }

        if ($createErr -eq 'team already exists') {
            Write-WarnMsg "Team '$teamSlug' already exists."
            $yn = Read-Host "  Join it instead? (y/n)"
            if ($yn -match '^[Yy]') {
                $choice = '2'
                break
            }
            continue
        } elseif ($createErr) {
            Write-FailMsg $createErr
            continue
        }

        Write-InfoMsg "Team created"
        break
    }

    if ($choice -eq '1') {
        New-Item -ItemType Directory -Force -Path $HACKATHON_DIR | Out-Null
        $targetPath = Join-Path $HACKATHON_DIR $teamSlug
        if (Test-Path $targetPath) { Remove-DirForced $targetPath }

        git clone "$repoUrlBase/$teamSlug.git" $targetPath
        if ($LASTEXITCODE -ne 0) {
            Write-FailMsg "Could not clone the new repo. Contact a hackathon organizer."
            exit 1
        }

        Set-Location $targetPath
        Write-ClaudeSettings $targetPath
        Write-Host "  Installing dependencies (takes a moment)..."
        npm install --silent 2>$null
        if ($LASTEXITCODE -ne 0) { Write-WarnMsg "npm install had warnings (usually fine)" }
        Write-InfoMsg "Ready"
    }
}

# --- Join existing team ---

if ($choice -eq '2') {
    if (-not $teamSlug) {
        Write-Host ""
        try {
            $teamsJson = Invoke-RestMethod -Method Get -Uri "$Provisioner/teams" -ErrorAction Stop
            $teams = @($teamsJson.teams)
        } catch {
            $teams = @()
        }

        if ($teams.Count -eq 0) {
            Write-FailMsg "No teams exist yet. Choose option 1 to start one."
            exit 1
        }

        Write-Host "  Available teams:"
        foreach ($t in $teams) { Write-Host "    - $t" }
        Write-Host ""

        while ($true) {
            $rawName = Read-Host "  Team to join"
            $teamSlug = Slugify $rawName
            if ($teams -contains $teamSlug) { break }
            Write-FailMsg "Team '$teamSlug' not found. Try again."
        }
    }

    Write-StepMsg "Joining team '$teamSlug'..."

    try {
        $null = Invoke-RestMethod -Method Post -Uri "$Provisioner/join-team" `
            -ContentType 'application/json' `
            -Body (@{ team = $teamSlug; username = $username } | ConvertTo-Json -Compress) `
            -ErrorAction Stop
    } catch {}

    Write-InfoMsg "Added to team"

    New-Item -ItemType Directory -Force -Path $HACKATHON_DIR | Out-Null
    $targetPath = Join-Path $HACKATHON_DIR $teamSlug

    if (Test-Path $targetPath) {
        Write-WarnMsg "Directory exists — pulling latest..."
        Set-Location $targetPath
        git remote set-url origin "$repoUrlBase/$teamSlug.git" 2>$null
        git pull --rebase origin main 2>$null
        Write-ClaudeSettings $targetPath
    } else {
        git clone "$repoUrlBase/$teamSlug.git" $targetPath
        if ($LASTEXITCODE -ne 0) {
            Write-FailMsg "Could not clone the repo. Contact a hackathon organizer."
            exit 1
        }
        Set-Location $targetPath
        Write-ClaudeSettings $targetPath
        Write-Host "  Installing dependencies (takes a moment)..."
        npm install --silent 2>$null
        if ($LASTEXITCODE -ne 0) { Write-WarnMsg "npm install had warnings (usually fine)" }
    }

    Write-InfoMsg "Ready"
}

# --- Done ---

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   You're all set!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Team:    $teamSlug"
Write-Host "  Project: $(Join-Path $HACKATHON_DIR $teamSlug)"
Write-Host ""
Write-Host "Next steps - copy and paste each command into this PowerShell window:" -ForegroundColor White
Write-Host ""

$stepNum = 1

if (-not (Test-Cmd claude)) {
    Write-Host "  $stepNum. Install Claude Code (takes ~30 seconds):"
    Write-Host ""
    Write-Host "     irm https://claude.ai/install.ps1 | iex" -ForegroundColor Blue
    Write-Host ""
    $stepNum++
}

Write-Host "  $stepNum. Go to your project folder:"
Write-Host ""
Write-Host "     cd '$(Join-Path $HACKATHON_DIR $teamSlug)'" -ForegroundColor Blue
Write-Host ""
$stepNum++

Write-Host "  $stepNum. Start Claude Code:"
Write-Host ""
Write-Host "     claude" -ForegroundColor Blue
Write-Host ""
$stepNum++

Write-Host "  $stepNum. Tell Claude what you want to build! Try something like:"
Write-Host ""
Write-Host "     I want to build a dashboard for tracking onboarding - make it look like Bubble" -ForegroundColor Blue
Write-Host ""
Write-Host "     Other useful things to say to Claude:"
Write-Host "       `"deploy this`"                   - get a shareable link"
Write-Host "       `"save my work`"                  - commit & push"
Write-Host "       `"get my teammate's changes`"     - pull the latest from teammates"
Write-Host ""
Write-Host "  Stuck? Ask a hackathon organizer or post in #hackathon on Slack." -ForegroundColor Yellow
Write-Host ""
