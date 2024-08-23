param ($server = "https://{groupshare-host}}/") # change this with the actual server

# Endspoints used...
$tasksEndpoint = $($server + "api/management/v2/backgroundtasks");

<#
    .SYNOPSIS
    Returns a list of Background Tasks.

    .DESCRIPTION
    Returns the first 2000 Background tasks of all types and statuses.
    Optional Parameters can be filled for filtering the items.    

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER startDate
    Represents the start date of the task creation.

    Should be in format YYYY-MM-DD eg. "2024-06-24"
    startDate and endDate should be both provided.

    By default the start date will be the previous day from today    

    .PARAMETER endDate
    Represents the end  date of the task creation.

    Should be in format YYYY-MM-DD eg. "2024-06-24"
    startDate and endDate should be both provided.

    Bt default the end date will be the today's date

    .PARAMETER statuses
    Represents the tasks statuses as a list of integers
    The number representation.
    1 - Queued,
    2 - InProgress,
    4 - Canceled,
    8 - Failed,
    16 - Done

    e.g -statuses @(1, 2)

    .PARAMETER types
    Represent the background task types as a list of integers.

    The number representation.
    1 - ArchiveProject, 
    2 - MonitorDueDate, 
    3 - DetachProjects, 
    4 - DetachProject, 
    5 - DeleteProject, 
    6 - CleanSyncPackages, 
    7 - PublishProject, 
    8 - CreateProject, 
    9 - ApplyTM, 
    10 - BcmImport, 
    11 - DeleteTU, 
    12 - ImportTM, 
    13 - ExportTM, 
    14 - RecomputeStats, 
    15 - ReindexTM, 
    18 - FullAlign, 
    20 - AutoReindex, 
    22 - UpdateTm, 
    23 - GeneratePTAReport, 
    24 - DeleteOrganization, 
    25 - PackageExport, 
    26 - PackageImport, 
    27 - EditTU

    e.g -statuses @(1, 2)

    .PARAMETER sortProperty
    Additionally the property for sorting.

    Expected Values:
    Name
    Status
    CreatedAt
    UpdatedAt
    IsGsTask
    sortProperty and sortDirection are both required for sorting.

    .PARAMETER sortDirection
    Represents the sort direction property.
    Expected Values:
    ASC
    DESC
    sortProperty and sortDirection are both required for sorting.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-AllBackgroundTasks -authorizationToken $token

    This method returns all the tasks for all categories and task types.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-AllBackgroundTasks -authorizationToken $token -sortProperty "Name" -sortDirection "ASC"

    This method returns all the tasks for all categories and task types sorted by their tasks names.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-AllBackgroundTasks -authorizationToken $token -statuses @(1, 2, 4, 8)

    This method only returns the backgroundTasks with the statuses of Queued, In Progress, Canceled and Failed

    .OUTPUTS
    [PSOBject[]]
    This method return a collection of psobjects representing the returned background tasks.
#>
function Get-AllBackgroundTasks 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,
 
        [String] $startDate = $(Get-DefaultDate -1),
        [String] $endDate = $(Get-DefaultDate),
        [int[]] $statuses = $null,
        [int[]] $types = $null,
        [string] $sortProperty = $null,
        [string] $sortDirection = $null
    )

    $headers = FormatHeaders $authorizationToken
    $uri = $tasksEndpoint;

    $status = Get-DefaultStatuses
    $type = Get-DefaultTypes

    if ($statuses)
    {
        $status = $statuses
    }
    if ($types)
    {
        $type = $types
    }

    $filter = [ordered]@{
        createdStart = $startDate
        createdEnd = $endDate
        Status = $status
        Type = $type
    }

    if ($sortProperty -and $sortDirection)
    {
        $sort = @( @{
            "property" = $sortProperty
            "direction" = $sortDirection
        })
    }

    $query = $filter | ConvertTo-Json -Compress
    $encoded = [System.Web.HttpUtility]::UrlEncode($query);

    if ($sort)
    {
        $sortJson = $sort | ConvertTo-Json -Compress
        $encodedSort = [System.Web.HttpUtility]::UrlEncode($sortJson);
        $uriQuery = "sort=$encodedSort&filter=$encoded"
    }
    else 
    {
        $uriQuery = "filter=$encoded"
    }

    $uri = $tasksEndpoint + "?page=1&start=50&limit=50&$uriQuery"
    $response = Invoke-Method {Invoke-RestMethod -uri $uri -Headers $headers}
    if ($response)
    {
        return $response.Items;
    }
}

<#
    .SYNOPSIS
    Removes the given background tasks.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER backgroundTasks
    Represents the tasks to to be removed as powershell objects.

    This object type can be retrieved from:
        Get-AllBackgroundTasks

    For further documentation:
        Get-Help Get-AllBackgroundTasks

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $backgroundTasks = Get-AllBackgroundTasks -authorizationToken $token -statuses @(1, 2, 4, 8)

    Remove-BackgroundTasks -authorizationToken $token -backgroundTasks $backgroundTasks

    .NOTES
    When providing multiple tasks that include non existing tasks, the function will display an error message for not finding the resource.
#>
function Remove-BackgroundTasks 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject[]] $backgroundTasks
    )


    $headers = FormatHeaders $authorizationToken;

    foreach ($task in $backgroundTasks)
    {
        $uri = $tasksEndpoint + "/" + $task.Id;
        Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers -Method Delete }
    }
}

function Invoke-Method 
{
    param (
        [scriptblock] $functionToExecute
    )

    try {
        return & $functionToExecute
    }
    catch 
    {
        Write-Host "Error occured: $_"
        return $null
    }
}

function FormatHeaders 
{
    param([String] $authorizationToken)

    return @{
        "Authorization" = "Bearer $authorizationToken"
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }
}

function Get-DefaultStatuses 
{
    return @(1, 2, 4, 8, 16)
}

function Get-DefaultTypes 
{
    return @(8,28,7,2,1,3,4,5,24,6,25,26,23,9,10,27,11,12,13,22,14,15,18,20) 
}

function Get-DefaultDate 
{
    param ([int] $minusDays)

    $todayDate = Get-Date;
    
    return $todayDate.AddDays($minusDays).ToString("yyyy-MM-dd")
}

Export-ModuleMember Get-AllBackgroundTasks;
Export-ModuleMember Remove-BackgroundTasks;