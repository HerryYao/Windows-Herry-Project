#Version <0.1.1> Beta
#This part is for upgrade Windows to specific version:
#usrchosever variable is for storing the value of versions which usr chose
#vervalue contains number to winver
Write-Host "Windows Server 2012 R2 Datacenter [End Support in 2026] = 0
Windows Server 2022 Datacenter [End Support in 2026] = 1
Windows Server 2019 Datacenter [End Support in 2029] = 2
Windows 11 IoT Enterprise 22H2 [End Support in 2025] = 3
Windows 10 IoT Enterprise 22H2 [End support in 2025] = 4"
$VerValue = @{"0" = "WINSVR2012R2DC"; "1" = "WINSVR2022DC"; "2" = "WINSVR2019DC"; "3" = "WIN11IOTENT"; "4" = "WIN10IOTENT"}
$USRChoseVer = Read-Host "Tell me which version you want to activate(Enter number)"
#If in hashtable $vervalue contains key value of "$usrchosever" = True
if ($VerValue.ContainsKey($USRChoseVer)) {
    $VerValueName = $VerValue[$USRChoseVer]
    Write-Host "You have chose $VerValueName.
NOTE: Use X64 version."
    Read-Host "Please mount your Original Windows ISO image before next step, press Enter to continue"
} else {
    Write-Host "No such Windows version available, try again."
    Start-Sleep -Seconds 10
    exit 0
}
$ISOMountPath = Read-Host "Enter your Original ISO's mount point(A letter)"
#WININFO
if ($USRChoseVer -eq "0" -or $USRChoseVer -eq "1" -or $USRChoseVer -eq "2") {
    $ExportIndex = "4"
    $SetEdition = "ServerDatacenter"
}
if ($USRChoseVer -eq "3" -or $USRChoseVer -eq "4") {
    $ExportIndex = "3"
    $SetEdition = "IoTEnterprise"
}
#/WININFO
if (Test-Path -Path $ISOMountPath":\sources\sxs") {
    $WIMMountPath = Read-Host "
NOTE: Make sure you have right access permisson of that drive,
drive which wim will be mounted must be NTFS formated,
and make sure it has at least 15GB free space.
Detected mounted ISO, Where do you want to mount wim image?
Type a drive letter which is not same as mounted ISO's.
It will create a folder called 'wim' inside that drive" 
    if (Test-Path -Path $WIMMountPath":\wim") {
        Write-Host "Error, delete previous wim folder and try again."
        Read-Host "Exit?"
        exit 0
    }
    New-Item -ItemType Directory -Path $WIMMountPath":\wim\iso\tmp" -Force | Out-Null
    Write-Host "Running... it may take a while"
    Read-Host "During excute, please close explorer window, if you see error out put, it means script failed. 
    Enter to continue"
    If (Test-Path -Path $ISOMountPath":\sources\install.wim") { #Check is this wim or esd
        $Wim = "install.wim"
    } else {
        $Wim = "install.esd"
    }
    Copy-Item $ISOMountPath":\*" -Exclude $Wim -Destination $WIMMountPath":\wim\iso" -Recurse
    Write-Host "Copied ISO files..."
    Export-WindowsImage -SourceImagePath $ISOMountPath":\sources\$Wim" -SourceIndex $ExportIndex -DestinationImagePath $WIMMountPath":\wim\install.wim" -DestinationName $vervaluename -CompressionType Max
    Write-Host "Exported wim image..."
    Mount-WindowsImage -ImagePath $WIMMountPath":\wim\install.wim" -Index 1 -Path $WIMMountPath":\wim\iso\tmp"
    Write-Host "Mounted wim image..."
    Set-WindowsEdition -Path $WIMMountPath":\wim\iso\tmp" -Edition "$SetEdition"
    Write-Host "UPGRADED YOUR WINDOWS..."
    Dismount-WindowsImage -Path $WIMMountPath":\wim\iso\tmp" -Save
    Write-Host "Dismounted wim image..."
    Move-Item -Path $WIMMountPath":\wim\install.wim" -Destination $WIMMountPath":\wim\iso\sources"
    Remove-Item -Path $WIMMountPath":\wim\iso\tmp"
    if (Test-Path -Path $WIMMountPath":\wim\iso\sources\pid.txt") {
        Remove-Item -Path $WIMMountPath":\wim\iso\sources\pid.txt"
    }
    Write-Host "Packing ISO..."
    $WIMMountPathPlus = "${WIMMountPath}:\"
    $CurrentLocation = Get-Location
    Start-Process -FilePath "$CurrentLocation\oscdimg.exe" -ArgumentList "-b$CurrentLocation\efisys.bin -pEF -u2 -udfver102 ${WIMMountPathPlus}wim\iso ${WIMMountPathPlus}\YourUpgradedWindows.iso"
    Write-Host "After OSCDIMG finishes, activated ISO will be on ${WIMMountPath}:\, remember you can report bugs on github."
    Read-Host "Confirm exit?"
    exit 0
} else {
    Write-Host "Failed, I said enter an ISO's mount point (A letter)."
    Start-Sleep -Seconds 10
    exit 0
}
#This part ends.