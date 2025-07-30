# ===================================================================
#  Basic TM Recovery Script with Windows File Dialog
#  Recovers corrupted Trados TMs using SQLite recovery tools
# ===================================================================

# Add Windows Forms for file dialog
Add-Type -AssemblyName System.Windows.Forms

# Function to select TM file
function Select-TMFile {
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Select Corrupted Trados TM File"
    $openFileDialog.Filter = "Trados TM Files (*.sdltm)|*.sdltm|All Files (*.*)|*.*"
    $openFileDialog.InitialDirectory = [Environment]::GetFolderPath("MyDocuments")
    
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $openFileDialog.FileName
    }
    return $null
}

# Select the corrupted TM file
$CorruptDb = Select-TMFile
if (-not $CorruptDb) {
    Write-Host "No file selected. Exiting." -ForegroundColor Red
    exit
}

# ──────────────────────────────────────────────────────────────
#    CONFIGURATION - Dynamic paths based on selected file
# ──────────────────────────────────────────────────────────────
# Path to SQLite tools
$SqliteToolsPath = 'C:\Users\pfilkin\Documents\Scripts\Powershell\sqlite_recovery_scripts\sqlite_tools'
$SqliteExe = Join-Path $SqliteToolsPath 'sqlite3.exe'

# Get the directory and filename of the corrupted TM
$WorkingDir = Split-Path $CorruptDb -Parent
$TMBaseName = [System.IO.Path]::GetFileNameWithoutExtension($CorruptDb)

# Set output paths in the same directory as the TM
$FullDump = Join-Path $WorkingDir "$TMBaseName`_dump_all.sql"
$RecoverDump = Join-Path $WorkingDir "$TMBaseName`_recovered.sql"
$FreshDb = Join-Path $WorkingDir "$TMBaseName`_fresh.sdltm"

# ──────────────────────────────────────────────────────────────
# 0) Verify tools and show configuration
# ──────────────────────────────────────────────────────────────
Clear-Host
Write-Host "=== Trados TM Recovery Tool ===" -ForegroundColor Cyan
Write-Host "Selected TM: $CorruptDb" -ForegroundColor Green
Write-Host "Working Directory: $WorkingDir" -ForegroundColor Green
Write-Host "Recovery will create:" -ForegroundColor Yellow
Write-Host "  - $TMBaseName`_recovered.sql (recovery dump)" -ForegroundColor Gray
Write-Host "  - $TMBaseName`_fresh.sdltm (recovered TM)" -ForegroundColor Gray
Write-Host ""

