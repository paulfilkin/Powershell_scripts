param ($server = "https://{groupshare-host}}/") # change this with the actual server

# Endspoints used...
$signInEndpoint = "$($server)authentication/api/1.0/login/signin"

<#
    .SYNOPSIS
    Creates the groupshare access key.

    .DESCRIPTION
    This function is generating an authorization key as a string, which can be saved and used for all of the other functions that needs to
    access sensitive information from the server.

    User can save this key as a variable and use it for managing Groupshare Resources.

    .PARAMETER userName
    Represents the username used for loging on the Groupshare Server

    .PARAMETER password
    Represents the password associated with the userName.

    .EXAMPLE
    SignIn "sa" "sa"

    Returns the authorization token for the above credentials.

    .NOTES
    When using this function with unexisting userName or with existing userName but wrong password

    This method will output the error message of the Login endpoint.

    .OUTPUTS
    [System.String]

    This method return a string representing the access token for groupshare sensitive information.
#>

function SignIn
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $userName,

        [Parameter(Mandatory=$true)]
        [String] $password)

    $body = @("ManagementRestApi", "ProjectServerRestApi", "MultiTermRestApi", "TMServerRestApi") | ConvertTo-Json
    $credentials = $userName + ":" + $password;
    $encodedCredentials = EncodeCredentials $credentials;
    $uri = $signInEndpoint

    $header = @{
        "Content-Type" = "application/json"
        "Authorization" = "Basic $encodedCredentials"
    };

    try
    {
        return Invoke-RestMethod -Uri $uri -Method Post -Body $body -Headers $header
    }
    catch 
    {
        Write-Host "Error occured: $_" -ForegroundColor Green
    }
}

function EncodeCredentials
{
    param([String] $credentials)

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($credentials);
    return [Convert]::ToBase64String($bytes);
}

Export-ModuleMember SignIn;