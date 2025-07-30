# ===================================================================
#  Advanced TM Recovery Script with Complete Toolkit
#  Uses all SQLite tools for comprehensive recovery and analysis
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
$CorruptTM = Select-TMFile
if (-not $CorruptTM) {
    Write-Host "No file selected. Exiting." -ForegroundColor Red
    exit
}

# ──────────────────────────────────────────────────────────────
#    CONFIGURATION - Dynamic paths based on selected file
# ──────────────────────────────────────────────────────────────
# Path to SQLite tools
$SqliteToolsPath = 'C:\Users\pfilkin\Documents\Scripts\Powershell\sqlite_recovery_scripts\sqlite_tools'
$SqliteExe = Join-Path $SqliteToolsPath 'sqlite3.exe'
$SqliteAnalyzer = Join-Path $SqliteToolsPath 'sqlite3_analyzer.exe'
$SqlDiff = Join-Path $SqliteToolsPath 'sqldiff.exe'
$SqliteRsync = Join-Path $SqliteToolsPath 'sqlite3_rsync.exe'

# Get the directory and filename of the corrupted TM
$WorkingDir = Split-Path $CorruptTM -Parent
$TMBaseName = [System.IO.Path]::GetFileNameWithoutExtension($CorruptTM)

# Create output directory for recovery files
$OutputDir = Join-Path $WorkingDir "$TMBaseName`_recovery_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

# ──────────────────────────────────────────────────────────────
# 0) Verify tools and show configuration
# ──────────────────────────────────────────────────────────────
Clear-Host
Write-Host "=== Advanced Trados TM Recovery Toolkit ===" -ForegroundColor Cyan
Write-Host "Selected TM: $CorruptTM" -ForegroundColor Green
Write-Host "Output Directory: $OutputDir" -ForegroundColor Green
Write-Host ""

# Check all tools
$tools = @{
    "SQLite"     = $SqliteExe
    "Analyzer"   = $SqliteAnalyzer
    "Diff Tool"  = $SqlDiff
    "Rsync Tool" = $SqliteRsync
}

$allToolsPresent = $true
foreach ($tool in $tools.GetEnumerator()) {
    if (Test-Path $tool.Value) {
        Write-Host "✓ $($tool.Key) found" -ForegroundColor Green
    }
    else {
        Write-Host "✗ $($tool.Key) NOT found at: $($tool.Value)" -ForegroundColor Red
        $allToolsPresent = $false
    }
}

if (-not $allToolsPresent) {
    Write-Host "`nSome tools are missing. Continue anyway? (Y/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -ne 'Y') {
        exit
    }
}

Write-Host "`nStarting recovery process..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

# ──────────────────────────────────────────────────────────────
# 1) Enhanced Database Analysis
# ──────────────────────────────────────────────────────────────
Write-Host "`n=== Phase 1: Database Analysis ===" -ForegroundColor Cyan
$analysisResults = @()
$analysisResults += "DETAILED CORRUPTION ANALYSIS REPORT"
$analysisResults += "==================================="
$analysisResults += "Analysis Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$analysisResults += ""

# Basic file info
$corruptFileInfo = Get-Item $CorruptTM
$analysisResults += "FILE INFORMATION"
$analysisResults += "----------------"
$analysisResults += "File: $($corruptFileInfo.Name)"
$analysisResults += "Size: $([math]::Round($corruptFileInfo.Length / 1MB, 2)) MB"
$analysisResults += "Last Modified: $($corruptFileInfo.LastWriteTime)"
$analysisResults += ""

# Try to get basic database info
Write-Host "Checking database integrity..." -ForegroundColor Yellow
$integrityCheck = & $SqliteExe $CorruptTM "PRAGMA integrity_check;" 2>&1
$analysisResults += "INTEGRITY CHECK RESULTS"
$analysisResults += "-----------------------"
if ($integrityCheck -match "error|malformed") {
    $analysisResults += "Status: CORRUPTED"
    $analysisResults += "Details: $integrityCheck"
}
else {
    $analysisResults += "Status: $integrityCheck"
}
$analysisResults += ""

