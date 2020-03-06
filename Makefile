#!/bin/bash
PWD = $(shell pwd)
obj-m = rtc-pcf85063.o
KVERSION = $(shell uname -r)
KBUILD = /lib/modules/$(KVERSION)/build
UID = $$(id -u)
PACKAGES = i2c-tools build-essential raspberrypi-kernel-headers
KVERSION_SHORT = $(shell uname -r | cut -d'.' -f1,2)

all:
	@echo "check dependencies..."
	@for p in $(PACKAGES); do \
		echo "$$p"; \
		dpkg -s "$$p" | grep Status; \
		if [ "$$?" != 0 ]; then \
			echo "please install missing package via apt install $$p"; \
	                exit 1; \
        	fi \
	done
	@echo "download rtc source..."
	@if [ ! -f rtc-pcf85063.c ]; then \
		wget https://raw.githubusercontent.com/torvalds/linux/v${KVERSION_SHORT}/drivers/rtc/rtc-pcf85063.c || (echo "could not download rtc source file"; exit 1); \
	fi
	@echo "build rtc module..."
	@make -C $(KBUILD) M=$(PWD) modules || (echo "Error building rtc module"; exit 1)
clean:
	make -C $(KBUILD) M=$(PWD) clean
	-rm -f rtc-pcf85063.c

install:
	@if [ "$$(id -u)" != 0 ]; then \
		echo "Please run as root"; \
		exit 1; \
	fi

	@echo "install rtc module..."
	@make -C $(KBUILD) M=$(PWD) INSTALL_MOD_PATH=$(INSTALL_ROOT) modules_install || (echo "could not install rtc module file (have you done make?)"; exit 1)
	depmod -A
	@echo disable fake-hwclock
	@systemctl disable fake-hwclock
	@echo "enable rtc module..."
	@echo "rtc_pcf85063" | sudo tee /usr/lib/modules-load.d/rtc_pcf85063.conf
	@echo "enable i2c interface..."
	raspi-config nonint do_i2c 0
	@echo "install rtc service..."
	@cp rtc-pcf85063.service /lib/systemd/system/rtc-pcf85063.service
	@systemctl daemon-reload
	@echo "start rtc service..."
	@systemctl start rtc-pcf85063.service
	@echo "enable rtc service..."
	@systemctl enable rtc-pcf85063.service
	@echo "Done - Please reboot your machine now"
