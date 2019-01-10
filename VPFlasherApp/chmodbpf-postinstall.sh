#!/bin/sh

# Original Copyright 1998-2019 Gerald Combs <gerald@wireshark.org> and Wireshark contributors
# Copyright 2019 Travis Johnson <johnsontravis21@gmail.com>

# The following code is a derivative work of the code from the Wireshark project, 
# which is licensed GPLv2. This code therefore is also licensed under the terms 
# of the GNU Public License, verison 2.
# https://github.com/wireshark/wireshark/blob/master/packaging/macosx/Scripts/chmodbpf-postinstall.sh

#
# Fix up ownership and permissions on /Library/Application Support/com.bashtheshell.macos.vpflasher;
# for some reason, it's not being owned by root:wheel, and it's not
# publicly readable and, for directories and executables, not publicly
# searchable/executable.
#
# Also take away group write permission.
#
# XXX - that may be a problem with the process of building the installer
# package; if so, that's where it *should* be fixed.
#

chown -R root:wheel "/Library/Application Support/com.bashtheshell.macos.vpflasher"
chmod -R a+rX,go-w "/Library/Application Support/com.bashtheshell.macos.vpflasher"

CHMOD_BPF_PLIST="/Library/LaunchDaemons/com.bashtheshell.ChmodBPF.plist"
BPF_GROUP="access_bpf"
BPF_GROUP_NAME="BPF device access ACL"

dscl . -read /Groups/"$BPF_GROUP" > /dev/null 2>&1 || \
    dseditgroup -q -o create "$BPF_GROUP"
dseditgroup -q -o edit -a "$USER" -t user "$BPF_GROUP"

cp "/Library/Application Support/com.bashtheshell.macos.vpflasher/ChmodBPF/com.bashtheshell.ChmodBPF.plist" \
    "$CHMOD_BPF_PLIST"
chmod u=rw,g=r,o=r "$CHMOD_BPF_PLIST"
chown root:wheel "$CHMOD_BPF_PLIST"

rm -rf /Library/StartupItems/ChmodBPF

launchctl load "$CHMOD_BPF_PLIST"
