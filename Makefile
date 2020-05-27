#!/bin/bash
PWD = $(shell pwd)
obj-m = rtc-pcf85063.o
KVERSION = $(shell uname -r)
KBUILD = /lib/modules/$(KVERSION)/build
UID = $$(id -u)
PACKAGES = i2c-tools build-essential raspberrypi-kernel-headers
KVERSION_SHORT = $(shell uname -r | cut -d'.' -f1,2)
RTC_SRC = rtc-pcf85063.c

.PHONY: all
all: check-packages build
	$(info rtc module successfully build, you may run 'sudo make install' now)

build: $(RTC_SRC)
	$(info build rtc module...)
	$(MAKE) -C $(KBUILD) M=$(PWD) modules
clean:
	$(MAKE) -C $(KBUILD) M=$(PWD) clean
	-rm -f *.[oc]

.PHONY: $(PACKAGES)
.PHONY: check-packages
check-packages: $(PACKAGES)
	$(info checking deb package dependencies...)
	@for p in $^; do \
		echo "$$p"; \
		dpkg -s "$$p" 2> /dev/null | grep -q Status; \
		if [ "$$?" != 0 ]; then \
			echo "package $$p not installed, please install via: apt-get install $$p"; \
			exit 1; \
		fi \
	done

$(RTC_SRC):
	$(info download $@ for kernel version $(KVERSION_SHORT) ...)
	curl -O --max-time 10 https://raw.githubusercontent.com/torvalds/linux/v$(KVERSION_SHORT)/drivers/rtc/$@

install:
	@if [ "$$(id -u)" != 0 ]; then \
		echo "Please run as root"; \
		exit 1; \
	fi

	$(info install rtc module...)
	@$(MAKE) -C $(KBUILD) M=$(PWD) INSTALL_MOD_PATH=$(INSTALL_ROOT) modules_install || (echo "could not install rtc module file (did you run make?)"; exit 1)
	@depmod -A
	systemctl disable fake-hwclock
	@echo "enable rtc module..."
	@echo "rtc_pcf85063" | tee /usr/lib/modules-load.d/rtc_pcf85063.conf
	@echo "enable i2c interface..."
	raspi-config nonint do_i2c 0
	@echo "install rtc service..."
	@cp rtc-pcf85063.service /lib/systemd/system/rtc-pcf85063.service
	@chmod 0644 /lib/systemd/system/rtc-pcf85063.service
	@systemctl daemon-reload
	systemctl start rtc-pcf85063.service
	systemctl enable rtc-pcf85063.service
	@echo "Done - Please reboot your machine now"
