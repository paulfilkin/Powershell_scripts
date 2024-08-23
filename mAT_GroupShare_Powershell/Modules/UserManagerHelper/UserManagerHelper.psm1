param ($server = "https://{groupshare-host}}/") # change this with the actual server

# Endspoints to be used...
$usersEndpoint = $server + "api/management/v2/users";
$usersFromRoleEndpoint = $server + "api/management/v2/roles"
$roleUpdateEndpoint = $server + "api/management/v2/roles/membership";
$organizationsEndpoint = $server + "api/management/v3/organizations";
$permissionsEndpoint = $server + "api/management/v2/permissions";
$rolesEndpoint = $server + "api/management/v2/roles";
$organizationResourcesEndpoint = $server + "api/management/v2/organizationresources";
$linkEndpoint = $server + "api/management/v2/resourcelink"
$translationProviderEndpoint = $server + "api/projectserver/v4/translationProvider"

<#
    .SYNOPSIS
    Returns a list with all the existing users on the Groupshare Server

    .DESCRIPTION
    Returns a list of users represented as powershell objects.
    
    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER organization
    Organization object.
    When this is required this method will return the users within this organization.

    Can be retriever from:
        Get-AllOrganizations
        Get-Organization
        New-Organization
        Update-Organization

    For further documentation see:
        Get-Help Get-AllOrganizations
        Get-Help Get-Organization
        Get-Help New-Organization
        Get-Help Update-Organization

    .parameter sortProperty
    Additionally the sortProperty can be provided to sort the users.

    One of the following values is expected:
    DisplayName
    Name
    UserType
    EmailAddress

    Both sortProperty and sortDirection are required for sorting.

    .parameter sortDirection
    Represents the direction for the sorting, ascending or descending
    
    Expected Value:
    ASC
    DESC

    Both sortProperty and sortDirection are required for sorting.

    .PARAMETER maxLimit
    Represents the maximum limit of the users to be generated.

    Default is 100.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-AllUsers -authorizationToken $token

    This example returns the first 100 users found from all the organizations.

    .Example
    $token = SignIn -userName "username" -password "password"
    $organizations = Get-AllOrganizations -authorizationToken $token
    Get-AllUsers -authorizationToken $token -organization $organizations[0]

    This example returns the first 100 users found from the root (first found) organization.

    .Example
    $token = SignIn -userName "username" -password "password"
    $organizations = Get-AllOrganizations -authorizationToken $token
    Get-AllUsers -authorizationToken $token -organization $organizations[0] -sortProperty "DisplayName" -sortDirection "ASC"

    This example returns the first 100 users found from the root (first found) organization sorted by their display name.

    .OUTPUTS
    [PSobject[]]
    This method returns a collection of users representing all the found users from the server.
#>
function Get-AllUsers {
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [psobject] $organization = $null,
        [string] $sortProperty = $null,
        [String] $sortDirection = $null,
        [int32] $maxLimit = 100
        )

    $uri = $usersEndpoint + "?page=1&limit=$maxLimit"
    if ($sortProperty -and $sortDirection)
    {
        $sort = @([ordered]@{
            "property" = $sortProperty
            "direction" = $sortDirection
        })

        $sortJson = $sort | ConvertTo-Json -Compress;
        $encodedSort = [System.Web.HttpUtility]::UrlEncode($sortJson)
        $uri += "&sort=$encodedSort"
    }

    if ($organization)
    {
        $filter = @{
            "organizationId" = $organization.UniqueId
        }
        $filterJson = $filter | ConvertTo-Json -Compress
        $encodedFilter = [System.Web.HttpUtility]::UrlEncode($filterJson)
        $uri += "&filter=$encodedFilter"
    }

    $headers = FormatHeaders $authorizationToken;

    $response = Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers }
    if ($response)
    {
        return $response.items;
    }
}

<#
    .SYNOPSIS
    Returns a list of all the users within a specific role.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER role
    Represent the role powershell object.

    Can be retrieved from:
        Get-AllRoles
        Get-Role
        New-Role
        Update-Role

    For further documentation:
        Get-Help Get-AllRoles
        Get-Help Get-Role
        Get-Help New-Role
        Get-Help Update-Role

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $role = Get-Role -authorizationToken $token -roleName "Admin"
    Get-AllUsersFromRole -authorizationToken $token -role $role

    .OUTPUTS
    [PSobject[]]
    This method returns a collection of users representing all the found users from the server.
#>

function Get-AllUsersFromRole 
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [PSObject] $role
    )

    $uri = $usersFromRoleEndpoint + "/" + $role.UniqueId + "/users" 
    $headers = FormatHeaders $authorizationToken;
    return Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers };
}

<#
    .SYNOPSIS
    Returns an existing user if found.

    .DESCRIPTION
    Returns an existing user represented as a powershell object.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER userName
    Represents the username of the user

    .PARAMETER userId
    Represents the unique Id of the user

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-User -authorizationToken $token -userName "JohnDow@mail.com"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-User -authorizationToken $token -userId "f9a6e0c0-70b6-4f24-87a1-d066f5baf12b"

    .OUTPUTS
    [PSobject]
    This method return a psobject representing the found User.
