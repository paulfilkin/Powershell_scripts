#############################################
### SIGN IN, IMPORT MODULES, AUTHENTICATE ###

# Import the GroupShareToolkit module
Import-Module -Name "c:\Users\pfilkin\Documents\GroupSharePowershellToolkit\Modules\GroupShareToolkit\GroupShareToolkit.psm1"

# Get the credentials from the CredentialStore directory
$credentials = Get-Credentials
if ($credentials) {
    # $datasetName = $credentials.DatasetName
    $server = $credentials.ServerUrl
    $credential = $credentials.Credential

    # Import the GroupShare modules, pass $server as a parameter
    Import-GroupShareModules -ScriptParentDir (Split-Path -Parent $MyInvocation.MyCommand.Path) -ServerUrl $server

    # Connect and authenticate the user
    $token = Connect-User -ServerUrl $server -Credential $credential
}




##################################################################
# List all organisations, their containers, and the TMs in those containers
$outputFilePath = "c:\Users\pfilkin\Documents\GroupSharePowershellToolkit\Scripts\Organisations_Containers_TMs.txt"

# Clear the file if it exists
if (Test-Path $outputFilePath) {
    Clear-Content $outputFilePath
}

Write-Host "`nListing all organisations, their containers, and the TMs in those containers:" -ForegroundColor Cyan

# Retrieve all organisations
$organizations = Get-AllOrganizations -authorizationToken $token

# Retrieve all containers
$containers = Get-AllContainers -authorizationToken $token

# Retrieve all TMs
$tms = Get-AllTMs -authorizationToken $token

# Iterate over each organisation
foreach ($organization in $organizations) {
    $orgLine = "`nOrganisation: $($organization.Name)"
    Write-Host $orgLine -ForegroundColor Green
    Add-Content -Path $outputFilePath -Value $orgLine

    # Filter containers by the organisation's ID
    $orgContainers = $containers | Where-Object { $_.OwnerId -eq $organization.UniqueId }

    if ($orgContainers.Count -gt 0) {
        # Iterate over each container in the organisation
        foreach ($container in $orgContainers) {
            # Check for a valid container name
            $containerName = if ($container.DisplayName -and $container.DisplayName.Trim() -ne "") { $container.DisplayName } else { "<Unnamed Container>" }

            $containerLine = "`tContainer: $containerName"
            Write-Host $containerLine -ForegroundColor Yellow
            Add-Content -Path $outputFilePath -Value $containerLine

            # Filter TMs by the container's ID
            $containerTMs = $tms | Where-Object { $_.ContainerId -eq $container.ContainerId }

            if ($containerTMs.Count -gt 0) {
                # List TMs in the container
                foreach ($tm in $containerTMs) {
                    $tmLine = "`t`tTM: $($tm.Name)"
                    Write-Host $tmLine -ForegroundColor White
                    Add-Content -Path $outputFilePath -Value $tmLine
                }
            } else {
                $noTmsLine = "`t`tNo TMs found in this container."
                Write-Host $noTmsLine -ForegroundColor Gray
                Add-Content -Path $outputFilePath -Value $noTmsLine
            }
        }
    } else {
        $noContainersLine = "`tNo containers found for this organisation."
        Write-Host $noContainersLine -ForegroundColor Red
        Add-Content -Path $outputFilePath -Value $noContainersLine
    }
}

Write-Host "`nOutput written to $outputFilePath" -ForegroundColor Cyan







# ##################################################################
# # List all organisations, their containers, and the TMs in those containers
# $outputFilePath = "c:\Users\pfilkin\Documents\GroupSharePowershellToolkit\Scripts\Organisations_Containers_TMs.txt"

# # Clear the file if it exists
# if (Test-Path $outputFilePath) {
#     Clear-Content $outputFilePath
# }

# Write-Host "Listing all organisations, their containers, and the TMs in those containers:" -ForegroundColor Cyan

# # Retrieve all organisations
# $organizations = Get-AllOrganizations -authorizationToken $token

# # Retrieve all containers
# $containers = Get-AllContainers -authorizationToken $token

# # Retrieve all TMs
# $tms = Get-AllTMs -authorizationToken $token

# # Iterate over each organisation
# foreach ($organization in $organizations) {
#     $orgLine = "`nOrganisation: $($organization.Name)"
#     Write-Host $orgLine -ForegroundColor Green
#     Add-Content -Path $outputFilePath -Value $orgLine

#     # Filter containers by the organisation's ID
#     $orgContainers = $containers | Where-Object { $_.OwnerId -eq $organization.UniqueId }

#     if ($orgContainers.Count -gt 0) {
#         # Iterate over each container in the organisation
#         foreach ($container in $orgContainers) {
#             $containerLine = "`tContainer: $($container.Name)"
#             Write-Host $containerLine -ForegroundColor Yellow
#             Add-Content -Path $outputFilePath -Value $containerLine

#             # Filter TMs by the container's ID
#             $containerTMs = $tms | Where-Object { $_.ContainerId -eq $container.ContainerId }

#             if ($containerTMs.Count -gt 0) {
#                 # List TMs in the container
#                 foreach ($tm in $containerTMs) {
#                     $tmLine = "`t`tTM: $($tm.Name)"
#                     Write-Host $tmLine -ForegroundColor White
#                     Add-Content -Path $outputFilePath -Value $tmLine
#                 }
#             } else {
#                 $noTmsLine = "`t`tNo TMs found in this container."
#                 Write-Host $noTmsLine -ForegroundColor Gray
#                 Add-Content -Path $outputFilePath -Value $noTmsLine
#             }
#         }
#     } else {
#         $noContainersLine = "`tNo containers found for this organisation."
#         Write-Host $noContainersLine -ForegroundColor Red
#         Add-Content -Path $outputFilePath -Value $noContainersLine
#     }
# }

# Write-Host "`nOutput written to $outputFilePath" -ForegroundColor Cyan
