# HT-Connect

## Description

Ht-Connect is a bash script for linux that will allow you to connect your Btech UV-Pro or VGC VN76 to a device that is running linux.  The device could be a Raspberry Pi or any other computer running Linux that also has Bluetooth.  Once the ht is connected this will allow you to use the radio with other software on the the computer that supports using the ht's built-in KISS TNC.

**NOTE 
This script only automates the connecting of the HT to the computer over Bluetooth.  Once connected you will have to setup whatever software you are using to use the ht.  This script does NOT set up the software to work with the ht. It is not clear yet what all software these HT's will work with so try it out and Have fun.**


## Getting the HT-Connect Script

simply copy the repo to you computer and run the script

### copy the repo

``` shell
get clone https://github.com/Dkane00/HT-Connect.git
```

### Easy Button

#### Cd into the repo
``` shell
cd HT-Connect
```
#### Make sure that the install script and the HT-Connect script are both executable
``` shell
sudo chmod +x install-ht-connect.sh HT-Connect.sh
```
#### Run the install Script
- This script will allow you to run the HT-Connect.sh script by just typing the simple command ht-connect from the command line
``` shell
./install-ht-connect.sh
```
### Running the HT-Connect script without installing the simple command

#### Cd into the repo
``` shell
cd HT-Connect
```

#### run the script
``` shell
./HT-Connect.sh
```