# Try to identify which tables are accessible
Write-Host "Identifying accessible tables..." -ForegroundColor Yellow
$analysisResults += "TABLE ACCESSIBILITY"
$analysisResults += "------------------"
$tables = & $SqliteExe $CorruptTM ".tables" 2>&1
if ($tables -notmatch "error") {
    # Tables command returns space-separated table names, potentially multiple per line
    $tableList = ($tables -split '\s+') | Where-Object { $_ -and $_ -ne '' }
    $analysisResults += "Accessible tables found: $($tableList.Count)"
    $analysisResults += ""
    
    # Check each table's accessibility and row count
    $accessibleCount = 0
    $corruptedCount = 0
    
    foreach ($table in $tableList) {
        if ($table) {
            try {
                $rowCount = & $SqliteExe $CorruptTM "SELECT COUNT(*) FROM '$table';" 2>&1
                if ($rowCount -match '^\d+$') {
                    $analysisResults += "  ✓ ${table}: $rowCount rows"
                    $accessibleCount++
                }
                else {
                    $analysisResults += "  ✗ ${table}: CORRUPTED/UNREADABLE"
                    $corruptedCount++
                }
            }
            catch {
                $analysisResults += "  ✗ ${table}: ERROR ACCESSING"
                $corruptedCount++
            }
        }
    }
    
    $analysisResults += ""
    $analysisResults += "Summary: $accessibleCount accessible, $corruptedCount corrupted/unreadable"
}
else {
    $analysisResults += "Unable to list tables - severe corruption"
    $analysisResults += "Error: $tables"
}
$analysisResults += ""

# Check for character encoding issues
Write-Host "Checking for character encoding issues..." -ForegroundColor Yellow
$analysisResults += "CHARACTER ENCODING ANALYSIS"
$analysisResults += "---------------------------"
try {
    $suspectChars = & $SqliteExe $CorruptTM @"
SELECT COUNT(*) as count 
FROM translation_units 
WHERE source_segment LIKE '%�%' 
   OR target_segment LIKE '%�%'
   OR source_segment GLOB '*[^[:print:]]*'
   OR target_segment GLOB '*[^[:print:]]*';
"@ 2>&1
    
    if ($suspectChars -match '^\d+$') {
        $analysisResults += "Segments with suspect characters: $suspectChars"
    }
    
    # Sample some problematic segments
    $samples = & $SqliteExe $CorruptTM @"
SELECT id, 
       CASE WHEN source_segment LIKE '%�%' THEN 'Source has replacement chars' 
            WHEN target_segment LIKE '%�%' THEN 'Target has replacement chars'
            ELSE 'Non-printable characters detected' 
       END as issue
FROM translation_units 
WHERE source_segment LIKE '%�%' 
   OR target_segment LIKE '%�%'
LIMIT 5;
"@ 2>&1
    
    if ($samples -and $samples -notmatch "error") {
        $analysisResults += "Sample problematic segments:"
        $analysisResults += $samples
    }
}
catch {
    $analysisResults += "Unable to analyze character encoding"
}
$analysisResults += ""

# Estimate recovery potential
Write-Host "Estimating recovery potential..." -ForegroundColor Yellow
$analysisResults += "RECOVERY ESTIMATION"
$analysisResults += "-------------------"

# Use the analyzer if available
if (Test-Path $SqliteAnalyzer) {
    Write-Host "Running SQLite analyzer..." -ForegroundColor Yellow
    $analyzerOutput = & $SqliteAnalyzer $CorruptTM 2>&1
    
    if ($analyzerOutput -notmatch "error|malformed") {
        # Extract useful metrics
        $dbSize = $analyzerOutput | Select-String "Database size:" | ForEach-Object { $_.Line }
        $pageSize = $analyzerOutput | Select-String "Page size:" | ForEach-Object { $_.Line }
        $freePages = $analyzerOutput | Select-String "Free pages:" | ForEach-Object { $_.Line }
        
        if ($dbSize) { $analysisResults += $dbSize }
        if ($pageSize) { $analysisResults += $pageSize }
        if ($freePages) { $analysisResults += $freePages }
    }
    
    # Save full analyzer output
    $analyzerOutput | Out-File "$OutputDir\sqlite_analyzer_output.txt"
    $analysisResults += "Full SQLite analyzer output saved to: sqlite_analyzer_output.txt"
}
else {
    $analysisResults += "SQLite analyzer not available for detailed metrics"
}

