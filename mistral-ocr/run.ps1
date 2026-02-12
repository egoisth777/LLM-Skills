# Get the directory where this script lives
$ScriptDir = $PSScriptRoot

# Define the paths relative to this script
$VenvPython = "$ScriptDir\.venv\Scripts\python.exe"
$TargetScript = "$ScriptDir\mistral_convert.py"

# Check if Venv exists (Safety check)
if (-not (Test-Path $VenvPython)) {
    Write-Error "Virtual environment not found! Run install.ps1 to set it up."
    exit 1
}

# Execute the python script using the Venv python, passing all arguments ($args)
& $VenvPython $TargetScript @args
