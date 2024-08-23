###########################################################################
### CONVERTS A BILINGUAL WORD TABLE IN THE FORMAT PROVIDED TO XLIFF 2.0 ###

# Ask for the Word document path
$docFullPath = Read-Host "Please enter the full path to the DOCX file"
if (-Not (Test-Path -Path $docFullPath)) {
    Write-Host "The file path you entered does not exist. Please check the path and try again."
    exit
}

# Prompt for source and target language codes
$sourceLangCode = Read-Host "Enter the source language code (e.g., 'zh-TW')"
$targetLangCode = Read-Host "Enter the target language code (e.g., 'pt-PT')"

# Create the XLIFF file name by changing the DOCX extension to .xliff
$xliffFile = [IO.Path]::ChangeExtension($docFullPath, ".xliff")

# Create a new invisible Word Application object
$wordApp = New-Object -ComObject Word.Application
$wordApp.Visible = $false

function Escape-Xml ($string) {
    $string -replace '&', '&amp;' `
            -replace '<', '&lt;' `
            -replace '>', '&gt;' `
            -replace '"', '&quot;' `
            -replace "'", '&apos;'
}


try {
    # Open the Word document
    $document = $wordApp.Documents.Open($docFullPath)
    $table = $document.Tables.Item(1)

    # Start building the XLIFF content
    $xliffContent = @"
<xliff xmlns="urn:oasis:names:tc:xliff:document:2.0" version="2.0" srcLang="$sourceLangCode" trgLang="$targetLangCode">
<file id="f1" original="word-document">
"@

# Iterate over each row in the table, skipping the header row
for ($i = 2; $i -le $table.Rows.Count; $i++) {
    $sourceText = Escape-Xml ($table.Cell($i, 1).Range.Text -replace "`r`n", "" -replace "`a", "").Trim()
    $targetText = Escape-Xml ($table.Cell($i, 2).Range.Text -replace "`r`n", "" -replace "`a", "").Trim()
    $unitId = "u" + $i
    $xliffContent += "<unit id=`"$unitId`">`r`n  <segment>`r`n    <source>$sourceText</source>`r`n    <target>$targetText</target>`r`n  </segment>`r`n</unit>`r`n"
}

    # Close the XLIFF content
    $xliffContent += @"
</file>
</xliff>
"@

    # Save the XLIFF content to the file
    $xliffContent | Set-Content -Path $xliffFile -Encoding UTF8

    Write-Host "XLIFF 2.0 file has been created at $xliffFile"
}
catch {
    Write-Host "An error occurred: $_"
}
finally {
    # Close the Word document and quit the application
    if ($document) {
        $document.Close($false)
    }
    $wordApp.Quit()

    # Clean up COM objects
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($document) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($wordApp) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}