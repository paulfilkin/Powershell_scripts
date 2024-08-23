param ($server = "https://{groupshare-host}}/") # change this with the actual server

# Endspoints to be used...
$termbasesEndpoint = $server + "multiterm/api/1.0/termbases"
$tmEndpoint = $server + "api/tmservice/tms";
$projectsTemplateEndpoint = $server + "api/projectserver/v4/projects/templates";
$fieldTemplatesEndpoint = $server + "api/fieldservice/templates";

<#
    .SYNOPSIS
    Gets the specified translation memory

    .DESCRIPTION
    Gets an existing translation memory that matches the name or the unique id, prioritising the unique id.
    Returns the Translation Memory as a powershell object.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER tmName
    Represents the name of the Translation Memory

    .PARAMETER tmId
    Represents the unique id of the Translation Memory

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-TM -authorizationToken $token -tmName "Sample TM"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-TM -authorizationToken "SampleToken" -tmId "f9a6e0c0-70b6-4f24-87a1-d066f5baf12b"

    .OUTPUTS
    [PSObject]
    This method returns a PSObject representing the found Translation Memory or $null if it was not found
#>
function Get-TM
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [String] $tmName = $null,
        [String] $tmId = $null)

    if ($tmId)
    {
        $uri = $tmEndpoint + "/$tmId";
        $headers = FormatHeaders $authorizationToken;
        $tm = Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers }
        if ($tm)
        {
            return $tm;
        }
    }

    $tms = Get-AllTMs $authorizationToken;
    foreach ($tm in $tms)
    {
        if ($tm.Name -eq $tmName)
        {
            return $tm;
        }
    }

}

<#
    .SYNOPSIS
    Gets all the translation memories as a list.

    .DESCRIPTION
    Gets all the translation memories.
    Returns a list of translation memories represented as powershell objects.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-AllTMs -authorizationToken $token

    .OUTPUTS
    [PSObject[]]
    This method returns a collection of PSObject representing all the Translation Memory existing on the server.
#>
function Get-AllTMs 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken)

    $uri = $tmEndpoint;
    $headers = FormatHeaders $authorizationToken;

    $response = Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers }
    if ($response)
    {
        return $response.Items;
    }    
}

<#
    .SYNOPSIS
    Gets all the translation memories within the given container as a list 

    .DESCRIPTION
    Gets all the translation memories within the given container.
    Returns a list of translation memories represented as powershell objects.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-AllTMs -authorizationToken $token

    .OUTPUTS
    [PSObject[]]
    This method returns a collection of PSObject representing the Translation Memory found on the server.
#>
function Get-TMsByContainer 
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $container
    )

    $tms = Get-AllTMs $authorizationToken
    if ($tms)
    {
        return $tms | Where-Object {$_.ContainerId -eq $container.ContainerId}
    }
}

<#
    .SYNOPSIS
    Creates a new Translation Memory

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER tmName
    Represents the name of the Trnslation Memory.
    
    .PARAMETER container
    Represents the container that will contain the Translation Memory as a powershell object

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

    .Parameter organization
    Represents the organization which will contain the container as a powershell object.

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

    .PARAMETER languageDirections
    Represents the group of target language to source languages as an array of powershell objects

    Can be retrieved from:
        Get-LanguageDirections

    For further documentation:
        Get-Help Get-LanguageDirections

    .PARAMETER fieldTemplate
    Represents the fieldTempalte as a powershell object that will be used for the TM creation

    Can be retrieved from:
        Get-AllFieldTemplates
        Get-FieldTemplate
        New-FieldTemplate
        Update-FieldTemplate
    
    For further documentation:
        Get-Help Get-AllFieldTemplates
        Get-Help Get-FieldTemplate
        Get-Help New-FieldTemplate
        Get-Help Update-FieldTemplate

    .PARAMETER description
    Additinoally, the descritpion for the TM can be provided

    .PARAMETER copyright
    The copyright for the TM.

    .PARAMETER recognizers
    Represents the recognizers of the Trnslation Memory.

    If the parameter it is not provided it will be set to RecognizeAll by default

    The following values can be applied:
    RecognizeNone Don't recognize any special tokens.
    RecognizeDates Recognizes date tokens.
    RecognizeTimes Recognizes time tokens.
    RecognizeNumbers Recognizes number tokens.
    RecognizeAcronyms Recognizes acronym tokens
    RecognizeVariables Recognizes variable tokens.
    RecognizeMeasurements Recognizes measurement tokens.
    RecognizeAlphaNumeric Recognizes alphanumeric tokens.
    RecognizeAll Recognizes all special tokens.

    In order to combine multiple recognizers they must be set as a comma separated list.
    E.G "RecognizeDates,RecognizeTimes"

    .PARAMETER fuzzyIndexes
    Represents the fuzzy indexes of the Translation Memory

    IF the parameter is not provided by default it will be set to "SourceWordBased,TargetWordBased", which are required.

    The following values can be applied:
    TargetCharacterBased N-gram-based fuzzy index on the target segment. Enabling this index will reduce the import performance.
    TargetWordBased Word-based fuzzy index on the target segment. Enabling this index will reduce the import performance.

    In order to add multiple fuzzy indexes they must be set as a comma separated list.
    E.G "SourceWordBased,TargetWordBased,TargetCharacterBased"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $container = Get-Container -authorizationToken $token -containerName "Sample Container"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $languageDirection = Get-LanguageDirections -source "en-US" -target @("de-DE")

    New-TM -authorizationToken $token -tmName "Sample TM" -container $container -organization $organization
        -languageDirections @($languageDirection)

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $container = Get-Container -authorizationToken $token -containerName "Sample Container"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $languageDirection = Get-LanguageDirections -source "en-US" -target @("de-DE")

    New-TM -authorizationToken $token -tmName "Sample TM" -container $container -organization $organization
        -languageDirections @($languageDirection) -copyright "Copyright"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $container = Get-Container -authorizationToken $token -containerName "Sample Container"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $languageDirection = Get-LanguageDirections -source "en-US" -target @("de-DE")

    New-TM -authorizationToken $token -tmName "Sample TM" -container $container -organization $organization
        -languageDirections @($languageDirection) -description "Powershell made TM"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $container = Get-Container -authorizationToken $token -containerName "Sample Container"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $languageDirection = Get-LanguageDirections -source "en-US" -target @("de-DE")

    New-TM -authorizationToken $token -tmName "Sample TM" -container $container -organization $organization
        -languageDirections @($languageDirection) -recognizers "RecognizeDates,RecognizeTimes"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $container = Get-Container -authorizationToken $token -containerName "Sample Container"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $languageDirection = Get-LanguageDirections -source "en-US" -target @("de-DE")

    New-TM -authorizationToken $token -tmName "Sample TM" -container $container -organization $organization
        -languageDirections @($languageDirection) -recognizers "RecognizeDates,RecognizeTimes" -fuzzyIndexes "TargetCharacterBased"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $container = Get-Container -authorizationToken $token -containerName "Sample Container"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $fieldTemplate = Get-FieldTemplate -authorizationToken $token -fieldTemplateName "Sample Field Template"
    $languageDirection = Get-LanguageDirections -source "en-US" -target @("de-DE", "fr-FR")
    $secondLanguageDirection = Get-LanguageDirections -source "en-GB" -target @("de-DE", "fr-FR")

    New-TM -authorizationToken $token -tmName "Sample TM" -container $container -organization $organization
        -languageDirections @($languageDirection, $secondLanguageDirection) -fieldTemplate $fieldTemplate
        -recognizers "RecognizeDates,RecognizeTimes" -fuzzyIndexes "TargetCharacterBased" 
        -description "Powershell Made TM" -copyRight "CopyRight"

    .OUTPUTS
    [PSObject]
    This method returns a PSObject representing the newly created Translation Memory.
