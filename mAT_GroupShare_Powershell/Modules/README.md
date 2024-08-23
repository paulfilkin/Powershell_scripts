# GroupShareToolkit

## Overview

The `GroupShareToolkit` module is designed to simplify and enhance the experience of working with Trados GroupShare by automating common tasks related to module loading, user authentication, and credential management. This toolkit serves as an extension to the [GroupShare PowerShell Toolkit](link to follow) that is provided by the Trados AppStore Team, adding functionality that streamlines interactions with the GroupShare server.

The GroupShare PowerShell Toolkit includes several modules, that I have also included here, provided by the Trados AppStore Team, each with its own specific focus:

- **AuthenticationHelper**
- **BackgroundTaskHelper**
- **ProjectServerHelper**
- **ResourcesHelper**
- **SystemConfigurationHelper**
- **UserManagerHelper**

These modules together form a comprehensive toolkit for managing various aspects of GroupShare, from user management to project configuration. The `GroupShareToolkit` complements these modules by providing additional functionality for module management and authentication processes.

This module includes the following key functions:

- `Get-Credentials`: Securely retrieves user credentials and server information from an XML file.
- `Import-GroupShareModules`: Dynamically loads GroupShare PowerShell modules from specified directories.
- `Connect-User`: Authenticates a user against the GroupShare server and retrieves an authorization token.

*<u>Important</u>*: I am only providing a copy of the [GroupShare PowerShell Toolkit](link to follow) modules as of the 23. August 2024.  Be sure to take the modules from the Trados AppStore Team repository to be sure you have the latest versions.

## Credits

This module was created to complement the GroupShare PowerShell Toolkit provided by the [Trados AppStore Team](#link-to-their-repository). All the original GroupShare-related modules and functionalities were developed by the Trados AppStore Team, and this toolkit builds upon their excellent work.

## Installation

To install the `GroupShareToolkit` module, you can simply clone or download this repository and import the module in your PowerShell session using the following command:

```powershell
Import-Module GroupShareToolkit
```

Ensure that you have the necessary dependencies from the original GroupShare PowerShell Toolkit available in your environment.

## Usage

Here is a brief overview of how to use the functions provided by the `GroupShareToolkit` module:

### Get-Credentials

The `Get-Credentials` function opens a file dialog allowing you to select an XML file containing encrypted credentials and server information. It returns a PowerShell object with the deserialized secure data.

```powershell
$credentials = Get-Credentials
```

### Import-GroupShareModules

This function dynamically loads specified GroupShare PowerShell modules, checking first in the script's directory and then in a fallback directory in the user's profile.

```powershell
Import-GroupShareModules -ScriptParentDir "C:\Scripts\GroupShare"
```

### Connect-User

The `Connect-User` function authenticates a user against the GroupShare server using the provided credentials and returns an authorization token.

```powershell
$token = Connect-User -ServerUrl "https://yourgroupshare.server.com" -Credential (Get-Credential)
```
