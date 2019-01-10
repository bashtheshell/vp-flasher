#!/usr/bin/env bash

### File name: build_deploy_script.sh
### Author: Travis Johnson
### Date last modified: 02/17/2019
### GNU Bash: 3.2.57

exitIfFailed() {
    if [ $? -ne 0 ]; then
        echo "+ Error has occurred. This script will now exit."
        exit 1
    fi
}

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

# check if the 'Packages - WhiteBox' app is installed.
if [ ! -d '/Applications/Packages.app' ]; then
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    echo "+ You do not have the 'Packages' app installed. Please install the 'Packages - WhiteBox' app."
    echo "+ Here's the download link: http://s.sudre.free.fr/Software/files/Packages.dmg"
    echo "+ This script will now exit."
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    exit 1
fi

# remove directory if existed without warning
echo "+++ Removing '/tmp/VPFlasherApp' directory..."
rm -vrf /tmp/VPFlasherApp

# change to building directory
echo "+++ Copying and changing to '/tmp/VPFlasherApp' directory. Script must run from current directory..."
cp -r ./VPFlasherApp /tmp/
exitIfFailed
cd /tmp/VPFlasherApp


# create virtual environment and source it
echo "+++ Create and source the virtual environment in '/tmp/VPFlasherApp' directory..."
$pythonExecPath$pythonExecFile -m venv venv
exitIfFailed
source /tmp/VPFlasherApp/venv/bin/activate

# install py2app and scapy
echo "+++ Upgrading pip..."
pip install --upgrade pip
exitIfFailed
echo "+++ Install latest version of py2app and scapy modules..."
pip install py2app scapy
exitIfFailed

# update the app version number
appVersion="$(basename /tmp/VPFlasherApp/VPFlasher* | sed 's/^.*_//' | sed 's/.py$//' )"
sed -i.bkup 's/^APP_VERSION=.*$/APP_VERSION="'"${appVersion}"'"/' /tmp/VPFlasherApp/setup.py
exitIfFailed

# build the app
echo "+++ Building the standalone bundled app from the source code..."
cp "/tmp/VPFlasherApp/VPFlasher_$appVersion.py" /tmp/VPFlasherApp/VPFlasher.py
exitIfFailed
python setup.py py2app
exitIfFailed

# set the build version and build the installation package
echo "+++ Building installer package..."
/usr/local/bin/packagesutil set project name "VPFlasher_$appVersion" --file /tmp/VPFlasherApp/vpflasher.pkgproj
exitIfFailed
/usr/local/bin/packagesutil set package-1 version "$appVersion" --file /tmp/VPFlasherApp/vpflasher.pkgproj
exitIfFailed
/usr/local/bin/packagesbuild -v /tmp/VPFlasherApp/vpflasher.pkgproj
exitIfFailed

# copy the package to original directory the script was run from
cp "/tmp/VPFlasherApp/pkg-build-dir/VPFlasher_$appVersion.pkg" $originalDir
exitIfFailed

# clean up build folder and deactivate virtual environment
echo "+++ Cleaning up before exiting script..."
deactivate
cd $originalDir
rm -rf /tmp/VPFlasherApp