#>
function New-TM
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [String] $tmName,

        [Parameter(Mandatory=$true)]
        [PSObject] $container,

        [Parameter(Mandatory=$true)]
        [psobject] $organization,   

        [Parameter(Mandatory=$true)]
        [PSObject[]] $languageDirections,

        [psobject] $fieldTemplate = $null,
        [String] $description = $null,
        [String] $copyright = $null,
        [String] $recognizers = "RecognizeAll",
        [String] $fuzzyIndexes = "SourceWordBased,TargetWordBased"
    )

    $uri = $tmEndpoint;
    $headers = FormatHeaders $authorizationToken;
    $defaultFuzzyIndexes = "SourceWordBased,TargetWordBased"
    if ($fuzzyIndexes)
    {
        $defaultFuzzyIndexes += ",$fuzzyIndexes"
    }

    $fuzzyIndexes = $defaultFuzzyIndexes

    $body = @{
        "Name" = $tmName
        "ContainerId" = $container.ContainerId
        "OwnerId" =  $organization.UniqueId
        "FuzzyIndexes" = $fuzzyIndexes
        "Recognizers" = $recognizers
        "Fields" = @()
        "Copyright" = $copyright
        "Location" = $organization.Path
        "IsTMSpecific" = $true
        "Description" = $description
        "LanguageDirections" = @($languageDirections | ForEach-Object { $_ })
    }

    if ($fieldTemplate)
    {
        $body.FieldTemplateId = $fieldTemplate.FieldTemplateId
    }

    $json = ConvertTo-Json $body -Depth 100

    $tm = Invoke-Method { Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $json }
    return Get-TM $token -tmId $tm
}

<#
    .SYNOPSIS
    Removes the specified Translation Memory

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER tm
    Represents an existing Translation Memory to be removed.

    Can be retrieved from:
        Get-AllTMs
        Get-TM
        New-TM
        Update-TM

    For further documentation:
        Get-Help Get-AllTMs
        Get-Help Get-TM
        Get-Help New-TM
        Get-Help Update-TM

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $tm = Get-TM -authorizationToken $token -tmName "Sample TM"

    Remove-TM -authorizationToken $token -tm $tm
#>
function Remove-TM 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [PSObject] $tm)

    $uri = $tmEndpoint + "/" + $tm.TranslationMemoryId;
    $headers = FormatHeaders $authorizationToken;

    return Invoke-Method { Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers }
}

<#
    .SYNOPSIS
    Updates an existing Translation Memory and returns the updated tm as an object.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER tm
    Represents an existing Translation Memory to be updated.

    Can be retrieved from:
        Get-AllTMs
        Get-TM
        New-TM
        Update-TM

    For further documentation:
        Get-Help Get-AllTMs
        Get-Help Get-TM
        Get-Help New-TM
        Get-Help Update-TM

    .PARAMETER languageDirections
    Optional parameter, represents the updated language direction of the tm.

    Can be retrieved from:
        Get-LanguageDirections

    For further documentation:
        Get-Help Get-LanguageDirections

    .PARAMETER fieldTemplate
    Represents the field template as a powershell object that will be associated with the tm.

    Can be retrieved from:
        Get-AllFieldTemplates
        Get-FieldTemplate
        New-FieldTemplate
        Update-FieldTemplate
    
    For further documentation:
        Get-Help Get-AllFieldTemplates
        Get-Help Get-FieldTemplate
        Get-Help New-FieldTemplate
        Get-Help Update-FieldTemplate

    .PARAMETER tmName
    Represents the new TM name

    .PARAMETER copyright
    Represents the new copytight of the TM

    .PARAMETER description
    Description for the tm.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $tm = Get-TM -authorizationToken $token -tmName "Sample TM"
    $newLanguageDirection = Get-LanguageDirections -source "en-US" -target @("de-DE")

    Update-TM -authorizationToken $token -tm $tm -languageDirections @($newLanguageDirection)

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $tm = Get-TM -authorizationToken $token -tmName "Sample TM"
    $newFieldTemplate = Get-FieldTemplate -authorizationToken $token -fieldTemplateName "Sample Field Template"

    Update-TM -authorizationToken $token -tm $tm -fieldTemplate $newFieldTemplate

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $tm = Get-TM -authorizationToken $token -tmName "Sample TM"
    $firstNewLanguageDirection = Get-LanguageDirections -source "en-US" -target @("de-DE")
    $secondtNewLanguageDirection = Get-LanguageDirections -source "en-GB" -target @("de-DE", "fr-FR")
    $newFieldTemplate = Get-FieldTemplate -authorizationToken $token -tm $TM-fieldTemplateName "Sample Field Template"

    Update-TM -authorizationToken $token -tm $tm -languageDirections @($firstNewLanguageDirection, $secondtNewLanguageDirection)
        -fieldTemplate $newFieldTemplate -tmName "Update Name" -copyright "Copyright" -description "Updated by TM"

    .OUTPUTS
    [PSObject]
    This method returns the updated Translation Memory as a PSObject.

    .NOTES
    If the provided parameters are not valid (e.g Field Template does not exist)
    The function will display an error on the console, then return the Translation Memory as a PSObject.
#>
function Update-TM 
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $tm,

        [psobject[]] $languageDirections = $null, 
        [psobject] $fieldTemplate = $null,
        [String] $tmName = $null,
        [String] $copyright = $null,
        [String] $description = $null
    )

    $uri = $tmEndpoint + "/" + $tm.TranslationMemoryId;
    $headers = FormatHeaders $authorizationToken;
    $body = [psobject]@{
        "TranslationMemoryId" = $tm.TranslationMemoryId
        "Name" = $tm.Name
        "ContainerId" = $tm.ContainerId
        "OwnerId" =  $tm.OwnerId
        "FuzzyIndexes" = $tm.FuzzyIndexes
        "Recognizers" = $tm.Recognizers
        "Fields" = $tm.Fields
        "Copyright" = $tm.Copyright
        "Location" = $tm.Location
        "IsTMSpecific" = $true
        "Description" = $tm.Description
        "LanguageDirections" = $tm.LanguageDirections
    }

    if ($languageDirections)
    {
        $body.LanguageDirections = @($languageDirections | ForEach-Object { $_ })
    }
    if ($fieldTemplate)
    {
        $body.fieldTemplateId = $fieldTemplate.FieldTemplateId
    }
    if ($tmName)
    {
        $body.Name = $tmName
    }
    if ($copyright)
    {
        $body.Copyright = $copyright
    }
    if ($description)
    {
        $body.Description = $description   
    }

    $json = $body | ConvertTo-Json -Depth 100
    $null = Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers -Body $json -Method Put }
    return Get-TM $authorizationToken -tmId $tm.TranslationMemoryId
}

