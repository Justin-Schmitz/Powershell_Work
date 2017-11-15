 ################################## Import ActiveDirectory ##############################################

Import-Module ActiveDirectory

################################## Start Exchange PSremote Session #############################################
$URLforExchangeServerPowershellTools = Read-host "What is your Exchange URL to connect the Exchange management Tools"
$ExchPSsession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $URLforExchangeServerPowershellTools -Authentication Kerberos
Import-PSSession $ExchPSsession

Clear-host

# Gets all of the users info to be copied to the new account
#Checking the user to copy if it exist
do {
    $nameds = Read-Host "Copy From Username"
    if (dsquery user -samid $nameds){
        "AD User Found"
    }

    elseif ($nameds = "null") {
        "AD User not Found"
        }
}
while ($nameds -eq "null")

#Checking if the new user exist

do {

    $NewUserds = Read-Host "New Username"

    While ( $NewUserds -eq "" ) { 
        $NewUserds = Read-Host "New Username"
        }
    $NewUser = $Newuserds
        
    if (dsquery user -samid $NewUserds){
        "Ad User Exist"
        }

    elseif ($NewUserds = "no") {
        "Validation OK"
        }
}

while ($Newuserds -ne "no")
		
# Gets all of the users info to be copied to the new account

$name = Get-AdUser -Identity $nameds -Properties *

$DN = $name.distinguishedName
$OldUser = [ADSI]"LDAP://$DN"
$Parent = $OldUser.Parent
$OU = [ADSI]$Parent
$OUDN = $OU.distinguishedName
$NewUser = Read-Host "New Username"
$firstname = Read-Host "First Name"
$Lastname = Read-Host "Last Name"
$NewName = "$firstname $lastname"
$domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() 

# Creates the user from the copied properties

New-ADUser `
    -SamAccountName $NewUser `
    -Name $NewName `
    -GivenName $firstname `
    -Surname $lastname `
    -Instance $DN `
    -Path "$OUDN" `
    -AccountPassword (Read-Host "New Password" -AsSecureString) `
    –userPrincipalName $NewUser@$domain `
    -Company $name.Company `
    -Department $name.Department `
    -Manager $name.Manager `
    -title $name.Title `
    -Office $name.Office `
    -City $name.city `
    -PostalCode $name.postalcode `
    -Country $name.country `
    -OfficePhone $name.OfficePhone `
    -Fax $name.fax `
    -State $name.State `
    -StreetAddress $name.StreetAddress `
    -Enabled $true `
    -ChangePasswordAtLogon $true

# gets groups from the Copied user and populates the new user in them

write-host "Copying Group Membership"

$groups = (GET-ADUSER –Identity $name –Properties MemberOf).MemberOf
foreach ($group in $groups) { 

    Add-ADGroupMember -Identity $group -Members $NewUser
}
$count = $groups.count

# List of Mailbox DB

Write-host "1- Mailbox Database"
Write-host "2- Mailbox Second Storage Group"
Write-host "3- Mailbox ThirdStorage Group"
$db = read-host "Which mailbox Database 1-3 ?"

# Select case for Which Mailbox Database

switch ($db) 
    { 
        1 {$db = "Mailbox Database"} 
        2 {$db = "Mailbox Second Storage Group"} 
        3 {$db = "Mailbox Third Storage Group"} 
        default {$db = "Mailbox Third Storage Group"}
    }

# After some testing it seems that sometimes ad don't have time to process everything and while trying to access the user for exchange it gave error.

write-host "Waiting 15 seconds for Active Directory to process earlier operations"

Start-Sleep -s 15

# Creates the New users mailbox 

Enable-Mailbox -Identity $NewUser@$domain -alias "$firstname.$Lastname" -Database CallCentre

# Sets secondary smtp adress while specifying the Primary smtp address(1st address with the SMTP is the primary one).

Start-Sleep -s 15

Set-Mailbox "$firstname.$Lastname" `
    -EmailAddressPolicyEnabled $false `
    -EmailAddresses SMTP:"$firstname.$Lastname@yourCompanyName.com"

# Creates the New user personal Folder and permission
#pathToNetowrkDrive
New-Item -type directory "\\#pathToNetowrkDrive\$NewUser"
$Right = "FullControl"
$Acl = Get-Acl "\\$pathToNetowrkDrive\$NewUser"
$Ar = New-Object system.security.accesscontrol.filesystemaccessrule($NewUser,$Right,"Allow")
$Acl.AddAccessRule($Ar)
Set-Acl "\\$pathToNetowrkDrive\$NewUser" $Acl
$pathToRoamingProfile
New-Item -type directory "\\$pathToRoamingProfile\$NewUser"
$Right = "FullControl"
$Acl = Get-Acl "\\$pathToRoamingProfile\$NewUser"
$Ar = New-Object system.security.accesscontrol.filesystemaccessrule($NewUser,$Right,"Allow")
$Acl.AddAccessRule($Ar)
Set-Acl "\\$pathToNetowrkDrive\$NewUser" $Acl