# Save analysis report
$analysisResults | Out-File "$OutputDir\analysis_report.txt"
Write-Host "Analysis complete. Detailed report saved." -ForegroundColor Green

# ──────────────────────────────────────────────────────────────
# 2) Standard Recovery Attempt
# ──────────────────────────────────────────────────────────────
Write-Host "`n=== Phase 2: Standard Recovery ===" -ForegroundColor Cyan
Write-Host "Attempting .recover command..." -ForegroundColor Yellow

$recoveryFile = "$OutputDir\standard_recovery.sql"
$output = & $SqliteExe $CorruptTM ".output '$recoveryFile'" ".recover" ".quit" 2>&1

if (Test-Path $recoveryFile) {
    $size = [math]::Round((Get-Item $recoveryFile).Length / 1MB, 2)
    Write-Host "Recovery dump created: $size MB" -ForegroundColor Green
}
else {
    Write-Host "Standard recovery failed, trying alternative methods..." -ForegroundColor Yellow
}

# ──────────────────────────────────────────────────────────────
# 3) Table-by-Table Extraction
# ──────────────────────────────────────────────────────────────
Write-Host "`n=== Phase 3: Individual Table Extraction ===" -ForegroundColor Cyan

# Get list of tables
$tables = & $SqliteExe $CorruptTM "SELECT name FROM sqlite_master WHERE type='table';" 2>&1

if ($tables -and $tables -notmatch "error") {
    $criticalTables = @(
        'translation_units',
        'translation_unit_variants', 
        'attributes',
        'date_attributes',
        'picklist_values',
        'contexts',
        'resources',
        'tm_metadata',
        'fields'
    )
    
    foreach ($table in $tables) {
        if ($table -and $table.Trim()) {
            $priority = if ($criticalTables -contains $table) { "[CRITICAL]" } else { "[STANDARD]" }
            Write-Host "  $priority Extracting: $table" -ForegroundColor Gray
            
            # Get schema
            $schemaFile = "$OutputDir\schema_$table.sql"
            & $SqliteExe $CorruptTM "SELECT sql FROM sqlite_master WHERE type='table' AND name='$table';" > $schemaFile 2>&1
            
            # Get data
            $dataFile = "$OutputDir\data_$table.sql"
            $extractCmd = @"
.mode insert $table
.output '$dataFile'
SELECT * FROM $table;
"@
            $extractCmd | & $SqliteExe $CorruptTM 2>&1 | Out-Null
            
            if ((Test-Path $dataFile) -and (Get-Item $dataFile).Length -gt 0) {
                Write-Host "    ✓ Extracted successfully" -ForegroundColor Green
            }
            else {
                Write-Host "    ✗ Failed to extract" -ForegroundColor Red
            }
        }
    }
}

# ──────────────────────────────────────────────────────────────
# 4) Raw Data Export (CSV format for emergency recovery)
# ──────────────────────────────────────────────────────────────
Write-Host "`n=== Phase 4: Raw Translation Export ===" -ForegroundColor Cyan
Write-Host "Attempting to export translations to CSV..." -ForegroundColor Yellow

# First try to export from the corrupted database
$csvExport = @"
.mode csv
.headers on
.output '$OutputDir\raw_translations_corrupted.csv'
SELECT 
    tu.id,
    tu.source_segment,
    tu.target_segment,
    tu.creation_date,
    tu.change_date,
    tu.change_user,
    tu.last_used_date,
    tu.usage_counter
FROM translation_units tu
WHERE tu.source_segment IS NOT NULL 
  AND tu.target_segment IS NOT NULL
ORDER BY tu.id;
"@

$csvExport | & $SqliteExe $CorruptTM 2>&1 | Out-Null

