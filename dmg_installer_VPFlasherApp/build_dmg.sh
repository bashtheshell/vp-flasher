#!/usr/bin/env bash

### Script to beautifully create the .dmg image
###
### File name: build.sh
### Author: Travis Johnson
### Date last modified: 02/21/2019
### GNU Bash: 3.2.57
###

exitIfFailed() {
    if [ $? -ne 0 ]; then
        echo "+ Error has occurred. This script will now exit."
        exit 1
    fi
}

# expected to be run in './dmg_installer_VPFlasherApp/' directory
echo "+++ Checking if current directory is './dmg_installer_VPFlasherApp/' ..."
currentdir="$(basename $PWD)"
if [ $currentdir != "dmg_installer_VPFlasherApp" ]; then
    /usr/bin/false # to trigger the next line to run
    exitIfFailed
fi

originalDir="$PWD"
pythonExecPath=''
pythonExecFile='/bin/python[1-9]'
pythonVersion=''

# check if the appropriate Python.org's Python version is installed:
if [ -d '/Library/Frameworks/Python.framework/Versions' ]; then
    pythonExecPath="$(ls -ld /Library/Frameworks/Python.framework/Versions/* | tail -n 1 | awk '{ print $NF }')"
    pythonVersion="$(echo "$($pythonExecPath$pythonExecFile --version)" | awk '{ print $NF }')"
    if [[ "$pythonVersion" < "3.7.0" ]]; then
        echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
        echo "+ You have older version of Python installed. This script requires verison 3.7 or higher."
        echo "+ Please download the latest version of Python from python.org and then re-run this script."
        echo "+ This script will now exit."
        echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
        exit 1
    fi
else
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "+ It appears you do not have Python (from Python.org) installed on your machine."
    echo "+ Please visit python.org and download the latest Python using binary installer. Thank you."
    echo "+ This script will now exit."
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    exit 1
fi

# remove file and directories if existed without warning
echo "+++ Removing './build-app-dir/' directory if existed..."
if [ -d './build-app-dir/' ]; then
    rm -vrf ./build-app-dir/ ./app-folder
    mkdir -v ./build-app-dir/
else
    mkdir -v ./build-app-dir/
fi

# change to building directory
echo "+++ Changing to '/build-app-dir/' directory..."
cp -r ../VPFlasherApp/ ./build-app-dir/
exitIfFailed
cd ./build-app-dir/

# create virtual environment and source it
echo "+++ Create and source the virtual environment in './build-app-dir/' directory..."
$pythonExecPath$pythonExecFile -m venv venv
exitIfFailed
source ./venv/bin/activate

# install py2app and scapy
echo "+++ Upgrading pip..."
pip install --upgrade pip
exitIfFailed
echo "+++ Install latest version of py2app and scapy modules..."
pip install py2app scapy
exitIfFailed

# update the app version number
appVersion="$(basename ./VPFlasher* | sed 's/^.*_//' | sed 's/.py$//' )"
sed -i.bkup 's/^APP_VERSION=.*$/APP_VERSION="'"${appVersion}"'"/' ./setup.py
exitIfFailed

# build the app
echo "+++ Building the standalone bundled app from the source code..."
cp "./VPFlasher_$appVersion.py" ./VPFlasher.py
exitIfFailed
python setup.py py2app
exitIfFailed

# move app and clean up environment
echo "+++ Moving app and cleaning up virtual environment..."
mkdir -v ../app-folder
mv -v ./dist/VPFlasher.app/ ../app-folder
deactivate
cd ..
rm -vrf ./build-app-dir/

# build the DMG installer
echo "+++ Building the DMG installer for VPFlasher app..."

test -f VPFlasher-Installer.dmg && rm VPFlasher-Installer.dmg
create-dmg \
--volname "VPFlasher Installer" \
--volicon "_icon.icns" \
--background "_background.png" \
--window-pos 200 120 \
--window-size 800 400 \
--icon-size 100 \
--icon "VPFlasher.app" 200 190 \
--hide-extension "VPFlasher.app" \
--app-drop-link 600 185 \
"VPFlasher-Installer.dmg" \
"app-folder/"

