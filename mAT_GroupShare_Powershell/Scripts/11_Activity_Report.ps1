#############################################
### SIGN IN, IMPORT MODULES, AUTHENTICATE ###

# Import the GroupShareToolkit module
Import-Module -Name "c:\Users\paul\Documents\Production Scripts\Powershell\GroupSharePowershellToolkit\Modules\GroupShareToolkit\GroupShareToolkit.psm1"

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
### HELPER FUNCTION TO GET ALL ITEMS WITH PAGINATION ###
function Get-AllItemsPaginated {
    param(
        [string]$BaseUri,
        [hashtable]$Headers,
        [int]$PageSize = 100,
        [string]$ItemsProperty = "Items"
    )
    
    $allItems = @()
    $page = 1
    $hasMore = $true
    
    while ($hasMore) {
        $uri = if ($BaseUri -contains "?") { 
            "$BaseUri&page=$page&limit=$PageSize" 
        } else { 
            "$BaseUri?page=$page&limit=$PageSize" 
        }
        
        try {
            $response = Invoke-RestMethod -Uri $uri -Headers $Headers -Method Get
            if ($response.$ItemsProperty -and $response.$ItemsProperty.Count -gt 0) {
                $allItems += $response.$ItemsProperty
                $page++
                # Check if we got fewer items than page size (last page)
                if ($response.$ItemsProperty.Count -lt $PageSize) {
                    $hasMore = $false
                }
            } else {
                $hasMore = $false
            }
        } catch {
            Write-Host "  Pagination stopped at page $page" -ForegroundColor Yellow
            $hasMore = $false
        }
    }
    
    return $allItems
}

#############################################
### SET UP DATE RANGE AND PARAMETERS ###
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "    GroupShare Server Activity Report" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Calculate date range (last 6 months)
$endDate = Get-Date -Format "yyyy-MM-dd"
$startDate = (Get-Date).AddMonths(-6).ToString("yyyy-MM-dd")

Write-Host "Report Period: $startDate to $endDate" -ForegroundColor Green
Write-Host "Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green

# Get all organizations for reference
Write-Host "`nRetrieving organizational structure..." -ForegroundColor Yellow
$allOrganizations = Get-AllOrganizations -authorizationToken $token
Write-Host "  Found $($allOrganizations.Count) organizations" -ForegroundColor Green

# Build organization hierarchy
Write-Host "`nBuilding organization hierarchy..." -ForegroundColor Yellow

# Create organization hierarchy map
$orgHierarchy = @{}
$orgById = @{}
$rootOrganizations = @()
$firstLevelOrganizations = @()

foreach ($org in $allOrganizations) {
    # Store org by ID for quick lookup
    if ($org.UniqueId) {
        $orgById[$org.UniqueId] = $org
    }
    
    # Build parent-child relationships
    if ($org.ParentOrganizationId -and $org.ParentOrganizationId -ne [System.Guid]::Empty) {
        if (-not $orgHierarchy.ContainsKey($org.ParentOrganizationId)) {
            $orgHierarchy[$org.ParentOrganizationId] = @()
        }
        $orgHierarchy[$org.ParentOrganizationId] += $org
    } else {
        $rootOrganizations += $org
    }
}

# Now identify first-level organizations (direct children of root)
foreach ($org in $allOrganizations) {
    if ($org.ParentOrganizationId -and $org.ParentOrganizationId -ne [System.Guid]::Empty) {
        $parent = $orgById[$org.ParentOrganizationId]
        if ($parent) {
            # Check if parent is root
            if (-not $parent.ParentOrganizationId -or 
                $parent.ParentOrganizationId -eq [System.Guid]::Empty -or
                $parent.Name -match "^Root" -or 
                $parent.Path -eq "/") {
                $firstLevelOrganizations += $org
            }
        }
    } elseif ($org.Name -ne "Root" -and $org.Path -ne "/") {
        # This org has no parent but isn't named "Root", so it's a first-level org
        $firstLevelOrganizations += $org
    }
}

Write-Host "  Found $($rootOrganizations.Count) root organizations" -ForegroundColor Green
Write-Host "  Found $($firstLevelOrganizations.Count) first-level organizations (parent companies)" -ForegroundColor Green
if ($firstLevelOrganizations.Count -gt 0 -and $firstLevelOrganizations.Count -le 10) {
    Write-Host "  First-level organizations:" -ForegroundColor Cyan
    foreach ($org in $firstLevelOrganizations) {
        Write-Host "    • $($org.Name)" -ForegroundColor Gray
    }
}
Write-Host "  Organization hierarchy mapped successfully" -ForegroundColor Green

# Function to get the first-level parent organization (not root)
function Get-RootParentOrganization {
    param($org)
    
    if (-not $org) { return $null }
    
    $current = $org
    $parent = $null
    $maxDepth = 10  # Prevent infinite loops
    $depth = 0
    
    # Walk up the tree until we find an org whose parent is root or has no parent
    while ($current.ParentOrganizationId -and 
           $current.ParentOrganizationId -ne [System.Guid]::Empty -and 
           $depth -lt $maxDepth) {
        
        $parent = $orgById[$current.ParentOrganizationId]
        
        if ($parent) {
            # Check if this parent's parent is root or doesn't exist
            # If so, return the current org as it's the first-level org
            if (-not $parent.ParentOrganizationId -or 
                $parent.ParentOrganizationId -eq [System.Guid]::Empty) {
                return $current
            }
            
            # Check if the parent is named "Root" or similar
            if ($parent.Name -match "^Root" -or $parent.Path -eq "/") {
                return $current
            }
            
            $current = $parent
        } else {
            break
        }
        $depth++
    }
    
    # If we get here, the org itself is a first-level org
    return $current
}

# Function to get the full organization path
function Get-OrganizationPath {
    param($org)
    
    if (-not $org) { return "Unknown" }
    
    $path = @()
    $current = $org
    $maxDepth = 10
    $depth = 0
    $seenIds = @{} # Track seen IDs to prevent loops
    
    while ($current -and $depth -lt $maxDepth) {
        # Check if we've seen this ID before (loop detection)
        if ($current.UniqueId -and $seenIds.ContainsKey($current.UniqueId)) {
            break
        }
        
        # Don't add "Root Organization" or "Root" multiple times
        if ($current.Name -eq "Root Organization" -or $current.Name -eq "Root") {
            # Only add it if it's the first item (the org itself is root) or if path is empty
            if ($path.Count -eq 0 -and $depth -eq 0) {
                $path = @($current.Name) + $path
            }
        } else {
            $path = @($current.Name) + $path
        }
        
        # Mark this ID as seen
        if ($current.UniqueId) {
            $seenIds[$current.UniqueId] = $true
        }
        
        # Move to parent
        if ($current.ParentOrganizationId -and $current.ParentOrganizationId -ne [System.Guid]::Empty) {
            $parent = $orgById[$current.ParentOrganizationId]
            if ($parent) {
                # Stop if parent is root
                if ($parent.Name -eq "Root Organization" -or $parent.Name -eq "Root" -or $parent.Path -eq "/") {
                    # Don't need to add root to the path unless path is empty
                    if ($path.Count -eq 0) {
                        $path = @("Root Organization")
                    }
                    break
                }
                $current = $parent
            } else {
                break
            }
        } else {
            break
        }
        $depth++
    }
    
    # Clean up the path - remove duplicate "Root Organization" entries
    $cleanPath = @()
    $lastItem = ""
    foreach ($item in $path) {
        if ($item -ne "Root Organization" -or $lastItem -ne "Root Organization") {
            $cleanPath += $item
            $lastItem = $item
        }
    }
    
    # If we have a path starting with Root Organization, ensure it's clean
    if ($cleanPath.Count -gt 1 -and $cleanPath[0] -eq "Root Organization") {
        # Only keep the first Root Organization
        $cleanPath = @("Root Organization") + ($cleanPath | Select-Object -Skip 1 | Where-Object { $_ -ne "Root Organization" })
    }
    
    if ($cleanPath.Count -eq 0) {
        return "Unknown"
    }
    
    return $cleanPath -join " > "
}

# Prompt for optional organization filter
$filterByOrg = Read-Host "`nDo you want to filter by a specific organization? (Y/N)"
$selectedOrganization = $null