#>
function Get-User
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [String] $userName = $null,
        [String] $userId = $null
    )

    if ($userId)
    {
        $userName = $userId
    }

    $uri = $usersEndpoint + "/$userName";
    $headers = FormatHeaders $authorizationToken;
    return Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers }
}

<#
    .SYNOPSIS
    Creates a new user

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER userName
    Represents the username

    .PARAMETER password
    Represents the password.

    The pasword must match the requirements set on the groupshare console.

    .PARAMETER organization
    Organization object.

    Can be retriever from:
        Get-AllOrganizations
        Get-Organization
        New-Organization
        Update-Organization

    For further documentation see:
        Get-Help Get-AllOrganizations
        Get-Help Get-Organization
        Get-Help New-Organization
        Get-Help Update-Organization

    .PARAMETER userType
    Represents the type of the user.

    The user type can be one of the following values:
    SDLUser
    WindowsUser
    CustomUser
    IdpUser

    .PARAMETER displayName
    Represents the display Name

    .PARAMETER role
    Represent the role powershell object.

    Can be retrieved from:
        Get-AllRoles
        Get-Role
        New-Role
        Update-Role

    For further documentation:
        Get-Help Get-AllRoles
        Get-Help Get-Role
        Get-Help New-Role
        Get-Help Update-Role
    
    .PARAMETER emailAddress
    Represents the user's email address

    Optionally, this parameter can be included and it should be an email format, otherwize an error message will be displayed

    .PARAMETER phoneNumber
    User's phone number.

    .PARAMETER description
    Represents the user's description 

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $role = Get-Role -authorizationToken -roleName "Admin"

    New-User -authorizationToken $token -userName "johndoe@mail.com" -password "P@ssword!1" -organization $organization
        -userType "SDLUser" -displayName "John Doe" -role $role

    .OUTPUTS
    [PSObject]
    This method returns a psobject representing the newly created user.
    #>
function New-User 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [String] $userName,

        [Parameter(Mandatory=$true)]
        [String] $password,

        [Parameter(Mandatory=$true)]
        [PSObject] $organization,

        [Parameter(Mandatory=$true)]
        [String] $userType,

        [Parameter(Mandatory=$true)]
        [String] $displayName,

        [Parameter(Mandatory=$true)]
        [psobject] $role,
        
        [String] $emailAddress = $null,
        [String] $phoneNumber = $null,
        [String] $description = $null)

    $uri = $usersEndpoint;
    $headers = FormatHeaders $authorizationToken;

    if ($null -eq $(get-role $authorizationToken -roleId $role.UniqueId))
    {
        return;
    }

    $body = @{
        "Name" = $userName
        "Password" = $password
        "DisplayName" = $displayName
        "OrganizationId" = $organization.UniqueId
        "UserType" = $userType
        "EmailAddress" = $emailAddress 
        "PhoneNumber" = $phoneNumber
        "Description" = $description
        "Roles" = @(@{
            "OrganizationId" = $organization.UniqueId
            "RoleId" = $role.UniqueId
        })
    }

    $bodyJson = $body | ConvertTo-Json
    $id = Invoke-Method { Invoke-RestMethod -Uri $uri -Method Post -Body $bodyJson -Headers $headers }
    if ($id)
    {
        return Get-User $authorizationToken -userId $id;
    }
}

<#
    .SYNOPSIS
    Removes the given user

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER user
    Represents an existing user as a powershell object

    Can be retrieved from:
        Get-AllUsers
        Get-AllUsersFromRole
        Get-User
        New-User
        Update-User
        Add-TranslationProviderToUser
        Remove-TranslationProviderFromUser

    For further documentation:
        Get-Help Get-AllUsersFromRole
        Get-Help Get-User
        Get-Help New-User
        Get-Help Update-User
        Get-Help Add-TranslationProviderToUser
        Get-Help Remove-TranslationProviderFromUser

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $user = Get-user -authorizationToken $token

    Remove-User -authorizationToken $token -user $user
#>
function Remove-User
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $user
    )

    $uri = $usersEndpoint + "\" + $user.UniqueId;
    $headers = FormatHeaders $authorizationToken;

    return Invoke-Method { Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers }
}

