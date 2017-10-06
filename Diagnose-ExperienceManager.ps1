Param(
    [string]$cmsUrl = "http://sdlweb",
    [string]$pageId = "tcm:5-238-64",  # TODO: support WebDAV URL
    [string]$pageTemplateId = "tcm:5-193-128",  # TODO: determine from Page (using Core Service)
    [ValidateScript({Test-Path $_ -PathType 'Container'})] 
    [string]$ServicesPath='C:\SDLServices\',
    [string]$PreviewStorageConfig=$ServicesPath + 'Preview\config\cd_storage_conf.xml',
    [string]$ContentStorageConfig=$ServicesPath + 'StagingContent\config\cd_storage_conf.xml'


)

"The journey begins... "

$scriptPath = Split-Path $script:MyInvocation.MyCommand.Path

$sessionToken = (& "$scriptPath\Start-PreviewSession.ps1" -cmsUrl $cmsUrl -pageId $pageId -pageTemplateId $pageTemplateId)

& "$scriptPath\Diagnose-PreviewDatabase.ps1" -ServicesPath $ServicesPath -token $sessionToken -PreviewStorageConfig $PreviewStorageConfig -ContentStorageConfig $ContentStorageConfig