<#
    .SYNOPSIS
    Returns all the existing project templates

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-AllProjectTemplates -authorizationToken $token

    .OUTPUTS
    [PSObject[]]
    This method returns a collection of psobject representing all the existing project templates from the server.

    .NOTES
    Using this function with an invalid authorizationToken will return the error message for this endpoint.
#>
function Get-AllProjectTemplates {
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken)

    $uri = $projectsTemplateEndpoint;
    $headers = FormatHeaders $authorizationToken;

    return Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers }
}

<#
    .SYNOPSIS
    Returns the specified project template.

    .DESCRIPTION
    Returns the project templates that has the specified name or the specified id if found, or null if not found.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER templateName
    Represents the name of the template.

    .PARAMETER templateId
    Represents the unique id of the template.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-ProjectTemplate -authorizationToken $token -templateName "Sample Template"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-ProjectTemplate -authorizationToken $token -templateId "f9a6e0c0-70b6-4f24-87a1-d066f5baf12b"

    .OUTPUTS
    [PSObject]
    This method returns a PSObject representing the existing project template found, or $null if no project template
    was found.

    .NOTES
    Using an invalid token will display the error message of this endpoint.
 #>
function Get-ProjectTemplate {
    param(
        [Parameter(Mandatory=$true)]
        [string] $authorizationToken,

        [String] $templateName = $null,
        [String] $templateId = $null)

    $templates = Get-AllProjectTemplates $authorizationToken;
    foreach ($template in $templates)
    {
        if ($template.Name -eq $templateName -or
            $template.Id -eq $templateId)
        {
            return $template;
        }
    }
}

<#
    .SYNOPSIS
    Creates a new project template.

    .DESCRIPTION
    Creates a new project template with default settings and with the provided parameters.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER templateName
    Represents the name of the template

    .Parameter organization
    Represents the organization which will own the template as a powershell object.

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

    .Parameter sourceLanguageCode
    Represents the source language of the project template.
    
    Example of language code is "en-US"

    .Parameter targetLanguageCodes
    Represents the target languages of the project template as a list of language codes.
    
    Example of language code is "en-US"

    .PARAMETER translationMemories
    Represents a list of translation memories that the project template will use as a list of
    powershell objects.

    Can be retrieved from:
        Get-AllTMs
        Get-TM
        New-TM
        Update-TM

    For further documentation:
        Get-Help Get-AllTMs
        Get-Help Get-TM
        Get-Help New-TM
        Get-Help Update-TM

    .PARAMETER segmentLockingSettings
    Represents a list of segmentLockingSettings for custom locking settings. The first item should be the setting for 
    the entire project template.

    Can be retrieved from:
        Get-DefaultSegmentLockingSettings
        Get-SegmentLockingSettings

    For further documentation:
        Get-Help Get-DefaultSegmentLockingSettings
        Get-Help Get-SegmentLockingSettings;

    .PARAMETER termbases
    Represents a list of termbases as powershell objects.
    
    Can be retrieved from:
        Get-Termbase

    For further documentation:
        Get-Help Get-Termbase

    .PARAMETER projectTemplatePath
    Additionally, the project template physycal path can be provided to be used for project template creation.

    The file should end with .sdltpl

    .PARAMETER description
    Optionally, the description of the project template

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"

    New-ProjectTemplate -authorizationToken $token -templateName "Sample Project Template"
        -organization $organization -sourceLanguageCode "en-US" -targetLanguageCodes @("de-DE", "fr-FR")

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $tm = Get-TM -authorizationToken $token -tmName "Sample TM"

    New-ProjectTemplate -authorizationToken $token -templateName "Sample Project Template"
        -organization $organization -sourceLanguageCode "en-US" -targetLanguageCodes @("de-DE", "fr-FR")
        -translationMemories @($tm)

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $tm = Get-TM -authorizationToken $token -tmName "Sample TM"
    $tb = Get-Termbase -authorizationToken $token -termbaseName "Sample TB"

    New-ProjectTemplate -authorizationToken $token -templateName "Sample Project Template"
        -organization $organization -sourceLanguageCode "en-US" -targetLanguageCodes @("de-DE", "fr-FR")
        -translationMemories @($tm) -termbases @($tb)

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $tm = Get-TM -authorizationToken $token -tmName "Sample TM"
    $tb = Get-Termbase -authorizationToken $token -termbaseName "Sample TB"
    $defaultSegmentLocking = Get-SegmentLockingSettings -anyTranslationStatuses $true -translationStatuses @("ApprovedTranslation", "Translated") 
        -translationOrigins @("TranslationMemory") -mtqe @("Good") -score 50
    $specificSegmentLocking = Get-SegmentLockingSettings -anyTranslationStatuses $true -translationStatuses @("ApprovedTranslation", "Translated") 
        -targetLanguageCode "de-DE"

    New-ProjectTemplate -authorizationToken $token -templateName "Sample Project Template"
        -organization $organization -sourceLanguageCode "en-US" -targetLanguageCodes @("de-DE", "fr-FR")
        -translationMemories @($tm) -termbases @($tb) -segmentLockingSettings @($defaultSegmentLocking, $specificSegmentLocking)

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"

    New-ProjectTemplate -authorizationToken $token -templateName "Sample Project Template"
        -organization $organization -projectTemplatePath "D:\Path\To\template.sdltpl"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $tm = Get-TM -authorizationToken $token -tmName "Sample TM"
    $tb = Get-Termbase -authorizationToken $token -termbaseName "Sample TB"

    New-ProjectTemplate -authorizationToken $token -templateName "Sample Project Template"
        -organization $organization -sourceLanguageCode "en-US" -targetLanguageCodes @("de-DE", "fr-FR")
        -translationMemories @($tm) -termbases @($tb) -projectTemplatePath "D:\Path\To\template.sdltpl"
        
    .OUTPUTS
    [PSObject]
    This method returns a psobject representing the updated project template
    
    .NOTES
    Using invalid authorizationToken, invalid organiation object, language codes and translation memories will return the error message
    of this endpoint.

    All the parameter must be specified correctly, except description, which is optional.