<#
    .SYNOPSIS
    Updates the exising the information of an existing user.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER user
    Represents an existing user as a powershell object

    Can be retrieved from:
        Get-AllUsers
        Get-AllUsersFromRole
        Get-User
        New-User
        Update-User
        Add-TranslationProviderToUser
        Remove-TranslationProviderFromUser

    For further documentation:
        Get-Help Get-AllUsersFromRole
        Get-Help Get-User
        Get-Help New-User
        Get-Help Update-User
        Get-Help Add-TranslationProviderToUser
        Get-Help Remove-TranslationProviderFromUser

    .PARAMETER password
    Represents the new password.

    The pasword must match the requirements set on the groupshare console.

    .PARAMETER organization
    Organization object.
    Represents the organization for which the user will belong to.

    Can be retriever from:
        Get-AllOrganizations
        Get-Organization
        New-Organization
        Update-Organization

    For further documentation see:
        Get-Help Get-AllOrganizations
        Get-Help Get-Organization
        Get-Help New-Organization
        Get-Help Update-Organization

    .PARAMETER userType
    Represents the type of the user.

    The user type can be one of the following values:
    SDLUser
    WindowsUser
    CustomUser

    .PARAMETER displayName
    Represents the new display Name

    .PARAMETER emailAddress
    Represents the new user's email address

    Optionally, this parameter can be included and it should be an email format, otherwize an error message will be displayed

    .PARAMETER phoneNumber
    Represents the new phoneNumber of the user

    .PARAMETER userDescription
    .Represents the new description of the user.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $user = Get-User -authorizationToken $token -userName "johndow@email.com"
    $newOrganization = Get-Organization -authorizationToken $token -organizationName "Sample Existing Organization"

    Update-User -authorizationToken $token -user $user -organization $newOrganization

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $user = Get-User -authorizationToken $token -userName "johndow@email.com"

    Update-User -authorizationToken $token -user $user -password "NewP@ssword1!"

    .OUTPUTS
    [PSObject]
    This method returns a psobject representing the updated user.

    .NOTES
    Changing the organization of the user will not change the current organization roles
#>
function Update-User 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [PSobject] $user,

        [String] $password = $null,
        [PSObject] $organization = $null,
        [String] $userType = $null,
        [String] $displayName =$null,
        [String] $emailAddress = $null,
        [String] $phoneNumber = $null,
        [String] $description = $null
    )

    $uri = $usersEndpoint;
    $headers = FormatHeaders $authorizationToken;
    $body = @{
        "UniqueId" = $user.UniqueId
        "Name" = $user.Name
        "Password" = $user.Password
        "DisplayName" = $user.DisplayName 
        "Description" = $user.Description
        "EmailAddress" = $user.EmailAddress 
        "PhoneNumber" = $user.PhoneNumber
        "OrganizationId" = $user.OrganizationId
        "UserType" = $user.UserType
    }

    $parameters = @("password", "displayname", "description", "emailAddress", "phoneNumber", "userType")

    foreach ($parameter in $parameters)
    {
        $paramValue = Get-Variable -Name $parameter -ValueOnly
        if ($paramValue -ne "")
        {
            $body.$parameter = $paramValue
        }
    }

    if ($organization)
    {
        $body.OrganizationId = $organization.UniqueId
    }

    $json = ConvertTo-Json $body -Depth 5;

    $id = Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Put }
    if ($id)
    {
        return Get-User $authorizationToken -userId $user.UniqueId
    }
}

<#
    .SYNOPSIS
    Adds a role to a user for the specified organization and returns the updated user
    as a powershell object.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER organization
    Organization object.

    Can be retriever from:
        Get-AllOrganizations
        Get-Organization
        New-Organization
        Update-Organization

    For further documentation see:
        Get-Help Get-AllOrganizations
        Get-Help Get-Organization
        Get-Help New-Organization
        Get-Help Update-Organization

    .PARAMETER role
    Represent the role powershell object.

    Can be retrieved from:
        Get-AllRoles
        Get-Role
        New-Role
        Update-Role

    For further documentation:
        Get-Help Get-AllRoles
        Get-Help Get-Role
        Get-Help New-Role
        Get-Help Update-Role

    .PARAMETER user
    Represents an existing user as a powershell object

    Can be retrieved from:
        Get-AllUsers
        Get-AllUsersFromRole
        Get-User
        New-User
        Update-User
        Add-TranslationProviderToUser
        Remove-TranslationProviderFromUser

    For further documentation:
        Get-Help Get-AllUsersFromRole
        Get-Help Get-User
        Get-Help New-User
        Get-Help Update-User
        Get-Help Add-TranslationProviderToUser
        Get-Help Remove-TranslationProviderFromUser

    .PARAMETER updateMode
    Represents the update operation.

    Expected values:
    Add
    Remove

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $user = Get-User -authorizationToken $token -userName "johndow@email.com"
    $role = Get-Role -authorizationToken $token -roleName "Admin"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"

    Update-RoleToUser -authorizationToken $token -organization $organization -role $role -user $user -updateMode "Add"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $user = Get-User -authorizationToken $token -userName "johndow@email.com"
    $role = Get-Role -authorizationToken $token -roleName "Admin"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"

    Update-RoleToUser -authorizationToken $token -organization $organization -role $role -user $user -updateMode "Remove"

    .OUTPUTS
    [PSObject]
    This method returns a psobject representing the updated user.

    .NOTES
    A user must have more than 1 role in order to remove a role from the user.
#>
function Update-RoleToUser
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $organization,

        [Parameter(Mandatory=$true)]
        [psobject] $role,

        [Parameter(Mandatory=$true)]
        [psobject] $user,

        [Parameter(Mandatory=$true)]
        [string] $updateMode
    )

    $uri = $roleUpdateEndpoint;
    $headers = FormatHeaders $authorizationToken;
    
    $bodyItem = @{
        "OrganizationId" = $organization.UniqueId
        "UserId" = $user.UniqueId
        "RoleId" = $role.UniqueId
    }
    $body = @($bodyItem)
    $json = $body | ConvertTo-Json -Depth 5;
    $json = "[" + $json + "]";

    switch ($updateMode) {
        "Add" { Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Put } }
        "Remove" { Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Delete } }
        Default { return }
    }

    return Get-User $authorizationToken -userId $user.UniqueId;
}

