###############################################################################
# * Do the thing
# * 
# * Mirrors some stuff.
#
# Written and maintained by:
#  * Brian Miller (brian@phospher.com) 
###############################################################################
$VERSION="1.0"

#Dirs
$DATA_DIR = "$env:AppData\PhValheim"
$STEAM_DIR = "${env:ProgramFiles(x86)}"+"\Steam"


#Stop everything if Steam isn't installed...
if (!(Test-Path "$STEAM_DIR\steam.exe")) {
	Write-Host "Steam not found at'"$STEAM_DIR"\steam.exe', exiting..."
	exit
}


#Header message
Write-Host ""
Write-Host "#############################################################################"
Write-Host "# PhosHeim Launcher v$VERSION"
Write-Host "#"
Write-Host "#  This script will automatically download world and mod files from Phospher"
Write-Host "#  servers and keep your system in-sync with everyone else."
Write-Host "#"
Write-Host "#  This script DOES NOT modify your local install nor will it change or"
Write-Host "#  delete anything from Valheim's Steam directory."
Write-Host "#"
Write-Host "#  All files are kept in '%appdata%\PhValheim'."
Write-Host "#"
Write-Host "#  Valheim must be installed via Steam!"
Write-Host "#############################################################################"


#Check local disk for DATA_DIR
if (Test-Path $DATA_DIR) {
	#Write-Host "PhValheim directory exists..."
} else {
	New-Item $DATA_DIR -ItemType Directory
	#Write-Host "PhValheim directory does not exist, creating..."
}


#Pull all worlds and store into $WORLDS
$WORLDS = $(Invoke-RestMethod https://files.phospher.com/valheim/worlds.txt).Split("`n")


#Create useable webclient
$WebClient = New-Object System.Net.Webclient


#Generate selectable list
do {
    $index = 1
        foreach ($WORLD in $WORLDS) {
            Write-Host "[$index] $WORLD"
            $index++
        }
	Write-Host "Please make a selection. Any other key to exit: " -NoNewLine
	$Selection = Read-Host

	if (!($Selection -match "^[0-9]")) {
		Write-Host "Exiting..."
		Start-Sleep -s 3
		exit
	}
	
}
until ($WORLDS[$selection-1])
$WORLD = $WORLDS[$selection-1].Trim()

if ($Selection -eq 0) {
	Write-Host "Exiting..."
	Start-Sleep -s 3
	exit
}

#Download version of selected world
$REMOTE_WORLD_VERSION = $(Invoke-RestMethod https://files.phospher.com/valheim/$WORLD/version.txt)


#Maintenance mode check
if ($REMOTE_WORLD_VERSION -eq 0) {
	Write-Host "$WORLD is in maintenance mode, exiting..."
	Start-Sleep -s 3
	exit
}


#Check local disk for WORLD directory
if (Test-Path $DATA_DIR/$WORLD) {
	Write-Host "$WORLD directory exists..."
} else {
	Write-Host "$WORLD directory does not exist, creating..."
	$null = New-Item $DATA_DIR/$WORLD -ItemType Directory
}


#Check local disk for World files and download if missing
if (Test-Path $DATA_DIR/$WORLD/version.txt) {
	Write-Host "Local version.txt file exists for $WORLD"
} else {	
	Write-Host "Local files for $WORLD do not exist, downloading..."
	Invoke-RestMethod https://files.phospher.com/valheim/$WORLD/version.txt -OutFile $DATA_DIR/$WORLD/version.txt
	$WebClient.DownloadFile("https://files.phospher.com/valheim/$WORLD/$WORLD.zip","$DATA_DIR/$WORLD/$WORLD.zip")
	Write-Host "Extracting files for $WORLD..."
	Expand-Archive -Force -LiteralPath "$DATA_DIR/$WORLD/$WORLD.zip" -DestinationPath "$DATA_DIR/$WORLD/."
}


#Check local disk to ensure World version file downloaded, else exit.
if (!(Test-Path $DATA_DIR/$WORLD/version.txt)) {
	Write-Host "Could not download world files, exiting..."
	Start-Sleep -s 10
	exit
}


$LOCAL_WORLD_VERSION = $(Get-Content $DATA_DIR/$WORLD/version.txt)


#Check and ensure local files match remote files (download new and/or update as needed)
if ($LOCAL_WORLD_VERSION -eq $REMOTE_WORLD_VERSION) {
	Write-Host "Local($LOCAL_WORLD_VERSION) and Remote($REMOTE_WORLD_VERSION) versions match for $WORLD..."
	Write-Host "Launching Valheim with $WORLD context..."
	& "$STEAM_DIR\steam.exe" -applaunch 892970 --doorstop-enable true --doorstop-target "$DATA_DIR/$WORLD/$WORLD/BepInEx/core/BepInEx.Preloader.dll"
	
	} else {
		Write-Host "Local($LOCAL_WORLD_VERSION) and Remote($REMOTE_WORLD_VERSION) versions DO NOT match for $WORLD, updating..."
		Invoke-RestMethod https://files.phospher.com/valheim/$WORLD/version.txt -OutFile $DATA_DIR/$WORLD/version.txt
		Write-Host "Downloading updatged files for $WORLD..."
		$WebClient.DownloadFile("https://files.phospher.com/valheim/$WORLD/$WORLD.zip","$DATA_DIR/$WORLD/$WORLD.zip")
		$LOCAL_WORLD_VERSION = $(Get-Content $DATA_DIR/$WORLD/version.txt)
		
		if (!($LOCAL_WORLD_VERSION -eq $REMOTE_WORLD_VERSION)) {
			Write-Host "Could not update local world version file for $WORLD, exiting..."
			Start-Sleep -s 10
			exit
		} else {	
			Write-Host "Successfully updated local world files for $WORLD..."
			
			#Extract freshly downloaded World data and prepare to launch
			Write-Host "Removing outdates files for $WORLD..."
			Remove-Item "$DATA_DIR/$WORLD/$WORLD" -Recurse
			Write-Host "Extracting files for $WORLD..."
			Expand-Archive -Force -LiteralPath "$DATA_DIR/$WORLD/$WORLD.zip" -DestinationPath "$DATA_DIR/$WORLD/."
			Write-Host "Launching Valheim with $WORLD context..."
			& "$STEAM_DIR\steam.exe" -applaunch 892970 --doorstop-enable true --doorstop-target "$DATA_DIR/$WORLD/$WORLD/BepInEx/core/BepInEx.Preloader.dll"
		}
}

