# ----------------------------
# SparseCheckout.ps1
# ----------------------------
# Clone a Git repo with sparse checkout, prompting the user to type
# the folder path inside the repo they want to checkout.
# Moves sparse-checked-out folder contents to the root of targetDir to avoid nesting.
# Cleans up all items except the project folder and solution file, including the .git folder.
# ----------------------------

# ---- Configurable Variables ----
$repoUrl     = "https://github.com/RWS/Sdl-Community.git"
$branch      = "master"
$baseDir     = "c:\Users\paul\Documents\GIT\SDLCommunityApps"

# ---- Load Windows Forms ----
Add-Type -AssemblyName System.Windows.Forms

# Prompt user for the subfolder path in the repo
$form = New-Object System.Windows.Forms.Form
$form.Text = "Sparse Checkout"
$form.Width = 500
$form.Height = 160
$form.StartPosition = "CenterScreen"

$label = New-Object System.Windows.Forms.Label
$label.Text = "Enter the folder path inside the repo to checkout (e.g., Multilingual XML FileType):"
$label.AutoSize = $true
$label.Top = 20
$label.Left = 10
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Width = 460
$textBox.Top   = 50
$textBox.Left = 10
$form.Controls.Add($textBox)

$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "OK"
$okButton.Top = 85
$okButton.Left = 300
$okButton.Add_Click({ $form.DialogResult = [System.Windows.Forms.DialogResult]::OK; $form.Close() })
$form.Controls.Add($okButton)
$form.AcceptButton = $okButton

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.Top = 85
$cancelButton.Left = 380
$cancelButton.Add_Click({ $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel; $form.Close() })
$form.Controls.Add($cancelButton)

# Show dialog
$dialogResult = $form.ShowDialog()
if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK -or [string]::IsNullOrWhiteSpace($textBox.Text)) {
    Write-Host "No folder path entered. Exiting."
    exit
}

$folderPath = $textBox.Text.Trim()

# ---- Compute the target directory ----
# Use folder name from path (e.g., 'File type definition for TMX' becomes 'File-type-definition-for-TMX')
$folderName = $folderPath -replace '[\\/:*?"<>|]', '-'  # Sanitize for Windows folder names
$targetDir = Join-Path $baseDir $folderName

# ---- Ensure base directory exists ----
if (-not (Test-Path $baseDir)) {
    New-Item -Path $baseDir -ItemType Directory | Out-Null
}

# ---- Git sparse checkout process ----
Write-Host "Configuring sparse checkout for '$folderPath' in $targetDir..."

# Check if the target directory already has a Git repository
if (-not (Test-Path (Join-Path $targetDir ".git"))) {
    Write-Host "Cloning $repoUrl into $targetDir with sparse checkout..."
    git clone --filter=blob:none --no-checkout $repoUrl $targetDir
}

Set-Location $targetDir

# Initialize sparse-checkout if not already enabled
if (-not (Test-Path ".git/info/sparse-checkout")) {
    git sparse-checkout init --cone
}

# Add the new folder to sparse-checkout
git sparse-checkout add "$folderPath"
git checkout $branch

# ---- Move contents of sparse-checked-out folder to root of targetDir ----
$sparseFolder = Join-Path $targetDir $folderPath
if (Test-Path $sparseFolder) {
    # Get all items inside the sparse-checked-out folder
    $items = Get-ChildItem -Path $sparseFolder -Force
    foreach ($item in $items) {
        # Move each item to the root of $targetDir
        $destination = Join-Path $targetDir $item.Name
        try {
            Move-Item -Path $item.FullName -Destination $destination -Force
            Write-Host "Moved $($item.Name) to $targetDir"
        } catch {
            Write-Host "Could not move $($item.Name): $($_.Exception.Message)"
        }
    }
    # Remove the now-empty sparse-checked-out folder
    try {
        Remove-Item -Path $sparseFolder -Force -Recurse
        Write-Host "Removed empty folder: ${sparseFolder}"
    } catch {
        Write-Host "Could not remove ${sparseFolder}: $($_.Exception.Message)"
    }
} else {
    Write-Host "Warning: Sparse-checked-out folder '${sparseFolder}' not found."
    exit
}

# ---- Identify the project folder and solution file ----
# Find the solution file (assume there is exactly one .sln file)
$solutionFile = Get-ChildItem -Path $targetDir -Filter "*.sln" -File | Select-Object -First 1
if (-not $solutionFile) {
    Write-Host "Error: No .sln file found in $targetDir. Exiting."
    exit
}
$solutionFileName = $solutionFile.Name
$solutionFilePath = $solutionFile.FullName

# Check if the solution file already exists (for subsequent runs)
if (Test-Path $solutionFilePath) {
    $existingItems = Get-ChildItem -Path $targetDir | Where-Object { $_.Name -ne ".git" }
    if ($existingItems.Count -eq 2) {  # Expecting solution file and project folder
        Write-Host "Solution file already exists at '$solutionFilePath' with expected project structure. Skipping checkout."
        Write-Host "Open '$solutionFilePath' in Visual Studio to start working."
        exit
    }
}

# Find the project folder (assume it's the folder containing a .csproj file)
$projectFolder = Get-ChildItem -Path $targetDir -Directory | Where-Object {
    $csprojFile = Join-Path $_.FullName "*.csproj"
    Test-Path $csprojFile
} | Select-Object -First 1

if (-not $projectFolder) {
    Write-Host "Error: No project folder with a .csproj file found in $targetDir. Exiting."
    exit
}
$projectFolderName = $projectFolder.Name

# ---- Clean-up of all items except the project folder and solution file ----
$itemsToRemove = Get-ChildItem -Force -Path $targetDir | Where-Object {
    $_.Name -ne $projectFolderName -and
    $_.Name -ne $solutionFileName
}

foreach ($item in $itemsToRemove) {
    try {
        Remove-Item -Path $item.FullName -Force -Recurse
        Write-Host "Removed item: $($item.Name)"
    } catch {
        Write-Host "Could not remove $($item.Name): $($_.Exception.Message)"
    }
}

Write-Host ""
Write-Host "Sparse checkout complete. Project contents are available at '$targetDir'."
Write-Host "Open '$solutionFilePath' in Visual Studio to start working."