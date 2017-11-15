<#      
        A pure and utter vanity project...
        1st day of March, in the year of our Lord, 2017
        Written with passion and deep man love care by The right honerable member, Justin
        This will let you
        - Allow self signed Certs sessions to the A10 via Powershell
        - Get a token for the API session
        - Get you a session ID
        - choose an Active Partition on the A10 Load Balancer
        - Choose the service group
        - Get you the servers within the Service Group
        - Choose the server(s) to disable
        This works... As long as you are using Least Connection
        I will work on getting the connection type passed through with the variable when I get a moment 
        Feedback welcomed and encouraged. 
        Let me know if you need anything else with the A10 API calls available..

        As always, let the script do the heavy lifting, freeing up some time for coffee!!
#>
##########################Allow self signed Certs##########################
$A10AuthConnectionURL = Read-Host "What is your A10 API endpoint connection URL with Name and password in String?"
$A10URL = Read-Host "What is your Base A10 URL, eg. https://A10"
$url = "$A10AuthConnectionURL"
$web = New-Object Net.WebClient
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true } 
$output = $web.DownloadString($url)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null   

##########################Get session ID##########################
$getsessionID = Invoke-WebRequest -Uri "$A10AuthConnectionURL" -Method Get -Verbose
#Get the session ID with Regex
$pattern = "(?<=\<session_id\>)(.*?)(?=\<\/session_id)"
$result = [regex]::match($getsessionID, $pattern).Groups[1].Value

###########################Select Active Partition##########################
$Get_Partition = Invoke-RestMethod "$A10URL" + "/" + "services/rest/V2.1/?session_id=$($result)&format=json&method=system.partition.getAll" -Verbose
$Select_Partition = $Get_Partition.partition_list.name | Out-GridView -PassThru -Verbose
$Active_Partition = @{
    name = "$Select_Partition"
}
Invoke-RestMethod "$A10URL" + "/" + "services/rest/V2.1/?session_id=$($result)&format=json&method=system.partition.active" -Body $Active_Partition -Verbose

########################### Select Server Group in Active Partition ##########################
$Get_ServerGroups = Invoke-RestMethod "$A10URL" + "/" + "services/rest/V2.1/?session_id=$($result)&format=json&method=slb.service_group.getAll" -Verbose

$Select_ServerGroup = $Get_ServerGroups.service_group_list.name | Out-GridView -PassThru -Verbose
$getgroupmembers = @{name=$Select_ServerGroup} | ConvertTo-Json -Verbose

########################### Select Servers within Server Group ##########################
$Get_ServerGroupsMembers = Invoke-RestMethod "$A10URL" + "/" + "services/rest/V2.1/?session_id=$($result)&format=json&method=slb.service_group.search" -Body $getgroupmembers -Method Post -Verbose

$Server_within_groups = $Get_ServerGroupsMembers.service_group.member_list | Out-GridView -PassThru -Verbose

########################### Select Which Servers to disable within group ##########################

$Server_within_groups | ForEach-Object{$_.status = 0}
$server_groups_converted_JSON = $Server_within_groups | ConvertTo-Json -Verbose

                                        
##########################Body of call to disable servers##########################


$Server_Set_To_Disabled = @"
{
    "service_group":  {
                        "lb_method":  2,
                          "member_list": [ 
                                        $server_groups_converted_JSON
                                         ]
                      },
                       "name":  "$Select_ServerGroup",
                          "protocol":  2
}
"@ | ConvertFrom-Json | ConvertTo-Json -Depth 20 -Verbose

##########################Body of call to disable servers##########################

$Check_my_Ass = Invoke-RestMethod "$A10URL" + "/" + "services/rest/V2.1/?session_id=$($result)&format=json&method=slb.service_group.update" -Body $Server_Set_To_Disabled -Method Post -Verbose
$Check_my_Ass

########################## Save New Config to confirm ##########################

$Save_my_Changes = Invoke-RestMethod "$A10URL" + "/" + "services/rest/V2.1/?session_id=$($result)&format=json&method=system.action.write_memory"
$Save_my_Changes