#>
function New-ProjectTemplate 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [String] $templateName,

        [Parameter(Mandatory=$true)]
        [PSObject] $organization,

        [String] $sourceLanguageCode,
        [String[]] $targetLanguageCodes,

        [PSObject[]] $translationMemories,
        [psobject[]] $segmentLockingSettings = $null,
        [psobject[]] $termbases = $null,
        [String] $description = $null,
        [string] $projectTemplatePath = $null,
        [bool] $enableSegmentLocking = $false)

    $uri = $projectsTemplateEndpoint;
    $headers = FormatHeaders $authorizationToken;

    # Gets the projecttemplatepath settings

    $template = @{
        "Name" = $templateName
        "Description" = $description
        "OrganizationId" = $organization.UniqueId
    }

    if ($projectTemplatePath -ne "")
    {
        $templateSettings = Get-TemplateSettingsFromPath $authorizationToken $projectTemplatePath;
        if ($templateSettings)
        {
            $template.Settings = $templateSettings
        }
    }

    if (($null -eq $templateSettings -and $sourceLanguageCode -eq "") -or 
        ($null -eq $templateSettings -and $targetLanguageCodes.Count -eq 0))
    {
        Write-Host "Project Template must have one source language code and at least one target language code" -ForegroundColor Green;
        return;
    }

    $settings = @{
        "SourceLanguageCode" = $sourceLanguageCode
        "TargetLanguageCodes" = $targetLanguageCodes
        "EnableSegmentLockTask" = $false
        "Termbases" = @() 
        "SegmentLockingSettings" = @($(Get-DefaultSegmentLockingSettings))
    }

    # Handle termbases if any
    $formattedTermbases = Format-Termbases $termbases | Where-Object { $null -ne $_ };
    $settings.Termbases += $formattedTermbases

    # Handles TMs if any
    $formatedTMS = FormatTMs $translationMemories | Where-Object {$null -ne $_ };
    $settings.TranslationMemories = @($formatedTMS);

    if ($segmentLockingSettings)
    {
        if ($segmentLockingSettings[0].targetLanguage -ne "")
        {
            Write-Host "The first Segment Locking settings should be for all the language pairs" -ForegroundColor Green
        }

        $settings.EnableSegmentLockTask = $enableSegmentLocking 
        $settings.SegmentLockingSettings = @($segmentLockingSettings)
    }

    if ($templateSettings)
    {
        $templateSettings.TranslationMemories += $formatedTMS
        $templateSettings.Termbases += $formattedTermbases

        if ($segmentLockingSettings)
        {
            $templateSettings.EnableSegmentLockTask = $enableSegmentLocking,
            $templateSettings.SegmentLockingSettings = @($segmentLockingSettings)
        }
    }
    else 
    {
        $template.Settings = $settings;
    }

    $json = ConvertTo-Json $template -Depth 100;
    $template = Invoke-Method { Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $json  }
    if ($template)
    {
        return Get-ProjectTemplate $authorizationToken -templateId $template
    }
}

<#
    .SYNOPSIS
    Updates an existing project template with the given parameters.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER projectTemplate
    Represents an existing project Template powershell object.

    Can be retrieved from:
        Get-AllProjectTemplate
        Get-ProjectTemplate
        New-ProjectTemplate
        Update-ProjectTemplate

    For further documentation:
        Get-Help Get-AllProjectTemplate
        Get-Help Get-ProjectTemplate
        Get-Help New-ProjectTemplate
        Get-Help Update-ProjectTemplate
    
    .PARAMETER name
    The new name for the project template

    .PARAMETER description
    The updated description

    .PARAMETER organization
    The new owner organization of this project template.

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

    .PARAMETER sourceLanguageCode
    Represents the new source language code for the project template. 

    Example of language code is "en-US"

    .PARAMETER targetLanguageCodes
    An array of language code representing the new target languages.

    Example of language code is "en-US"

    .PARAMETER tms
    Represents the new translation memories.

    Can be retrieved from:
        Get-AllTMs
        Get-TM
        New-TM
        Update-TM

    For further documentation:
        Get-Help Get-AllTMs
        Get-Help Get-TM
        Get-Help New-TM
        Get-Help Update-TM

    .PARAMETER tmsWithScope
    Formatted translation memory, scoped for one or many pair of source language to target language

    Can be retrieved from:
        Get-TmWithScope

    For further documentation:
        Get-Help Get-TmsWithScope

    .PARAMETER segmentLockingSettings
    The new updated segmetn locking settings. 
    The first element from the array should be the setting for all langauge pairs.

    Can be retrieved from:
        Get-DefaultSegmentLockingSettings
        Get-SegmentLockingSettings

    For further documentation:
        Get-Help Get-DefaultSegmentLockingSettings
        Get-Help Get-SegmentLockingSettings;

    .PARAMETER termbases
    The new termbases.

    Can be retrieved from:
        Get-Termbase

    For further documentation:
        Get-Help Get-Termbase

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $template = Get-ProjectTemplate -authorizationToken $token -templateName "Sample Project Template"

    Update-ProjectTemplate -authorizationToken $token -projectTemplate $template -name "Updated Name"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $template = Get-ProjectTemplate -authorizationToken $token -templateName "Sample Project Template"

    Update-ProjectTemplate -authorizationToken $token -projectTemplate $template -name "Updated Name"
        -organization $organization

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $template = Get-ProjectTemplate -authorizationToken $token -templateName "Sample Project Template"
    $tm = Get-TM -authorizationToken $token -tmName "Sample TM"
    $tb = Get-Termbase -authorizationToken $token -termbaseName "Sample TB"
    $defaultSegmentLocking = Get-SegmentLockingSettings -anyTranslationStatuses $true -translationStatuses @("ApprovedTranslation", "Translated") 
        -translationOrigins @("TranslationMemory") -mtqe @("Good") -score 50
    $specificSegmentLocking = Get-SegmentLockingSettings -anyTranslationStatuses $true -translationStatuses @("ApprovedTranslation", "Translated") 
        -targetLanguageCode "de-DE"

    Update-ProjectTEmplate -authorizationToken $token -projectTemplate $template -tms @($tm) -termbases ($tb)
        -segmentLockingSettings ($defaultSegmentLocking, $specificSegmentLocking)

    .OUTPUTS
    [PSObject]
    This method returns a psobject representing the updated project template
#>
function Update-ProjectTemplate {
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $projectTemplate,

        [string] $name = $null,
        [string] $description = $null,
        [psobject] $organization = $null,
        [string] $sourceLanguageCode = $null,
        [string[]] $targetLanguageCodes = $null,
        [psobject[]] $tms = $null,
        [psobject[]] $segmentLockingSettings = $null,
        [psobject[]] $termbases = $null,
        [bool] $enableSegmentLocking
    )

    $uri = $projectsTemplateEndpoint + "/" + $projectTemplate.Id
    $headers = FormatHeaders $authorizationToken

    $templateObj = Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers }
    $template = @{
        "Name" = $projectTemplate.Name
        "Description" = $projectTemplate.Description
        "OrganizationId" = $projectTemplate.OrganizationId
    }

    if ($name)
    {
        $template.name = $name
    }
    if ($description)
    {
        $template.description = $description
    }
    if ($organization)
    {
        $template.organizationId = $organization.UniqueId
    }

    $templateSettings = @{
        "SourceLanguageCode" = $templateObj.sourceLanguageCode 
        "TargetLanguageCodes" = $templateObj.targetLanguageCodes
        "EnableSegmentLockTask" = $templateObj.EnableSegmentLockTask
        "Termbases" = $templateObj.termbases 
        "SegmentLockingSettings" = $templateObj.SegmentLockingSettings 
        "TranslationMemories" = $templateObj.TranslationMemories 
    }

    if ($sourceLanguageCode)
    {
        $templateSettings.SourceLanguageCode = $sourceLanguageCode
    }

    if ($targetLanguageCodes)
    {
        $templateSettings.TargetLanguageCodes = @($targetLanguageCodes)
    }

    if ($tms)
    {
        $templateSettings.TranslationMemories = $templateSettings.TranslationMemories | Where-Object { $_.Scope.count -gt 0 }
        $templateSettings.TranslationMemories += FormatTMs $tms;
        $templateSettings.TranslationMemories = $templateSettings.TranslationMemories | Where-Object { $null -ne $_ } 
    }
    if ($segmentLockingSettings)
    {
        $templateSettings.EnableSegmentLockTask = $enableSegmentLocking
        $templateSettings.SegmentLockingSettings = @($segmentLockingSettings);
    }
    if ($termbases)
    {
        $templateSettings.Termbases = @(Format-Termbases $termbases);
    }

    $template.settings = $templateSettings;
    $json = $template | ConvertTo-Json -Depth 100
    $response = Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers -Method Put -Body $json }
    return Get-ProjectTemplate $authorizationToken -templateId $projectTemplate.Id
}

