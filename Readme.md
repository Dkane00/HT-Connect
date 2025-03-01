# HT-Connect

## Description

Ht-Connect is a bash script for linux that will allow you to connect your Btech UV-Pro or VGC VN76 to a device that is running linux.  The device could be a Raspberry Pi or any other computer running Linux that also has Bluetooth.  Once the ht is connected this will allow you to use the radio with other software on the the computer that supports using the ht's built-in KISS TNC.

**NOTE 
This script only automates the connecting of the HT to the computer over Bluetooth.  Once connected you will have to setup whatever software you are using to use the ht.  This script does NOT set up the software to work with the ht. It is not clear yet what all software these HT's will work with so try it out and Have fun.**


## Installing the HT-Connect

### Clone this repo

``` shell
get clone https://github.com/Dkane00/HT-Connect.git
```
#### Cd into HT-Connect folder
``` shell
cd HT-Connect
```
#### Run the install
``` shell
./install-ht-connect.sh
```

## How to Use

Commands:
- htc --help
  - This will give you this list of commands and what they do 

- htc pair
  - This command will will scan for Bluetooth devices and give you a list of found devices of which it will connect the one that you select. 

- htc connect
  - This command will connect an already paired ht to a rfcomm serial port on your computer that can then be used to interface the radio with software on your computer that will work with rfcomm serial ports.

- htc disconnect
  - This command will diconnect the radio from the rfcomm port and Bluetooth.



## What is to come

- kissattach
  - will be adding a command to connect the ht to kissattach which will allow the use of the Linux native ax-25 protocall.  This will allow the radio to be used with pat winlink as well as some packet bbs terminals

- Maybe a GUI
  - I may try to put all of this in a simple GUI so that it can be even more user friendly and easier for those that may not be too familar with the terminal.