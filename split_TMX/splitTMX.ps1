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
    
    Write-Output "Reading TMX file content from: $TMXFilePath"
    
    # Read the TMX file content
    $TMXContent = Get-Content -Path $TMXFilePath -Raw
    
    # Define the header and footer
    $Header = @"
<?xml version='1.0' ?>
<!DOCTYPE tmx SYSTEM 'tmx11.dtd'>
<tmx version='1.1'>
<header
  creationtool='TMXtract 1.2 17-10-2017'
  adminlang='EN-US'
  srclang='IT-IT'
>
</header>
<body>
"@

    $Footer = @"
</body>
</tmx>
"@

    Write-Output "Extracting body content from the TMX file"
    
    # Extract body content
    $BodyMatch = [regex]::Match($TMXContent, "(?s)<body>(.*?)</body>")
    if ($BodyMatch.Success) {
        $Body = $BodyMatch.Groups[1].Value
    } else {
        Write-Error "Failed to extract <body> content from the TMX file."
        exit
    }

    Write-Output "Body content extracted. Length: $($Body.Length)"
    
    # Split the body content into <tu> segments
    Write-Output "Splitting body content into <tu> segments"
    $Segments = [regex]::Matches($Body, "(?s)<tu>.*?</tu>") | ForEach-Object { $_.Value }

    Write-Output "Total segments found: $($Segments.Count)"
    
    # Calculate the number of segments per file
    $TotalSegments = $Segments.Count
    $SegmentsPerFile = [math]::Ceiling($TotalSegments / $NumParts)
    Write-Output "Segments per file: $SegmentsPerFile"
    
    # Get the original filename without extension
    $FileName = [System.IO.Path]::GetFileNameWithoutExtension($TMXFilePath)
    $FilePath = [System.IO.Path]::GetDirectoryName($TMXFilePath)
    
    # Split and write new TMX files
    for ($i = 0; $i -lt $NumParts; $i++) {
        $StartIndex = $i * $SegmentsPerFile
        $EndIndex = [math]::Min(($i + 1) * $SegmentsPerFile, $TotalSegments) - 1
        Write-Output "Processing file part $($i + 1) - Segments $StartIndex to $EndIndex"
        
        if ($EndIndex -ge $StartIndex) {
            $NewSegments = $Segments[$StartIndex..$EndIndex]
            $NewBody = $NewSegments -join "`r`n"
            
            # Create the new TMX content
            $NewTMXContent = "$Header`r`n$NewBody`r`n$Footer"
            
            # Write the new TMX file
            $NewFileName = "{0:000}_$FileName.tmx" -f ($i + 1)
            $NewFilePath = Join-Path -Path $FilePath -ChildPath $NewFileName
            Write-Output "Writing new TMX file: $NewFilePath"
            Set-Content -Path $NewFilePath -Value $NewTMXContent -Encoding UTF8
            Write-Output "Created file: $NewFilePath"
        } else {
            Write-Output "Skipping part $($i + 1) due to no segments"
        }
    }
}

# Prompt for TMX file
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