<#
    .SYNOPSIS
    Gets all the organizations and sub organizations.

    .DESCRIPTION
    Returns a list of all organizations represented as powershell objects.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-AllOrganizations -authorizationToken $token

    .OUTPUTS
    [PSobject[]]
    This method retuns a collection of psobjects representing the found organizations.
x

#>
function Get-AllOrganizations 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken)

    $uri = $organizationsEndpoint + "?hideImplicitLibs=true";
    $headers = FormatHeaders $authorizationToken;

    return Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers }
}


<#
    .SYNOPSIS
    Gets an existing organization

    .DESCRIPTION
    Returns an existing organization if found, prioritizing the organization Id
    Return an existing user as a powershell object.
    If an organization was not found, it will display the not found error message.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER organizationName
    Represents the name of the organization

    .PARAMETER organizationId
    Represents the unique Id of the organization

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-Organization -authorizationToken $token -organizationName "Root Organization"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-Organization -authorizationToken $token -organizationId "f9a6e0c0-70b6-4f24-87a1-d066f5baf12b"

    .OUTPUTS
    [PSObject]
    This method returns a psobject representing the found organization, or $null if it was not found.

    .NOTES
    When both parameters are provided, the function searches for the organizationId first. If the organization is not found, an error message will be displayed
    for not finding this resource, then it will search for the organization with the provided name.
#>
function Get-Organization
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [String] $organizationName = $null,
        [String] $organizationId = $null)

    if ($organizationId)
    {
        $uri = $organizationsEndpoint + "/$organizationId"
        $headers = FormatHeaders $authorizationToken

        $org = Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers }
        if ($org)
        {
            return $org;
        }
    }

    foreach ($organization in $(Get-AllOrganizations $authorizationToken))
    {
        if ($organization.psobject.Properties.Match("Name") -and
            $organization.Name -eq $organizationName)
        {
            return $organization;
        }   
    }

    return $null;
}

<#
    .SYNOPSIS
    Creates a new organization within an existing one.

    .DESCRIPTION
    Creates a new organization with the provided details and returns an object with the newly created organization.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER parentOrganization
    Organization object.
    Represent the owner of this newly created organization.

    Can be retriever from:
        Get-AllOrganizations
        Get-Organization
        New-Organization
        Update-Organization

    For further documentation see:
        Get-Help Get-AllOrganizations
        Get-Help Get-Organization
        Get-Help New-Organization
        Get-Help Update-Organization

    .PARAMETER organizationName
    Represents the name of the organization.

    .PARAMETER organizationDescription
    Represents the description of the organization. 

    If not provided the newly created organization will not have any description.

    .PARAMETER isLibrary
    Represents a valud indicating whether the new organization will be a library.

    If not provided the newly created organization will not be set as a library.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"

    New-Organization -authorizationToken $token -organizationName "Sample Organization" -parentOrganization $organization

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"

    New-Organization -authorizationToken $token -organizationName "Sample Organization" -parentOrganization $organization -isLibrary $true

    .OUTPUTS
    [PSObject]
    This method returns a psobject representing the newly created organization.
#>
function New-Organization 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [PSObject] $parentOrganization,

        [Parameter(Mandatory=$true)]
        [String] $organizationName,

        [String] $organizationDescription = $null,
        [Boolean] $isLibrary = $false)

    $uri = $organizationsEndpoint;
    $headers = FormatHeaders $authorizationToken;
    $body = 
    @{
        "Name" = $organizationName
        "Description" = $organizationDescription
        "ParentOrganizationId" = $parentOrganization.UniqueId
        "IsLibrary" = $isLibrary
    }

    $json = ConvertTo-Json $body; 
    $id = Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Post }
    if ($id)
    {
        return Get-Organization $authorizationToken -organizationId $id;
    }
}

<#
    .SYNOPSIS
    Removes an existing organization

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER organization
    Organization object.
    Represent the organization that will be removed.

    Can be retriever from:
        Get-AllOrganizations
        Get-Organization
        New-Organization
        Update-Organization

    For further documentation see:
        Get-Help Get-AllOrganizations
        Get-Help Get-Organization
        Get-Help New-Organization
        Get-Help Update-Organization

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Existing Organization"
    Remove-Organization -authorizationToken $token -organization $organization

    .NOTES
    Trying to remove an organization that does not exist will display on the powershell console the endpoint error for not finding this resource.
#>
function Remove-Organization {
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $organization)

    $uri = $organizationsEndpoint + "/" + $organization.UniqueId;
    $headers = FormatHeaders $authorizationToken;

    Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers -Method Delete }
}

