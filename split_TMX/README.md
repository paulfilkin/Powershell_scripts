# TMX File Splitter

This PowerShell script is designed to split a Translation Memory eXchange (TMX) file into multiple smaller TMX files. The script provides a user-friendly interface for selecting the TMX file and specifying the number of parts to split it into. Each part will contain a proportional number of translation units (`<tu>` elements), ensuring that the content is evenly distributed across the generated files.

I did base this on a TMX downloaded from the [DGT-Translation Memory website](https://joint-research-centre.ec.europa.eu/language-technology-resources/dgt-translation-memory_en) so there is no guarantee it will work for every variety of TMX you'll ever come across.  You'll find the sample in the repository if you want to test it.

Also note there are two versions of the script using different methods and outputs.

## Features

- **File Selection**: Prompts the user to select the TMX file to be split.
- **Header and Footer Extraction**: Automatically extracts and retains the original TMX file's header and footer to ensure the integrity of the format in the split files.
- **Body Splitting**: Splits the body of the TMX file into user-defined parts, distributing `<tu>` elements evenly across the new files.
- **Output**: Saves the split TMX files in the same directory as the original file, with filenames indicating the part number.

## Usage

1. **Run the Script**: Launch the script in a PowerShell environment
   - if running ***splitTMX.ps1*** it should be copied into the same folder as the TMX
   - if running ***splitTMX_v2.ps1*** it does not have to be in the same folder as the TMX

2. **Select TMX File**: A file dialog will appear, allowing you to choose the TMX file you wish to split.
3. **Enter Number of Parts**: You will be prompted to enter the number of parts to split the TMX file into.
4. **Processing**: The script will process the TMX file and create the specified number of parts
   - if running ***splitTMX.ps1***: into the same folder as the original TMX
   - if running ***splitTMX_v2.ps1***: into a new folder with the same name and location as the original file.

5. **Output**: The split files will be named in the format `001_Filename.tmx`, `002_Filename.tmx`, etc.

## Example

Suppose you have a TMX file named `Example.tmx` and you want to split it into 3 parts:

1. Run the script.
2. Select `Example.tmx` from the file dialog.
3. Enter `3` when prompted for the number of parts.
4. The script will create `001_Example.tmx`, `002_Example.tmx`, and `003_Example.tmx` in the same directory as `Example.tmx`.

## Notes

- Ensure that the TMX file is well-formed and contains a valid structure, as the script relies on regular expressions to parse and split the file.
- The script is designed to handle TMX files of any size, but processing time may vary depending on the file size and the number of parts specified.
- The split files will retain the original TMX format, including the header and footer sections.

## Troubleshooting

- **No `<tu>` segments found**: If the script fails to find any `<tu>` elements in the TMX file, it will terminate. Ensure the TMX file is correctly formatted and contains translation units.
- **Invalid number of parts**: If the number of parts entered is not a valid positive integer, the script will terminate. Please ensure you enter a valid number.
- **TMX Complexity**: I wrote this script specifically to solve a problem with a TMX I had to hand.  It may not work correctly for every TMX you'll ever come across.  So be prepared to make some changes as needed.  Hopefully this will give you the idea.

