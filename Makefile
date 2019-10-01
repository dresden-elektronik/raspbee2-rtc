#!/bin/bash
PWD=$(shell pwd)
obj-m = rtc-pcf85063.o
KVERSION = $(shell uname -r)
KBUILD=/lib/modules/$(KVERSION)/build
UID = $$(id -u)
PACKAGES = i2c-tools build-essential raspberrypi-kernel-headers

all:
	@echo "checking dependencies..."
	@for p in $(PACKAGES); do \
		echo "$$p"; \
		dpkg -s "$$p" | grep Status; \
		if [ "$$?" != 0 ]; then \
			echo "please install missing package via apt install $$p"; \
	                exit 1; \
        	fi \
	done
	@echo "downloading rtc source..."
	@if [ ! -f rtc-pcf85063.c ]; then \
		wget https://raw.githubusercontent.com/torvalds/linux/master/drivers/rtc/rtc-pcf85063.c || (echo "could not download rtc source file"; exit 1); \
	fi
	@echo "building rtc module..."
	@make -C $(KBUILD) M=$(PWD) modules || (echo "Error building rtc module"; exit 1)
clean:
	make -C $(KBUILD) M=$(PWD) clean
install:
	@if [ "$$(id -u)" != 0 ]; then \
		echo "Please run as root"; \
		exit 1; \
	fi

	@echo "installing rtc module..."
	@make -C $(KBUILD) M=$(PWD) INSTALL_MOD_PATH=$(INSTALL_ROOT) modules_install || (echo "could not install rtc module file (have you done make?)"; exit 1)
	depmod -A
	@echo "enabling rtc module..."
	@echo "rtc_pcf85063" | sudo tee /usr/lib/modules-load.d/rtc_pcf85063.conf
	@echo "enabling i2c interface..."
	@if [ ! -z "$$(cat /boot/config.txt | grep "^#dtparam=i2c_arm=on")" ]; then \
		sed -i 's/#dtparam=i2c_arm=on/dtparam=i2c_arm=on/g' /boot/config.txt; \
	elif [ ! -z "$$(cat /boot/config.txt | grep "^dtparam=i2c_arm=on" | xargs)" ]; then \
		:; \
	else \
		echo "" | sudo tee -a /boot/config.txt; \
		echo "#enable i2c" | sudo tee -a /boot/config.txt; \
		echo "dtparam=i2c_arm=on" | sudo tee -a /boot/config.txt; \
	fi

	@echo "downloading rtc service..."
	@if [ ! -f rtc-pcf85063.service ]; then \
		wget -O rtc-pcf85063.service https://raw.githubusercontent.com/dresden-elektronik/raspbee2-rtc/master/rtc-pcf85063.service?token=AC4SYY43WXO6RAOLUWKD2E25TQZ2M || (echo "could not download rtc service file"; exit 1); \
	fi
	@echo "moving rtc service..."
	@mv rtc-pcf85063.service /lib/systemd/system/rtc-pcf85063.service
	@systemctl daemon-reload
	@echo "starting rtc service..."
	@systemctl start rtc-pcf85063.service
	@echo "enabling rtc service..."
	@systemctl enable rtc-pcf85063.service
	@echo "setting rtc time..."
	hwclock --systohc
	@echo "done"
