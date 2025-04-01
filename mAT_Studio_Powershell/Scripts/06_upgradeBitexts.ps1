$ErrorActionPreference = "Stop"

# Set the script to use Trados Studio 2024
$StudioVersion = "Studio18"

# Display a message to indicate the purpose of the script
Write-Host "This script converts a bitext XML to TMX and creates an SDLTM using the PowerShell Toolkit."

# Load the Windows Forms assembly for the file picker dialog
Add-Type -AssemblyName System.Windows.Forms

# Create a file picker dialog
$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.InitialDirectory = "C:\Users\pfilkin\Documents\StudioPowershellToolkit\BiTexts"
$openFileDialog.Filter = "XML Files (*.xml)|*.xml|All Files (*.*)|*.*"
$openFileDialog.Title = "Select a Bitext XML File"

# Show the dialog and check if the user selected a file
$dialogResult = $openFileDialog.ShowDialog()
if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "No file selected. Exiting script."
    exit 1
}

# Get the selected bitext file path
$bitextFile = $openFileDialog.FileName

# Derive the TMX file path: same folder, same name, but with .tmx extension
$tmxFile = [System.IO.Path]::ChangeExtension($bitextFile, ".tmx")

# Step 1: Convert Bitext XML to TMX
try {
    # Load the bitext XML file with proper encoding
    [xml]$bitextXml = Get-Content -Path $bitextFile -Encoding UTF8

    # Get the current date in TMX format (e.g., 20250401T120000Z)
    $creationDate = (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")

    # Create XML writer settings for proper formatting
    $xmlWriterSettings = New-Object System.Xml.XmlWriterSettings
    $xmlWriterSettings.Indent = $true
    $xmlWriterSettings.Encoding = [System.Text.Encoding]::UTF8
    $xmlWriterSettings.OmitXmlDeclaration = $false

    # Create a new XML writer to build the TMX file
    $writer = [System.Xml.XmlWriter]::Create($tmxFile, $xmlWriterSettings)

    # Write the XML declaration and DOCTYPE
    $writer.WriteStartDocument()
    # $writer.WriteDocType("tmx", $null, "tmx14.dtd", $null)  # DTD removed


    # Start the TMX element
    $writer.WriteStartElement("tmx")
    $writer.WriteAttributeString("version", "1.4")

    # Write the header
    $writer.WriteStartElement("header")
    $writer.WriteAttributeString("creationtool", "PowerShell Script")
    $writer.WriteAttributeString("creationtoolversion", "1.0")
    $writer.WriteAttributeString("datatype", "plaintext")
    $writer.WriteAttributeString("segtype", "sentence")
    $writer.WriteAttributeString("adminlang", "en-us")
    $writer.WriteAttributeString("srclang", "en")
    $writer.WriteAttributeString("creationdate", $creationDate)
    $writer.WriteEndElement() # header

    # Write the body
    $writer.WriteStartElement("body")

    # Check if there are any records to process
    if (-not $bitextXml.bitext.record) {
        $writer.WriteEndElement() # body
        $writer.WriteEndElement() # tmx
        $writer.WriteEndDocument()
        $writer.Close()
        Write-Error "No records found in the bitext file. Please ensure the file contains valid bitext data."
        exit 1
    }

    # Loop through each record in the bitext
    foreach ($record in $bitextXml.bitext.record) {
        # Extract source (eng) and target (fra) segments using InnerText
        $sourceText = $record.eng.InnerText
        $targetText = $record.fra.InnerText

        # Validate that both source and target texts exist
        if (-not $sourceText -or -not $targetText) {
            Write-Warning "Skipping record with wuid '$($record.wuid)' because it is missing source or target text."
            continue
        }

        # Create a new translation unit (tu)
        $writer.WriteStartElement("tu")

        # Create source tuv (translation unit variant) for English
        $writer.WriteStartElement("tuv")
        $writer.WriteAttributeString("lang", "http://www.w3.org/XML/1998/namespace", "en")
        $writer.WriteStartElement("seg")
        $writer.WriteString($sourceText)
        $writer.WriteEndElement() # seg
        $writer.WriteEndElement() # tuv

        # Create target tuv for French
        $writer.WriteStartElement("tuv")
        $writer.WriteAttributeString("lang", "http://www.w3.org/XML/1998/namespace", "fr")
        $writer.WriteStartElement("seg")
        $writer.WriteString($targetText)
        $writer.WriteEndElement() # seg
        $writer.WriteEndElement() # tuv

        $writer.WriteEndElement() # tu
    }

    $writer.WriteEndElement() # body
    $writer.WriteEndElement() # tmx
    $writer.WriteEndDocument()
    $writer.Close()

    Write-Host "TMX file created successfully: $tmxFile"
}
catch {
    Write-Error "An error occurred during TMX creation: $_"
    if ($writer) { $writer.Close() }
    exit 1
}

# Step 2: Create SDLTM from the TMX file
try {
    # Notify the user that the necessary modules for Trados Studio will be loaded next
    Write-Host "Loading PowerShell Toolkit modules for Trados Studio..."

    # Determine the script's directory
    $scriptPath = $MyInvocation.MyCommand.Path
    $scriptParentDir = Split-Path $scriptPath -Parent

    # Attempt to find the Modules directory first relative to the script location
    $modulesDir = Join-Path $scriptParentDir "Modules"

    # Check PSModulePath for the correct module directory
    $customModulePath = $Env:PSModulePath -split ';' | ForEach-Object {
        if ($_ -and (Test-Path $_)) {
            $potentialPath = Join-Path $_ "ToolkitInitializer\ToolkitInitializer.psm1"
            if (Test-Path $potentialPath) {
                return $_
            }
        }
    }

    # If no valid path is found in PSModulePath, fall back to default Documents location
    if (-not (Test-Path $modulesDir)) {
        if ($customModulePath) {
            $modulesDir = $customModulePath
        }
        else {
            $modulesDir = Join-Path $Env:USERPROFILE "Documents\WindowsPowerShell\Modules"
        }
    }

    # Import the ToolkitInitializer module to initialize the Trados Studio environment
    $modulePath = Join-Path $modulesDir "ToolkitInitializer\ToolkitInitializer.psm1"
    if (Test-Path $modulePath) {
        Import-Module -Name $modulePath
    }
    else {
        Write-Host "ToolkitInitializer module not found at $modulePath"
        exit 1
    }

    # Import the specific toolkit modules for SDL Trados Studio
    Import-ToolkitModules $StudioVersion

    # Notify the user that the script will now create a new Translation Memory (TM)
    Write-Host "Now creating a new Translation Memory (SDLTM) from the TMX file..."

    # Set the directory where the new TM will be saved
    $tmDirectory = [System.IO.Path]::GetDirectoryName($tmxFile)

    # Ensure the TMX file exists
    if (-not (Test-Path $tmxFile)) {
        Write-Host "The TMX file does not exist at $tmxFile. Exiting."
        exit 1
    }

    # Use XmlReader with settings to allow DTD processing
    $readerSettings = New-Object System.Xml.XmlReaderSettings
    $readerSettings.DtdProcessing = [System.Xml.DtdProcessing]::Parse
    $xmlReader = [System.Xml.XmlReader]::Create($tmxFile, $readerSettings)

    $sourceLangCode = $null
    $targetLangCode = $null

    while ($xmlReader.Read()) {
        if ($xmlReader.NodeType -eq [System.Xml.XmlNodeType]::Element -and $xmlReader.Name -eq "tuv") {
            if (-not $sourceLangCode) {
                $sourceLangCode = $xmlReader.GetAttribute("xml:lang")
            }
            elseif (-not $targetLangCode) {
                $targetLangCode = $xmlReader.GetAttribute("xml:lang")
                break  # Exit loop once both codes are found
            }
        }
    }

    $xmlReader.Close()

    if ($sourceLangCode -and $targetLangCode) {
        Add-Type -AssemblyName System.Windows.Forms
    
        # Function to prompt for language selection
        function Prompt-LanguageCode {
            param (
                [string]$title,
                [string]$defaultValue
            )
    
            $form = New-Object System.Windows.Forms.Form
            $form.Text = $title
            $form.Size = New-Object System.Drawing.Size(400, 160)
            $form.StartPosition = "CenterScreen"
    
            $label = New-Object System.Windows.Forms.Label
            $label.Text = "Enter language code (must be fully qualified, en-US for example):"
            $label.AutoSize = $true
            $label.Location = New-Object System.Drawing.Point(10, 10)
            $form.Controls.Add($label)
    
            $textBox = New-Object System.Windows.Forms.TextBox
            $textBox.Text = $defaultValue
            $textBox.Location = New-Object System.Drawing.Point(10, 35)
            $textBox.Width = 360
            $form.Controls.Add($textBox)
    
            $okButton = New-Object System.Windows.Forms.Button
            $okButton.Text = "OK"
            $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $okButton.Location = New-Object System.Drawing.Point(290, 65)
            $form.AcceptButton = $okButton
            $form.Controls.Add($okButton)
    
            if ($form.ShowDialog() -eq "OK") {
                return $textBox.Text
            }
            else {
                throw "User cancelled language selection."
            }
        }
    
        # Prompt user to confirm or adjust language codes
        $sourceLangCode = Prompt-LanguageCode -title "Confirm Source Language" -defaultValue $sourceLangCode
        $targetLangCode = Prompt-LanguageCode -title "Confirm Target Language" -defaultValue $targetLangCode
    
        Write-Host "Final Source Language: $sourceLangCode"
        Write-Host "Final Target Language: $targetLangCode"
    

        # Get the base name of the TMX file (without the extension)
        $tmBaseName = [System.IO.Path]::GetFileNameWithoutExtension($tmxFile)

        Write-Host "The base name for the new TM will be: $tmBaseName"

        # Extract language codes for the filename
        $srcLangAbbr = $sourceLangCode.Split("-")[0]
        $srcCountryAbbr = $sourceLangCode.Split("-")[1]
        $tgtLangAbbr = $targetLangCode.Split("-")[0]
        $tgtCountryAbbr = $targetLangCode.Split("-")[1]

        # Construct the full TM file name
        $tmFileName = "${srcLangAbbr}(${srcCountryAbbr}) - ${tgtLangAbbr}(${tgtCountryAbbr})_${tmBaseName}.sdltm"

        # Define the full file path where the new Translation Memory will be saved
        $tmFilePath = Join-Path $tmDirectory $tmFileName

        # Set a description for the Translation Memory
        $sdltmdesc = "Created by PowerShell"

        # Create a new file-based Translation Memory (TM)
        New-FileBasedTM -filePath $tmFilePath -description $sdltmdesc -sourceLanguageName $sourceLangCode -targetLanguageName $targetLangCode

        # Import the TMX file into the newly created Translation Memory
        Import-Tmx -importFilePath $tmxFile -tmPath $tmFilePath -sourceLanguage $sourceLangCode -targetLanguage $targetLangCode

        # Inform the user that the Translation Memory has been successfully created
        Write-Host "SDLTM created at: $tmFilePath"
    }
    else {
        Write-Host "Error: Unable to find the source or target language codes in the TMX file."
        exit 1
    }
}
catch {
    Write-Error "An error occurred during SDLTM creation: $_"
    exit 1
}

# Wait for user input before closing
Read-Host -Prompt "Press Enter to exit"