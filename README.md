# raspbee2-rtc
RTC kernel module builder for RaspBee II

This repository provides a Makefile which downloads, builds and installs the RTC kernel module needed for the RaspBee II Zigbee shield on Raspberry Pi.

## Install

1. install dependencies
\
  <code> sudo apt install i2c-tools build-essential raspberrypi-kernel-headers </code>
2. clone this repository
3. <code>cd raspbee2-rtc</code>
4. <code>make</code>
5. <code>sudo make install</code>

## Troubelshooting
If something went wrong during install please consider following error sources:

- install dependencies
- execute make without sudo
- execute make install with sudo
- if behind a proxy make sure it is correctly configured
 
 ## Testing
 Test if the RTC works correctly:
 \
   <code>sudo hwclock</code>

## Dependecies
Hardware:
RPI1 (Revision 2 or greater), RPI2, RPI3, RPI4
RaspBee II Zigbee shield
