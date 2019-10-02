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
	raspi-config nonint do_i2c 0
	@echo "moving rtc service..."
	@mv rtc-pcf85063.service /lib/systemd/system/rtc-pcf85063.service
	@systemctl daemon-reload
	@echo "starting rtc service..."
	@systemctl start rtc-pcf85063.service
	@echo "enabling rtc service..."
	@systemctl enable rtc-pcf85063.service
	@echo "Done - Please reboot your machine now"
