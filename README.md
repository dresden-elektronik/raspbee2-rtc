# RaspBee II RTC
RTC kernel module builder for RaspBee II

This repository provides a Makefile which downloads, builds and installs the RTC kernel module for the RaspBee II Zigbee shield for Raspberry Pi.

The RTC is *not mandatory* for the use of the RaspBee II as a ZigBee coordinator.

When the linux kernel gets updated it can happen that the RTC module *build fails* because it takes some time until the raspberry pi kernel headers package is updated with the new version.
In this case you can repeat the build in a few days.

## Dependencies
### Hardware
* Raspberry Pi 1, 2B, 3B, 3B+ or 4B
* [RaspBee II](https://phoscon.de/raspbee2) Zigbee shield
* FW version 26610700 or higher (http://deconz.dresden-elektronik.de/deconz-firmware/deCONZ_RaspBeeII_0x26610700.bin.GCF)

### Supported platforms
Raspbian Stretch or Buster

## Install

0. Update Raspberry Pi and Reboot
        
        sudo apt update
        sudo apt upgrade
        reboot

1. Install dependencies

        sudo apt install i2c-tools build-essential raspberrypi-kernel-headers

2. Download installation archive

        curl -O -L https://github.com/dresden-elektronik/raspbee2-rtc/archive/master.zip
        unzip master.zip

3. Change into extracted directory

        cd raspbee2-rtc-master

4. Compile RTC kernel module

        make

5. Install RTC kernel module

        sudo make install

6. Reboot Raspberry Pi

        sudo reboot

7. Configure system time to RTC module

        sudo hwclock --systohc

8. Test that RTC is working

        sudo hwclock --verbose


    <pre><code>Waiting in loop for time from /dev/rtc0 to change
    ...got clock tick
    Time read from Hardware Clock: 2020/03/06 13:55:21
    Hw clock time : 2020/03/06 13:55:21 = 1583502921 seconds since 1969
    Time since last adjustment is 1583502921 seconds
    Calculated Hardware Clock drift is 0.000000 seconds
    2020-03-06 14:55:20.017097+01:00</code></pre>
    
       timedatectl
       
    <pre><code>Local time: Fri 2020-04-03 12:42:20 CEST
           Universal time: Fri 2020-04-03 10:42:20 UTC
                 RTC time: Fri 2020-04-03 10:41:56
                Time zone: Europe/Berlin (CEST, +0200)
           System clock synchronized: no
              NTP service: inactive
          RTC in local TZ: no</code></pre>
          
## Troubleshooting
If something went wrong during install please consider the following error sources:

- Install dependencies
- Execute make without sudo
- Execute make install with sudo
- If behind a proxy make sure it is correctly configured

If you get Error Message like
<pre><code>make -C /lib/modules/6.1.21-v8+/build M=/home/openhabian/raspbee2-rtc-master modules
        make[1]: *** /lib/modules/6.1.21-v8+/build: File or directory not found.  Exit.
        make: *** [Makefile:17: build] Error 2</code></pre>

- try adding "arm_64bit=0" to config.txt, reboot and try again
 
 ## Use the RTC
 Set RTC time to system time:
 \
   <code>sudo hwclock --systohc</code>

 Read the RTC time:
 \
   <code>sudo hwclock -r</code>


 For more information see: https://linux.die.net/man/8/hwclock
