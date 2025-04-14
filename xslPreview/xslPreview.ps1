# Only proceed if 2 files were passed in
if ($args.Count -ne 2) {
    Write-Host "Please select exactly one XML file and one XSL file, then use 'Send to'."
    exit 1
}

$xmlFile = $null
$xslFile = $null

foreach ($f in $args) {
    if ($f.ToLower().EndsWith(".xml")) {
        $xmlFile = $f
    } elseif ($f.ToLower().EndsWith(".xsl") -or $f.ToLower().EndsWith(".xslt")) {
        $xslFile = $f
    }
}

# Ensure both types were found
if (-not $xmlFile -or -not $xslFile) {
    Write-Host "You must select one XML file and one XSL or XSLT file."
    exit 1
}

# Output and temp paths
$outputPath = "$env:TEMP\preview.html"
$pyTempPath = "$env:TEMP\xsl_preview_temp.py"

# Write inline Python script
@"
import webbrowser
from lxml import etree
from pathlib import Path

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
"@ | Set-Content -Encoding UTF8 -Path $pyTempPath

# Run it
python $pyTempPath

# Clean up
Remove-Item $pyTempPath -Force