<#
    .SYNOPSIS
    Updates the name and/or description of an existing organization

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER organization
    Organization object.
    Represent the organization that will be updated.

    Can be retriever from:
        Get-AllOrganizations
        Get-Organization
        New-Organization
        Update-Organization

    For further documentation see:
        Get-Help Get-AllOrganizations
        Get-Help Get-Organization
        Get-Help New-Organization
        Get-Help Update-Organization

    .PARAMETER organizationName
    Represents the new organization name.

    .PARAMETER organizationDescription
    Represents the new organization description.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    Update-Organizations -authorizationToken $token -organization $organization -organizationName "Updated Name"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    Update-Organizations -authorizationToken $token -organization $organization -organizationName "Updated Name" -organizationDescription "Sample description"

    .OUTPUTS
    [PSobject]
    This method returns a psobject representing the update organization.
#>
function Update-Organization 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [PSOBject] $organization,

        [String] $organizationName = $null,
        [String] $organizationDescription = $null
    )

    $uri = $organizationsEndpoint;
    $headers = FormatHeaders $authorizationToken
    $body = 
    @{
        "UniqueId" = $organization.UniqueId
        "Name" = $organization.Name 
        "Description" = $organization.Description
    }

    if ($organizationName -ne "")
    {
        $body.Name = $organizationName
    }
    if ($organizationDescription -ne "")
    {
        $body.Description = $organizationDescription
    }

    $json = ConvertTo-Json $body;

    $null = Invoke-Method {  Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $json }
    return Get-Organization $authorizationToken -organizationId $organization.UniqueId;
}

<#
    .SYNOPSIS
    Gets all the available roles.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-AllRoles -authorizationToken $token

    .OUTPUTS
    [PSobject[]]
    This method returns a collection of psobject representing all the roles from the server.
#>
function Get-AllRoles 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken)

    $uri = $rolesEndpoint;
    $headers = FormatHeaders $authorizationToken;

    return Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers }
}

<#
    .SYNOPSIS
    Returns the specified role.

    .DESCRIPTION
    Returns the role that matches the role id, if provided, otherwone it searches for a role that matches the role name.
    Returns the role as a powershell object.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER roleName
    Represents the name of the role.

    If the roleId is provided it returns the role with the specified id.

    .PARAMETER roleId
    Represents the unique role id.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-Role -authorizationToken $token -roleName "Admin"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-Role -authorizationToken $token -roleId "f9a6e0c0-70b6-4f24-87a1-d066f5baf12b"

    .OUTPUTS
    [PSObject]
    This method returns a psobject representing the found role or $null if no role was found.
#>
function Get-Role 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [String] $roleName = $null,
        [String] $roleId = $null
    )

    if ($roleId)
    {
        $uri = $rolesEndpoint + "/$roleId";
        $headers = FormatHeaders $authorizationToken;

        $role = Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers  }
        if ($role)
        {
            return $role
        }
    }

    $roles = Get-AllRoles $authorizationToken;
    return $roles | Where-Object { $roleName -eq $_.Name } | Select-Object -First 1;
}

<#
    .SYNOPSIS
    Creates a new role and returns it.

    .DESCRIPTION
    Creates a new role with the given parameters and returns the newly created role as a powershell object.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER roleName
    Represents the name of the role

    .PARAMETER permissions
    Represents the permissions for the new role.

    Can be retrieved from:
        Get-Permissions

    For further documentation:
        Get-Help Get-Permissions

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $allPermissions = Get-Permissions -authorizationToken $token

    New-Role -authorizationToken $token -roleName "Sample Role Name" -permissions $allPermissions

    .OUTPUTS
    [PSOBject]
    This method returns a psobject representing the newly created role.
#>
function New-Role 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [String] $roleName,

        [Parameter(Mandatory=$true)]
        [psobject[]] $permissions
    )

    $uri = $rolesEndpoint;
    $headers = FormatHeaders $authorizationToken;
    $body = @{
        "Name" = $roleName
        "Permissions" = $permissions
    }

    $jsonBody = $body | ConvertTo-Json -Depth 4;
    $roleId = Invoke-Method { Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $jsonBody }
    if ($roleId)
    {
        return Get-Role $authorizationToken -roleId $roleId;
    }
}

<#
    .SYNOPSIS
    Removes the specified role

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER role
    Role powershell object.
    Represents the role that will be removed.

    Can be retrieved from:
        Get-AllRoles
        Get-Role
        New-Role
        Update-Role

    For further documentation:
        Get-Help Get-AllRoles
        Get-Help Get-Role
        Get-Help New-Role
        Get-Help Update-Role

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $role = Get-Role -authorizationToken $token -roleName "Sample Role Name"
    Remove-Role -authorizationToken $token -role $role
#>
function Remove-Role 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [PSObject] $role
    )

    $uri = $rolesEndpoint + "/" + $role.UniqueId;
    $headers = FormatHeaders $authorizationToken;

    Invoke-Method { Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers }
}

