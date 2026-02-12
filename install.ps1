# Get the directory where this script is located
$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "`n-------------------------------------"
Write-Host "Installing Claude Skills" -ForegroundColor Cyan
Write-Host "-------------------------------------"

# 1. Ensure the target directory exists
$ClaudeSkillsDir = Join-Path $HOME ".claude\skills"
if (-not (Test-Path $ClaudeSkillsDir)) {
    New-Item -ItemType Directory -Force -Path $ClaudeSkillsDir | Out-Null
    Write-Host "Created skills directory: $ClaudeSkillsDir"
}

# 2. Loop through subdirectories and create junctions
$SkillFolders = Get-ChildItem -Path $RepoDir -Directory | Where-Object { $_.Name -ne ".git" }

foreach ($Skill in $SkillFolders) {
    $SkillName = $Skill.Name
    $Target = Join-Path $ClaudeSkillsDir $SkillName
    $Source = $Skill.FullName

    # Check if it has a SKILL.md file (valid skill folder)
    if (-not (Test-Path (Join-Path $Source "SKILL.md"))) {
        Write-Host "  - Skipping $SkillName (no SKILL.md found)" -ForegroundColor DarkGray
        continue
    }

    # Check if target already exists
    if (Test-Path $Target) {
        $Item = Get-Item $Target -Force
        # Check if it's already a junction pointing to the correct source
        if ($Item.LinkType -eq "Junction" -and $Item.Target -eq $Source) {
            Write-Host "  = Already linked: $SkillName" -ForegroundColor DarkGray
            continue
        }
        # Different target or not a junction - replace it
        Write-Host "  - Replacing existing $SkillName..." -ForegroundColor Yellow
        Remove-Item -Path $Target -Force -Recurse
    }

    # Create the junction (Windows equivalent of symlink for directories)
    New-Item -ItemType Junction -Path $Target -Target $Source | Out-Null
    Write-Host "  + Linked $SkillName" -ForegroundColor Green
}

Write-Host "Skills installed successfully!" -ForegroundColor Green

Write-Host "`n-------------------------------------"
Write-Host "Secrets Management (Doppler)" -ForegroundColor Cyan
Write-Host "-------------------------------------"

# 1. Check if Doppler is installed
if (-not (Get-Command "doppler" -ErrorAction SilentlyContinue)) {
    Write-Warning "Doppler CLI is not installed. Skipping secrets sync."
    return
}

# 2. Check Login Status
$LoginCheck = doppler me --json 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Authentication required. Opening browser..." -ForegroundColor Yellow
    # This command pauses the script until you finish logging in via the browser
    doppler login -y --no-read-env-file

    # Verify login worked
    $LoginCheck = doppler me --json 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Login failed or was cancelled. Skipping secrets sync."
        return
    }
}

# 3. Setup Project Config
# Check if config exists for this specific folder
if (-not (Test-Path "$RepoDir\.doppler.yaml")) {
    Write-Host "Linking directory to Doppler project 'claude-skills'..."

    # We use --no-read-env-file to prevent conflicts
    doppler setup --project claude-skills --config dev --no-interactive 2>$null

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Could not link project. Please run 'doppler setup' manually once to select your project."
        return
    }
}

# 4. Download and Set Environment Variables
Write-Host "Fetching secrets from Cloud..." -ForegroundColor Cyan

# Fetch secrets (Checking Exit Code explicitly)
$JsonData = doppler secrets download --no-file --format json 2>$null

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to download secrets. You may not have access to the 'claude-skills' project or 'dev' config."
    return
}

try {
    $Secrets = $JsonData | ConvertFrom-Json

    foreach ($Prop in $Secrets.PSObject.Properties) {
        $Key = $Prop.Name
        $Value = $Prop.Value

        # Check current User variable
        $CurrentValue = [System.Environment]::GetEnvironmentVariable($Key, "User")

        if ($CurrentValue -ne $Value) {
            [System.Environment]::SetEnvironmentVariable($Key, $Value, "User")
            Write-Host "  + Updated: $Key" -ForegroundColor Green
        } else {
            Write-Host "  = Verified: $Key" -ForegroundColor DarkGray
        }
    }
    Write-Host "Secrets synced successfully!" -ForegroundColor Green
} catch {
    Write-Error "Failed to parse Doppler secrets."
}