<#
    .SYNOPSIS
    Removes the spcified project template.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER template
    Represents the project template as a powershell object.

    Can be retrieved from:
        Get-AllProjectTemplate
        Get-ProjectTemplate
        New-ProjectTemplate
        Update-ProjectTemplate

    For further documentation:
        Get-Help Get-AllProjectTemplate
        Get-Help Get-ProjectTemplate
        Get-Help New-ProjectTemplate
        Get-Help Update-ProjectTemplate

    .EXAMPLE 
    $token = SignIn -userName "username" -password "password"
    $projectTemplate = Get-ProjectTemplate -authorizationToken $token -templateName "Sample Project Template"

    Remove-ProjectTemplate -authorizationToken $token -template $projectTemplate

    .NOTES
    If the authorizationToken is invalid this function will return the error message of this endpoint.

    Using an existing or non existing template object will display the same output but only the existing templates will be removed.

#>
function Remove-ProjectTemplate {
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [PSObject] $template)

    $uri = $projectsTemplateEndpoint + "\" + $template.Id;
    $headers = FormatHeaders $authorizationToken;

    Invoke-Method { Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers }
}

<#
    .SYNOPSIS
    Export the provided project templates

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER projectTemplates
    Represents an array of project templates that will be exported.
    
    Can be retrieved from:
        Get-AllProjectTemplate
        Get-ProjectTemplate
        New-ProjectTemplate
        Update-ProjectTemplate

    For further documentation:
        Get-Help Get-AllProjectTemplate
        Get-Help Get-ProjectTemplate
        Get-Help New-ProjectTemplate
        Get-Help Update-ProjectTemplate

    .PARAMETER outputFilesPath
    Represents the physical location where the projects will be saved.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $allProjectTemplates = Get-AllProjectTemplates -authorizationToken $token

    Export-ProjectTemplate -authorizationToken $token -projectTemplates @($allProjectTemplates[0])
         -outputFilesPath "C:\Documents\exporttemplate.sdltm"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $allProjectTemplates = Get-AllProjectTemplates -authorizationToken $token

    Export-ProjectTemplate -authorizationToken $token -projectTemplates @($allProjectTemplates[0])
         -outputFilesPath "C:\Documents\exporttemplate"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $allProjectTemplates = Get-AllProjectTemplates -authorizationToken $token

    Export-ProjectTemplate -authorizationToken $token 
        -projectTemplates @($allProjectTemplates[0], $allProjectTemplates[1])
         -outputFilesPath "C:\Documents\output"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $allProjectTemplates = Get-AllProjectTemplates -authorizationToken $token

    Export-ProjectTemplate -authorizationToken $token 
        -projectTemplates @($allProjectTemplates[0], $allProjectTemplates[1])
         -outputFilesPath "C:\Documents\output.zip"
#>
function Export-ProjectTemplate {
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject[]] $projectTemplates,

        [Parameter(Mandatory=$true)]
        [String] $outputFilesPath
    )

    $uri = $projectsTemplateEndpoint + "/download"
    $singleTemplateExt = ".sdltpl"
    $multipleTemplatesExt = ".zip"

    if ($projectTemplates.Count -eq 1)
    {
        if ($outputFilesPath.EndsWith($singleTemplateExt) -eq $false)
        {
            $outputFilesPath += $singleTemplateExt
        }
    }
    else 
    {
        if ($outputFilesPath.EndsWith($multipleTemplatesExt) -eq $false)
        {
            $outputFilesPath += $multipleTemplatesExt
        }
    }

    $templatesIds = $projectTemplates | ForEach-Object { $_.Id }
    $templateQuery = $templatesIds -join ","

    $uri += "?templatesIds=$templateQuery"
    $headers = FormatHeaders $authorizationToken;

    Invoke-Method { Invoke-RestMethod -Headers $headers -Uri $uri -OutFile $outputFilesPath}    
}

<#
    .SYNOPSIS
    Returns a list with all the existing termbases from the server.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-AllTermbases -authorizationToken $token

    .OUTPUTS
    [PSObject[]]
    This method returns a collectino of PSObject representing all the existing termbases.
#>
function Get-AllTermbases 
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken
    )

    $headers = FormatHeaders $authorizationToken;
    $uri = $termbasesEndpoint;

    $response = Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers }
    if ($response)
    {
        return $response.Termbases;
    }
}

<#
    .SYNOPSIS
    Returns the termbase with the specified name.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER termbaseName
    represents the name of the termbase

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-Termbase -authorizationToken $token -termbaseName "Sample Termbase"

    .OUTPUTS
    [PSObject]
    This method returns a psobject representing an existing Termbase or $null if not found.

    .NOTES
    When using this method, the termbase should be provided with the exact format.

    Example: Existing Termbase Name: "Sample Termbase"
    The Termbase name should be exactly "Sample Termbase" respecting every character case.
#>
function Get-Termbase
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [String] $termbaseName
    )

    $uri = $termbasesEndpoint + "/" + [System.URi]::EscapeDataString($termbaseName);
    $headers = FormatHeaders $authorizationToken
    $tb = Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers }

    if ($tb)
    {
        return $tb.termbase
    }
}

<#
    .SYNOPSIS
    Imports a tmx into an existing Translation Memory

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER tm
    Represents the Translation Memory that will import the tmx.

    Can be retrieved from:
        Get-AllTMs
        Get-TM
        New-TM
        Update-TM

    For further documentation:
        Get-Help Get-AllTMs
        Get-Help Get-TM
        Get-Help New-TM
        Get-Help Update-TM

    .PARAMETER sourceLanguageCode
    Represents the source language code that will be used for import.

    Example of language code is "en-US"

    .PARAMETER targetLanguageCode
    Represents the target language code that will be used for the import.

    Example of language code is "en-US"

    .PARAMETER tmxPath
    Represents the physical location of the file to be used for import.

    The file for this location must end with the extension ".gz"

    .EXAMPLE
    Import-TMX -authorizationToken "SampleToken" -tm $existingTM
        -sourceLanguageCode "en-US" -targetLanguageCide "de-DE"-tmxPath "D:\Path\To\import.tmx"
#>
function Import-TMX 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [PSObject] $tm,

        [Parameter(Mandatory=$true)]
        [String] $sourceLanguageCode,

        [Parameter(Mandatory=$true)]
        [String] $targetLanguageCode,

        [Parameter(Mandatory=$true)]
        [String] $tmxPath)

    $uri = $tmEndpoint + "/" + $tm.TranslationMemoryId
    $query = "/import?source=$sourceLanguageCode&target=$targetLanguageCode"

    $fullUri = [System.Uri]::New($uri + $query);
    $absolutePath = $fullUri.AbsoluteUri;

    $headers = @{
        "Content-Type" = "multipart/form-data"
        "Accept" = "application/json"
        "Authorization" = "Bearer $token"
    }

    $body = @{
        "file" = Get-Item -Path $tmxPath
    }

    try
    {
        return Invoke-WebRequest -Uri $absolutePath -Method Post -Headers $headers -Form $body
    }
    catch 
    {
        Write-output "Error occured: $_";
    }
}

