param(
[ValidateScript({Test-Path $_ -PathType 'Container'})] 
[string]$ServicesPath='C:\SDLServices\',
[string]$PreviewStorageConfig=$ServicesPath + 'Preview\config\cd_storage_conf.xml'
)


$PreviewStorageDom = [xml](gc $PreviewStorageConfig)

$SessionWrapperXPath = Select-Xml -Xml $PreviewStorageDom `
                                -XPath "Configuration/Global/Storages/Wrappers/Wrapper/Storage[@Id='sessionDb']"
if ($SessionWrapperXPath.Node -eq $null) {
    "Unable to locate Session wrapper storage config for your Preview Service. This is sufficient reason for XPM to function incorrectly"
    exit
} else {
    $SessionWrapper = $SessionWrapperXPath.Node
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
$conn.Open()

function Count-MatchingRecords ($query){
  $comm = new-object System.Data.SqlClient.SqlCommand
  $comm.CommandText = $query
  $comm.CommandType = "Text"
  $comm.Connection = $conn
  $comm.ExecuteNonQuery() 
}  

function Execute-Query ($query){
  $comm = new-object System.Data.SqlClient.SqlCommand
  $comm.CommandText = $query
  $comm.CommandType = "Text"
  $comm.Connection = $conn
  
  $reader = $comm.ExecuteReader() 
  while ($reader.Read()){
    $result = $tabs = ""
     for ($i = 0;$i -lt $reader.FieldCount; $i++){
       $result += "$tabs{0}" -f $reader.GetValue($i) 
       $tabs = "`t`t`t"
     }
     $result
  } 
  $reader.Close()
}

$RecordsFound = Count-MatchingRecords "SELECT PREVIEW_SESSION_ID FROM PREVIEW_SESSIONS WHERE PREVIEW_SESSION_ID = '$token'"

if ($RecordsFound -lt 1) {
    "You are hosed, give up now"
}

Execute-Query "SELECT * from PREVIEW_SESSIONS"

$Conn.Close()