<#
    .SYNOPSIS
    Updates an existing role

    .DESCRIPTION
    Updates an existing role based on the provided parameters and returns the newly created role.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER role
    Role powershell object.
    Represents the role that will be updated.

    Can be retrieved from:
        Get-AllRoles
        Get-Role
        New-Role
        Update-Role

    For further documentation:
        Get-Help Get-AllRoles
        Get-Help Get-Role
        Get-Help New-Role
        Get-Help Update-Role

    .PARAMETER newRoleName
    Represents the new name of the role.

    Optional parameter.

    .PARAMETER permissions
    Represents the  new sets of permissions for this role.

    Can be retrieved from:
        Get-Permissions

    For further documentation:
        Get-Help Get-Permissions

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $role = Get-Role -authorizationToken $token -roleName "Sample Role Name"
    Update-Role -authorizationToken $token -role $role -newRoleName "Updated Role Name"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $role = Get-Role -authorizationToken $token -roleName "Sample Role Name"
    $newPermissions = Get-Permissions -authorizationToken $token -permissionNames @("Add Library", "Delete Library")

    Update-Role -authorizationToken $token -role $role -permissions $newPemrissions

    .OUTPUTS
    [PSobject]
    This method returns a psobject representing the updated role.
#>
function Update-Role 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $role, 

        [String] $newRoleName = $null,
        [psobject[]] $permissions = $null
    )

    $uri = $rolesEndpoint;
    $headers = FormatHeaders $authorizationToken

    $body = @{
        "UniqueId" = $role.UniqueId
        "Permissions" = $role.Permissions | ForEach-Object { @{ "UniqueId" = $_.UniqueId } }
        "Name" = $role.Name
        "IsProtected" = $role.IsProtected
    }
    if ($newRoleName)
    {
        $body.Name = $newRoleName
    }
    if ($permissions)
    {
        $body.Permissions = $permissions | ForEach-Object { @{ "UniqueId" = $_.UniqueId } }
    }

    $json = $body | ConvertTo-Json -Depth 5
    $null = Invoke-Method { Invoke-RestMethod -uri $uri -Method Put -Headers $headers -Body $json }
    return get-role $authorizationToken -roleId $body.UniqueId;
}

<#
    .SYNOPSIS
    Returns a list with all the resources within a specified organization.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER organization
    Organization object.
    Represents the owner organization of the returned resources.

    Can be retriever from:
        Get-AllOrganizations
        Get-Organization
        New-Organization
        Update-Organization

    For further documentation see:
        Get-Help Get-AllOrganizations
        Get-Help Get-Organization
        Get-Help New-Organization
        Get-Help Update-Organization

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"  
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"

    Get-AllOrganizationResources -authorizationToken $token -organization $organization

    .OUTPUTS
    [PSObject[]]
    This method returns a collection of psobject representing organizationresources.
#>
function Get-AllOrganizationResources 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [PSObject] $organization
    )

    $uri = $organizationResourcesEndpoint + "?id=" + $organization.UniqueId;
    $headers = FormatHeaders $authorizationToken

    return Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers }
}

<#
    .SYNOPSIS
    Move existing resources from one organization to a new one.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER resources
    Represents the organization resources that will be moved.
    
    Can be retrieved from: 
        Get-AllOrganizationResources

    For further documentation:
        Get-Help Get-AllOrganizationResources

    .PARAMETER newOrganization
    Organization object.
    Represents the new owner organization of the returned resources.

    Can be retriever from:
        Get-AllOrganizations
        Get-Organization
        New-Organization
        Update-Organization

    For further documentation see:
        Get-Help Get-AllOrganizations
        Get-Help Get-Organization
        Get-Help New-Organization
        Get-Help Update-Organization

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"   
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $newOrganization = Get-Organization -authorizationToken $token -organizationName "Other Organization"
    $resources = Get-AllOrganizationResources -authorizationToken $token -organization $organization

    Move-OrganizationToResources -authorizationToken $token -resources @($resources[0], $resources[1]) -newOrganization $newOrganization

    .NOTES
    Trying to move resources that do not exist will result with the following behaviour.
    If no resource is a valid resource, this function will display the error message for this endpoint.
    If there are valid resources with some invalid resources, the function will only move the valid resources.
#>
function Move-OrganizationResources 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject[]] $resources,

        [Parameter(Mandatory=$true)]
        [psobject] $newOrganization
    )

    $uri = $organizationResourcesEndpoint;
    $headers = FormatHeaders $authorizationToken;
    $body = @{
        "ResourceIds" = @($resources | ForEach-Object { $_.Id })
        "OrganizationId" = $newOrganization.UniqueId
    }

    $json = $body | ConvertTo-Json -Depth 3

    return Invoke-Method { Invoke-RestMethod -uri $uri -Method Put -Headers $headers -Body $json }
}