<#
    .SYNOPSIS
    Exports the tmx from an existing Translation Memory to the given location.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER tm 
    Represents the Translation Memory that will be used for generating the export file.

    Can be retrieved from:
        Get-AllTMs
        Get-TM
        New-TM
        Update-TM

    For further documentation:
        Get-Help Get-AllTMs
        Get-Help Get-TM
        Get-Help New-TM
        Get-Help Update-TM

    .PARAMETER sourceLanguageCode
    Represents the source language code that will be used for import.

    Example of language code is "en-US"

    .PARAMETER targetLanguageCode
    Represents the target language code that will be used for the import.

    Example of language code is "en-US"

    .PARAMETER outputFilePath
    Represents the physical location where the file will be created.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $tm = Get-TM -authorizationToken $token -tmName "Sample TM"

    Export-TMX -authorizationToken $token -tm $tm -sourceLanguageCode "en-US" -targetLanguageCode "de-DE" 
        -outputFilePath "C:\Documents\export"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $tm = Get-TM -authorizationToken $token -tmName "Sample TM"

    Export-TMX -authorizationToken $token -tm $tm -sourceLanguageCode "en-US" -targetLanguageCode "de-DE" 
        -outputFilePath "C:\Documents\export.tmx.gz"
#>
function Export-TMX
{  
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [PSObject] $tm,
 
        [Parameter(Mandatory=$true)]
        [String] $sourceLanguageCode,

        [Parameter(Mandatory=$true)]
        [String] $targetLanguageCode,

        [Parameter(Mandatory=$true)]
        [String] $outputFilePath
    )

    $returnedExtension = ".tmx.gz"

    if ($outputFilePath.EndsWith($returnedExtension) -eq $false)
    {
        $outputFilePath += $returnedExtension;
    }

    $baseUri = $tmEndpoint + "/" + $tm.TranslationMemoryId + "/export";
    $query = "source=$sourceLanguageCode&target=$targetLanguageCode"
    $headers = FormatHeaders $authorizationToken;

    $uriBuilder = New-Object System.UriBuilder($baseUri);
    $uriBuilder.Query = $query;

    $task = Invoke-Method { Invoke-RestMethod -Uri $uriBuilder.Uri -Method Post -Headers $headers }
    if ($task)
    {
        Get-ExportFile $authorizationToken $task $outputFilePath;
    }

}

<#
    .SYNOPSIS
    Returns a list with all the field templates on the server.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"

    Get-AllFieldTemplates -authorizationToken $token

    .OUTPUTS
    [PSObject[]]
    This method returns a collection of psobjects representing all the existing fieldtemplates.
#>
function Get-AllFieldTemplates 
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken
    )

    $uri = $fieldTemplatesEndpoint;
    $headers = FormatHeaders $authorizationToken;

    $response = Invoke-Method { Invoke-RestMethod -Uri $uri -Headers $headers }
    if ($response)
    {
        return $response.items | Where-Object { $_.IsTMSpecific -eq $false };
    }
}

<#
    .SYNOPSIS
    Returns the specified Field Template as a powershell object

    .DESCRIPTION
    Returns the field template with the specified id, if found.
    If both fieldtemplateId and fieldTemplatename are provided, this function will search for both of them.
    If no field template was found with the specified id, it will display an error message on the powershell console
    and look for the field template with the given name.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER fieldTemplateName
    Represents the name of the field template

    .PARAMETER fieldTemplateId
    Represents the unique id of the field template.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-FieldTemplate -authorizationToken $token -fieldTemplateName "Sample Field Name"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    Get-FieldTemplate -authorizationToken $token -fieldTemplateId "f9a6e0c0-70b6-4f24-87a1-d066f5baf12b"

    .OUTPUTS
    [PSObject]
    This method returns a psobject representing the found field template. If the field template was not found 
    $null is returned.
#>
function Get-FieldTemplate 
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [String] $fieldTemplateName = $null,
        [String] $fieldTemplateId = $null
    )

    if ($fieldTemplateId)
    {
        $uri = $fieldTemplatesEndpoint + "/" + $fieldTemplateId;
        $headers = FormatHeaders $authorizationToken;

        $response = Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers } 
        if ($response)
        {
            return $response;
        }
    }

    $templates = Get-AllFieldTemplates $authorizationToken;
    foreach ($template in $templates)
    {
        if ($template.Name -eq $fieldTemplateName)
        {
            return $template;
        }
    }
}

<#
    .SYNOPSIS
    Creates a new field template and returns it as a powershell object.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER name
    Represents the name of the field template.

    .PARAMETER organization
    Represents the owner organization of the field template as a powershell object.

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

    .PARAMETER fields
    Represents the field definitions as a list of powershell objects.

    Can be retrieved from:
        Get-FieldDefinition

    For further documentation:
        Get-Help Get-FieldDefinition

    .PARAMETER description
    Additionally, description parameter represents a description for the field template.

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $fieldDefinition = Get-FieldDefinition -name "Sample Field Name" -type "Integer"

    New-FieldTemplate -authorizationToken $token -name "Sample Field Template" -organization $organization 
        -fields @(fieldDefinition)


    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $firstFieldDefinition = Get-FieldDefinition -name "Sample Field Name" -type "Integer"
    $secondFieldDefinition = Get-FieldDefinition -name "Sample Field Name" -type "MultipleString" -values @("Value1", "Value2")

    New-FieldTemplate -authorizationToken $token -name "Sample Field Template" -organization $organization 
        -fields @(firstFieldDefinition, $secondFieldDefinition)


    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $organization = Get-Organization -authorizationToken $token -organizationName "Root Organization"
    $firstFieldDefinition = Get-FieldDefinition -name "Sample Field Name" -type "Integer"
    $secondFieldDefinition = Get-FieldDefinition -name "Sample Field Name" -type "MultipleString" -values @("Value1", "Value2")

    New-FieldTemplate -authorizationToken $token -name "Sample Field Template" -organization $organization 
        -fields @(firstFieldDefinition, $secondFieldDefinition) -description "Created by Powershell"

    .OUTPUTS
    [PSObject]
    This method returns a PSOBject representing the newly created Field Template.

#>
function New-FieldTemplate 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [String] $name,
        
        [Parameter(Mandatory=$true)]
        [psobject] $organization,

        [Parameter(Mandatory=$true)]
        [psobject[]] $fields,

        [String] $description = $null
    )

    $uri = $fieldTemplatesEndpoint;
    $headers = FormatHeaders $authorizationToken;
    $body = 
    @{
        "Name" = $name
        "OwnerId" = $organization.UniqueId
        "Fields" = $fields
        "Description" = $description
    }

    $json = $body | ConvertTo-Json -Depth 5;

    $fieldId = Invoke-Method { Invoke-RestMethod -uri $uri -Headers $headers -Body $json -Method Post }
    return Get-FieldTemplate $authorizationToken -fieldTemplateId $fieldId
}

<#
    .SYNOPSIS
    Removes an existing field template.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER fieldTemplate
    Represents the field template object that will be removed.

    Can be retrieved from:
        Get-AllFieldTemplates
        Get-FieldTemplate
        New-FieldTemplate
        Update-FieldTemplate
    
    For further documentation:
        Get-Help Get-AllFieldTemplates
        Get-Help Get-FieldTemplate
        Get-Help New-FieldTemplate
        Get-Help Update-FieldTemplate

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $fieldTemplate = Get-FieldTemplate -authorizationToken $token -fieldTemplateName "Sample Field Template"
    
    Remove-FieldTemplate -authorizationToken $token -fieldTemplate $fieldTemplate

    .NOTES
    This function will not display, nor return anything when removing or not finding the resource.