if ($filterByOrg -eq "Y" -or $filterByOrg -eq "y") {
    $myOrganization = Read-Host "Enter the organisation name"
    $selectedOrganization = $allOrganizations | Where-Object { $_.Name -eq $myOrganization }
    
    if ($selectedOrganization.Count -eq 0) {
        Write-Host "No such organisation found. Proceeding with all organizations." -ForegroundColor Yellow
        $selectedOrganization = $null
    } elseif ($selectedOrganization.Count -gt 1) {
        Write-Host "Multiple organisations found. Proceeding with all organizations." -ForegroundColor Yellow
        $selectedOrganization = $null
    } else {
        $selectedOrganization = $selectedOrganization[0]
        Write-Host "Filtering by organization: $($selectedOrganization.Name)" -ForegroundColor Green
    }
}

#############################################
### RETRIEVE ALL USERS WITHOUT LIMITS ###
Write-Host "`nRetrieving user information..." -ForegroundColor Yellow
try {
    # Build the base URI for users
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }
    
    $usersBaseUri = $server.TrimEnd('/') + "/api/management/v2/users"
    $allUsers = Get-AllItemsPaginated -BaseUri $usersBaseUri -Headers $headers -PageSize 500 -ItemsProperty "items"
    
    Write-Host "  Found $($allUsers.Count) users (all pages retrieved)" -ForegroundColor Green
} catch {
    Write-Host "  Error retrieving users: $_" -ForegroundColor Red
    # Fallback to module function
    $allUsers = Get-AllUsers -authorizationToken $token -maxLimit 10000
    Write-Host "  Fallback: Found $($allUsers.Count) users" -ForegroundColor Yellow
}

#############################################
### RETRIEVE ALL BACKGROUND TASKS WITHOUT LIMITS ###
Write-Host "`n[1/4] Retrieving Background Tasks..." -ForegroundColor Cyan

