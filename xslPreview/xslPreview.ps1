# Only proceed if 2 files were passed in
if ($args.Count -ne 2) {
    Write-Host "Please select exactly one XML file and one XSL file, then use 'Send to'."
    exit 1
}

$xmlFile = $null
$xslFile = $null

# Identify XML and XSL/XSLT files
foreach ($f in $args) {
    if ($f.ToLower().EndsWith(".xml")) {
        $xmlFile = $f
    } elseif ($f.ToLower().EndsWith(".xsl") -or $f.ToLower().EndsWith(".xslt")) {
        $xslFile = $f
    }
}

# Ensure both types were found and files exist
if (-not $xmlFile -or -not $xslFile) {
    Write-Host "You must select one XML file and one XSL or XSLT file."
    exit 1
}
if (-not (Test-Path $xmlFile) -or -not (Test-Path $xslFile)) {
    Write-Host "One or both selected files do not exist or are inaccessible."
    exit 1
}

# Ensure both files are in the same folder
$xmlFolder = Split-Path $xmlFile -Parent
$xslFolder = Split-Path $xslFile -Parent
if ($xmlFolder -ne $xslFolder) {
    Write-Host "Both XML and XSL/XSLT files must be in the same folder."
    exit 1
}

# Output path in the same folder as input files
$outputBase = Join-Path $xmlFolder "preview.html"
$outputPath = $outputBase
$counter = 1
while (Test-Path $outputPath) {
    $outputPath = Join-Path $xmlFolder "preview_$counter.html"
    $counter++
}

# Temp Python script path
$pyTempPath = "$env:TEMP\xsl_preview_temp.py"

# Write inline Python script with error handling
@"
import webbrowser
from lxml import etree
from pathlib import Path

try:
    xml_file = Path(r'''$xmlFile''')
    xsl_file = Path(r'''$xslFile''')
    output_file = Path(r'''$outputPath''')

    with xml_file.open("rb") as xf, xsl_file.open("rb") as sf:
        xml_doc = etree.parse(xf)
        xsl_doc = etree.parse(sf)
        transform = etree.XSLT(xsl_doc)
        result = transform(xml_doc)
        with output_file.open("wb") as out:
            out.write(etree.tostring(result, pretty_print=True, method="html"))

    webbrowser.open(output_file.as_uri())
except Exception as e:
    print(f"Error: {str(e)}")
    input("Press Enter to exit...")
"@ | Set-Content -Encoding UTF8 -Path $pyTempPath

# Run Python script and handle errors
try {
    $process = Start-Process python -ArgumentList $pyTempPath -NoNewWindow -PassThru -Wait
    if ($process.ExitCode -ne 0) {
        Write-Host "Python script failed to execute. Ensure Python and lxml are installed."
    }
} catch {
    Write-Host "Error running Python script: $_"
} finally {
    # Clean up temporary Python script
    if (Test-Path $pyTempPath) {
        Remove-Item $pyTempPath -Force
    }
}