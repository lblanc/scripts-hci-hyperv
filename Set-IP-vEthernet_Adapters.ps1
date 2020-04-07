#### SCRIPT START #####

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

$adapters = get-NetAdapter | where {$_.Name -imatch "vEthernet "}
$mask =24
$IPType = "IPv4"

function Select-Folder($message='Select a folder', $path = 0) { 
    $object = New-Object -comObject Shell.Application  
     
    $folder = $object.BrowseForFolder(0, $message, 0, $path) 
    if ($folder -ne $null) { 
        $folder.self.Path 
    } 
} 
$exportpath = Select-Folder 'Select the folder to export ip dump files' 

Get-NetIPAddress -AddressFamily IPv4 | where {$_.InterfaceAlias -imatch "vEthernet "}  | Export-Csv -Path $exportpath"\Old_iSCSI_IP.csv"

foreach ($adapter in $adapters)
{
# Remove any existing IP, gateway from our ipv4 adapter
If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
    $adapter | Remove-NetIPAddress -AddressFamily $IPType -Confirm:$false
}

If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
    $adapter | Remove-NetRoute -AddressFamily $IPType -Confirm:$false
}
$ip = [Microsoft.VisualBasic.Interaction]::InputBox("Enter IP for this adapter", $adapter.name, $ip)
$mask  = [Microsoft.VisualBasic.Interaction]::InputBox("Enter mask for this adapter", $adapter.name, $mask)


# Configure the IP address and default gateway
$adapter | New-NetIPAddress `
    -AddressFamily $IPType `
    -IPAddress $ip `
    -PrefixLength $mask `
}

Get-NetIPAddress -AddressFamily IPv4 | where {$_.InterfaceAlias -imatch "vEthernet "}  | Export-Csv -Path $exportpath"\New_iSCSI_IP.csv"


#### SCRIPT END #####