try {
    # We need to work around the 50 item limit in the module
    $allBackgroundTasks = @()
    
    # Build the URI properly
    $backgroundTasksBaseUri = $server.TrimEnd('/') + "/api/management/v2/backgroundtasks"
    
    # Build the filter
    $filter = [ordered]@{
        createdStart = $startDate
        createdEnd = $endDate
        Status = @(1, 2, 4, 8, 16)  # All statuses
        Type = @(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,18,20,22,23,24,25,26,27,28)  # All types
    }
    
    $query = $filter | ConvertTo-Json -Compress
    $encoded = [System.Web.HttpUtility]::UrlEncode($query)
    
    # Try to get with higher limit
    $uri = "$backgroundTasksBaseUri`?page=1&start=0&limit=5000&filter=$encoded"
    
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    if ($response.Items) {
        $allBackgroundTasks = $response.Items
    }
    
    # If we hit a limit, paginate
    if ($response.TotalCount -and $response.TotalCount -gt $allBackgroundTasks.Count) {
        Write-Host "  Retrieving additional pages..." -ForegroundColor Yellow
        $totalPages = [Math]::Ceiling($response.TotalCount / 100)
        for ($page = 2; $page -le $totalPages; $page++) {
            $uri = "$backgroundTasksBaseUri`?page=$page&start=$(($page-1)*100)&limit=100&filter=$encoded"
            $pageResponse = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            if ($pageResponse.Items) {
                $allBackgroundTasks += $pageResponse.Items
            }
        }
    }
    
    $backgroundTasks = $allBackgroundTasks
    Write-Host "  Found $($backgroundTasks.Count) background tasks (all retrieved)" -ForegroundColor Green
    
} catch {
    Write-Host "  Error with custom retrieval: $_" -ForegroundColor Red
    Write-Host "  Falling back to module function..." -ForegroundColor Yellow
    # Fallback to module function
    $backgroundTasks = Get-AllBackgroundTasks `
        -authorizationToken $token `
        -startDate $startDate `
        -endDate $endDate
    Write-Host "  Found $($backgroundTasks.Count) background tasks (limited)" -ForegroundColor Yellow
}

#############################################
### RETRIEVE ALL PROJECTS WITHOUT LIMITS ###
Write-Host "`n[2/4] Retrieving Project Activity..." -ForegroundColor Cyan

try {
    # Get ALL projects first without date filters to see the real total
    $projectsBaseUri = $server.TrimEnd('/') + "/api/projectserver/v2/projects"
    
    # Build query for all projects
    $allProjectsFilter = @{
        includeSubOrgs = $true
        orgPath = "/"
        publishStart = ""
        publishEnd = ""
        dueStart = ""
        dueEnd = ""
        status = 31  # All statuses (1+2+4+8+16)
    }
    
    $allProjectsQuery = $allProjectsFilter | ConvertTo-Json -Compress
    $allProjectsEncoded = [System.Web.HttpUtility]::UrlEncode($allProjectsQuery)
    
    # Get all projects with high limit
    $allProjectsUri = "$projectsBaseUri`?page=1&start=0&limit=10000&filter=$allProjectsEncoded"
    $allProjectsResponse = Invoke-RestMethod -Uri $allProjectsUri -Headers $headers -Method Get
    
    $allProjects = @()
    if ($allProjectsResponse.Items) {
        $allProjects = $allProjectsResponse.Items
    }
    
    Write-Host "  Total projects on server: $($allProjects.Count) (actual count)" -ForegroundColor Yellow
    
    # Now get projects with activity in date range
    $activeProjectsFilter = @{
        includeSubOrgs = $true
        orgPath = if ($selectedOrganization) { $selectedOrganization.Path } else { "/" }
        publishStart = $startDate
        publishEnd = $endDate
        dueStart = $startDate
        dueEnd = $endDate
        status = 31  # All statuses
    }
    
    $activeProjectsQuery = $activeProjectsFilter | ConvertTo-Json -Compress
    $activeProjectsEncoded = [System.Web.HttpUtility]::UrlEncode($activeProjectsQuery)
    
    $activeProjectsUri = "$projectsBaseUri`?page=1&start=0&limit=10000&filter=$activeProjectsEncoded"
    $activeProjectsResponse = Invoke-RestMethod -Uri $activeProjectsUri -Headers $headers -Method Get
    
    $projects = @()
    if ($activeProjectsResponse.Items) {
        $projects = $activeProjectsResponse.Items
    }
    
    Write-Host "  Found $($projects.Count) projects with activity in date range" -ForegroundColor Green
    
} catch {
    Write-Host "  Error with custom project retrieval: $_" -ForegroundColor Red
    Write-Host "  Falling back to module functions..." -ForegroundColor Yellow
    
    # Fallback to module functions
    $allProjects = Get-AllProjects -authorizationToken $token
    Write-Host "  Total projects: $($allProjects.Count)" -ForegroundColor Yellow
    
    $projects = Get-AllProjects `
        -authorizationToken $token `
        -publishStart $startDate `
        -publishEnd $endDate `
        -defaultPublishDates $false
    
    Write-Host "  Active projects: $($projects.Count)" -ForegroundColor Yellow
}

#############################################
### ENHANCED USER AND PROJECT CREATOR ANALYSIS ###

# After retrieving projects, let's extract and analyze creators
Write-Host "`n[2.5/4] Analyzing Project Creators and Users..." -ForegroundColor Cyan

# Extract unique project creators from projects
$projectCreators = @()
if ($projects.Count -gt 0) {
    # Check various possible fields for creator information
    $creatorFields = @('CreatedBy', 'CreatedByUserName', 'CreatedByUserId', 'Owner', 'Author')
    
    foreach ($project in $projects) {
        $creatorFound = $false
        
        # Try each possible field
        foreach ($field in $creatorFields) {
            if ($project.PSObject.Properties.Name -contains $field -and $project.$field) {
                $projectCreators += [PSCustomObject]@{
                    ProjectName = $project.Name
                    ProjectId = $project.ProjectId
                    Creator = $project.$field
                    Field = $field
                    CreatedAt = $project.CreatedAt
                }
                $creatorFound = $true
                break
            }
        }
        
        # If no explicit creator field, check in description or other metadata
        if (-not $creatorFound) {
            # Check if there's any email-like pattern in the project data
            $projectJson = $project | ConvertTo-Json -Depth 2
            if ($projectJson -match '([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})') {
                $emailFound = $matches[1]
                $projectCreators += [PSCustomObject]@{
                    ProjectName = $project.Name
                    ProjectId = $project.ProjectId
                    Creator = $emailFound
                    Field = "ExtractedFromData"
                    CreatedAt = $project.CreatedAt
                }
            }
        }
    }
    
    Write-Host "  Found $($projectCreators.Count) project creation records" -ForegroundColor Green
    
    # Get unique creators
    $uniqueCreators = $projectCreators | Select-Object -ExpandProperty Creator -Unique
    Write-Host "  Unique project creators: $($uniqueCreators.Count)" -ForegroundColor Green
    
    if ($uniqueCreators.Count -gt 0) {
        Write-Host "  Sample creators found:" -ForegroundColor Yellow
        $uniqueCreators | Select-Object -First 5 | ForEach-Object {
            Write-Host "    • $_" -ForegroundColor Gray
        }
    }
}

# Let's also check project file information for user activity
Write-Host "`nChecking for user activity in project files..." -ForegroundColor Yellow
$fileUserActivity = @()

foreach ($project in $projects | Select-Object -First 10) {  # Sample first 10 projects
    try {
        # Get project files info
        $filesInfo = Get-ProjectFilesInfo -authorizationToken $token -project $project
        
        if ($filesInfo) {
            foreach ($file in $filesInfo) {
                # Check for assignees
                if ($file.Assignees -and $file.Assignees.Count -gt 0) {
                    foreach ($assignee in $file.Assignees) {
                        $fileUserActivity += [PSCustomObject]@{
                            ProjectName = $project.Name
                            FileName = $file.FileName
                            UserName = $assignee.UserName
                            DisplayName = $assignee.DisplayName
                            Email = $assignee.EmailAddress
                            Role = "Assignee"
                        }
                    }
                }
                
                # Check for last modified by
                if ($file.LastModifiedBy) {
                    $fileUserActivity += [PSCustomObject]@{
                        ProjectName = $project.Name
                        FileName = $file.FileName
                        UserName = $file.LastModifiedBy
                        DisplayName = $file.LastModifiedBy
                        Email = ""
                        Role = "LastModified"
                    }
                }
            }
        }
    } catch {
        # Silently continue if we can't get file info for a project
    }
}

if ($fileUserActivity.Count -gt 0) {
    $uniqueFileUsers = $fileUserActivity | Select-Object UserName, DisplayName, Email -Unique
    Write-Host "  Found $($uniqueFileUsers.Count) users from file assignments" -ForegroundColor Green
}

# Enhanced user retrieval with better error handling
Write-Host "`nRetrieving user information (enhanced)..." -ForegroundColor Yellow

# First, let's check what the actual user endpoint returns
try {
    $testUri = $server.TrimEnd('/') + "/api/management/v2/users?page=1&limit=1"
    $testResponse = Invoke-RestMethod -Uri $testUri -Headers $headers -Method Get
    
    Write-Host "  User API test response:" -ForegroundColor Yellow
    Write-Host "    Total Count: $($testResponse.TotalCount)" -ForegroundColor Gray
    Write-Host "    Items Count: $($testResponse.items.Count)" -ForegroundColor Gray
    
    if ($testResponse.items -and $testResponse.items.Count -gt 0) {
        Write-Host "  Sample user structure:" -ForegroundColor Yellow
        $testResponse.items[0] | Get-Member -MemberType NoteProperty | Select-Object -First 5 | ForEach-Object {
            Write-Host "    • $($_.Name)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  Could not test user API: $_" -ForegroundColor Red
}

# Now retrieve all users with better pagination
$allUsers = @()
try {
    $usersBaseUri = $server.TrimEnd('/') + "/api/management/v2/users"
    $page = 1
    $pageSize = 100
    $hasMore = $true
    
    while ($hasMore) {
        $uri = "$usersBaseUri`?page=$page&limit=$pageSize"
        
        try {
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            
            if ($response.items -and $response.items.Count -gt 0) {
                $allUsers += $response.items
                Write-Host "    Retrieved page $page with $($response.items.Count) users (Total so far: $($allUsers.Count))" -ForegroundColor Gray
                
                # Check if we have more pages
                if ($response.TotalCount) {
                    $totalPages = [Math]::Ceiling($response.TotalCount / $pageSize)
                    if ($page -ge $totalPages) {
                        $hasMore = $false
                    } else {
                        $page++
                    }
                } else {
                    # If no TotalCount, check if we got a full page
                    if ($response.items.Count -lt $pageSize) {
                        $hasMore = $false
                    } else {
                        $page++
                    }
                }
            } else {
                $hasMore = $false
            }
        } catch {
            Write-Host "  Error on page $page`: $_" -ForegroundColor Red
            $hasMore = $false
        }
    }
    
    Write-Host "  Total users retrieved: $($allUsers.Count)" -ForegroundColor Green
    
} catch {
    Write-Host "  Error retrieving users: $_" -ForegroundColor Red
}

# If we still have no users, try alternative approaches
if ($allUsers.Count -eq 0) {
    Write-Host "`nTrying alternative user retrieval methods..." -ForegroundColor Yellow
    
    # Try to get users from roles
    try {
        $roles = Get-AllRoles -authorizationToken $token
        Write-Host "  Found $($roles.Count) roles" -ForegroundColor Gray
        
        foreach ($role in $roles | Select-Object -First 3) {  # Sample first 3 roles
            try {
                $roleUsers = Get-AllUsersFromRole -authorizationToken $token -role $role
                if ($roleUsers) {
                    $allUsers += $roleUsers
                    Write-Host "    Found $($roleUsers.Count) users in role: $($role.Name)" -ForegroundColor Gray
                }
            } catch {
                # Continue with next role
            }
        }
        
        # Remove duplicates
        if ($allUsers.Count -gt 0) {
            $allUsers = $allUsers | Select-Object -Unique -Property UniqueId
        }
        
    } catch {
        Write-Host "  Could not retrieve users from roles: $_" -ForegroundColor Red
    }
}

# Create a comprehensive user list from all sources
Write-Host "`nCompiling comprehensive user list from all sources..." -ForegroundColor Yellow
$comprehensiveUsers = @()

# Add users from user API
foreach ($user in $allUsers) {
    $comprehensiveUsers += [PSCustomObject]@{
        Source = "UserAPI"
        UserName = $user.Name
        DisplayName = $user.DisplayName
        Email = $user.EmailAddress
        UniqueId = $user.UniqueId
        Organization = $user.OrganizationId
    }
}

# Add users from project creators
foreach ($creator in $uniqueCreators) {
    # Check if this creator is not already in our list
    if (-not ($comprehensiveUsers | Where-Object { $_.UserName -eq $creator -or $_.Email -eq $creator })) {
        $comprehensiveUsers += [PSCustomObject]@{
            Source = "ProjectCreator"
            UserName = $creator
            DisplayName = $creator
            Email = if ($creator -match '@') { $creator } else { "" }
            UniqueId = ""
            Organization = ""
        }
    }
}

# Add users from file activity
foreach ($fileUser in $uniqueFileUsers) {
    if (-not ($comprehensiveUsers | Where-Object { $_.UserName -eq $fileUser.UserName })) {
        $comprehensiveUsers += [PSCustomObject]@{
            Source = "FileActivity"
            UserName = $fileUser.UserName
            DisplayName = $fileUser.DisplayName
            Email = $fileUser.Email
            UniqueId = ""
            Organization = ""
        }
    }
}

Write-Host "  Total unique users from all sources: $($comprehensiveUsers.Count)" -ForegroundColor Green

# Display user summary
if ($comprehensiveUsers.Count -gt 0) {
    Write-Host "`n  User Summary by Source:" -ForegroundColor Cyan
    $comprehensiveUsers | Group-Object -Property Source | ForEach-Object {
        Write-Host "    • $($_.Name): $($_.Count) users" -ForegroundColor Gray
    }
    
    Write-Host "`n  Sample Users:" -ForegroundColor Cyan
    $comprehensiveUsers | Select-Object -First 5 | ForEach-Object {
        Write-Host "    • $($_.DisplayName) ($($_.Email)) - Source: $($_.Source)" -ForegroundColor Gray
    }
}

# Update the global $allUsers variable with comprehensive list
if ($comprehensiveUsers.Count -gt 0) {
    $allUsers = $comprehensiveUsers
    Write-Host "`n  ✓ User data successfully compiled from multiple sources" -ForegroundColor Green
} else {
    Write-Host "`n  ⚠️ Warning: No user data could be retrieved from any source" -ForegroundColor Yellow
    Write-Host "     This may indicate an API permission issue or authentication problem" -ForegroundColor Yellow
}

# Debug: Show actual project structure to understand user fields
if ($projects.Count -gt 0) {
    Write-Host "`nDebug: Project data structure (first project):" -ForegroundColor Magenta
    $projects[0] | Get-Member -MemberType NoteProperty | Select-Object -First 10 | ForEach-Object {
        $value = $projects[0].($_.Name)
        if ($value) {
            Write-Host "  $($_.Name): $value" -ForegroundColor Gray
        }
    }
}

#############################################
### ANALYZE ACTIVITY DATA WITH USER CORRELATION ###
Write-Host "`n[3/4] Analyzing Activity Data..." -ForegroundColor Cyan

# Define better mappings for task types
$taskTypeSimplification = @{
    "DeleteProject" = "Delete Project"
    "CreateProject" = "Create Project"
    "GeneratePTAReport" = "Generate PTA Report"
    "CleanSynchronizationPackages" = "Clean Sync Packages"
    "DetachProjects" = "Detach Projects"
    "MonitorFilesDueDate" = "Monitor Due Dates"
    "PeriodicArchivingProjects" = "Periodic Archiving"
    "PublishProject" = "Publish Project"
    "UpdateProject" = "Update Project"
    "ApplyTM" = "Apply TM"
    "ImportTM" = "Import TM"
    "ExportTM" = "Export TM"
    "PackageExport" = "Export Package"
    "PackageImport" = "Import Package"
    "PackagePublishing" = "Package Publishing"
    "BcmImport" = "BCM Import"
    "DeleteTU" = "Delete TU"
    "RecomputeStats" = "Recompute Statistics"
    "ReindexTM" = "Reindex TM"
    "FullAlign" = "Full Alignment"
    "AutoReindex" = "Auto Reindex"
    "UpdateTm" = "Update TM"
    "EditTU" = "Edit TU"
    "DeleteOrganization" = "Delete Organization"
}

# Map project statuses
$projectStatusMapping = @{
    0 = "Started"
    1 = "Pending"
    2 = "In Progress"
    3 = "Completed"
    4 = "Archived"
    5 = "Detached"
}

# Process background tasks with better user/org extraction
if ($backgroundTasks.Count -gt 0) {
    $processedTasks = $backgroundTasks | ForEach-Object {
        # Extract and clean task type name
        $taskTypeName = ""
        if ($_.Type -match '\.([^\.]+)WorkItem') {
            $taskTypeName = $matches[1]
        } elseif ($_.Type -match '\.([^\.]+),') {
            $taskTypeName = $matches[1]
        } else {
            $taskTypeName = $_.Type
        }
        
        # Clean up task type name
        $taskTypeName = $taskTypeName -replace 'WorkItem$', ''
        $taskTypeName = $taskTypeName -replace 'ProjectTasks\.', ''
        $taskTypeName = $taskTypeName -replace 'Tasks\.', ''
        
        # Apply simplification mapping
        if ($taskTypeSimplification.ContainsKey($taskTypeName)) {
            $taskTypeName = $taskTypeSimplification[$taskTypeName]
        } else {
            $taskTypeName = $taskTypeName -creplace '(?<!^)(?=[A-Z])', ' '
        }
        
        # Map status
        $statusName = switch ($_.Status) {
            1 { "Queued" }
            2 { "In Progress" }
            4 { "Canceled" }
            8 { "Failed" }
            16 { "Done" }
            default { "Unknown" }
        }
        
        # Extract organization name from task name or path
        $organizationName = "Unknown"
        $extractedUser = "System"
        
        # Try to extract org and user from task name
        # Task names often have format: "OrgName/ProjectName" or similar
        if ($_.Name) {
            # Try to extract organization from the beginning of the name
            if ($_.Name -match '^([^/\\]+)[/\\]') {
                $organizationName = $matches[1]
            }
            # For project-related tasks, try to find the org in the name
            elseif ($_.Name -match '(QA_only|Consoltec|Public_Demo|Globetrotter|fastforward|Dev_only|Project Resources|Trados Product Teams)') {
                $organizationName = $matches[1]
                if ($organizationName -eq "Globetrotter") {
                    $organizationName = "Globetrotter Int."
                }
            }
        }
        
        # If still unknown, try OrganizationPath
        if ($organizationName -eq "Unknown" -and $_.OrganizationPath) {
            $pathParts = $_.OrganizationPath -split '/'
            $organizationName = $pathParts | Where-Object { $_ -ne "" } | Select-Object -Last 1
            if (-not $organizationName) { $organizationName = "Root" }
        }
        
        # Try to extract user from CreatedBy or other fields
        if ($_.CreatedBy) {
            $extractedUser = $_.CreatedBy
        } elseif ($_.User) {
            $extractedUser = $_.User
        } elseif ($_.InitiatedBy) {
            $extractedUser = $_.InitiatedBy
        }
        
        # Get user details from our user list
        $userDisplayName = $extractedUser
        $userEmail = ""
        if ($extractedUser -and $extractedUser -ne "System") {
            $userDetails = $allUsers | Where-Object { 
                $_.UserName -eq $extractedUser -or 
                $_.DisplayName -eq $extractedUser 
            } | Select-Object -First 1
            if ($userDetails) {
                $userDisplayName = if ($userDetails.DisplayName) { $userDetails.DisplayName } else { $extractedUser }
                $userEmail = if ($userDetails.Email) { $userDetails.Email } else { "" }
            }
        }
        
        [PSCustomObject]@{
            "Task Name" = $_.Name
            "Task Type" = $taskTypeName.Trim()
            "Status" = $statusName
            "Created" = $_.CreatedAt
            "Updated" = $_.UpdatedAt
            "User" = $extractedUser
            "UserDisplayName" = $userDisplayName
            "UserEmail" = $userEmail
            "Organization" = $organizationName
        }
    }
} else {
    $processedTasks = @()
}

# Process projects WITH USER INFORMATION AND PARENT ORG
if ($projects.Count -gt 0) {
    $processedProjects = $projects | ForEach-Object {
        $statusText = if ($projectStatusMapping.ContainsKey($_.Status)) {
            $projectStatusMapping[$_.Status]
        } else {
            "Unknown"
        }
        
        # Extract organization from path or name
        $orgName = "Unknown"
        $parentOrgName = "Unknown"
        $fullOrgPath = "Unknown"
        
        # Try to find the organization object
        $projectOrg = $null
        if ($_.OrganizationId) {
            $projectOrg = $orgById[$_.OrganizationId]
        }
        
        if ($projectOrg) {
            $orgName = $projectOrg.Name
            # Get the first-level parent (not root)
            $firstLevelParent = Get-RootParentOrganization -org $projectOrg
            if ($firstLevelParent) {
                # If the project org is already a first-level org, it is its own parent
                if ($firstLevelParent.UniqueId -eq $projectOrg.UniqueId) {
                    $parentOrgName = $orgName
                } else {
                    $parentOrgName = $firstLevelParent.Name
                }
            } else {
                $parentOrgName = $orgName
            }
            # Get the full path
            $fullOrgPath = Get-OrganizationPath -org $projectOrg
        } elseif ($_.OrganizationPath) {
            $pathParts = $_.OrganizationPath -split '/' | Where-Object { $_ -ne "" }
            $orgName = $pathParts | Select-Object -Last 1
            if (-not $orgName) { $orgName = "Unknown" }
            # First non-empty part is the first-level org
            $parentOrgName = $pathParts | Select-Object -First 1
            if (-not $parentOrgName) { $parentOrgName = $orgName }
            $fullOrgPath = $_.OrganizationPath
        } elseif ($_.OrganizationName) {
            $orgName = $_.OrganizationName
            # Try to find the org object by name
            $projectOrg = $allOrganizations | Where-Object { $_.Name -eq $orgName } | Select-Object -First 1
            if ($projectOrg) {
                $firstLevelParent = Get-RootParentOrganization -org $projectOrg
                if ($firstLevelParent) {
                    if ($firstLevelParent.UniqueId -eq $projectOrg.UniqueId) {
                        $parentOrgName = $orgName
                    } else {
                        $parentOrgName = $firstLevelParent.Name
                    }
                } else {
                    $parentOrgName = $orgName
                }
                $fullOrgPath = Get-OrganizationPath -org $projectOrg
            } else {
                $parentOrgName = $orgName
            }
        }
        
        # Extract creator information
        $creatorName = if ($_.CreatedBy) { $_.CreatedBy } else { "Unknown" }
        $creatorEmail = ""
        $creatorDisplayName = $creatorName
        
        # Try to find creator in our user list
        if ($creatorName -ne "Unknown") {
            $creatorDetails = $allUsers | Where-Object { 
                $_.UserName -eq $creatorName -or 
                $_.DisplayName -eq $creatorName -or
                $_.Email -eq $creatorName
            } | Select-Object -First 1
            
            if ($creatorDetails) {
                $creatorDisplayName = if ($creatorDetails.DisplayName) { $creatorDetails.DisplayName } else { $creatorName }
                $creatorEmail = if ($creatorDetails.Email) { $creatorDetails.Email } else { "" }
            }
        }
        
        $_ | Add-Member -NotePropertyName "StatusText" -NotePropertyValue $statusText -PassThru -Force
        $_ | Add-Member -NotePropertyName "OrganizationName" -NotePropertyValue $orgName -PassThru -Force
        $_ | Add-Member -NotePropertyName "ParentOrganizationName" -NotePropertyValue $parentOrgName -PassThru -Force
        $_ | Add-Member -NotePropertyName "FullOrganizationPath" -NotePropertyValue $fullOrgPath -PassThru -Force
        $_ | Add-Member -NotePropertyName "CreatorName" -NotePropertyValue $creatorName -PassThru -Force
        $_ | Add-Member -NotePropertyName "CreatorDisplayName" -NotePropertyValue $creatorDisplayName -PassThru -Force
        $_ | Add-Member -NotePropertyName "CreatorEmail" -NotePropertyValue $creatorEmail -PassThru -Force
    }
} else {
    $processedProjects = @()
}

#############################################
### CREATE ORGANIZATION-CENTRIC ANALYSIS WITH USERS ###
Write-Host "`n[4/4] Generating Organization Activity Analysis..." -ForegroundColor Cyan

# Get organizations with activity
$activeOrganizations = @()

# From background tasks
if ($processedTasks.Count -gt 0) {
    $taskOrgs = $processedTasks | Select-Object -ExpandProperty Organization -Unique
    $activeOrganizations += $taskOrgs
}

# From projects
if ($processedProjects.Count -gt 0) {
    $projectOrgs = $processedProjects | Select-Object -ExpandProperty OrganizationName -Unique
    $activeOrganizations += $projectOrgs
}

# Get unique active organizations
$activeOrganizations = $activeOrganizations | Select-Object -Unique | Where-Object { $_ -and $_ -ne "Unknown" }

# Create detailed organization activity breakdown WITH USER TRACKING
$organizationDetails = @()

foreach ($org in $activeOrganizations) {
    # Get tasks for this organization
    $orgTasks = $processedTasks | Where-Object { $_.Organization -eq $org }
    $orgProjects = $processedProjects | Where-Object { $_.OrganizationName -eq $org }
    
    # Get unique users from BOTH tasks and projects
    $orgUsersFromTasks = $orgTasks | Where-Object { $_.User -ne "System" } | 
                                     Select-Object User, UserDisplayName, UserEmail -Unique
    
    $orgUsersFromProjects = $orgProjects | Where-Object { $_.CreatorName -ne "Unknown" } |
                                          Select-Object @{Name="User";Expression={$_.CreatorName}},
                                                       @{Name="UserDisplayName";Expression={$_.CreatorDisplayName}},
                                                       @{Name="UserEmail";Expression={$_.CreatorEmail}} -Unique
    
    # Combine users from both sources
    $allOrgUsers = @()
    $allOrgUsers += $orgUsersFromTasks
    $allOrgUsers += $orgUsersFromProjects
    
    # Remove duplicates based on User name
    $uniqueOrgUsers = $allOrgUsers | Group-Object -Property User | ForEach-Object {
        $_.Group | Select-Object -First 1
    }
    
    # Task type breakdown for this org
    $orgTaskTypes = $orgTasks | Group-Object -Property "Task Type" | 
                               Select-Object @{Name="Type";Expression={$_.Name}}, Count
    
    # Task status breakdown for this org
    $orgTaskStatus = $orgTasks | Group-Object -Property Status | 
                                Select-Object @{Name="Status";Expression={$_.Name}}, Count
    
    # Project creator breakdown
    $projectCreatorStats = $orgProjects | Group-Object -Property CreatorName |
                                         Select-Object @{Name="Creator";Expression={$_.Name}}, 
                                                      @{Name="ProjectCount";Expression={$_.Count}}
    
    $organizationDetails += [PSCustomObject]@{
        Organization = $org
        TotalTasks = $orgTasks.Count
        TotalProjects = $orgProjects.Count
        UniqueUsers = $uniqueOrgUsers.Count
        Users = $uniqueOrgUsers
        ProjectCreators = $projectCreatorStats
        TaskTypes = $orgTaskTypes
        TaskStatuses = $orgTaskStatus
        Tasks = $orgTasks
        Projects = $orgProjects
    }
}

# Sort by total activity
$organizationDetails = $organizationDetails | Sort-Object @{Expression={$_.TotalTasks + $_.TotalProjects}} -Descending

#############################################
### PARENT ORGANIZATION ANALYSIS ###
Write-Host "`n[4.5/4] Generating Parent Organization Analysis..." -ForegroundColor Cyan

# Group activities by PARENT organization
$parentOrgActivities = @{}

# Process projects by parent org
foreach ($project in $processedProjects) {
    $parentOrg = if ($project.ParentOrganizationName) { $project.ParentOrganizationName } else { "Unknown" }
    
    if (-not $parentOrgActivities.ContainsKey($parentOrg)) {
        $parentOrgActivities[$parentOrg] = @{
            Projects = @()
            Tasks = @()
            SubOrganizations = @{}
        }
    }
    
    $parentOrgActivities[$parentOrg].Projects += $project
    
    # Track sub-organization
    $subOrg = $project.OrganizationName
    if ($subOrg -and $subOrg -ne $parentOrg) {
        if (-not $parentOrgActivities[$parentOrg].SubOrganizations.ContainsKey($subOrg)) {
            # Properly capture the full path from the project
            $fullPath = if ($project.FullOrganizationPath -and $project.FullOrganizationPath -ne "Unknown") {
                $project.FullOrganizationPath
            } else {
                # Build path as Parent > SubOrg if we don't have the full path
                "$parentOrg > $subOrg"
            }
            
            $parentOrgActivities[$parentOrg].SubOrganizations[$subOrg] = @{
                Projects = @()
                Tasks = @()
                FullPath = $fullPath
            }
        }
        $parentOrgActivities[$parentOrg].SubOrganizations[$subOrg].Projects += $project
    }
}

# Process tasks by parent org (if we can determine it)
foreach ($task in $processedTasks) {
    $taskOrg = $task.Organization
    $parentOrg = "Unknown"  # Default to Unknown
    
    # Try to find the actual organization and its parent
    if ($taskOrg -ne "Unknown") {
        $org = $allOrganizations | Where-Object { $_.Name -eq $taskOrg } | Select-Object -First 1
        if ($org) {
            $firstLevelParent = Get-RootParentOrganization -org $org
            if ($firstLevelParent) {
                # If the task org is already a first-level org, it is its own parent
                if ($firstLevelParent.UniqueId -eq $org.UniqueId) {
                    $parentOrg = $taskOrg
                } else {
                    $parentOrg = $firstLevelParent.Name
                }
            } else {
                $parentOrg = $taskOrg
            }
        } else {
            # If we can't find the org object, try to infer from known first-level orgs
            if ($taskOrg -in @("QA_only", "Consoltec", "Public_Demo", "Globetrotter Int.", 
                               "fastforward", "Dev_only", "Project Resources", "Trados Product Teams")) {
                $parentOrg = $taskOrg
            }
        }
    }
    
    if (-not $parentOrgActivities.ContainsKey($parentOrg)) {
        $parentOrgActivities[$parentOrg] = @{
            Projects = @()
            Tasks = @()
            SubOrganizations = @{}
        }
    }
    
    $parentOrgActivities[$parentOrg].Tasks += $task
    
    # Track sub-organization tasks
    if ($taskOrg -ne $parentOrg -and $taskOrg -ne "Unknown") {
        if (-not $parentOrgActivities[$parentOrg].SubOrganizations.ContainsKey($taskOrg)) {
            # Try to get the full path for this organization
            $fullPath = ""
            $taskOrgObj = $allOrganizations | Where-Object { $_.Name -eq $taskOrg } | Select-Object -First 1
            if ($taskOrgObj) {
                $fullPath = Get-OrganizationPath -org $taskOrgObj
            } else {
                # Build a simple path if we can't find the org
                $fullPath = "$parentOrg > $taskOrg"
            }
            
            $parentOrgActivities[$parentOrg].SubOrganizations[$taskOrg] = @{
                Projects = @()
                Tasks = @()
                FullPath = $fullPath
            }
        }
        $parentOrgActivities[$parentOrg].SubOrganizations[$taskOrg].Tasks += $task
    }
}

# Create detailed parent organization breakdown
$parentOrganizationDetails = @()

foreach ($parentOrgName in $parentOrgActivities.Keys) {
    $parentData = $parentOrgActivities[$parentOrgName]
    
    # Get unique users across all activities
    $allUsersForParent = @()
    
    # Users from projects
    $projectUsers = $parentData.Projects | 
                   Where-Object { $_.CreatorName -ne "Unknown" } |
                   Select-Object @{Name="User";Expression={$_.CreatorName}},
                                @{Name="UserDisplayName";Expression={$_.CreatorDisplayName}},
                                @{Name="UserEmail";Expression={$_.CreatorEmail}} -Unique
    $allUsersForParent += $projectUsers
    
    # Users from tasks
    $taskUsers = $parentData.Tasks | 
                Where-Object { $_.User -ne "System" -and $_.User -ne "" } |
                Select-Object User, UserDisplayName, UserEmail -Unique
    $allUsersForParent += $taskUsers
    
    # Remove duplicates
    $uniqueUsers = $allUsersForParent | Group-Object -Property User | ForEach-Object {
        $_.Group | Select-Object -First 1
    }
    
    # Project creator breakdown
    $projectCreatorStats = $parentData.Projects | 
                          Group-Object -Property CreatorName |
                          Where-Object { $_.Name -ne "Unknown" } |
                          Select-Object @{Name="Creator";Expression={$_.Name}}, 
                                       @{Name="ProjectCount";Expression={$_.Count}}
    
    # Sub-organization summary
    $subOrgSummaries = @()
    foreach ($subOrgName in $parentData.SubOrganizations.Keys) {
        $subOrgData = $parentData.SubOrganizations[$subOrgName]
        $subOrgSummaries += [PSCustomObject]@{
            Name = $subOrgName
            ProjectCount = $subOrgData.Projects.Count
            TaskCount = $subOrgData.Tasks.Count
            TotalActivity = $subOrgData.Projects.Count + $subOrgData.Tasks.Count
            Path = $subOrgData.FullPath
        }
    }
    
    $parentOrganizationDetails += [PSCustomObject]@{
        ParentOrganization = $parentOrgName
        TotalProjects = $parentData.Projects.Count
        TotalTasks = $parentData.Tasks.Count
        TotalActivity = $parentData.Projects.Count + $parentData.Tasks.Count
        UniqueUsers = $uniqueUsers.Count
        Users = $uniqueUsers
        ProjectCreators = $projectCreatorStats
        SubOrganizations = $subOrgSummaries | Sort-Object TotalActivity -Descending
        Projects = $parentData.Projects
        Tasks = $parentData.Tasks
    }
}

# Sort by total activity
$parentOrganizationDetails = $parentOrganizationDetails | Sort-Object TotalActivity -Descending

##########################################################
### DISPLAY RESULTS WITH PARENT ORGANIZATION HIERARCHY ###

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║          ACTIVITY SUMMARY REPORT                       ║" -ForegroundColor Yellow
Write-Host "║          Period: $startDate to $endDate                ║" -ForegroundColor Yellow
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Yellow

# Overall Statistics
Write-Host "`n▶ OVERALL STATISTICS" -ForegroundColor Cyan
Write-Host "  ├─ Total Background Tasks Retrieved: $($backgroundTasks.Count)"
Write-Host "  ├─ Total Projects on Server: $($allProjects.Count)"
Write-Host "  ├─ Projects with Activity: $($projects.Count)"
Write-Host "  ├─ Active Parent Organizations: $($parentOrganizationDetails.Count)"
Write-Host "  ├─ Total Organizations in System: $($allOrganizations.Count)"
Write-Host "  └─ Total Users in System: $($comprehensiveUsers.Count)"

# Parent Organization Activity Summary
Write-Host "`n▶ ACTIVITY BY PARENT ORGANIZATION (COMPANY LEVEL)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Gray

foreach ($parentOrgDetail in $parentOrganizationDetails) {
    Write-Host "`n  🏢 $($parentOrgDetail.ParentOrganization)" -ForegroundColor Yellow -NoNewline
    Write-Host " (Parent Company)" -ForegroundColor DarkGray
    Write-Host "  ├─ Total Activities: $($parentOrgDetail.TotalActivity)" -ForegroundColor White
    Write-Host "  ├─ Projects: $($parentOrgDetail.TotalProjects)" -ForegroundColor White
    Write-Host "  ├─ Background Tasks: $($parentOrgDetail.TotalTasks)" -ForegroundColor White
    Write-Host "  └─ Active Users: $($parentOrgDetail.UniqueUsers)" -ForegroundColor White
    
    # Show sub-organizations if any
    if ($parentOrgDetail.SubOrganizations.Count -gt 0) {
        Write-Host "      Sub-Organizations:" -ForegroundColor Cyan
        foreach ($subOrg in $parentOrgDetail.SubOrganizations) {
            if ($subOrg.Name -ne $parentOrgDetail.ParentOrganization) {
                Write-Host "        📁 $($subOrg.Name)" -ForegroundColor DarkCyan
                Write-Host "           Activities: $($subOrg.TotalActivity) (Projects: $($subOrg.ProjectCount), Tasks: $($subOrg.TaskCount))" -ForegroundColor Gray
            }
        }
    }
    
    # Show project creators
    if ($parentOrgDetail.ProjectCreators.Count -gt 0) {
        Write-Host "      Top Project Creators:" -ForegroundColor Cyan
        foreach ($creator in ($parentOrgDetail.ProjectCreators | Sort-Object ProjectCount -Descending | Select-Object -First 5)) {
            $creatorDetails = $parentOrgDetail.Users | Where-Object { $_.User -eq $creator.Creator } | Select-Object -First 1
            if ($creatorDetails -and $creatorDetails.UserEmail) {
                Write-Host "        • $($creator.Creator) ($($creatorDetails.UserEmail)) - $($creator.ProjectCount) projects" -ForegroundColor Gray
            } else {
                Write-Host "        • $($creator.Creator) - $($creator.ProjectCount) projects" -ForegroundColor Gray
            }
        }
    }
    
    # Show recent activity samples
    $recentProjects = $parentOrgDetail.Projects | Sort-Object CreatedAt -Descending | Select-Object -First 3
    if ($recentProjects.Count -gt 0) {
        Write-Host "      Recent Projects:" -ForegroundColor Cyan
        foreach ($project in $recentProjects) {
            $projectDate = "Unknown date"
            if ($project.CreatedAt) {
                try {
                    $dateString = $project.CreatedAt
                    if ($dateString -match '^\d{2}/\d{2}/\d{4}') {
                        $projectDate = [DateTime]::ParseExact($dateString, "MM/dd/yyyy HH:mm:ss", $null).ToString("yyyy-MM-dd")
                    } elseif ($dateString -match '^\d{4}-\d{2}-\d{2}') {
                        $projectDate = [DateTime]::Parse($dateString).ToString("yyyy-MM-dd")
                    } else {
                        $projectDate = [DateTime]::Parse($dateString).ToString("yyyy-MM-dd")
                    }
                } catch {
                    $projectDate = "Unknown date"
                }
            }
            $subOrgText = if ($project.OrganizationName -ne $parentOrgDetail.ParentOrganization) { 
                " [$($project.OrganizationName)]" 
            } else { 
                "" 
            }
            Write-Host "        • $($project.Name)$subOrgText" -ForegroundColor Gray
            Write-Host "          Created: $projectDate by $($project.CreatorName)" -ForegroundColor DarkGray
        }
    }
}

# Parent Organization Summary Table
Write-Host "`n▶ PARENT ORGANIZATION SUMMARY TABLE" -ForegroundColor Cyan
$parentOrganizationDetails | Select-Object @{Name="Parent Organization";Expression={$_.ParentOrganization}},
                                           @{Name="Projects";Expression={$_.TotalProjects}},
                                           @{Name="Tasks";Expression={$_.TotalTasks}},
                                           @{Name="Total";Expression={$_.TotalActivity}},
                                           @{Name="Users";Expression={$_.UniqueUsers}},
                                           @{Name="Sub-Orgs";Expression={$_.SubOrganizations.Count}} |
                            Format-Table -AutoSize

# Organization Hierarchy View
Write-Host "`n▶ ORGANIZATION HIERARCHY WITH ACTIVITY" -ForegroundColor Cyan
foreach ($parentOrgDetail in ($parentOrganizationDetails | Select-Object -First 10)) {
    Write-Host "`n  $($parentOrgDetail.ParentOrganization) ($($parentOrgDetail.TotalActivity) activities)" -ForegroundColor Yellow
    
    # Group sub-organizations and show their hierarchy
    $subOrgs = $parentOrgDetail.SubOrganizations | Where-Object { $_.Name -ne $parentOrgDetail.ParentOrganization }
    foreach ($subOrg in $subOrgs) {
        $indent = "    "
        if ($subOrg.Path) {
            $pathDepth = ($subOrg.Path -split '>').Count
            if ($pathDepth -gt 2) {
                $indent = "    " * ($pathDepth - 1)
            }
        }
        Write-Host "$indent└─ $($subOrg.Name) ($($subOrg.TotalActivity) activities)" -ForegroundColor DarkCyan
    }
}

# Top Users by Parent Organization
Write-Host "`n▶ TOP USERS BY PARENT ORGANIZATION" -ForegroundColor Cyan
$userByParentOrg = @{}

foreach ($project in $processedProjects) {
    if ($project.CreatorName -and $project.CreatorName -ne "Unknown") {
        $parentOrg = if ($project.ParentOrganizationName) { $project.ParentOrganizationName } else { "Unknown" }
        if (-not $userByParentOrg.ContainsKey($parentOrg)) {
            $userByParentOrg[$parentOrg] = @{}
        }
        if (-not $userByParentOrg[$parentOrg].ContainsKey($project.CreatorName)) {
            $userByParentOrg[$parentOrg][$project.CreatorName] = @{
                Email = $project.CreatorEmail
                Count = 0
            }
        }
        $userByParentOrg[$parentOrg][$project.CreatorName].Count++
    }
}

foreach ($parentOrg in ($userByParentOrg.Keys | Sort-Object)) {
    $users = $userByParentOrg[$parentOrg]
    $topUsers = $users.GetEnumerator() | 
                Sort-Object { $_.Value.Count } -Descending | 
                Select-Object -First 3
    
    if ($topUsers) {
        Write-Host "`n  $parentOrg`:" -ForegroundColor Yellow
        foreach ($user in $topUsers) {
            $email = if ($user.Value.Email) { "($($user.Value.Email))" } else { "" }
            Write-Host "    • $($user.Key) $email - $($user.Value.Count) projects" -ForegroundColor Gray
        }
    }
}

# Export options with parent organization data
Write-Host "`n" -NoNewline
$exportChoice = Read-Host "Do you want to export detailed results to CSV and Markdown files? (Y/N)"

if ($exportChoice -eq "Y" -or $exportChoice -eq "y") {
    $exportPath = Read-Host "Enter the export directory path (or press Enter for current directory)"
    if ([string]::IsNullOrWhiteSpace($exportPath)) {
        $exportPath = Get-Location
    }
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    try {
        # Export projects with parent organization info
        if ($processedProjects.Count -gt 0) {
            $projectsFile = Join-Path $exportPath "Projects_WithParentOrgs_${timestamp}.csv"
            $processedProjects | Select-Object Name, 
                                              StatusText, 
                                              ParentOrganizationName,
                                              OrganizationName,
                                              FullOrganizationPath,
                                              CreatorName,
                                              CreatorEmail,
                                              CreatedAt,
                                              DueDate,
                                              SourceLanguage, 
                                              @{Name="TargetLanguages";Expression={$_.TargetLanguages -join ";"}} | 
                                Export-Csv -Path $projectsFile -NoTypeInformation
            Write-Host "✓ Exported projects with parent orgs to: $projectsFile" -ForegroundColor Green
        }
        
        # Export parent organization summary
        if ($parentOrganizationDetails.Count -gt 0) {
            $parentOrgFile = Join-Path $exportPath "ParentOrganizationActivity_${timestamp}.csv"
            $parentOrganizationDetails | Select-Object @{Name="ParentOrganization";Expression={$_.ParentOrganization}},
                                                       @{Name="TotalProjects";Expression={$_.TotalProjects}},
                                                       @{Name="TotalTasks";Expression={$_.TotalTasks}},
                                                       @{Name="TotalActivity";Expression={$_.TotalActivity}},
                                                       @{Name="UniqueUsers";Expression={$_.UniqueUsers}},
                                                       @{Name="SubOrganizations";Expression={$_.SubOrganizations.Count}},
                                                       @{Name="SubOrgNames";Expression={($_.SubOrganizations | ForEach-Object { $_.Name }) -join "; "}},
                                                       @{Name="TopCreators";Expression={($_.ProjectCreators | Select-Object -First 3 | ForEach-Object { "$($_.Creator):$($_.ProjectCount)" }) -join "; "}} |
                                        Export-Csv -Path $parentOrgFile -NoTypeInformation
            Write-Host "✓ Exported parent organization activity to: $parentOrgFile" -ForegroundColor Green
        }
        
        # Export organization hierarchy
        $hierarchyFile = Join-Path $exportPath "OrganizationHierarchy_${timestamp}.csv"
        $hierarchyData = @()
        foreach ($parentOrgDetail in $parentOrganizationDetails) {
            # Only export sub-organizations that are different from the parent
            $subOrgsToExport = $parentOrgDetail.SubOrganizations | Where-Object { $_.Name -ne $parentOrgDetail.ParentOrganization }
            
            if ($subOrgsToExport.Count -gt 0) {
                foreach ($subOrg in $subOrgsToExport) {
                    $hierarchyData += [PSCustomObject]@{
                        ParentOrganization = $parentOrgDetail.ParentOrganization
                        SubOrganization = $subOrg.Name
                        FullPath = $subOrg.Path
                        Projects = $subOrg.ProjectCount
                        Tasks = $subOrg.TaskCount
                        TotalActivity = $subOrg.TotalActivity
                    }
                }
            } else {
                # If no sub-organizations, just add the parent org itself
                $hierarchyData += [PSCustomObject]@{
                    ParentOrganization = $parentOrgDetail.ParentOrganization
                    SubOrganization = "(No sub-organizations)"
                    FullPath = $parentOrgDetail.ParentOrganization
                    Projects = $parentOrgDetail.TotalProjects
                    Tasks = $parentOrgDetail.TotalTasks
                    TotalActivity = $parentOrgDetail.TotalActivity
                }
            }
        }
        if ($hierarchyData.Count -gt 0) {
            $hierarchyData | Export-Csv -Path $hierarchyFile -NoTypeInformation
            Write-Host "✓ Exported organization hierarchy to: $hierarchyFile" -ForegroundColor Green
        }
        
        # Generate Markdown Report
        $markdownFile = Join-Path $exportPath "ActivityReport_${timestamp}.md"
        $mdContent = @"
# GroupShare Server Activity Report

**Report Period:** $startDate to $endDate  
**Generated on:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Server:** $server

---

## Overall Statistics

- **Total Background Tasks Retrieved:** $($backgroundTasks.Count)
- **Total Projects on Server:** $($allProjects.Count)
- **Projects with Activity:** $($projects.Count)
- **Active Parent Organizations:** $($parentOrganizationDetails.Count)
- **Total Organizations in System:** $($allOrganizations.Count)
- **Total Users in System:** $($comprehensiveUsers.Count)

---

## Activity by Parent Organization (Company Level)

"@

        foreach ($parentOrgDetail in $parentOrganizationDetails) {
            $mdContent += "`n### 🏢 $($parentOrgDetail.ParentOrganization)`n`n"
            $mdContent += "- **Total Activities:** $($parentOrgDetail.TotalActivity)`n"
            $mdContent += "- **Projects:** $($parentOrgDetail.TotalProjects)`n"
            $mdContent += "- **Background Tasks:** $($parentOrgDetail.TotalTasks)`n"
            $mdContent += "- **Active Users:** $($parentOrgDetail.UniqueUsers)`n`n"

            if ($parentOrgDetail.SubOrganizations.Count -gt 0) {
                $mdContent += "#### Sub-Organizations`n`n"
                $mdContent += "| Sub-Organization | Projects | Tasks | Total Activities |`n"
                $mdContent += "|-----------------|----------|-------|------------------|`n"
                
                foreach ($subOrg in $parentOrgDetail.SubOrganizations) {
                    if ($subOrg.Name -ne $parentOrgDetail.ParentOrganization) {
                        $mdContent += "| $($subOrg.Name) | $($subOrg.ProjectCount) | $($subOrg.TaskCount) | $($subOrg.TotalActivity) |`n"
                    }
                }
                $mdContent += "`n"
            }

            if ($parentOrgDetail.ProjectCreators.Count -gt 0) {
                $mdContent += "#### Top Project Creators`n`n"
                $mdContent += "| Creator | Email | Projects |`n"
                $mdContent += "|---------|-------|----------|`n"
                
                foreach ($creator in ($parentOrgDetail.ProjectCreators | Sort-Object ProjectCount -Descending | Select-Object -First 5)) {
                    $creatorDetails = $parentOrgDetail.Users | Where-Object { $_.User -eq $creator.Creator } | Select-Object -First 1
                    $email = if ($creatorDetails -and $creatorDetails.UserEmail) { $creatorDetails.UserEmail } else { "" }
                    $mdContent += "| $($creator.Creator) | $email | $($creator.ProjectCount) |`n"
                }
                $mdContent += "`n"
            }

            $recentProjects = $parentOrgDetail.Projects | Sort-Object CreatedAt -Descending | Select-Object -First 5
            if ($recentProjects.Count -gt 0) {
                $mdContent += "#### Recent Projects`n`n"
                $mdContent += "| Project Name | Organization | Created Date | Created By |`n"
                $mdContent += "|-------------|--------------|--------------|------------|`n"
                
                foreach ($project in $recentProjects) {
                    $projectDate = "Unknown"
                    if ($project.CreatedAt) {
                        try {
                            $dateString = $project.CreatedAt
                            if ($dateString -match '^\d{2}/\d{2}/\d{4}') {
                                $projectDate = [DateTime]::ParseExact($dateString, "MM/dd/yyyy HH:mm:ss", $null).ToString("yyyy-MM-dd")
                            } elseif ($dateString -match '^\d{4}-\d{2}-\d{2}') {
                                $projectDate = [DateTime]::Parse($dateString).ToString("yyyy-MM-dd")
                            } else {
                                $projectDate = [DateTime]::Parse($dateString).ToString("yyyy-MM-dd")
                            }
                        } catch {
                            $projectDate = "Unknown"
                        }
                    }
                    $mdContent += "| $($project.Name) | $($project.OrganizationName) | $projectDate | $($project.CreatorName) |`n"
                }
                $mdContent += "`n"
            }
        }

        $mdContent += "---`n`n## Parent Organization Summary`n`n"
        $mdContent += "| Parent Organization | Projects | Tasks | Total | Users | Sub-Orgs |`n"
        $mdContent += "|-------------------|----------|-------|-------|-------|----------|`n"
        
        foreach ($parentOrgDetail in $parentOrganizationDetails) {
            $mdContent += "| $($parentOrgDetail.ParentOrganization) | $($parentOrgDetail.TotalProjects) | $($parentOrgDetail.TotalTasks) | $($parentOrgDetail.TotalActivity) | $($parentOrgDetail.UniqueUsers) | $($parentOrgDetail.SubOrganizations.Count) |`n"
        }

        $mdContent += "`n---`n`n## Organization Hierarchy`n`n"
        
        foreach ($parentOrgDetail in ($parentOrganizationDetails | Select-Object -First 10)) {
            $mdContent += "### $($parentOrgDetail.ParentOrganization) ($($parentOrgDetail.TotalActivity) activities)`n`n"
            
            $subOrgs = $parentOrgDetail.SubOrganizations | Where-Object { $_.Name -ne $parentOrgDetail.ParentOrganization }
            if ($subOrgs.Count -gt 0) {
                foreach ($subOrg in $subOrgs) {
                    $indent = ""
                    if ($subOrg.Path) {
                        $pathDepth = ($subOrg.Path -split '>').Count
                        if ($pathDepth -gt 2) {
                            $indent = "  " * ($pathDepth - 2)
                        }
                    }
                    $mdContent += "$indent- **$($subOrg.Name)** ($($subOrg.TotalActivity) activities)`n"
                }
            } else {
                $mdContent += "- *(No sub-organizations)*`n"
            }
            $mdContent += "`n"
        }

        $mdContent += "---`n`n## Top Users by Parent Organization`n`n"
        
        foreach ($parentOrg in ($userByParentOrg.Keys | Sort-Object)) {
            $users = $userByParentOrg[$parentOrg]
            $topUsers = $users.GetEnumerator() | 
                        Sort-Object { $_.Value.Count } -Descending | 
                        Select-Object -First 5
            
            if ($topUsers) {
                $mdContent += "### $parentOrg`n`n"
                $mdContent += "| User | Email | Projects |`n"
                $mdContent += "|------|-------|----------|`n"
                
                foreach ($user in $topUsers) {
                    $email = if ($user.Value.Email) { $user.Value.Email } else { "" }
                    $mdContent += "| $($user.Key) | $email | $($user.Value.Count) |`n"
                }
                $mdContent += "`n"
            }
        }

        $mdContent += "---`n`n## User Summary`n`n"
        $mdContent += "### Users by Source`n`n"
        $mdContent += "| Source | Count |`n"
        $mdContent += "|--------|-------|`n"
        
        $comprehensiveUsers | Group-Object -Property Source | ForEach-Object {
            $mdContent += "| $($_.Name) | $($_.Count) |`n"
        }

        $mdContent += "`n---`n`n## Task Analysis`n`n"
        $mdContent += "### Background Tasks by Type`n`n"
        $mdContent += "| Task Type | Count |`n"
        $mdContent += "|-----------|-------|`n"
        
        $taskTypeStats = $processedTasks | Group-Object -Property "Task Type" | 
                                          Sort-Object Count -Descending |
                                          Select-Object -First 10
        foreach ($taskType in $taskTypeStats) {
            $mdContent += "| $($taskType.Name) | $($taskType.Count) |`n"
        }

        $mdContent += "`n### Background Tasks by Status`n`n"
        $mdContent += "| Status | Count |`n"
        $mdContent += "|--------|-------|`n"
        
        $taskStatusStats = $processedTasks | Group-Object -Property Status
        foreach ($status in $taskStatusStats) {
            $mdContent += "| $($status.Name) | $($status.Count) |`n"
        }

        $mdContent += "`n---`n`n## Export Information`n`n"
        $mdContent += "### Files Generated`n`n"
        $mdContent += "- Projects with Parent Organizations: Projects_WithParentOrgs_${timestamp}.csv`n"
        $mdContent += "- Parent Organization Activity: ParentOrganizationActivity_${timestamp}.csv`n"
        $mdContent += "- Organization Hierarchy: OrganizationHierarchy_${timestamp}.csv`n"
        $mdContent += "- This Report: ActivityReport_${timestamp}.md`n`n"
        
        $mdContent += "### Report Parameters`n`n"
        $mdContent += "- **Date Range:** $startDate to $endDate`n"
        $mdContent += "- **Organization Filter:** $(if ($selectedOrganization) { $selectedOrganization.Name } else { 'All Organizations' })`n"
        $mdContent += "- **Total Records Processed:**`n"
        $mdContent += "  - Background Tasks: $($backgroundTasks.Count)`n"
        $mdContent += "  - Projects: $($projects.Count)`n"
        $mdContent += "  - Organizations: $($allOrganizations.Count)`n"
        $mdContent += "  - Users: $($comprehensiveUsers.Count)`n`n"
        
        $mdContent += "---`n`n*Report generated by GroupShare Activity Report Script v1.0*`n"

        # Write the markdown file
        $mdContent | Out-File -FilePath $markdownFile -Encoding UTF8
        Write-Host "✓ Exported activity report to: $markdownFile" -ForegroundColor Green
        
        Write-Host "`nAll files exported successfully!" -ForegroundColor Green
        
    } catch {
        Write-Host "✗ Error exporting files: $_" -ForegroundColor Red
    }
}

Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║      Activity report generation complete!              ║" -ForegroundColor Green
Write-Host "║      Parent organization analysis included             ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green