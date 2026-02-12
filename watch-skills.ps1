# Watch-Skills.ps1
# A background watcher that monitors for new/deleted skill folders and syncs symlinks

param(
    [switch]$Install,      # Install as a scheduled task
    [switch]$Uninstall,    # Remove the scheduled task
    [switch]$Status        # Check if watcher is running
)

$TaskName = "ClaudeSkillsWatcher"
$RepoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeSkillsDir = Join-Path $HOME ".claude\skills"

# ============ Task Scheduler Management ============
if ($Install) {
    # Create a scheduled task that runs at logon
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    # Remove existing task if present
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Description "Watches LLM-Skills repo and syncs symlinks to .claude/skills"

    Write-Host "Installed scheduled task '$TaskName'" -ForegroundColor Green
    Write-Host "The watcher will start automatically at logon." -ForegroundColor Cyan
    Write-Host "To start it now, run: Start-ScheduledTask -TaskName '$TaskName'" -ForegroundColor Cyan
    return
}

if ($Uninstall) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "Removed scheduled task '$TaskName'" -ForegroundColor Yellow
    return
}

if ($Status) {
    $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($Task) {
        $Info = Get-ScheduledTaskInfo -TaskName $TaskName
        Write-Host "Task Status: $($Task.State)" -ForegroundColor Cyan
        Write-Host "Last Run: $($Info.LastRunTime)"
        Write-Host "Next Run: $($Info.NextRunTime)"
    } else {
        Write-Host "Watcher task is not installed." -ForegroundColor Yellow
        Write-Host "Run with -Install to set it up."
    }
    return
}

# ============ Helper Functions ============
function Test-ValidSkill {
    param([string]$FolderPath)
    return (Test-Path (Join-Path $FolderPath "SKILL.md"))
}

function Sync-SkillLink {
    param(
        [string]$SkillName,
        [string]$SourcePath,
        [ValidateSet("Create", "Delete")]
        [string]$Action
    )

    $Target = Join-Path $ClaudeSkillsDir $SkillName

    if ($Action -eq "Create") {
        if (-not (Test-ValidSkill $SourcePath)) {
            return
        }

        # Ensure skills directory exists
        if (-not (Test-Path $ClaudeSkillsDir)) {
            New-Item -ItemType Directory -Force -Path $ClaudeSkillsDir | Out-Null
        }

        # Check if already correctly linked
        if (Test-Path $Target) {
            $Item = Get-Item $Target -Force
            if ($Item.LinkType -eq "Junction" -and $Item.Target -eq $SourcePath) {
                return
            }
            Remove-Item -Path $Target -Force -Recurse
        }

        New-Item -ItemType Junction -Path $Target -Target $SourcePath | Out-Null
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Created link: $SkillName" -ForegroundColor Green
    }
    elseif ($Action -eq "Delete") {
        if (Test-Path $Target) {
            $Item = Get-Item $Target -Force
            # Only remove if it's a junction (don't accidentally delete real folders)
            if ($Item.LinkType -eq "Junction") {
                Remove-Item -Path $Target -Force
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Removed link: $SkillName" -ForegroundColor Yellow
            }
        }
    }
}

# ============ Main Watcher Logic ============
Write-Host "Starting Claude Skills Watcher..." -ForegroundColor Cyan
Write-Host "Monitoring: $RepoDir" -ForegroundColor DarkGray
Write-Host "Target: $ClaudeSkillsDir" -ForegroundColor DarkGray

# Initial sync
$SkillFolders = Get-ChildItem -Path $RepoDir -Directory | Where-Object { $_.Name -ne ".git" }
foreach ($Skill in $SkillFolders) {
    Sync-SkillLink -SkillName $Skill.Name -SourcePath $Skill.FullName -Action "Create"
}

# Create FileSystemWatcher
$Watcher = New-Object System.IO.FileSystemWatcher
$Watcher.Path = $RepoDir
$Watcher.IncludeSubdirectories = $false
$Watcher.EnableRaisingEvents = $true
$Watcher.NotifyFilter = [System.IO.NotifyFilters]::DirectoryName