if (Test-Path "$OutputDir\raw_translations_corrupted.csv") {
    $fileSize = (Get-Item "$OutputDir\raw_translations_corrupted.csv").Length
    if ($fileSize -gt 100) {
        $lineCount = (Get-Content "$OutputDir\raw_translations_corrupted.csv" | Measure-Object -Line).Lines - 1
        Write-Host "Exported $lineCount translation units from corrupted database" -ForegroundColor Green
        Move-Item "$OutputDir\raw_translations_corrupted.csv" "$OutputDir\raw_translations.csv" -Force
    }
    else {
        Write-Host "Direct export failed due to corruption" -ForegroundColor Yellow
        Remove-Item "$OutputDir\raw_translations_corrupted.csv" -Force -ErrorAction SilentlyContinue
    }
}

# ──────────────────────────────────────────────────────────────
# 5) Create Fresh Database from Recovery
# ──────────────────────────────────────────────────────────────
Write-Host "`n=== Phase 5: Creating Fresh Database ===" -ForegroundColor Cyan

$freshDb = "$OutputDir\$TMBaseName`_recovered.sdltm"

# Find the best recovery file to use
$recoverySource = if (Test-Path "$OutputDir\standard_recovery.sql") {
    "$OutputDir\standard_recovery.sql"
}
else {
    # Combine all table extracts
    $combinedFile = "$OutputDir\combined_recovery.sql"
    $combined = @("BEGIN TRANSACTION;")
    
    Get-ChildItem "$OutputDir\schema_*.sql" | ForEach-Object {
        $combined += Get-Content $_
    }
    Get-ChildItem "$OutputDir\data_*.sql" | ForEach-Object {
        $combined += Get-Content $_
    }
    
    $combined += "COMMIT;"
    $combined | Out-File $combinedFile -Encoding UTF8
    $combinedFile
}