<#
    .SYNOPSIS
    Link the specified resources with the given organization.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER resources
    Represents the organization resources that will be linked with the new organization.

    Can be retrieved from: 
        Get-AllOrganizationResources

    For further documentation:
        Get-Help Get-AllOrganizationResources

    .PARAMETER organization
    Represents the new organization that will contain the above resources.
    
    Can be retriever from:
        Get-AllOrganizations
        Get-Organization
        New-Organization
        Update-Organization

    For further documentation see:
        Get-Help Get-AllOrganizations
        Get-Help Get-Organization
        Get-Help New-Organization
        Get-Help Update-Organization

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"   
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $newOrganization = Get-Organization -authorizationToken $token -organizationName "Other Organization"
    $resources = Get-AllOrganizationResources -authorizationToken $token -organization $organization

    Join-ResourcesToOrganization -authorizationToken $token -resources @($resources[0], $resources[1]) -organization $newOrganization

    .NOTES
    Trying to link resources that do not exist will result with the following behaviour.
    If no resource is a valid resource, this function will display the error message for this endpoint.
    If there are valid resources with some invalid resources, the function will only link the valid resources.
#>
function Join-ResourcesToOrganization 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject[]] $resources,

        [Parameter(Mandatory=$true)]
        [psobject] $organization
    )

    $uri = $linkEndpoint;
    $headers = FormatHeaders $authorizationToken;

    $orgId = $organization.UniqueId;

    [String[]] $resourcesIds = $resources | ForEach-Object { $_.Id }
    $body = @{
        "ResourceIds" = @($resourcesIds)
        "OrganizationId" = $orgId
    }

    $json = $body | ConvertTo-Json -Depth 2;
    $null = Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers -Body $json -Method Put }
    return Get-AllOrganizationResources $authorizationToken $organization | Where-Object { $resourcesIds -contains $_.Id }
}

<#
    .SYNOPSIS
    UnLink the specified resources with the given organization.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER resources
    Represents the resources that will be unlinked from this organization.
    
    Can be retrieved from: 
        Get-AllOrganizationResources

    For further documentation:
        Get-Help Get-AllOrganizationResources

    .PARAMETER organization
    Represents the new organization that will contain the above resources.
    
    Can be retriever from:
        Get-AllOrganizations
        Get-Organization
        New-Organization
        Update-Organization

    For further documentation see:
        Get-Help Get-AllOrganizations
        Get-Help Get-Organization
        Get-Help New-Organization
        Get-Help Update-Organization

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"   
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $newOrganization = Get-Organization -authorizationToken $token -organizationName "Other Organization"
    $resources = Get-AllOrganizationResources -authorizationToken $token -organization $organization

    Split-ResourcesFromOrganization -authorizationToken $token -resources @($resources[0], $resources[1]) -organization $newOrganization

    .NOTES
    Trying to unlink resources that do not exist will result with the following behaviour.
    If no resource is a valid resource, this function will display the error message for this endpoint.
    If there are valid resources with some invalid resources, the function will only link the valid resources.
#>
function Split-ResourcesFromOrganization 
{
    param(
        [Parameter(Mandatory=$true)]
        [String[]] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject[]] $resources,

        [Parameter(Mandatory=$true)]
        [psobject] $organization
    )

    $uri = $linkEndpoint;
    $headers = FormatHeaders $authorizationToken;
    $orgId = $organization.UniqueId;

    [String[]] $resourcesIds = $resources | ForEach-Object { $_.Id }
    $body = @{
        "ResourceIds" = $resourcesIds
        "OrganizationId" = $orgId
    }
    $json = $body | ConvertTo-Json -Depth 2;
    
    return Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers -Body $json -Method Delete }
}

<#
    .SYNOPSIS
    Returns a list with all the permissions or only the ones that matches a specific name.

    .DESCRIPTION
    Returns a list with all the permissions if no permission names parameter was provided, otherwise it only returns the permissions that are included in the permission names parameter.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER permissionNames
    Optional Parameters, if provided returns only the permissions that matches the Display Names.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"   
    Get-Permissions -authorizationToken $token

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"   
    Get-Permissions -authorizationToken $token -permissionNames @("Add Library", "Delete Library")

    .OUTPUTS
    [PSObject[]]
    This method returns a collectino of powershell objects represnting all the permissions or only the provided ones.

#>
function Get-Permissions 
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [String[]] $permissionNames = $null
    )

    $uri = $permissionsEndpoint;
    $headers = FormatHeaders $authorizationToken;

    $items = Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers }
    if ($permissionNames)
    {
        $items = $items | Where-Object {$permissionNames -contains $_.DisplayName}
    }

    return $items;
}

<#
    .SYNOPSIS
    Returns the translation provider of the user.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER user
    Represent the user for which the translationprovider should be retrieved from.

    Can be retrieved from:
        Get-AllUsers
        Get-AllUsersFromRole
        Get-User
        New-User
        Update-User
        Add-TranslationProviderToUser
        Remove-TranslationProviderFromUser

    For further documentation:
        Get-Help Get-AllUsers
        Get-Help Get-AllUsersFromRole
        Get-Help Get-User
        Get-Help New-User
        Get-Help Update-User
        Get-Help Add-TranslationProviderToUser
        Get-Help Remove-TranslationProviderFromUser

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"   
    $user = Get-User -authorizationToken $token -userName "johndoe@mail.com"

    Get-UserTranslationProvider -authorizationToken $token -user $user

    .OUTPUTS
    [PSObject]
    This method returns a psobject representing the Translation Provider details.