#>
function Remove-FieldTemplate 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $fieldTemplate
    )

    $uri = $fieldTemplatesEndpoint + "/" + $fieldTemplate.FieldTemplateId;
    $headers = FormatHeaders $authorizationToken;

    return Invoke-Method { Invoke-RestMethod -uri $uri -Method Delete -Headers $headers }
}

<#
    .SYNOPSIS
    Updates an existing field template with the provided parameters and returns the updated object.

    .PARAMETER authorizationToken
    Represents the security token that allows user to access sensitive resources. 

    Can be retrieved from:
        SignIn 

    For further documentation:
        Get-Help SignIn

    .PARAMETER fieldTemplate
    Represents the field template object that will be updated.

    Can be retrieved from:
        Get-AllFieldTemplates
        Get-FieldTemplate
        New-FieldTemplate
        Update-FieldTemplate
    
    For further documentation:
        Get-Help Get-AllFieldTemplates
        Get-Help Get-FieldTemplate
        Get-Help New-FieldTemplate
        Get-Help Update-FieldTemplate

    .PARAMETER name
    Represents the new field template name.

    .PARAMETER fields
    Represents the new field definitions as a list of powershell objects.

    Can be retrieved from:
        Get-FieldDefinition

    For further documentation:
        Get-Help Get-FieldDefinition

    .PARAMETER description
    Represents the updated description

    .PARAMETER organization
    Represents the new owner organization of the field template.

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
    $token = SignIn -userName "username" -password "password"
    $fieldTemplate = Get-FieldTemplate -authorizationToken $token -fieldTemplateName "Sample Field Template"

    Update-FieldTemplate -authorizationToken $token -fieldTemplate $fieldTemplate -name "Updated Field Template"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $fieldTemplate = Get-FieldTemplate -authorizationToken $token -fieldTemplateName "Sample Field Template"

    Update-FieldTemplate -authorizationToken $token -fieldTemplate $fieldTemplate -description "Created by powershell"

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $fieldTemplate = Get-FieldTemplate -authorizationToken $token -fieldTemplateName "Sample Field Template"
    $firstFieldDefinition = Get-FieldDefinition -name "Sample Field Name" -type "Integer"

    Update-FieldTemplate -authorizationToken $token -fieldTemplate $fieldTemplate -fields @($firstFieldDefinition)

    .EXAMPLE
    $token = SignIn -userName "username" -password "password"
    $fieldTemplate = Get-FieldTemplate -authorizationToken $token -fieldTemplateName "Sample Field Template"
    $firstFieldDefinition = Get-FieldDefinition -name "Sample Field Name" -type "Integer"
    $secondFieldDefinition = Get-FieldDefinition -name "Sample Field Name" -type "MultipleString" -values @("Value1", "Value2")

    Update-FieldTemplate -authorizationToken $token -fieldTemplate $fieldTemplate -name "Updated Field Template"
        -description "Created by Powershell" -fields @($firstFieldDefinition, $secondFieldDefinition)

    .OUTPUTS
    [PSObject]
    This method returns a PSObject represeting the updated Field Template
#>
function Update-FieldTemplate 
{
    param (
        [Parameter(Mandatory=$true)]
        [String] $authorizationToken,

        [Parameter(Mandatory=$true)]
        [psobject] $fieldTemplate,

        [String] $name = $null,
        [psobject[]] $fields = $null,
        [String] $description = $null
    )

    $uri = $fieldTemplatesEndpoint + "/" + $fieldTemplate.FieldTemplateId;
    $headers = FormatHeaders $authorizationToken;

    $patchOperation = @();
    if ($name)
    {
        $patchOperation += @{
            "operation" = "replace"
            "path" = "/name"
            "value" = $name
        }
    }
    if ($fields)
    {
        $patchOperation += @{
            "operation" = "replace"
            "path" = "/fields"
            "value" = $fields
        }
    }
    if ($description)
    {
        $patchOperation += @{
            "operation" = "replace"
            "path" = "/description"
            "value" = $description
        }
    }

    $json = $patchOperation | ConvertTo-Json -Depth 5;

    if ($patchOperation.Count -eq 1)
    {
        $json = "[ " + $json + "]"
    }

    $null = Invoke-Method { Invoke-RestMethod -uri $uri -Method Patch -Headers $headers -Body $json }
    return Get-FieldTemplate $authorizationToken -fieldTemplateId $fieldTemplate.FieldTemplateId;
}

<#
    .SYNOPSIS
    Helper function that group a target language to multiple source languages.

    .DESCRIPTION
    This method group one source language to multiple target languages returning a psobject object that can be used for creating
    Translation Memories

    .Parameter source
    Represents the source language of the project template.
    
    Example of language code is "en-US"

    .Parameter target
    Represents the target languages of the project template as a list of language codes.
    
    Example of language code is "en-US"

    .EXAMPLE
    Get-LanguageDirections -source "en-US" -target @("de-DE")

    .EXAMPLE
    Get-LanguageDirections -source "en-US" -target @("de-DE", "fr-FR")

    .OUTPUTS
    [PSObject]
    This method return a psobject representing one or multiple language directions for creating Translation Memories.
#>
function Get-LanguageDirections 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $source,
        
        [Parameter(Mandatory=$true)]
        [String[]] $target
    )

    $languageDirections = @();

    foreach ($language in $target)
    {
        $languageDirections += [psobject]@{
            "Source" = $source
            "Target" = $language
        }
    }

    return $languageDirections;
}

<#
    .SYNOPSIS
    Helper function to create a field definition.

    .DESCRIPTION
    Creates a field definition powershell object.
    This function returns a PSObject representing the field templates definition which
    can be used for creating/updating existing field templates.

    .PARAMETER name
    Represents the name of the field definition

    .PARAMETER type
    Represents the type of the field definition.

    One of the following values are expected
    SingleString
    MultipleString
    Integer
    DateTime
    SinglePicklist
    MultiplePicklist

    .PARAMETER values
    Custom values for the field definitions as an array of strings.

    This parameter should be populated only when the type parameter is SinglePicklist or MultiplePicklist

    .EXAMPLE
    Get-FieldDefinition -name "Sample Name" -type "SingleString"

    .EXAMPLE
    Get-FieldDefinition -name "Sample Field Name" -type "MultipleString" -values @("Value1", "Value2")

    .OUTPUTS
    [PSObject]
    This method returns a psobject representing a field definition.
    This object can be later used for creating/updating Field Templates.
#>
function Get-FieldDefinition 
{
    param(
        [Parameter(Mandatory=$true)]
        [String] $name,

        [Parameter(Mandatory=$true)]
        [String] $type,

        [String[]] $values
    )

    $output = @{
        "Name" = $name
        "Type" = $type
    }

    [PSObject[]] $fieldValues = @();
    if ($values)
    {
        foreach ($value in $values)
        {
            $fieldValues += @{"Name" = $value};
        }

        $output.Values = $fieldValues;
    }

    return $output;
}

