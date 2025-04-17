# sparseCheckoutSDLCommunity

A PowerShell script for selectively cloning a single project or folder from a large Git repository using Git's sparse checkout feature. Ideal for monorepos with multiple subprojects.  I created this to be able to selectively download the code for just one particular plugin in the [SDL Community open-sourced plugins](https://github.com/rws/sdl-community) page.  I did it because I don't believe Visual Studio has this ability built it... it's all or nothing.  But I could be wrong!!

## Features

- Prompts for the folder to clone from the repo using a Windows UI input box.
- Automatically sanitizes the folder name and creates a dedicated directory.
- Performs a sparse checkout to fetch only the selected folder.
- Moves the project contents to the root of the local folder for easy access.
- Removes unnecessary files, including `.git` and CI configs, while keeping the solution and project files.
- Supports reusing existing sparse-checkout configurations without re-downloading.

## Prerequisites

- Windows PowerShell
- Git 2.25 or newer (for sparse-checkout support)
- Git must be available in your system PATH
- .NET Framework (for Windows Forms dialog box)

## Usage

1. Clone this repository or download the `SparseCheckout.ps1` script.
2. Open PowerShell and run the script:

   ```powershell
   .\sparseCheckoutSDLCommunity.ps1

------

### Configurable Variables

At the top of the script, you’ll find three configurable variables that determine how and where the script runs:

```powershell
$repoUrl     = "https://github.com/RWS/Sdl-Community.git"
$branch      = "master"
$baseDir     = "c:\Users\paul\Documents\GIT\SDLCommunityApps"
```

#### `$repoUrl`

This is the **URL of the Git repository** you want to perform the sparse checkout from.

- Replace this with the HTTPS URL of your own repo if you're using a different source.

- Example:

  ```powershell
  $repoUrl = "https://github.com/my-org/monorepo.git"
  ```

#### `$branch`

Specifies the **branch name** to check out from the repository.

- Default is `"master"`, but many modern repositories use `"main"` or another branch.

- Make sure this matches the actual branch name in your repo.

- Example:

  ```powershell
  $branch = "main"
  ```

#### `$baseDir`

The **base directory on your local machine** where sparse-checked-out projects will be placed.

- The script will create a new folder inside this directory based on the name of the selected project.

- It is recommended to use a clean location where you store all cloned projects.

- Example:

  ```powershell
  $baseDir = "D:\Dev\MonorepoProjects"
  ```

