$mac_array = @()
$array1 = @()
$nic_num = 1


$array1 = Import-Csv -path 'C:\Users\jgalvin.DODIARANGE\Documents\ScriptRepo (vandelay)\galvin\ip_change.csv'


$GuestUser=Read-Host -Prompt "What is the Guest Username for the machines?"
$GuestPass=Read-Host -Prompt "What is the Guest Password for the machines?" -AsSecureString

#loop


for ($i=0; $i -lt $array1.Length; $i++){
    
    #if the VM name is blank then we are assuming this is now for another NIC for the same machine. And assign prior vm_name.
    if ($array1[$i].vm_name.Equals("")){
    
        Write-Host "Configuring next NIC on the same VM"
        $nic_num++
    #keeps vm name for multi-nic runs
        $array1[$i].vm_name = $array1[($i - 1)].vm_name
        
    } else {
    #resets back to 1 to be ready for the next new machine
        $nic_num = 1

    }
    write-host "nic number is" $nic_num

    #if first time running against VM, copy the required script over.
    #and/or get MAC's
    if ($nic_num -eq 1){

        write-host "copying required script file to VM " $array1[$i].vm_name
        copy-vmguestfile -source C:\Users\jgalvin.DODIARANGE\Documents\change_ip.sh -Destination /var/ -vm $array1[$i].vm_name -LocalToGuest -force -GuestUser $GuestUser -GuestPassword $GuestPass -Verbose

        Clear-Variable mac_array
        $mac_array = Get-NetworkAdapter -vm $array1[$i].vm_name | select-object MacAddress

    }

    Write-Host "mac address for vm" $mac_array[($nic_num - 1)].MacAddress
    Write-Host "mac list length is" $mac_array.length
    write-host "nic num is:" $nic_num
    write-host "nic num -1 is:" ($nic_num - 1)
    write-host "name of the VM getting modified is " $array1[$i].vm_name

    #/change_ip.sh <interface_name/mac> <ip-addr> <netmask> <gateway>
    #need to still get MAC

    $code = "chmod +x /var/change_ip.sh; /var/change_ip.sh -a " + $mac_array[($nic_num - 1)].MacAddress + " -b " + $array1[$i].new_ip + " -c " + $array1[$i].new_nm + " -d " + $array1[$i].new_gw + " -e " + $nic_num

    Write-Host "the code being sent is: " $code

    Invoke-VMScript -VM $array1[$i].vm_name -ScriptType bash -ScriptText $code -GuestUser $GuestUser -GuestPassword $GuestPass -Verbose

    #Invoke-VMScript -VM "$array1[$i].vm_name" -ScriptType bash -ScriptText "/change_ip.sh eth0 10.10.33.33 255.255.255.0 10.10.33.1 1" -GuestUser $GuestUser -GuestPassword $GuestPass

    write-host "full array is: " $array1[$i]

}

#get MAC for interfaces for the VM.
#actually, getting the network interfaces gives us a list including a count, we can use that to specify how many times the loop should run for, for each VM. - not doing this yet.
#if we have this seperate and split can run items in parallel

function GET_MAC {

    $mac_array = Get-NetworkAdapter -vm $array1[$i].vm_name | select-object MacAddress

    Write-Host "mac address for vm" $mac_array[$i].MacAddress
    Write-Host "mac list length is" $mac_array.length

}