if (-not (Test-Path $SqliteExe)) {
    Write-Error "SQLite executable not found at: $SqliteExe"
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# ──────────────────────────────────────────────────────────────
# 1) First, try the .recover command
# ──────────────────────────────────────────────────────────────
Write-Host "Step 1: Attempting .recover command..." -ForegroundColor Yellow

# Method 1: Direct command execution
try {
    $output = & $SqliteExe $CorruptDb ".output '$RecoverDump'" ".recover" ".quit" 2>&1
    if ($output -match "error") {
        Write-Host "SQLite reported: $output" -ForegroundColor Red
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}

# Check if recovery dump was created
if (Test-Path $RecoverDump) {
    $size = [math]::Round((Get-Item $RecoverDump).Length / 1MB, 2)
    Write-Host "Recovery dump created successfully: $size MB" -ForegroundColor Green
}
else {
    Write-Host "Recovery dump was not created. Trying alternative approach..." -ForegroundColor Yellow
    
    # Method 2: Using cmd
    $cmd = "echo .output '$RecoverDump' && echo .recover && echo .quit"
    cmd /c "$cmd | `"$SqliteExe`" `"$CorruptDb`"" 2>&1 | Out-Null
}

# ──────────────────────────────────────────────────────────────
# 2) If .recover didn't work, try .dump
# ──────────────────────────────────────────────────────────────
if (-not (Test-Path $RecoverDump) -or (Get-Item $RecoverDump -ErrorAction SilentlyContinue).Length -eq 0) {
    Write-Host "`nStep 2: .recover failed. Trying .dump..." -ForegroundColor Yellow
    
    try {
        $output = & $SqliteExe $CorruptDb ".output '$FullDump'" ".dump" ".quit" 2>&1
        if ($output -match "error") {
            Write-Host "SQLite error during dump: $output" -ForegroundColor Red
        }
        
        if (Test-Path $FullDump) {
            Write-Host "Dump created successfully" -ForegroundColor Green
            $RecoverDump = $FullDump
        }
    }
    catch {
        Write-Host "Error during dump: $_" -ForegroundColor Red
    }
}

# ──────────────────────────────────────────────────────────────
# 3) Alternative: Try table-by-table extraction
# ──────────────────────────────────────────────────────────────
if (-not (Test-Path $RecoverDump) -or (Get-Item $RecoverDump -ErrorAction SilentlyContinue).Length -eq 0) {
    Write-Host "`nStep 3: Trying table-by-table extraction..." -ForegroundColor Yellow
    
    $recoveryContent = @()
    
    try {
        $tables = & $SqliteExe $CorruptDb "SELECT name FROM sqlite_master WHERE type='table';" 2>&1
        
        if ($tables -and $tables -notmatch "error") {
            $recoveryContent += "BEGIN TRANSACTION;"
            
            foreach ($table in $tables) {
                if ($table -and $table.Trim()) {
                    Write-Host "  Extracting table: $table" -ForegroundColor Gray
                    
                    $schema = & $SqliteExe $CorruptDb "SELECT sql FROM sqlite_master WHERE type='table' AND name='$table';" 2>&1
                    if ($schema -notmatch "error" -and $schema) {
                        $recoveryContent += "$schema;"
                        
                        $data = & $SqliteExe $CorruptDb ".mode insert $table" "SELECT * FROM $table;" 2>&1
                        if ($data -notmatch "error") {
                            $recoveryContent += $data
                        }
                    }
                }
            }
            
            $recoveryContent += "COMMIT;"
            $recoveryContent | Out-File -FilePath $RecoverDump -Encoding UTF8
            Write-Host "Table extraction completed" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Error during table extraction: $_" -ForegroundColor Red
    }
}

# ──────────────────────────────────────────────────────────────
# 4) Import the recovered SQL into a new database
# ──────────────────────────────────────────────────────────────
if (Test-Path $RecoverDump) {
    Write-Host "`nStep 4: Importing recovered data into fresh database..." -ForegroundColor Yellow
    
    if (Test-Path $FreshDb) {
        Remove-Item $FreshDb -Force
        Write-Host "Removed existing fresh database" -ForegroundColor Gray
    }
    
    try {
        $sqlContent = Get-Content $RecoverDump -Raw
        $sqlContent | & $SqliteExe $FreshDb
        Write-Host "Import completed" -ForegroundColor Green
    }
    catch {
        Write-Error "Error during import: $_"
        
        Write-Host "Trying alternative import method..." -ForegroundColor Yellow
        & $SqliteExe $FreshDb ".read '$RecoverDump'" 2>&1
    }
}
else {
    Write-Error "No recovery dump file found to import!"
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# ──────────────────────────────────────────────────────────────
# 5) Final integrity check
# ──────────────────────────────────────────────────────────────
if (Test-Path $FreshDb) {
    Write-Host "`nStep 5: Running integrity check on fresh database..." -ForegroundColor Yellow
    $integrityResult = & $SqliteExe $FreshDb "PRAGMA integrity_check;" 2>&1
    
    if ($integrityResult -eq "ok") {
        Write-Host "Integrity check passed! ✓" -ForegroundColor Green
        Write-Host "`nRecovery complete. Fresh database created at:" -ForegroundColor Green
        Write-Host $FreshDb -ForegroundColor Cyan
    }
    else {
        Write-Host "Integrity check result: $integrityResult" -ForegroundColor Red
    }
    
    Write-Host "`nDatabase statistics:" -ForegroundColor Yellow
    $tableCount = & $SqliteExe $FreshDb "SELECT COUNT(*) FROM sqlite_master WHERE type='table';" 2>&1
    Write-Host "Tables recovered: $tableCount" -ForegroundColor Cyan
    
    # Try to get translation unit count
    $tuCount = & $SqliteExe $FreshDb "SELECT COUNT(*) FROM translation_units;" 2>&1
    if ($tuCount -notmatch "error") {
        Write-Host "Translation units recovered: $tuCount" -ForegroundColor Cyan
    }
}

# ──────────────────────────────────────────────────────────────
# 6) Summary
# ──────────────────────────────────────────────────────────────
Write-Host "`n=== Recovery Summary ===" -ForegroundColor Green
Write-Host "Original TM: $(Split-Path $CorruptDb -Leaf)" -ForegroundColor Gray
Write-Host "Recovered TM: $(Split-Path $FreshDb -Leaf)" -ForegroundColor Gray

if (Test-Path $RecoverDump) {
    $size = [math]::Round((Get-Item $RecoverDump).Length / 1MB, 2)
    Write-Host "Recovery dump size: $size MB" -ForegroundColor Gray
}

Write-Host "`nAll output files are in: $WorkingDir" -ForegroundColor Cyan
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")