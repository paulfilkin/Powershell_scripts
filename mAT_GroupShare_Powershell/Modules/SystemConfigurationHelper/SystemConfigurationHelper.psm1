param ($server = "https://{groupshare-host}}/") # change this with the actual server

# Endspoints to be used...
$containersEndpoint = $server + "api/tmservice/containers"
$licenseEndpoint = $server + "api/management/v2/license"
$dbServersEndpoint = $server + "api/tmservice/dbservers";

<#
    .SYNOPSIS
    Returns the licensing information.

    .DESCRIPTION
    Returns the licensing information as a powershell object.
    
    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-Licensing -authorizationToken $token

    This example first retrieves the authorizationToken, then retrieves the licensing information.

    .OUTPUTS
    [PSOject]
    This method return a psobject representing information about licensing information.
    If the authorizationToken is not valid, the output will be $null
#>
function Get-Licensing 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken)

    $uri = $licenseEndpoint
    $headers = FormatHeaders $authorizationToken;

    return Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers }
}

<#
    .SYNOPSIS
    Gets all the existing Database servers.
    
    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn
    
    .EXAMPLE
    $token = SignIn  -userName "userName" -password "password"
    Get-AllDbServers -authorizationToken $token

    his example first retrieves the authorizationToken, then retrieves the database servers.

    .OUTPUTS
    [PSObject[]]

    This method returns a collecton of PSObject representing all the existing database servers from the server.
#>
function Get-AllDbServers
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken)
        
    $uri = $dbServersEndpoint;
    $headers = FormatHeaders $authorizationToken;

    $response = Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers }
    if ($response)
    {
        return $response.Items;
    }
}

<#
    .SYNOPSIS
    Returns the dbserver that matches one of the provided values

    .DESCRIPTION
    Returns the dbserver as a powershell object based on the dberver id or dbserver name

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER serverName
    Represents the name of the db server

    .PARAMETER serverId
    Represents the unique id of the db server

    .EXAMPLE
    $token = SignIn  -userName "userName" -password "password"
    Get-AllDbServer -authorizationToken $token -serverName "Sample Database"

    This example first retrieves the authorization token, then retrieves the database with the "Sample Database" name.
    If the database with this name is found, it will retrieve it as a PSObject.
    If the database does not exist, this method will return $null.

    .EXAMPLE
    $token = SignIn  -userName "userName" -password "password"
    Get-AllDbServer -authorizationToken $token -serverId "f9a6e0c0-70b6-4f24-87a1-d066f5baf12b"

    This example first retrieves the authorization token, then retrieves the database with the "f9a6e0c0-70b6-4f24-87a1-d066f5baf12b" id.
    If the database with this name is found, it will retrieve it as a PSObject.
    If the database does not exist, this method will return $null.

    .OUTPUTS
    [PSObject]
    This method returns a PSObject the Database Server found from the server.
    If the database does not exist or if the token is not valid, this method will return $null.

    .NOTES
    When providing both serverId and serverName if the function does not find the requested server, it will display the error message from the endpoint,
    then if the servername was provided, it will search for the server with the specified name.
#>
function Get-DbServer 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [String] $serverName = $null,
        [String] $serverId = $null
    )

    if ($serverId)
    {
        $uri = $dbServersEndpoint + "/" + $serverId;
        $headers = FormatHeaders $authorizationToken;

        $db = Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers }
        if ($db)
        {
            return $db;
        }
    }

    foreach ($dbServer in $(Get-AllDbServers $authorizationToken))
    {
        if ($dbServer.Name -eq $serverName)
        {
            return $dbServer;
        }
    }

    return $null;
}

<#
    .SYNOPSIS
    Creates a new db server

    .DESCRIPTION 
    Creates a new db server with the provided details and returns it as a powershell object after creation.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER name
    Represents the new name of the db server

    .PARAMETER serverName 
    Represents the name of the host server

    .PARAMETER authentication
    Represents the authentcation method of the db server

    Values can be:
        Windows
        Database - if this value is provided, user should input the optional parameters username and password

    .PARAMETER ownerOrganization
    Represents the owner organization of the db server.

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

    .PARAMETER description
    Represents the description of the db server

    .PARAMETER userName
    Represents the username for the host authentication.
    If the authentication value is "Database" this parameter must be provided.

    .PARAMETER password
    Represents the password for the host authentication.
    If the authentication value is "Database" this parameter must be provided.

    .EXAMPLE
    $token = SignIn -userName "userName" -password "password"
    $organizations = Get-AllOrganizations $token
    New-DbServer -authorizationToken -name "New Database Server" -serverName "Host Server Name" -authentication "Windows" -ownerOrganization $organizations[0]

    This example first retrieves the authorization token and all the organizations from the server,
    then it creates a new databasse server with the provided name and server name located at the first organization.

    .EXAMPLE
    $token = SignIn -userName "userName" -password "password"
    $organizations = Get-AllOrganizations $token
    New-DbServer -authorizationToken -name "New Database Server" -serverName "Host Server Name" -authentication "Database" -ownerOrganization $organizations[0] -userName "authUserName" -password "password"

    This example first retrieves the authorization token and all the organizations from the server,
    then it creates a new databasse server with the provided name and server name located at the first organization,
    additionally adding security credentials.

    This example first retrieves the authorization token, then creates a new database server with the specified id "f9a6e0c0-70b6-4f24-87a1-d066f5baf12b" and name "Another Database Server". If a server with this id already exists, it may be updated or an error may be returned.

    .OUTPUTS
    [PSObject]
    This method returns a PSObject representing the newly created database server. If the creation fails or if the token is not valid, this method will return $null.

