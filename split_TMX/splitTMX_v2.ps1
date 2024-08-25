# Function to prompt for a file
function Get-TMXFile {
    Add-Type -AssemblyName System.Windows.Forms
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "TMX files (*.tmx)|*.tmx"
    $OpenFileDialog.ShowDialog() | Out-Null
    return $OpenFileDialog.FileName
}

# Function to split the TMX file using Regex for TU extraction
function Split-TMXFile {
    param (
        [string]$TMXFilePath,
        [int]$NumParts
    )

    Write-Output "Reading TMX file content from: $TMXFilePath"

    # Read the entire file as text
    $TMXContent = Get-Content -Path $TMXFilePath -Raw

    # Extract the header
    $headerMatch = [regex]::Match($TMXContent, "(?s)(<tmx.*?<body>)")
    if ($headerMatch.Success) {
        $header = $headerMatch.Groups[1].Value
        Write-Output "Header extracted."
    } else {
        Write-Error "Failed to extract the header. Exiting."
        exit
    }

    # Extract the footer
    $footerMatch = [regex]::Match($TMXContent, "(?s)(</body>.*?</tmx>)")
    if ($footerMatch.Success) {
        $footer = $footerMatch.Groups[1].Value
        Write-Output "Footer extracted."
    } else {
        Write-Error "Failed to extract the footer. Exiting."
        exit
    }

    # Extract all TU elements
    $tuMatches = [regex]::Matches($TMXContent, "(?s)(<tu\b.*?</tu>)")
    $segments = @()
    foreach ($match in $tuMatches) {
        $segments += $match.Value
    }

    $totalSegments = $segments.Count
    if ($totalSegments -eq 0) {
        Write-Error "No <tu> segments found in the TMX file. Exiting."
        exit
    }

    Write-Output "Total segments found: $totalSegments"

    $segmentsPerFile = [math]::Ceiling($totalSegments / $NumParts)
    Write-Output "Segments per file: $segmentsPerFile"

    # Get the original filename without extension and the folder path
    $FileName = [System.IO.Path]::GetFileNameWithoutExtension($TMXFilePath)
    $FilePath = [System.IO.Path]::GetDirectoryName($TMXFilePath)

    # Create a new folder for the split files
    $SplitFolderPath = Join-Path -Path $FilePath -ChildPath "Split_$FileName"
    if (-not (Test-Path -Path $SplitFolderPath)) {
        New-Item -Path $SplitFolderPath -ItemType Directory | Out-Null
        Write-Output "Created directory: $SplitFolderPath"
    }

    # Split and write new TMX files
    for ($i = 0; $i -lt $NumParts; $i++) {
        $startIndex = $i * $segmentsPerFile
        $endIndex = [math]::Min(($i + 1) * $segmentsPerFile, $totalSegments) - 1
        Write-Output "Processing file part $($i + 1) - Segments $startIndex to $endIndex"

        if ($endIndex -ge $startIndex) {
            $newBody = $segments[$startIndex..$endIndex] -join "`r`n"
            $newTMXContent = "$header`r`n$newBody`r`n$footer"

            $newFileName = "{0:000}_$FileName.tmx" -f ($i + 1)
            $newFilePath = Join-Path -Path $SplitFolderPath -ChildPath $newFileName
            Write-Output "Writing new TMX file: $newFilePath"
            Set-Content -Path $newFilePath -Value $newTMXContent -Encoding UTF8
            Write-Output "Created file: $newFilePath"
        }
    }
}

# Prompt for TMX file
Write-Output "Please select the TMX file you wish to split."
$TMXFilePath = Get-TMXFile
if (-not $TMXFilePath) {
    Write-Error "No TMX file selected. Exiting."
    exit
}

Write-Output "Selected TMX file: $TMXFilePath"

# Prompt for number of parts
$NumParts = Read-Host "Enter the number of parts to split the TMX file into"

if (-not [int]::TryParse($NumParts, [ref]$NumParts) -or $NumParts -le 0) {
    Write-Error "Invalid number of parts. Exiting."
    exit
}

Write-Output "Number of parts to split the TMX file into: $NumParts"

# Split the TMX file
Split-TMXFile -TMXFilePath $TMXFilePath -NumParts $NumParts
