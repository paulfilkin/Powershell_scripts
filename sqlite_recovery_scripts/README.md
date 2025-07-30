# Trados TM Recovery Scripts

A collection of PowerShell scripts for recovering corrupted SDL Trados Translation Memory (TM) files using SQLite recovery tools.

## Overview

These scripts help recover data from corrupted Trados TM files (.sdltm) which are SQLite databases. They provide different levels of recovery options, from basic recovery to advanced analysis with detailed corruption reports.

## Prerequisites

### SQLite Tools

You'll need the SQLite command-line tools. You can find a copy of these tools in this repository, but it might be advisable to take the latest versions from the official source:

**Download SQLite tools from:** https://www.sqlite.org/download.html

Look for the "Precompiled Binaries for Windows" section and download:

- `sqlite-tools-win-x64-*.zip` (or x86 for 32-bit systems)

Extract the following executables to a folder on your system:

- `sqlite3.exe` (required)
- `sqlite3_analyzer.exe` (optional, for advanced analysis)
- `sqldiff.exe` (optional, for backup comparison)

### PowerShell

- Windows PowerShell 5.1 or later
- PowerShell 7.x recommended for better performance

## Scripts Included

### 1. recoverSDLTM_Basic.ps1

Basic recovery script for quick TM recovery with essential features.

**Features:**

- Windows file dialog for easy TM selection
- Automatic recovery using SQLite's `.recover` command
- Fallback to `.dump` if recovery fails
- Table-by-table extraction as last resort
- Integrity check on recovered database
- All outputs saved in the same folder as the corrupted TM

**Output files:**

- `[TMName]_recovered.sql` - SQL dump of recovered data
- `[TMName]_fresh.sdltm` - Recovered TM file ready for use in Trados

### 2. recoverSDLTM_Advanced.ps1

Comprehensive recovery script with detailed analysis and reporting.

**Features:**

- All features from the basic script, plus:
- Detailed corruption analysis report
- Character encoding issue detection
- Table accessibility checking with row counts
- Recovery statistics showing percentage recovered
- CSV export with clean text (XML segments converted to readable text)
- SQLite analyzer integration for deep database analysis
- Backup comparison capabilities (if backups exist)
- Progress indicators for long operations

**Output files:**

- ```
  [TMName]_recovery_[timestamp]/
  ```

   \- Folder containing all recovery files

  - `analysis_report.txt` - Detailed corruption analysis
  - `standard_recovery.sql` - Main recovery SQL dump
  - `[TMName]_recovered.sdltm` - Recovered TM file
  - `raw_translations.csv` - Clean text export of all translations
  - `RECOVERY_REPORT.txt` - Summary report with statistics
  - Individual table SQL files (if table-by-table extraction was used)

## SQLite Tools Usage

### Which tools are used and when:

#### **sqlite3.exe** (Required)

The main SQLite command-line tool used for all recovery operations:

- Running the `.recover` command to extract data from corrupted databases
- Performing `.dump` operations as a fallback recovery method
- Executing SQL queries for table-by-table extraction
- Creating new databases and importing recovered data
- Running integrity checks on recovered databases
- Extracting data for CSV export
- Counting tables and translation units for statistics

#### **sqlite3_analyzer.exe** (Optional - Advanced script only)

Database analysis tool used for:

- Detailed corruption analysis
- Extracting database metrics (page size, free pages, space usage)
- Identifying structural problems in the corrupted database
- Providing detailed space usage statistics by table
- Helping estimate recovery potential

#### **sqldiff.exe** (Optional - Advanced script only)

Database comparison tool used for:

- Comparing corrupted TM with backup files (if found)
- Generating differential analysis between databases
- Identifying what data might be missing from the corrupted file
- Creating SQL scripts showing differences between databases

#### **sqlite3_rsync.exe** (Not currently used)

- Available in the toolset but not implemented in current scripts
- Could be used for selective table recovery in future versions (if the need arises!)

### Summary

- **Basic Script**: Only requires `sqlite3.exe`
- **Advanced Script**: Uses `sqlite3.exe` (required), `sqlite3_analyzer.exe` and `sqldiff.exe` (optional but recommended for full functionality)

The scripts will check for available tools and continue with reduced functionality if optional tools are missing.

## Installation

1. Download the scripts to a folder on your computer
2. Download the SQLite tools provided or get the latest from from https://www.sqlite.org/download.html
3. Place the SQLite executables into a suitable location and modify the `$SqliteToolsPath` variable in the scripts to point to your SQLite tools location

## Usage

### Basic Recovery

1. Run the `recoverSDLTM_Basic.ps1` script
2. Select your corrupted .sdltm file in the file dialog
3. Wait for the recovery process to complete
4. Find the recovered TM (`[TMName]_fresh.sdltm`) in the same folder as your original file

### Advanced Recovery

1. Run the `recoverSDLTM_Advanced.ps1` script
2. Select your corrupted .sdltm file in the file dialog
3. The script will create a timestamped recovery folder
4. Review the analysis report to understand the corruption
5. Check the recovery statistics to see how much data was recovered
6. Use the CSV export if you need to import translations elsewhere

## Understanding the Output

### Analysis Report (Advanced Script)

The analysis report provides:

- **Integrity Check Results**: Shows if the database is corrupted
- **Table Accessibility**: Lists each table and whether it's readable
- **Character Encoding Analysis**: Detects segments with encoding issues
- **Recovery Estimation**: Provides metrics about the database structure

### Recovery Statistics

Shows:

- Original translation units count
- Recovered translation units count
- Recovery percentage
- Number of tables recovered

### CSV Export

The advanced script creates a CSV file with:

- ID, source text, target text (extracted from XML)
- Creation date, change date, user information
- Usage counter

## Troubleshooting

### "SQLite executable not found"

- Ensure SQLite tools are downloaded and extracted
- Check the path in the script matches your installation
- Update the `$SqliteToolsPath` variable if needed

### "Variable reference is not valid" errors

- This is fixed in the provided scripts
- Occurs when PowerShell misinterprets colons in strings

### Empty CSV exports

- The scripts handle XML-formatted segments in Trados TMs
- Ensure you're using the latest version of the scripts

### Partial recovery

- Some corruption may prevent full recovery
- Check the analysis report for details on what's corrupted
- The `.recover` command usually provides the best results

## Technical Details

### How Trados TMs Work

- Trados TMs are SQLite databases with .sdltm extension
- Translation units are stored in the `translation_units` table
- Segments are stored as XML in modern Trados versions
- Multiple supporting tables store metadata and attributes

### Recovery Methods Used

1. **SQLite .recover command**: Built-in recovery mechanism (most effective)
2. **Database dump**: Exports all readable data
3. **Table-by-table extraction**: Extracts each table individually
4. **XML parsing**: Converts XML segments to readable text for CSV export

## Acknowledgments

Created by Claude.AI for the Trados community. These scripts leverage SQLite's powerful recovery capabilities to help translators recover their valuable translation memories when corruption occurs.

## Support

For issues or questions:

- Check the troubleshooting section above
- Review the analysis report for corruption details
- Ensure you have the latest SQLite tools
- Make backups of recovered TMs immediately after verification
- Still stuck?  Drop a question into the [RWS Community](https://community.rws.com/product-groups/trados-portfolio/trados-studio/f/regex_and_xpath)

Remember: Always create regular backups of your TMs, preferably by exporting to TMX, to prevent data loss!