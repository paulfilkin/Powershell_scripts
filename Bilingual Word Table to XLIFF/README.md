# Bilingual Word Table to XLIFF 2.0 Converter

This PowerShell script converts a bilingual table in a Microsoft Word document into an XLIFF 2.0 file. This is particularly useful for those who work with translation projects and need to export translation data into an industry-standard XLIFF format.

## Requirements

- **Microsoft Word**: The script relies on the Word COM object to interact with Word documents. Ensure that Microsoft Word is installed on the system where the script is executed.
- **PowerShell**: The script is compatible with PowerShell 7. However, it should work with any recent version of PowerShell that supports COM objects.

## Usage

1. **Clone or Download the Repository**: 

   If you haven't already, clone or download this repository to your local machine.

   ```sh
   git clone https://github.com/yourusername/repositoryname.git
   ```

2. **Run the Script**:

   Open a PowerShell terminal and navigate to the directory where the script is located. Run the script by typing:

   ```sh
   ./table_2_xliff.ps1
   ```

3. **Follow the Prompts**:

   - **Enter the Word Document Path**: The script will prompt you to enter the full path to the DOCX file containing the bilingual table. Ensure the file exists at the specified path.
   - **Source Language Code**: Enter the language code for the source language (e.g., `en-US` for English, United States).
   - **Target Language Code**: Enter the language code for the target language (e.g., `fr-FR` for French, France).

4. **Output**:

   The script generates an XLIFF 2.0 file in the same directory as the Word document, with the same name but with an `.xliff` extension.

## Script Details

- **Escape-Xml Function**: This function ensures that any XML special characters in the text are properly escaped. This prevents XML parsing errors when creating the XLIFF file.

- **Document Processing**: The script processes the bilingual table in the Word document, iterating through each row (starting from the second row, assuming the first row is a header). It extracts the source and target text, escapes any XML special characters, and then formats them into XLIFF units.

- **Error Handling**: The script includes a try-catch-finally block to manage potential errors. If an error occurs during processing, a message is displayed, and the script ensures that Word is properly closed and memory is cleaned up.

## Troubleshooting

- **File Path Issues**: If the script reports that the file path does not exist, double-check the path you provided for any typos or missing directories.
  
- **COM Object Issues**: If you encounter issues related to the Word COM object, ensure that Microsoft Word is properly installed and that you have sufficient permissions to access it via PowerShell.

