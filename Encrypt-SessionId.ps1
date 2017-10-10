Param(
    [string]$sessionId='eefdf6e3-2d53-4c4e-8e5c-8f24899db44b',
    [string]$cdCoreJar='cd_core-8.5.0-1011.jar',
    [string]$cdCommonUtilJar='cd_common_util-8.5.0-1009.jar'
)

# For now encrypting is enough, and it seems we can use standard Tridion utilities for this. 
# For source material on this technique please see https://docs.sdl.com/LiveContent/content/en-US/SDL%20Web-v5/GUID-C62C8F86-9EE0-4BAB-A2CD-40F696D2FFBD
# If we could figure out how to decrypt a Token to an Id, that would be even better, but might call security into question if we managed it!!


$scriptPath = Split-Path $script:MyInvocation.MyCommand.Path

pushd $scriptPath

# Validation attributes only work on parameter values that get passed. We want to cover the provided defaults too

if (-not ((Test-Path -Path $cdCoreJar) -and (Test-Path -Path $cdCommonUtilJar))) {
    popd
    throw "Please ensure that the cd_core-BUILD.jar and cd_common_util-BUILD.jar are present in the same folder as this script"
}

$encryptedString = java -cp "$cdCoreJar;$cdCommonUtilJar" com.tridion.crypto.Encrypt $sessionId
$encryptedString.SubString('SDL Web configuration value = encrypted:'.Length)

popd