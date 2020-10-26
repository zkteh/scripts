##Orignal Author : https://gallery.technet.microsoft.com/scriptcenter/d0670079-6158-4dc5-a9da-b261c70e4b7d
##Original Author : https://www.opentechguides.com/how-to/article/powershell/131/ping-list-of-ips.html



###################
Param(
  [Parameter(Mandatory=$true, position=0)][string]$csvfile
)

$ColumnHeader = "IPAddress" 
$ipaddresses = import-excel $csvfile | Where-Object{$_.installed -eq "Y"} 

# Write-Host "Reading file" $csvfile 
# $ipaddresses = import-excel $csvfile | Where-Object{$_.installed -eq "Y"}

# Write-Host "Started Pinging.."
# foreach( $ip in $ipaddresses) {
#     if (test-connection $ip.("IP Address") -count 1 -quiet) {
#         write-host $ip.("IP Address") "Ping succeeded." -foreground green

#     } else {
#          write-host $ip.("IP Address") "Ping failed." -foreground red
#     }
    
# }

Write-Host "Pinging Completed."
#########################


# reset the lists of hosts prior to looping 
$OutageHosts = $Null 
# specify the time you want email notifications resent for hosts that are down 
$EmailTimeOut = 30  #minutes
# specify the time you want to cycle through your host lists. 
$SleepTimeOut = 5   #seconds
# specify the maximum hosts that can be down before the script is aborted 
$MaxOutageCount = 10 
# specify who gets notified 
$notificationto = "teh.zheekian@hotayi.com" 
# specify where the notifications come from 
$notificationfrom = "it.test.mail@hotayi.com" 
# specify the SMTP server 
$smtpserver = "localhost"
 
# start looping here 
Do{ 
$available = $Null 
$notavailable = $Null 
Write-Host (Get-Date) 
 
# Read the File with the Hosts every cycle, this way to can add/remove hosts 
# from the list without touching the script/scheduled task,  
# also hash/comment (#) out any hosts that are going for maintenance or are down. 
foreach( $ip in $ipaddresses)  { 
    $p = Test-Connection $ip.IPAddress  -count 1 -quiet   #-ComputerName $_ -Count 1 -ea silentlycontinue 
if($p) 
    { 
     # if the Host is available then just write it to the screen 
     write-host "Available host ---> "$ip.IPAddress  -BackgroundColor Green -ForegroundColor White 
     [Array]$available += $ip.IPAddress
    } 
else 
    { 
     # If the host is unavailable, give a warning to screen 
     write-host "Unavailable host ------------> "$ip.IPAddress -BackgroundColor Magenta -ForegroundColor White 
     $p = Test-Connection $ip.IPAddress -count 1 -quiet
     #$p = Test-Connection -ComputerName $_ -Count 1 -ea silentlycontinue 
     if(!($p)) 
       { 
        # If the host is still unavailable for 4 full pings, write error and send email 
        write-host "Unavailable host ------------> "$ip.IPAddress  -BackgroundColor Red -ForegroundColor White 
        [Array]$notavailable += $ip.IPAddress
 
        if ($OutageHosts -ne $Null) 
            { 
                if (!$OutageHosts.ContainsKey($ip.IPAddress)) 
                { 
                 # First time down add to the list and send email 
                 Write-Host "$($ip.IPAddress) Is not in the OutageHosts list, first time down" 
                 $OutageHosts.Add($ip.IPAddress,(get-date)) 
                 $Now = Get-date 
                 $Body = "$($ip.IPAddress) has not responded for 5 pings at $Now"
                Send-MailMessage -Body "$body" -to $notificationto -from $notificationfrom  -Subject "Camera $($ip.IPAddress)  is down" -SmtpServer $smtpserver 
                #   Send-MailMessage -To "jon-snow@winterfell.com" -From "mother-of-dragons@houseoftargaryen.net" `
                #    -Subject "Hey, Jon" -Body  "$($ip.IPAddress) has $Now"   -SmtpServer "localhost" -Port 25
                } 
                else 
                { 
                    # If the host is in the list do nothing for 1 hour and then remove from the list. 
                    Write-Host "$($ip.IPAddress) Is in the OutageHosts list" 
                    if (((Get-Date) - $OutageHosts.Item($ip.IPAddress)).TotalMinutes -gt $EmailTimeOut) 
                    {$OutageHosts.Remove($ip.IPAddress)} 
                } 
            } 
        else 
            { 
                #First time down create the list and send email 
                Write-Host "Adding "$ip.IPAddress " to OutageHosts." 
                $OutageHosts = @{$ip.IPAddress=(get-date)} 
                $Body = "$($ip.IPAddress) has not responded for 5 pings at $Now"  
                Send-MailMessage -Body "$body" -to $notificationto -from $notificationfrom -Subject "Camera $($ip.IPAddress)  is down" -SmtpServer $smtpserver 
                # Send-MailMessage -To "jon-snow@winterfell.com" -From "mother-of-dragons@houseoftargaryen.net" `
                #    -Subject "Hey, Jon" -Body  "$($ip.IPAddress) has $Now"   -SmtpServer "localhost" -Port 25
            }  
       } 
    } 
} 
# Report to screen the details 
Write-Host "Available count:"$available.count 
Write-Host "Not available count:"$notavailable.count 
Write-Host "Not available hosts:" 
$OutageHosts 
Write-Host "" 
Write-Host "Sleeping $SleepTimeOut seconds" 
sleep $SleepTimeOut 
if ($OutageHosts.Count -gt $MaxOutageCount) 
{ 
    # If there are more than a certain number of host down in an hour abort the script. 
    $Exit = $True 
    $body = $OutageHosts | Out-String 
    Send-MailMessage -Body "$body" -to $notificationto -from $notificationfrom -Subject "More than $MaxOutageCount Camera down, monitoring aborted"-SmtpServer $smtpServer 
} 
} 
while ($Exit -ne $True) 
 
