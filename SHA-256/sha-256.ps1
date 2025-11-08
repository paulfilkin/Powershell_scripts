# compute-sha256.ps1
# Prompts for a file path, computes its SHA-256 hash, displays it, and copies it to the clipboard.

# Prompt user for the file path
$filePath = Read-Host "Enter the full path to the file"

# Verify the file exists
if (-not (Test-Path -Path $filePath -PathType Leaf)) {
    Write-Host "Error: File not found at the specified path." -ForegroundColor Red
    exit 1
}

try {
    # Compute SHA-256 hash
    $hash = Get-FileHash -Path $filePath -Algorithm SHA256
    $sha256 = $hash.Hash

    # Display results
    Write-Host "`nFile:" $hash.Path
    Write-Host "SHA-256:" $sha256 "`n"

    # Copy to clipboard
    Set-Clipboard -Value $sha256
    Write-Host "The SHA-256 hash has been copied to the clipboard." -ForegroundColor Green
}
catch {
    Write-Host "Error calculating hash: $($_.Exception.Message)" -ForegroundColor Red
}