<#
    .SYNOPSIS
    Creates segment locking settings for project templates creation.

    .PARAMETER targetLanguageCode
    Represents the target language code

    E.g "en-US"

    .PARAMETER anyTranslationStatuses
    Boolean value indicating whether this settings will be:
        ANY of the specified translation statuses OR origins when true
        BOTH the specified translation statuses AND origins when false

    .PARAMETER translationStatuses
    Represents the translation statuses as an array of strings
    Expected values are:
    SignedOff
    ApprovedTranslation
    Translated
    TranslationRejected
    Draft
    SignOffRejected

    .PARAMETER translationOrigins
    Represents the translation Origins
    Expected values are:
    TranslationMemory
    NeuralMachineTranslation
    Interactive
    PerfectMatch
    AutoPropagated
    CopyFromSource
    AutomatedAlignment
    ReverseAlignment
    MachineTranslation
    AdaptiveMachineTranslation

    .PARAMETER mtqe
    This should be provided only when the target language is set to an empty string ""
    Expected values
    Good
    Adequate
    Poor

    .PARAMETER score
    This should be provided only when the target language is set to an empty string ""
    Value between 0 and 100 expected

    .EXAMPLE
    Get-SegmentLockingSettings -anyTranslationStatuses $true -translationStatuses @("ApprovedTranslation", "Translated") 
        -translationOrigins @("TranslationMemory") -mtqe @("Good") -score 50

    .EXAMPLE
    Get-SegmentLockingSettings -anyTranslationStatuses $true -translationStatuses @("ApprovedTranslation", "Translated") 
        -targetLanguageCode "de-DE"
#>
function Get-SegmentLockingSettings 
{
    param (
        [Parameter(Mandatory=$true)]
        [Bool] $anyTranslationStatuses,
        
        [Parameter(Mandatory=$true)]
        [String[]] $translationStatuses,
        
        [Parameter(Mandatory=$true)]
        [String[]] $translationOrigins,
        
        [String] $targetLanguageCode,
        [System.Linq.Enumerable[]] $mtqe,
        [System.Nullable[int]] $score
    )

    $segmentLockingSetting = @{
        "targetLanguage" = $targetLanguageCode
        "useAndCondition" = $anyTranslationStatuses
        "TranslationOrigins" = $translationOrigins
        "TranslationStatuses" = $translationStatuses
    }

    if ($targetLanguageCode -eq "")
    {
        $segmentLockingSetting.score = [psobject]$null        
    }
    else 
    {
        $segmentLockingSetting.score = $score
        $segmentLockingSetting.mtqe = @()
    }

    return $segmentLockingSetting;
}

<#
    .SYNOPSIS
    Gets the default settings for segment locking for project template creation.
#>
function Get-DefaultSegmentLockingSettings
{
    return @{
        "useAndCondition" = $false
        "translationStatuses" = @("ApprovedSignOff", "ApprovedTranslation", "Translated")
        "translationOrigins" = @("TranslationMemory", "NeuralMachineTranslation")
        "score" = "100"
        "mtqe" = @("Good")
        "targetLanguage" = ""
    }
}

function FormatHeaders 
{
    param([String] $authorizationToken)

    return @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }
}

function FormatMultiformHeaders
{
    param([String] $authorizationToken)

    return @{
        "Authorization" = "Bearer $token"
    }
}

function Get-ExportFile 
{
    param(
        [String] $authorizationToken,
        [PSOBject] $task,
        [String] $outputPath
    )

    $taskHeaders = FormatHeaders $authorizationToken;
    $taskUri = $server + "/api/tmservice/tasks/" + $task.id;
    $status = Invoke-Method { Invoke-RestMethod -Uri $taskUri -Headers $taskHeaders }
        
    while ($status.Status -eq "Queued")
    {
        Start-Sleep -Seconds 2;
        $status = Invoke-RestMethod -Uri $taskUri -Headers $taskHeaders
    }

    $output = $taskUri + "/output";
    Invoke-Method { Invoke-RestMethod -Uri $output -Headers $taskHeaders -OutFile $outputPath }
}

function FormatTMs
{
    param(
        [psobject[]] $tms
    )

    $output = @();

    foreach ($tm in $tms)
    {
        $tmModel = @{
            "uri" = FormatTMUri $tm.Name $tm.Location
            "scope" = @()
            "overrideParent" = $true
            "id" = $tm.TranslationMemoryId
        }

        $output += $tmModel;
    }

    return [psobject[]]$output;
}

function FormatTMUri 
{
    param(
        [String] $tmName,
        [String] $orgPath)

    $encodedLocation = [System.Uri]::EscapeDataString($orgPath)
    $encodedTmName = [System.Uri]::EscapeDataString($tmName)

    $url = "sdltm.$($server)?orgPath=$encodedLocation&tmName=$encodedTmName"
    return $url;
}

function Format-Termbases 
{
    param([psobject[]] $termbases)

    $output = @();

    if ($null -eq $termbases)
    {
        return $output;
    }

    foreach ($termbase in $termbases)
    {
        $output += [psobject] @{ 
            "uri" = "sdltb." + $server + "\%\" + [System.Web.HttpUtility]::UrlEncode($termbase.Name)
            "name" = $termbase.Name 
            "languages" = $termbase.Languages | ForEach-Object { @{
                "name" = $_.name
                "code" = $_.code
            } } 
        }
    }

    return $output;
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

function Get-TemplateSettingsFromPath 
{
    param (
        [String] $authorizationToken,
        [String] $templatePath
    )

    $templateExtension = ".sdltpl"

    if ($templatePath.EndsWith($templateExtension) -eq $false)
    {
        $templatePath += $templateExtension
    }

    if ($(Test-Path -Path $templatePath) -eq $false)
    {
        Write-Host "Template file does not exist at the given location" -ForegroundColor Green;
        return;
    }

    $url = $projectsTemplateEndpoint + "/querytemplatedetails"
    $headers = @{
        'Content-Type' = 'application/json'
        'Accept' = 'application/json'
        'Authorization' = "Bearer $authorizationToken"
    }

    $dataContent = Get-Content -Path $templatePath -Raw;
    $data = @{ImportedXml = $dataContent}

    return Invoke-Method { Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body ($data | ConvertTo-Json -Depth 10) }
}
 
Export-ModuleMember Get-AllTMs;
Export-ModuleMember Get-TMsByContainer;
Export-ModuleMember Get-TM;
Export-ModuleMember New-TM;
Export-ModuleMember Remove-Tm;
Export-ModuleMember Update-TM;
Export-ModuleMember Get-AllProjectTemplates;
Export-ModuleMember Get-ProjectTemplate;
Export-ModuleMember New-ProjectTemplate;
Export-ModuleMember Update-ProjectTemplate;
Export-ModuleMember Remove-ProjectTemplate;
Export-ModuleMember Export-ProjectTemplate;
Export-ModuleMember Get-AllTermbases;
Export-ModuleMember Get-Termbase;
Export-ModuleMember Import-TMX; 
Export-ModuleMember Export-TMX;
Export-ModuleMember Get-AllFieldTemplates;
Export-ModuleMember Get-FieldTemplate;
Export-ModuleMember New-FieldTemplate;
Export-ModuleMember Remove-FieldTemplate;
Export-ModuleMember Update-FieldTemplate;
Export-ModuleMember Get-LanguageDirections;
Export-ModuleMember Get-FieldDefinition;
Export-ModuleMember Get-DefaultSegmentLockingSettings;
Export-ModuleMember Get-SegmentLockingSettings;