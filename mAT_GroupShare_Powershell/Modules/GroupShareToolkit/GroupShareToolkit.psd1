# GroupShareToolkit.psd1

@{
    ModuleVersion = '1.0.0'
    Author = 'multifarious'
    Description = 'A PowerShell toolkit for simplifying the loading of modules, logging in and authenticating.'

    # The root module or the main script module to process
    RootModule = 'GroupShareToolkit.psm1'

    # Functions to export from this module
    FunctionsToExport = @(
        'Get-Credentials',
        'Import-GroupShareModules',
        'Connect-User'
    )

    # Copyright information
    Copyright = '(c) multifarious. All rights reserved.'

    # List of all files packaged with this module
    FileList = @(
        '.\GroupShareToolkit.psm1'
        '.\GroupShareToolkit.psd1'
    )

    # Compatible PowerShell Editions (omitted if not specifically targeting different PowerShell editions)
    # CompatiblePSEditions = @()
}