#>
function New-DbServer 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [String] $name, 

        [Parameter(Mandatory=$true)]
        [String] $serverName,

        [Parameter(Mandatory=$true)]
        [String] $authentication,

        [Parameter(Mandatory=$true)]
        [psobject] $ownerOrganization,

        [String] $description = $null,
        [String] $userName = $null,
        [String] $password = $null
    )

    $uri = $dbServersEndpoint
    $headers = FormatHeaders $authorizationToken

    $body = @{
        "OwnerId" = $ownerOrganization.UniqueId
        "Name" = $name
        "Host" = $serverName 
        "Authentication" = $authentication
        "Description" = $description
    }

    if ($authentication = "Database")
    {
        $body.userName = $userName
        $body.password = $passowrd
    }

    $json = $body | ConvertTo-Json -Depth 4;
    $id = Invoke-Method { Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $json }
    if ($id)
    {
        return Get-DbServer $authorizationToken -serverId $id
    }
}

<#
    .SYNOPSIS
    Removes an existing Db server

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER dbServer
    Represents the existing dbServer that will be removed.

    Can be retrieved from:
        Get-AllDbServers
        Get-DbServer
        New-DbServer
        Update-DbServer

    For further documentation:
        Get-Help Get-AllDbServers
        Get-Help Get-DbServer
        Get-Help New-DbServer
        Get-Help Update-DbServer

    .EXAMPLE
    $token = SignIn -userName "userName" -password "password"
    $dbServer = Get-DbServer -authorizationToken $token -serverName "Existing Database"
    Remove-DbServer -authorizationToken $token -dbServer $dbServer

    This example retrievers first the authorization Token and the database server with the name "Existing Database"
    then removes it from the server.

    .NOTES
    If the given server is not found, the system will display an error message on the powershell console.
#>
function Remove-DbServer 
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $dbServer
    )

    $uri = $dbServersEndpoint + "/" + $dbServer.DatabaseServerId;
    $headers = FormatHeaders $authorizationToken;

    Invoke-Method { Invoke-RestMethod -uri $uri -Method Delete -Headers $headers }
}

<#
    .SYNOPSIS 
    Updates an existing db server

    .DESCRIPTION
    Updates the given dbserver and it returns the updated object.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER dbServer
    Represents the existing dbServer that will be updated.

    Can be retrieved from:
        Get-AllDbServers
        Get-DbServer
        New-DbServer
        Update-DbServer

    For further documentation:
        Get-Help Get-AllDbServers
        Get-Help Get-DbServer
        Get-Help New-DbServer
        Get-Help Update-DbServer

    .PARAMETER newServerName
    Represents the new name of the db server

    .PARAMETER description
    Represents the new description of the db server.

    .PARAMETER authentication
    Represents the new authentication method.

    Values can be:
        Windows
        Databbase - if this value is provided, user should input the optional parameters username and password

    .PARAMETER userName
    Represents the username for the new host authentication.
    If the authentication value is "Database" this parameter must be provided.

    .PARAMETER password
    Represents the password for the new host authentication.
    If the authentication value is "Database" this parameter must be provided.

    .EXAMPLE
    $token = SignIn -userName "userName" -password "password"
    $dbServer = Get-DbServer -authorizationToken $token -serverName "Existing Database"
    Update-DbServer -authorizationToken $token -dbServer $dbServer -newServerName "Updated Database Name"

    This example retrieves the authorization token and use it to retrieve the database server with the name Existing database,
    then change the name to Updated Database Name

    .EXAMPLE
    $token = SignIn -userName "userName" -password "password"
    $dbServer = Get-DbServer -authorizationToken $token -serverName "Existing Database"
    Update-DbServer -authorizationToken $token -dbServer $dbServer -authentication "Database" -userName "authUserName" -password "password"

    This example retrieves the authorization token and use it to retrieve the database server with the name Existing database,
    then change the access to the database to Database and sets the credentials for access.

    .OUTPUTS
    [PSOBject]
    This method returns a psobject representing the updated database server.