#>
function Get-UserTranslationProvider
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $user
    )

    $uri = $translationProviderEndpoint + "/" + $user.UniqueId;
    $headers = FormatHeaders $authorizationToken;

    return Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers }
}

<#
    .SYNOPSIS
    Adds a translation provider to the specified user.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER user
    Represents the user as a powershell object to whom the translation provider will be added. 

    Can be retrieved from:
        Get-AllUsers
        Get-AllUsersFromRole
        Get-User
        New-User
        Update-User
        Add-TranslationProviderToUser
        Remove-TranslationProviderFromUser

    For further documentation:
        Get-Help Get-AllUsers
        Get-Help Get-AllUsersFromRole
        Get-Help Get-User
        Get-Help New-User
        Get-Help Update-User
        Get-Help Add-TranslationProviderToUser
        Get-Help Remove-TranslationProviderFromUser

    .PARAMETER clientId
    Represents the client id

    .PARAMETER clientSecret
    Represent the clientSecret.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $user = Get-User -authorizationToken $token -userName "john.doe@mail.com"

    Add-TranslationProviderToUser -authorizationToken $token -user $user -clientId "ClientID" -clientSecre "ClientSecret."

    .OUTPUTS
    [PSObject]
    This method returns a psobject representing the updated user.
#>
function Add-TranslationProviderToUser 
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $user,

        [Parameter(Mandatory=$true)]
        [String] $clientId,

        [Parameter(Mandatory=$true)]
        [string] $clientSecret
    )

    $uri = $translationProviderEndpoint + "/" + $user.UniqueId;
    $headers = FormatHeaders $authorizationToken;
    $body = @{
        "ClientId" = $clientId
        "ClientSecret" = $clientSecret
        "TranslationProviderType" = "MTCloud"
    }

    $json = $body | ConvertTo-Json -Depth 4;
    $id = Invoke-Method { Invoke-RestMethod -Headers $headers -uri $uri -Body $json -Method Post }
    return Get-User $authorizationToken -userId $id;
}

<#
    .SYNOPSIS
    Removes the translation provider from the specified user.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER user
    Represents the user as a powershell object to whom the translation provider will be added. 

    Can be retrieved from:
        Get-AllUsers
        Get-AllUsersFromRole
        Get-User
        New-User
        Update-User
        Add-TranslationProviderToUser
        Remove-TranslationProviderFromUser

    For further documentation:
        Get-Help Get-AllUsers
        Get-Help Get-AllUsersFromRole
        Get-Help Get-User
        Get-Help New-User
        Get-Help Update-User
        Get-Help Add-TranslationProviderToUser
        Get-Help Remove-TranslationProviderFromUser

    .PARAMETER translationProvider
    Represents the translationprovider that will be remove.

    Can be retrieved from:
        Get-UserTranslationProvider

    For further documentation: 
        Get-Help Get-UserTranslationProvider

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $user = Get-User -authorizationToken $token -userName "john.doe@mail.com"
    $translationProvider = Get-UserTranslationProvider -authorizationToken -user $user

    Remove-TranslationProviderFromUser -authorizationToken $token -user $user -translationProvider $translationProvider

    .OUTPUTS
    [PSObject]
    This method returns a psobject representing the updated user.
#>
function Remove-TranslationProviderFromUser 
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $user,

        [Parameter(Mandatory=$true)]
        [psobject] $translationProvider
    )

    $uri = $translationProviderEndpoint + "/" + $user.UniqueId + "?providerSettingId=" + $translationProvider.ProviderSettingId;
    $headers = FormatHeaders $authorizationToken;

    $null = Invoke-Method { Invoke-RestMethod -Headers $headers -Uri $uri -Method Delete }
    return Get-User $authorizationToken -userId $user.UniqueId;
}


function FormatHeaders 
{
    param ([String] $token)

    return @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
        "Accept" = "application/json"
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

Export-ModuleMember Get-AllUsers; 
Export-ModuleMember Get-AllUsersFromRole;
Export-ModuleMember Get-User; 
Export-ModuleMember New-User; 
Export-ModuleMember Remove-User;  
Export-ModuleMember Update-User;  
Export-ModuleMember Update-RoleToUser; 
Export-ModuleMember Get-AllOrganizations; 
Export-ModuleMember Get-Organization; 
Export-ModuleMember New-Organization; 
Export-ModuleMember Remove-Organization; 
Export-ModuleMember Update-Organization; 
Export-ModuleMember Get-AllRoles; 
Export-ModuleMember Get-Role;
Export-ModuleMember New-Role; 
Export-ModuleMember Remove-Role; 
Export-ModuleMember Update-Role; 
Export-ModuleMember Get-Permissions;
Export-ModuleMember Get-AllOrganizationResources;
Export-ModuleMember Move-OrganizationResources;
Export-ModuleMember Join-ResourcesToOrganization;
Export-ModuleMember Split-ResourcesFromOrganization;
Export-ModuleMember Get-UserTranslationProvider;
Export-ModuleMember Add-TranslationProviderToUser;
Export-ModuleMember Remove-TranslationProviderFromUser;