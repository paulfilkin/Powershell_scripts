# Function to prompt for a file
function Get-TMXFile {
    Add-Type -AssemblyName System.Windows.Forms
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "TMX files (*.tmx)|*.tmx"
    $OpenFileDialog.ShowDialog() | Out-Null
    return $OpenFileDialog.FileName
}

# Function to split the TMX file
function Split-TMXFile {
    param (
        [string]$TMXFilePath,
        [int]$NumParts
    )
    
    # Read the TMX file content
    $TMXContent = Get-Content -Path $TMXFilePath -Raw

    # Extract header content
    $HeaderMatch = [regex]::Match($TMXContent, "(?s)(<tmx.*?<body>)")
    if ($HeaderMatch.Success) {
        $Header = $HeaderMatch.Groups[1].Value
    } else {
        Write-Error "Failed to extract header from the TMX file."
        exit
    }

    # Extract footer content
    $FooterMatch = [regex]::Match($TMXContent, "(?s)(</body>.*?</tmx>)")
    if ($FooterMatch.Success) {
        $Footer = $FooterMatch.Groups[1].Value
    } else {
        Write-Error "Failed to extract footer from the TMX file."
        exit
    }

    # Extract body content
    $BodyMatch = [regex]::Match($TMXContent, "(?s)<body>(.*?)</body>")
    if ($BodyMatch.Success) {
        $Body = $BodyMatch.Groups[1].Value
    } else {
        Write-Error "Failed to extract <body> content from the TMX file."
        exit
    }

    # Split the body content into <tu> segments
    $Segments = [regex]::Matches($Body, "(?s)<tu\b.*?</tu>") | ForEach-Object { $_.Value }

    if ($Segments.Count -eq 0) {
        Write-Error "No <tu> segments found in the TMX file. Exiting."
        exit
    }
    
    # Calculate the number of segments per file
    $TotalSegments = $Segments.Count
    $SegmentsPerFile = [math]::Ceiling($TotalSegments / $NumParts)
    
    # Get the original filename without extension
    $FileName = [System.IO.Path]::GetFileNameWithoutExtension($TMXFilePath)
    $FilePath = [System.IO.Path]::GetDirectoryName($TMXFilePath)
    
    # Create a new folder for the split files
    $NewFolderPath = Join-Path -Path $FilePath -ChildPath $FileName
    if (-not (Test-Path -Path $NewFolderPath)) {
        New-Item -Path $NewFolderPath -ItemType Directory | Out-Null
    }

    # Split and write new TMX files
    for ($i = 0; $i -lt $NumParts; $i++) {
        $StartIndex = $i * $SegmentsPerFile
        $EndIndex = [math]::Min(($i + 1) * $SegmentsPerFile, $TotalSegments) - 1
        
        if ($EndIndex -ge $StartIndex) {
            $NewFileName = "{0:000}_$FileName.tmx" -f ($i + 1)
            $NewFilePath = Join-Path -Path $NewFolderPath -ChildPath $NewFileName

            # Write the header
            Add-Content -Path $NewFilePath -Value $Header -Encoding UTF8
            
            # Write the segments directly to the file
            for ($j = $StartIndex; $j -le $EndIndex; $j++) {
                Add-Content -Path $NewFilePath -Value $Segments[$j] -Encoding UTF8
            }
            
            # Write the footer
            Add-Content -Path $NewFilePath -Value $Footer -Encoding UTF8
        }
    }
}

# Prompt for TMX file
$TMXFilePath = Get-TMXFile
if (-not $TMXFilePath) {
    Write-Error "No TMX file selected. Exiting."
    exit
}

# Prompt for number of parts
$NumParts = Read-Host "Enter the number of parts to split the TMX file into"

if (-not [int]::TryParse($NumParts, [ref]$NumParts) -or $NumParts -le 0) {
    Write-Error "Invalid number of parts. Exiting."
    exit
}

# Split the TMX file
Split-TMXFile -TMXFilePath $TMXFilePath -NumParts $NumParts

# END OF SCRIPT