# Event handlers
$OnCreated = Register-ObjectEvent $Watcher "Created" -Action {
    $Name = $Event.SourceEventArgs.Name
    $FullPath = $Event.SourceEventArgs.FullPath

    if ($Name -eq ".git") { return }

    # Wait a moment for SKILL.md to potentially be created
    Start-Sleep -Milliseconds 500

    $ClaudeSkillsDir = Join-Path $HOME ".claude\skills"
    $Target = Join-Path $ClaudeSkillsDir $Name

    if (Test-Path (Join-Path $FullPath "SKILL.md")) {
        if (-not (Test-Path $ClaudeSkillsDir)) {
            New-Item -ItemType Directory -Force -Path $ClaudeSkillsDir | Out-Null
        }
        if (-not (Test-Path $Target)) {
            New-Item -ItemType Junction -Path $Target -Target $FullPath | Out-Null
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Created link: $Name" -ForegroundColor Green
        }
    }
}

$OnDeleted = Register-ObjectEvent $Watcher "Deleted" -Action {
    $Name = $Event.SourceEventArgs.Name

    if ($Name -eq ".git") { return }

    $ClaudeSkillsDir = Join-Path $HOME ".claude\skills"
    $Target = Join-Path $ClaudeSkillsDir $Name

    if (Test-Path $Target) {
        $Item = Get-Item $Target -Force -ErrorAction SilentlyContinue
        if ($Item -and $Item.LinkType -eq "Junction") {
            Remove-Item -Path $Target -Force
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Removed link: $Name" -ForegroundColor Yellow
        }
    }
}

$OnRenamed = Register-ObjectEvent $Watcher "Renamed" -Action {
    $OldName = $Event.SourceEventArgs.OldName
    $NewName = $Event.SourceEventArgs.Name
    $NewPath = $Event.SourceEventArgs.FullPath

    if ($OldName -eq ".git" -or $NewName -eq ".git") { return }

    $ClaudeSkillsDir = Join-Path $HOME ".claude\skills"

    # Remove old link
    $OldTarget = Join-Path $ClaudeSkillsDir $OldName
    if (Test-Path $OldTarget) {
        $Item = Get-Item $OldTarget -Force -ErrorAction SilentlyContinue
        if ($Item -and $Item.LinkType -eq "Junction") {
            Remove-Item -Path $OldTarget -Force
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Removed link: $OldName" -ForegroundColor Yellow
        }
    }

    # Create new link if valid skill
    if (Test-Path (Join-Path $NewPath "SKILL.md")) {
        $NewTarget = Join-Path $ClaudeSkillsDir $NewName
        if (-not (Test-Path $NewTarget)) {
            New-Item -ItemType Junction -Path $NewTarget -Target $NewPath | Out-Null
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Created link: $NewName" -ForegroundColor Green
        }
    }
}

# Also watch for SKILL.md creation in existing folders
$SkillWatcher = New-Object System.IO.FileSystemWatcher
$SkillWatcher.Path = $RepoDir
$SkillWatcher.Filter = "SKILL.md"
$SkillWatcher.IncludeSubdirectories = $true
$SkillWatcher.EnableRaisingEvents = $true

$OnSkillCreated = Register-ObjectEvent $SkillWatcher "Created" -Action {
    $FullPath = $Event.SourceEventArgs.FullPath
    $SkillDir = Split-Path -Parent $FullPath
    $SkillName = Split-Path -Leaf $SkillDir
    $RepoDir = Split-Path -Parent $SkillDir

    # Only process if it's a direct child of repo
    $ExpectedRepo = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
    if ($RepoDir -ne $ExpectedRepo) { return }

    $ClaudeSkillsDir = Join-Path $HOME ".claude\skills"
    $Target = Join-Path $ClaudeSkillsDir $SkillName

    if (-not (Test-Path $ClaudeSkillsDir)) {
        New-Item -ItemType Directory -Force -Path $ClaudeSkillsDir | Out-Null
    }

    if (-not (Test-Path $Target)) {
        New-Item -ItemType Junction -Path $Target -Target $SkillDir | Out-Null
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Created link: $SkillName (SKILL.md added)" -ForegroundColor Green
    }
}

Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Watcher started. Press Ctrl+C to stop." -ForegroundColor Cyan

# Keep the script running
try {
    while ($true) {
        Wait-Event -Timeout 60
    }
} finally {
    # Cleanup on exit
    Unregister-Event -SourceIdentifier $OnCreated.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $OnDeleted.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $OnRenamed.Name -ErrorAction SilentlyContinue
    Unregister-Event -SourceIdentifier $OnSkillCreated.Name -ErrorAction SilentlyContinue
    $Watcher.Dispose()
    $SkillWatcher.Dispose()
    Write-Host "Watcher stopped." -ForegroundColor Yellow
}