if ($recoverySource -and (Test-Path $recoverySource)) {
    Write-Host "Importing recovery data..." -ForegroundColor Yellow
    Get-Content $recoverySource -Raw | & $SqliteExe $freshDb 2>&1 | Out-Null
    
    # Integrity check
    $integrity = & $SqliteExe $freshDb "PRAGMA integrity_check;" 2>&1
    if ($integrity -eq "ok") {
        Write-Host "✓ Fresh database created successfully!" -ForegroundColor Green
        
        # Get statistics
        $stats = @{}
        $stats.Tables = & $SqliteExe $freshDb "SELECT COUNT(*) FROM sqlite_master WHERE type='table';" 2>&1
        $stats.TUs = & $SqliteExe $freshDb "SELECT COUNT(*) FROM translation_units;" 2>&1
        
        Write-Host "`nRecovered database statistics:" -ForegroundColor Cyan
        Write-Host "  Tables: $($stats.Tables)" -ForegroundColor Gray
        if ($stats.TUs -notmatch "error") {
            Write-Host "  Translation Units: $($stats.TUs)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "✗ Integrity check failed: $integrity" -ForegroundColor Red
    }
}

# ──────────────────────────────────────────────────────────────
# 6) Differential Analysis (if backup exists)
# ──────────────────────────────────────────────────────────────
Write-Host "`n=== Phase 6: Checking for Backup Comparison ===" -ForegroundColor Cyan

# Look for potential backup files
$potentialBackups = Get-ChildItem $WorkingDir -Filter "*.sdltm" | 
Where-Object { $_.FullName -ne $CorruptTM -and $_.Name -match "backup|copy|original" }

if ($potentialBackups -and (Test-Path $SqlDiff)) {
    Write-Host "Found potential backup files:" -ForegroundColor Yellow
    $potentialBackups | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
    
    Write-Host "`nCompare with backup? (Y/N)" -ForegroundColor Yellow
    $response = Read-Host
    
    if ($response -eq 'Y') {
        $backup = $potentialBackups[0].FullName
        Write-Host "Comparing with: $backup" -ForegroundColor Gray
        & $SqlDiff $backup $CorruptTM > "$OutputDir\differential_analysis.sql" 2>&1
    }
}

# ──────────────────────────────────────────────────────────────
# 7) Generate Enhanced Recovery Report
# ──────────────────────────────────────────────────────────────
Write-Host "`n=== Generating Recovery Report ===" -ForegroundColor Cyan

# Calculate recovery statistics
$recoveryStats = @{}
if (Test-Path $freshDb) {
    $recoveryStats.RecoveredTUs = & $SqliteExe $freshDb "SELECT COUNT(*) FROM translation_units;" 2>&1
    $recoveryStats.RecoveredTables = & $SqliteExe $freshDb "SELECT COUNT(*) FROM sqlite_master WHERE type='table';" 2>&1
    $recoveryStats.RecoveredSize = [math]::Round((Get-Item $freshDb).Length / 1MB, 2)
}

# Try to get original TU count from corrupted DB
$originalTUs = & $SqliteExe $CorruptTM "SELECT COUNT(*) FROM translation_units;" 2>&1
if ($originalTUs -match '^\d+$' -and $recoveryStats.RecoveredTUs -match '^\d+$') {
    $recoveryPercentage = [math]::Round(($recoveryStats.RecoveredTUs / $originalTUs) * 100, 2)
}
else {
    $recoveryPercentage = "Unable to calculate"
}

$report = @"
TRADOS TM RECOVERY REPORT
========================
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

ORIGINAL FILE
-------------
Path: $CorruptTM
Size: $([math]::Round((Get-Item $CorruptTM).Length / 1MB, 2)) MB
Last Modified: $((Get-Item $CorruptTM).LastWriteTime)

RECOVERY RESULTS
----------------
Output Directory: $OutputDir

RECOVERY STATISTICS
-------------------
$(if ($originalTUs -match '^\d+$') { "Original translation units: $originalTUs" } else { "Original translation units: Unable to read" })
Recovered translation units: $($recoveryStats.RecoveredTUs)
Recovery rate: $recoveryPercentage%
Recovered database size: $($recoveryStats.RecoveredSize) MB
Number of tables recovered: $($recoveryStats.RecoveredTables)

FILES GENERATED:
$(Get-ChildItem $OutputDir | ForEach-Object { 
    "- $($_.Name) ($([math]::Round($_.Length/1KB, 2)) KB)"
} | Out-String)

RECOVERY STEPS COMPLETED:
$(if (Test-Path "$OutputDir\analysis_report.txt") { "✓ Database analysis" } else { "✗ Database analysis (skipped)" })
$(if (Test-Path "$OutputDir\standard_recovery.sql") { "✓ Standard recovery (.recover)" } else { "✗ Standard recovery (failed)" })
$(if (Get-ChildItem "$OutputDir\data_*.sql") { "✓ Table-by-table extraction" } else { "✗ Table-by-table extraction" })
$(if (Test-Path "$OutputDir\raw_translations.csv") { "✓ CSV export" } else { "✗ CSV export" })
$(if (Test-Path $freshDb) { "✓ Fresh database creation" } else { "✗ Fresh database creation" })

CORRUPTION ANALYSIS
-------------------
See analysis_report.txt for detailed corruption analysis including:
- Integrity check results
- Table accessibility status
- Character encoding issues
- Recovery estimation

NEXT STEPS
----------
1. Open the recovered TM in Trados Studio:
   $freshDb

2. If that fails, import the CSV file:
   $OutputDir\raw_translations.csv

3. Review the detailed corruption analysis:
   $OutputDir\analysis_report.txt

4. Individual table SQL files are available for manual recovery if needed.

IMPORTANT: Create a backup of the recovered TM immediately after verification!
"@

$report | Out-File "$OutputDir\RECOVERY_REPORT.txt"
Write-Host $report

# ──────────────────────────────────────────────────────────────
# 8) Open output folder
# ──────────────────────────────────────────────────────────────
Write-Host "`nOpening recovery folder..." -ForegroundColor Green
Start-Process explorer.exe $OutputDir

# ──────────────────────────────────────────────────────────────
# 9) Export clean CSV from recovered database (final step)
# ──────────────────────────────────────────────────────────────
if (Test-Path $freshDb) {
    Write-Host "`n=== Phase 9: Creating Clean CSV Export ===" -ForegroundColor Cyan
    Write-Host "Extracting readable text from XML segments..." -ForegroundColor Yellow
    
    # Add XML type for parsing
    Add-Type -AssemblyName System.Xml
    
    # Function to extract text from XML segment
    function Extract-TextFromSegment {
        param($xmlSegment)
        
        try {
            # Handle potential encoding issues
            $xmlSegment = $xmlSegment -replace '&(?!amp;|lt;|gt;|quot;|apos;)', '&amp;'
            
            # Parse XML
            $xml = [xml]$xmlSegment
            
            # Extract all text nodes
            $textNodes = $xml.SelectNodes("//text()")
            $text = ($textNodes | ForEach-Object { $_.Value }) -join " "
            
            # Clean up whitespace
            $text = $text -replace '\s+', ' '
            $text = $text.Trim()
            
            return $text
        }
        catch {
            # If XML parsing fails, try to extract text between tags
            $text = $xmlSegment -replace '<[^>]+>', ' '
            $text = $text -replace '\s+', ' '
            return $text.Trim()
        }
    }
    
    # Export raw data with custom delimiter to avoid CSV issues
    $tempRawExport = [System.IO.Path]::GetTempFileName()
    $rawQuery = @"
SELECT 
    id || '|DELIMITER|' || 
    source_segment || '|DELIMITER|' || 
    target_segment || '|DELIMITER|' ||
    creation_date || '|DELIMITER|' ||
    change_date || '|DELIMITER|' ||
    change_user || '|DELIMITER|' ||
    last_used_date || '|DELIMITER|' ||
    usage_counter
FROM translation_units
WHERE length(source_segment) > 0 
  AND length(target_segment) > 0
ORDER BY id;
"@
    
    & $SqliteExe $freshDb "$rawQuery" > $tempRawExport 2>&1
    
    # Process the raw export
    $csvContent = @()
    $csvContent += "id,source_text,target_text,creation_date,change_date,change_user,last_used_date,usage_counter"
    
    $rawLines = Get-Content $tempRawExport
    $processedCount = 0
    $totalLines = $rawLines.Count
    
    Write-Host "Processing $totalLines records..." -ForegroundColor Gray
    
    foreach ($line in $rawLines) {
        if ($line -match '\|DELIMITER\|') {
            $fields = $line -split '\|DELIMITER\|'
            if ($fields.Count -ge 8) {
                $id = $fields[0]
                $sourceXml = $fields[1]
                $targetXml = $fields[2]
                $creationDate = $fields[3]
                $changeDate = $fields[4]
                $changeUser = $fields[5]
                $lastUsedDate = $fields[6]
                $usageCounter = $fields[7]
                
                # Extract text from XML
                $sourceText = Extract-TextFromSegment $sourceXml
                $targetText = Extract-TextFromSegment $targetXml
                
                # Escape for CSV
                $sourceText = $sourceText -replace '"', '""'
                $targetText = $targetText -replace '"', '""'
                $changeUser = $changeUser -replace '"', '""'
                
                $csvLine = "`"$id`",`"$sourceText`",`"$targetText`",`"$creationDate`",`"$changeDate`",`"$changeUser`",`"$lastUsedDate`",`"$usageCounter`""
                $csvContent += $csvLine
                $processedCount++
                
                # Show progress
                if ($processedCount % 500 -eq 0) {
                    Write-Host "  Processed $processedCount of $totalLines records..." -ForegroundColor Gray
                }
            }
        }
    }
    
    Remove-Item $tempRawExport -Force
    
    # Save the clean CSV
    $csvFile = Join-Path $OutputDir "raw_translations.csv"
    $csvContent | Out-File $csvFile -Encoding UTF8
    
    if ($processedCount -gt 0) {
        Write-Host "✓ Exported $processedCount translation units with clean text" -ForegroundColor Green
        Write-Host "  Clean text CSV: $csvFile" -ForegroundColor Cyan
        
        # Show file size
        $cleanSize = [math]::Round((Get-Item $csvFile).Length / 1MB, 2)
        Write-Host "  File size: $cleanSize MB" -ForegroundColor Gray
    }
    else {
        Write-Host "✗ No translation units could be processed" -ForegroundColor Red
    }
}

Write-Host "`nRecovery process complete!" -ForegroundColor Green
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")