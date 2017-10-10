param(
[ValidateScript({Test-Path $_ -PathType 'Leaf'})] 
[string]$PreviewStorageConfig,
[ValidateScript({Test-Path $_ -PathType 'Leaf'})]
[string]$ContentStorageConfig,
[ValidateNotNullOrEmpty()]
[string]$token
)


$scriptPath = Split-Path $script:MyInvocation.MyCommand.Path

$PreviewStorageDom = [xml](gc $PreviewStorageConfig)

$sessionWrapperXPath = "Configuration/Global/Storages/Wrappers/Wrapper/Storage[1]"
$SessionWrapperSelect = Select-Xml -Xml $PreviewStorageDom -XPath $sessionWrapperXPath
if ($SessionWrapperSelect.Node -eq $null) {
    "Unable to locate Session wrapper storage config for your Preview Service. This is sufficient reason for XPM to function incorrectly"
    exit
} else {
    $SessionWrapper = $SessionWrapperSelect.Node
}

$ContentStorageDom = [xml](gc $ContentStorageConfig)
$ContentSessionWrapperSelect = Select-Xml -Xml $ContentStorageDom -XPath $sessionWrapperXPath

if ($ContentSessionWrapperSelect.Node -eq $null) {
    "Unable to locate Session wrapper storage config for your Content Service. This is sufficient reason for XPM to function incorrectly"
    exit
}

$DbServerName = (Select-Xml -Xml $SessionWrapper -XPath "DataSource/Property[@Name='serverName']").Node.Value
$DbPortNumber = (Select-Xml -Xml $SessionWrapper -XPath "DataSource/Property[@Name='portNumber']").Node.Value
$DbDatabaseName = (Select-Xml -Xml $SessionWrapper -XPath "DataSource/Property[@Name='databaseName']").Node.Value
$DbUser = (Select-Xml -Xml $SessionWrapper -XPath "DataSource/Property[@Name='user']").Node.Value
$DbPassword = (Select-Xml -Xml $SessionWrapper -XPath "DataSource/Property[@Name='password']").Node.Value

$connStringBuilder = new-object System.Data.SqlClient.SqlConnectionStringBuilder
$connStringBuilder["Data Source"] = $DbServerName
$connStringBuilder["Initial Catalog"] = $DbDatabaseName
$connStringBuilder["User ID"] = $Dbuser
$connStringBuilder["Password"] = $DbPassword

$conn = new-object System.Data.SqlClient.SqlConnection
$conn.ConnectionString = $connStringBuilder.ConnectionString
#TODO - catch here and give a message 
$conn.Open()

$comm = new-object System.Data.SqlClient.SqlCommand
$comm.CommandText = "SELECT PREVIEW_SESSION_ID, EXPIRATION_DATE FROM PREVIEW_SESSIONS"
$comm.CommandType = "Text"
$comm.Connection = $conn

$reader = $comm.ExecuteReader() 
$foundCount = 0
while ($reader.Read()){
     $sessionId = $reader.GetString(0) 
     $expirationDate = $reader.GetDateTime(1)

     $sessionToken = (& $scriptPath\Encrypt-SessionId -SessionId $sessionId)
     if ($sessionToken -eq $token) {
        if ($foundCount++ -lt 1) {
            "Matching session record found. All is well with the world."
        }
        "$sessionToken`t$sessionId`t$expirationDate"
     }
} 
$reader.Close()
if ($foundCount -lt 1) {
    "No matching session found. Back to the drawing board"    
}


$Conn.Close()

