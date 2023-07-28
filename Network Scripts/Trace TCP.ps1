$connections = @{
    "LB-444" = "10.30.172.200:444"
    "LB-29912" = "10.30.172.200:29912"
    #"UPS-Node1-444" = "10.30.172.143:444"
    #"UPS-Node2-444" = "10.30.172.144:444"
    "UPS-Node3-444" = "10.30.172.145:444"
    #"UPS-Node1-29912" = "10.30.172.143:29912"
    #"UPS-Node2-29912" = "10.30.172.144:29912"
    "UPS-Node3-29912" = "10.30.172.145:29912"
}

$logfile = "c:\Tmp\tcpLog\connection_log.csv"

while ($true) {
    $date = Get-Date -Format 'yyyy-MM-dd - HH:mm:ss:ff'
    foreach ($connection in $connections.GetEnumerator()) {
        $name = $connection.Key
        $hostaddr, $port = $connection.Value.Split(":")
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connectionResult = $null

        try {
            $connectionResult = $tcpClient.BeginConnect($hostaddr, $port, $null, $null)
            $wait = $connectionResult.AsyncWaitHandle.WaitOne(100)
        
            if ($wait -and $tcpClient.Connected) {
                $message = "$date - INFO:  TCP connection to; $hostaddr; $name; Port $port; is successful" 
                
                foreach ($element in $message) {
                    $msg = $element.Split(";")
                    write-host ("| {0,20}  | {1,-12}  | {2,-20} |  {3,-13} | {4,-14}  |" -f $msg)
                    "| {0,20} | {1,-12}  | {2,-20}  | {3,-13} |  {4,-14} |" -f $msg | Out-File -FilePath $logfile -Append
                }

            } else {
                $message = "$date - INFO:  TCP connection to; $hostaddr; $name; Port $port; failed"
 
                foreach ($element in $message) {
                    $msg = $element.Split(";")
                    write-host ("| {0,20}  | {1,-12}  | {2,-20} |  {3,-13} | {4,-14}  |" -f $msg)
                    "| {0,20} | {1,-12}  | {2,-20}  | {3,-13} |  {4,-14} |" -f $msg | Out-File -FilePath $logfile -Append
                }
                $tcpClient.Close()
            }
        } catch {
            $errorMessage = "An error occurred while checking TCP connection to $name ($hostaddr) on port $port $_"
            Write-host $errorMessage
            $errorMessage | Out-File -FilePath $logfile -Append
        } 
      
    }

    Start-Sleep -Seconds 1
}
