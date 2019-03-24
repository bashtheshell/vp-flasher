# VP-Flasher
An extensible videophone notification app that can either flash widget on screen or through LED light (e.g. [blink(1)](https://blink1.thingm.com/)).

## What's VP?

Simply put. Videophones operate like any phone except they come with embedded video support. Please see [here](https://en.wikipedia.org/wiki/Videotelephony) for more information.

## What's New? (CHANGELOG)

- (v1.0.0) Support for [blink(1)](https://blink1.thingm.com/) USB notification LED light is finally here! 😃

## Motivation

As most projects you'd find on GitHub, this was inspired by repetitive issues I encountered at work. There was a need to have an alert that's visibly blaring and captivating while briefly glancing away from the screen. It's expected that everyone experiences interruptions and distractions at work, which is an inevitable part of life. Even at homes, we humans can get carried away.

This app is simply an add-on to improve or make current notification system extensible. Like many products we'd find on the market, we'd wish for improvements that can be made as soon as possible if they're not meeting our expectations. Some of us can only do so much to improve the products

In this case, I have thought outside the box and came up with a solution using what's publicly available to us. The videophone software in question uses certain communication protocols that can be observed using packet analyzer. By employing on network traffic filtration, it's feasible to develop a program that would react to certain traffic passing.

This project also became a proof-of-concept as a proposed solution for other similar proprietary videophone software.

## Demonstration

Here's a brief demo (about 30 seconds long) of the app flashing on screen along with the blinking USB notification light when receiving a call through the videophone software.<sup>[1](#disclaimer)</sup>

<a href="http://www.youtube.com/watch?feature=player_embedded&v=AGXSad484Qc" target="_blank"><img src="http://img.youtube.com/vi/AGXSad484Qc/1.jpg" alt="VPFlasher Demo - YouTube Video" width="240" height="180" border="10" /></a>

<br>

## Quick Start

Assuming you're running the videophone software (as the one shown in the demonstration) already, you can simply download the lastest VPFlasher package from the [Releases page](https://github.com/bashtheshell/vp-flasher/releases
) and run the installer on macOS. The app is not compatible with other platforms at this time.

Once the app is installed, you can find the VPFlasher app in the *Applications* folder. Once you double-click the icon, the app would run continuously until you quit the app.

To see it in action, you must receive an incoming call through the videophone software.

<br>

## Not So Quick (for advanced users only)

### Requirements (for building app from source code):

- **Operating System:** macOS 10.11 (El Capitan) or higher
- **Videophone Software:** [Convo for macOS](https://www.convorelay.com/macos)<sup>[1](#disclaimer)</sup> (tested with v3.0.23)
- **Installer Creator:** [Packages - WhiteBox](http://s.sudre.free.fr/Software/Packages/about.html) (tested with v1.2.5)
- **Python Version:** 3.7 or higher
- **Sensory Loss:** Hearing loss

It's highly recommended to install the latest version of Python 3 (must be greater than or equal to 3.7) using the binary installer for macOS from [python.org](https://www.python.org/) as it comes with Tcl/Tk 8.6 included, a required dependency for the VPFlasher app. This should not interfere with the default system Python. Also, `pip` and `pyvenv` are also shipped with it.

Once Python is installed, the following path should exist where you'll find the necessary Python version (3.7 is used here): `/Library/Frameworks/Python.framework/Versions/3.7/bin/`

###### <a name="disclaimer">1</a>: DISCLAIMER - This GitHub repository is not affiliated, associated, authorized, endorsed by, or in any way officially connected with Convo Communications, LLC, or any of their subsidiaries or affiliates. All product and company names are the registered trademarks of their original owners. The use of any trade name or trademark is for demonstration, identification, and reference purposes only and does not imply any association with the trademark holder of their product brand. It is higly advised to review their [911/Legal Disclaimer](https://www.convorelay.com/legal) for registration eligibility prior to using their product. 

### Steps to Build App:

1. ```
   git clone https://github.com/bashtheshell/vp-flasher.git
   cd vp-flasher
   ```
   
2. In the *VPFlasherApp* folder, you'd find a couple of files. The relevant files here you'd want to take a look at are *VPFlasher_x.x.x.py* and *setup.py*. If you are making incremental change to the *VPFlasher_x.x.x.py* file, please feel free to update the *x.x.x* version number in the filename.

3. Change to *vp-flasher* directory if you are not in it already and run the `./build_deploy_script.sh` script.

4. In a moment, you should see the resulting *VPFlasher_x.x.x.pkg* file in the current directory with the updated version number shown in the filename.

## Behind the Scene

This app was made possible by Scapy's `sniff` and Tk/Tcl's `tkinter` modules. `sniff` was a crtiical component of the app as it's responsible for analyzing the network traffic, waiting for specific SIP payloads to pass through. It may be the oldest packet dissection Python module, but its abundance of resources and ease of support made it a superior choice.

The GUI creation was done with `tkinter` module, and I want to give special thanks to this [book](https://www.packtpub.com/application-development/tkinter-gui-application-development-blueprints-second-edition) as I would not be able to complete this project sooner without it.

## Extra

At one point, I created a DMG installer when I thought I was ready to distribute the app, but then I learned that the app didn't work due to missing scripts to create the BPF devices. The error would be `No /dev/bpf handle is available !`. I was able to quickly rectify the problem as I borrowed the `ChmodBPF` script from Wireshark along with other associated files. However, this would require me to place those files in specific locations and make modification to the system requiring privilege escalation. Thus, the reason why I went with the package installer solution instead.

Nevertheless, here's the [build_dmg.sh](./dmg_installer_VPFlasherApp/build_dmg.sh) script I created which would generate this beautiful DMG installer in *dmg_installer_VPFlasherApp* folder. This would require *Homebrew* installed as well as other [requirements](#requirements-for-building-app-from-source-code) mentioned earlier. First, you'd need to install the `create-dmg` package (special thanks to [Andrey Tarantsov](https://github.com/andreyvit/create-dmg)) by running `brew install create-dmg`.

The DMG installer should be created after running the *build_dmg.sh* script. After you've installed the app using the DMG installer, you'd need to place [com.bashtheshell.ChmodBPF.plist](./VPFlasherApp/com.bashtheshell.ChmodBPF.plist) and [ChmodBPF](./VPFlasherApp/ChmodBPF) files in the system-wide `/Library/Application Support/com.bashtheshell.macos.vpflasher/ChmodBPF/` directory. Create the full path if it doesn't exist and be sure to give *ChmodBPF* script executable permission. Then run the [chmodbpf-postinstall.sh](./VPFlasherApp/chmodbpf-postinstall.sh) script as `sudo` user to complete the installation.

## What's Next

Maybe it's time I get around to fixing that optimization issue as reported below. No promise it'll be done soon.

## Known Issues

- The on-screen widgets would only work on the primary display. Multiple displays are not currently supported. Please submit a pull request or a ticket if you have a solution you can share to support this.
- Occassionally, the app may not react to the incoming calls due to multiple simultaneous traffic bursting through the network. Try restarting the VPFlasher app if you're experiencing issue. Please submit a ticket if issue persists. Thanks in advance. Optimization is on the roadmap.
- The blink(1) notification light may get stuck in its previous state due to an unexpected crash. To fix the issue, please re-insert the USB stick.
