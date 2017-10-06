param(
[string]$PreviewStorageConfig,
[string]$ContentStorageConfig,
[string]$token
)


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

if ($token) {
$RecordsFound = Count-MatchingRecords "SELECT PREVIEW_SESSION_ID FROM PREVIEW_SESSIONS WHERE PREVIEW_SESSION_ID = '$token'"

    if ($RecordsFound -lt 1) {
        "Checked for PREVIEW_SESSIONS record matching your token: $token. None found. You have a problem... maybe"
    }
}

Execute-Query "SELECT * from PREVIEW_SESSIONS"

$Conn.Close()