#>
function Update-DbServer 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,
        
        [Parameter(Mandatory=$true)]
        [psobject] $dbServer,

        [String] $newServerName = $null,
        [String] $description = $null,
        [String] $authentication = $null,
        [String] $userName = $null,
        [String] $password = $null
    )

    $uri = $dbServersEndpoint + "/" + $dbServer.DatabaseServerId;
    $headers = FormatHeaders $authorizationToken;

    $body = @{
        "OwnerId" = $dbServer.OwnerId
        "Name" = $dbServer.Name
        "Host" = $dbServer.Host 
        "Description" = $dbServer.Description
    }

    if ($newServerName)
    {
        $body.Name = $newServerName;
    }
    if ($description)
    {
        $body.Description = $description
    }

    if ($authentication)
    {
        $body.Authentication = $authentication;

        if ($authentication -eq "Database")
        {
            $body.userName = $userName
            $body.Password = $passowrd
        }
    }

    $json = $body | ConvertTo-Json -Depth 4;
    Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers -Method Put -Body $json}
    return Get-DbServer $authorizationToken -serverId $dbServer.DatabaseServerId;
}

<#
    .SYNOPSIS
    Gets the specified container

    .DESCRIPTION
    Gets the container that matches the specified id or the specified name, prioritizing the id.
    Returns a container represented as a powershell object.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be generated by SignIn function.

    See Get-Help SignIn for further documentation.

    .PARAMETER containerName
    Represents the name of the container

    .PARAMETER containerId
    Represents the unique id of the container

    .EXAMPLE
    $token = SignIn -userName "userName" -password "password"
    Get-Container -authorizationToken $token -containerName "Sample Container Name"

    .EXAMPLE
    $token = SignIn -userName "userName" -password "password"
    Get-Container -authorizationToken $token -containerId "f9a6e0c0-70b6-4f24-87a1-d066f5baf12b"

    .OUTPUTS
    [PSObject]
    This example returns a psobject representing the foudn container, or $null if the container was not found
#>
function Get-Container 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [String] $containerName = $null,
        [String] $containerId = $null
    )

    if ($containerId)
    {
        $uri = $containersEndpoint + "/$containerId";
        $headers = FormatHeaders $authorizationToken;

        $container = Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers }
        if ($container)
        {
            return $container;
        }
    }

    foreach ($container in $(Get-AllContainers $authorizationToken))
    {
        if ($container.DisplayName -eq $containerName)
        {
            return $container;
        }
    }
}


<#  
    .SYNOPSIS
    Gets all the existing containers as a list of containers.

    .DESCRIPTION
    Returns all the containers as a list of containers represented as powershell objects.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .EXAMPLE
    $token = SignIn -userName "userName" -password "password"
    Get-AllContainers -authorizationToken $token

    This method firt retrieves the authorizationToken, then use it to retrieve all the containers.

    .OUTPUTS
    [PSObject[]]
    This method returns a collection of psobjects representing all the containers found on the server.
#>
function Get-AllContainers 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken)

    $uri = $containersEndpoint;
    $headers = FormatHeaders $authorizationToken
    
    $response = Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers }
    if ($response)
    {
        return $response.Items;
    }
}


<#  
    .SYNOPSIS
    Gets all the existing containers as a list of containers that are part of the given organzation.

    .DESCRIPTION
    Returns all the containers within a given organization as a list of containers represented as powershell objects.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER organization
    Represents the organization as a PSObject that will be used as a filter.

    Can be retrieved from:
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
    $token = SignIn -userName "userName" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    Get-AllContainers -authorizationToken $token -organization $organization

    This method firt retrieves the authorizationToken, then use it to retrieve all the containers.

    .OUTPUTS
    [PSObject[]]
    This method returns a collection of psobjects representing the containers found on the server.
#>
function Get-ContainersByOrganization
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $organization
    )

    $containers = Get-AllContainers $token
    if ($containers)
    {
        return $containers | Where-Object { $_.OwnerId -eq $organization.UniqueId }
    }
}

