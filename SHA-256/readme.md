# Compute SHA-256 PowerShell Script

A lightweight PowerShell script for Windows 10 and 11 that calculates the SHA-256 hash of any selected file. The script prompts for the file path, validates it, displays the hash, and copies it to the clipboard. It's essentially a tool I use because it's faster (for me!) than opening a powershell window at the right location and typing this:

```powershell
Get-FileHash .\filename.zip -Algorithm SHA256
```

## Features

- Prompts for a file path interactively  
- Verifies the file exists before proceeding  
- Computes the SHA-256 hash using the built-in Get-FileHash cmdlet  
- Automatically copies the resulting hash to the clipboard  
- Displays clear success and error messages  

## Requirements

- Windows 10 or 11  
- PowerShell 5.1 or later (or PowerShell 7)  
- Clipboard service enabled in Windows  

## Usage

```powershell
.\sha-256.ps1
```

When prompted, enter the full path to your file, for example:

```
Enter the full path to the file: C:\Downloads\filename.zip
```

Example output:

```
File: C:\Downloads\filename.zip
SHA-256: 1F4A3B1C2B7E93D36D84B8BCE18C9E9123456789ABCDEF0123456789ABCDEF0

The SHA-256 hash has been copied to the clipboard.
```

## Example Use Cases

- Verifying file integrity after download  
- Checking that installer packages or ISOs are unmodified  
- Comparing checksums between systems  



