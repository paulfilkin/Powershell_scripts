# XML + XSL Preview Tool

This tool simplifies previewing the result of an XSL or XSLT transformation applied to an XML file, rendering the output as HTML in your default web browser. It’s ideal for developers and translators working with XSLT stylesheets, such as Trados previews or other XML rendering tasks.

## What It Does

- Accepts one `.xml` and one `.xsl` or `.xslt` file via the Windows **"Send to"** context menu.
- Requires both input files to be in the same folder.
- Uses Python’s `lxml` library to perform the XSL transformation.
- Generates an HTML file (`preview.html`) in the same folder as the input files.
- Opens the HTML preview automatically in your default browser.

## Prerequisites

Ensure the following are set up before using the tool:

### Windows Requirements

- **Python 3** installed and added to your system `PATH`. Verify with:

  ```bash
  python --version
  ```

- The `lxml` Python package installed. Install it by running:

  ```bash
  pip install lxml
  ```

### File Association

- The script is designed for use via the Windows **"Send to"** context menu. Select one XML file and one XSL/XSLT file (from the same folder), right-click, and choose the script from the **"Send to"** menu.

## Setup Instructions

### Adding to "Send to" Menu

To streamline usage, add the script to the Windows **"Send to"** menu:

1. **Save the Script**:

   - Place the script (e.g., `preview.ps1`) in a permanent location, such as `C:\Scripts\`.

2. **Create a Shortcut (.lnk)**:

   - Right-click `preview.ps1` and select **Create shortcut**.
   - Rename the shortcut, e.g., `XML_XSL_Preview.lnk`, for clarity.

3. **Move to "Send to" Folder**:

   - Press `Win + R`, type `shell:sendto`, and press Enter to open the **"Send to"** folder.
   - Move or copy the `.lnk` file to this folder.

4. **Verify**:

   - In File Explorer, select an XML and XSL/XSLT file from the same folder, right-click, and confirm **"Send to" → XML_XSL_Preview** appears.

### Testing the Setup

- Use the provided sample files (`dogs.xml` and `style.xsl`) to test.
- Ensure both files are in the same folder, select them, right-click, and choose **"Send to" → XML_XSL_Preview**.
- The transformed HTML (`preview.html`) should appear in the same folder and open in your default browser.

## How It Works

1. Validates that exactly two files are provided: one `.xml` and one `.xsl` or `.xslt`.
2. Ensures both files exist, are accessible, and are in the same folder.
3. Generates a temporary Python script (`xsl_preview_temp.py`) in `%TEMP%` that:
   - Parses the XML and XSLT using `lxml.etree`.
   - Applies the transformation.
   - Saves the result as `preview.html` in the input files’ folder.
   - Opens the HTML in the default browser.
4. Executes the Python script and deletes it afterward.

## Cleanup

- The temporary Python script (`xsl_preview_temp.py`) is automatically deleted from `%TEMP%` after execution.
- The HTML output (`preview.html`) remains in the input files’ folder for easy access. If a file named `preview.html` already exists, a unique name (e.g., `preview_1.html`) is used to avoid overwriting.

## Troubleshooting

If the script doesn’t work:

- **File Selection**: Ensure you’ve selected exactly **one** `.xml` **and one** `.xsl` **or** `.xslt` file from the same folder.
- **Same Folder**: Verify both files are in the same directory, as the script enforces this.
- **Python Setup**: Confirm Python is installed and accessible (`python --version`).
- **Library Check**: Verify `lxml` is installed (`pip show lxml`).
- **File Access**: Ensure the selected files and their folder are accessible and not locked.
- **Syntax Errors**: Check that the XML and XSL files are valid; invalid files may cause silent failures.
- **Shortcut Issues**: Confirm the `.lnk` file in the **"Send to"** folder points to the correct script.
- **Browser**: Ensure your default browser is set correctly if the HTML doesn’t open.

## Contributing

Contributions are welcome! Submit issues or pull requests to enhance the script or documentation.