<#
    .SYNOPSIS
    Creates a new container.

    .DESCRIPTION
    Creates a new containers.
    Returns the newly created container.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER containerName
    Represents the name of the container

    .Parameter organization
    Represents the organization which will own the container as a powershell object.

    Can be retrieved from:
        Get-AllOrganizations
        Get-Organization
        New-Organization
        Update-Organization

    For further documentation see:
        Get-Help Get-AllOrganizations
        Get-Help Get-Organization
        Get-Help New-Organization
        Get-Help Update-Organization

    .PARAMETER dbServer
    Represents the server that will contain this container

    Can be retrieved from:
        Get-AllDbServers
        Get-DbServer
        New-DbServer
        Update-DbServer

    For further documentation:
        Get-Help Get-AllDbServers
        Get-Help Get-DbServer
        Get-Help New-DbServer
        Get-Help Update-DbServer

    .PARAMETER $containerDBName
    Optionally, the name of the container's database, which by default is container name without white spaces + "DB"
    Additionally this parameter should not container whitespaces and should not start with a number.

    .EXAMPLE
    $token = SignIn -userName "userName" -password "password"
    $organizations = Get-AllOrganizations -authorizationToken $token
    $dbServers = Get-AllDbServers -authorizationToken $token
    New-Container -authorizationToken $token -containerName "Sample Container" -organization $organizations[0] -dbServer $dbServers[0]

    .OUTPUTS
    [PSObject]
    This method returns the newly created container as a psobject.
#>
function New-Container
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [String] $containerName,

        [Parameter(Mandatory=$true)]
        [PSObject] $organization,

        [Parameter(Mandatory=$true)]
        [PSObject] $DbServer,
        
        [String] $containerDbName = $null)

    $uri = $containersEndpoint;
    $headers = FormatHeaders $authorizationToken;

    $nameWithoutWs = $containerName -replace "\s", ""
    $body = @{
        "DatabaseServerId" = $DbServer.DatabaseServerId
        "DatabaseName" = $nameWithoutWs  + "DB"
        "DisplayName" = $containerName
        "OwnerId" = $organization.UniqueId
    }

    if ($containerDbName)
    {
        $body.DatabaseName = $containerDbName;
    }

    $json = ConvertTo-Json $body;

    $containerId = Invoke-Method { Invoke-RestMethod -Uri $uri -Method Post -Body $json -Headers $headers }
    if ($containerId)
    {
        return Get-Container $authorizationToken -ContainerId $containerId
    }
}

<#
    .SYNOPSIS
    Removes the specified container

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER container
    Represents the container to be removed as a powershell object

    Can be retrieved from:
        Get-AllContainers
        Get-Container
        New-Container
        Update-Container

    For further documentation:
        Get-Help Get-AllContainers
        Get-Help Get-Container
        Get-Help New-Container
        Get-Help Update-Container

    .EXAMPLE
    $token = SignIn -userName "userName" -password "password"
    $container = Get-Container -authorizationToken $token
    Remove-Container -authorizationToken $token -container $container

    .NOTES
    If the specified container is not found, the function will display the error message of not found.
#>
function Remove-Container {
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [PSObject] $container)

    $headers = FormatHeaders $authorizationToken;
    $uri =  $containersEndpoint + "/" + $container.ContainerId;
    Invoke-Method { Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers }
}

<#
    .SYNOPSIS
    Changes the name of an existing container
    
    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER container
    Represents the container to be updated
 
    Can be retrieved from:
        Get-AllContainers
        Get-Container
        New-Container
        Update-Container

    For further documentation:
        Get-Help Get-AllContainers
        Get-Help Get-Container
        Get-Help New-Container
        Get-Help Update-Container

    .PARAMETER containerName
    Represents the new name the specified container will have

    .EXAMPLE
    $token = SignIn -userName "userName" -password "password"
    $container = Get-Container $token -containerName "Powershell Container"
    Update-Container -authorizationToken $token -container $container -containerName "Updated Name"

    .OUTPUTS
    [PSObject]
    This method returns a psobject representing the newly updated container.
#>
function Update-Container 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $container,

        [String] $containerName = $null
    )

    $uri = $containersEndpoint + "/" + $container.ContainerId;
    $headers = FormatHeaders $authorizationToken
    $body =
    @{
        "ContainerId" = $container.ContainerId
        "DisplayName" = $containerName
    }

    $json = ConvertTo-Json $body;
    Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers -Body $json -Method Put }
    return Get-Container $authorizationToken -containerId $container.ContainerId;
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

Export-ModuleMember Get-Licensing;
Export-ModuleMember Get-AllDbServers;
Export-ModuleMember Get-DBServer;
Export-ModuleMember New-DbServer;
Export-ModuleMember Remove-DbServer;
Export-ModuleMember Update-DbServer;
Export-ModuleMember Get-AllContainers;
Export-ModuleMember Get-ContainersByOrganization;
Export-ModuleMember Get-Container;
Export-ModuleMember New-Container;
Export-ModuleMember Remove-Container;
Export-ModuleMember Update-Container;