#!/bin/bash
PWD = $(shell pwd)
obj-m = rtc-pcf85063.o
KVERSION = $(shell uname -r)
KBUILD = /lib/modules/$(KVERSION)/build
UID = $$(id -u)
KVERSION_SHORT = $(shell uname -r | cut -d'.' -f1,2)
RTC_SRC = rtc-pcf85063.c

.PHONY: all
all: build
	$(info rtc module successfully build, you may run 'sudo make install' now)

build: $(RTC_SRC)
	$(info build rtc module...)
	$(MAKE) -C $(KBUILD) M=$(PWD) modules
clean:
	$(MAKE) -C $(KBUILD) M=$(PWD) clean
	-rm -f *.[oc]

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
	@echo "enable rtc module..."
	@echo "rtc_pcf85063" | tee /usr/lib/modules-load.d/rtc_pcf85063.conf
	@echo "enable i2c interface..."
	raspi-config nonint do_i2c 0
	@echo "install rtc service..."
	@cp rtc-pcf85063.service /lib/systemd/system/rtc-pcf85063.service
	@if [ -d /sys/class/i2c-dev ]; then \
    	sudo sed -i "s|ExecStart=/bin/bash -c 'echo pcf85063 0x51 > /sys/class/i2c-adapter/i2c-1/new_device'|ExecStart=/bin/bash -c 'echo pcf85063 0x51 > /sys/class/i2c-dev/i2c-1/device/new_device'|" /lib/systemd/system/rtc-pcf85063.service; \
    	echo "using directory /i2c-dev in service file"; \
    else \
    	echo "using directory /i2c-adapter in service file"; \
		systemctl disable fake-hwclock; \
	fi
	@chmod 0644 /lib/systemd/system/rtc-pcf85063.service
	@systemctl daemon-reload
	systemctl start rtc-pcf85063.service
	systemctl enable rtc-pcf85063.service
	@echo "Done - Please reboot your machine now"
