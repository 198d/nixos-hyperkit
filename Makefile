STRIPPED_ISO := $(ISO)/stripped.iso
RAW_ISO := $(ISO)/raw.iso
ISO_MOUNT_DIR := $(ISO)/NIXOS_ISO

MACHINE_UUID := $(MACHINE)/uuid
MACHINE_DISK := $(MACHINE)/disk.qcow2
MACHINE_CONSOLE := $(MACHINE)/console
MACHINE_PIDFILE := $(MACHINE)/hyperkit.pid
MACHINE_KERNEL := $(MACHINE)/kernel
MACHINE_INITRD := $(MACHINE)/initrd

MEMORY := 2G
CPUS := 2


.PHONY: clean $(MACHINE) install run poweroff


$(ISO_MOUNT_DIR): $(STRIPPED_ISO)
	hdiutil attach -mountpoint $@ $(STRIPPED_ISO)


$(STRIPPED_ISO): $(RAW_ISO)
	dd if=/dev/zero bs=2k count=1 of=$@
	dd if=$(RAW_ISO) bs=2k skip=1 >> $@


$(RAW_ISO):
	[ -f $@ ]


$(MACHINE):
	mkdir -p $@
	[ -f $(MACHINE_DISK) ] || qcow-tool create --size=50GiB $(MACHINE_DISK)
	[ -f $(MACHINE_UUID) ] || uuidgen > $(MACHINE_UUID)

poweroff:
	sudo kill $(shell cat $(MACHINE_PIDFILE))


clean:
	hdiutil detach $(ISO_MOUNT_DIR)


livecd: $(ISO_MOUNT_DIR)
	sudo bin/hyperkit -A -m $(MEMORY) -c $(CPUS) -u \
		-l com1,stdio \
		-s 0:0,hostbridge \
		-s 1,virtio-net \
		-s 2,ahci-cd,$(shell pwd)/$(RAW_ISO) \
		-s 31,lpc \
		-f kexec,$(ISO_MOUNT_DIR)/boot/bzImage,$(ISO_MOUNT_DIR)/boot/initrd,"earlyprintk=serial console=ttyS0 $(shell cat $(ISO_MOUNT_DIR)/loader/entries/nixos-iso.conf | grep '^options' | cut -d ' ' -f 2-)"


install: $(ISO_MOUNT_DIR) $(MACHINE)
	[ -f $(MACHINE_PIDFILE) ] && sudo kill -0 $(shell cat $(MACHINE_PIDFILE)) && \
			echo "Machine running!" && exit 1 || \
		rm -rf $(MACHINE_PIDFILE)
	sudo bin/hyperkit -A -m $(MEMORY) -c $(CPUS) -u \
 		-F $(MACHINE_PIDFILE) \
		-U $(shell cat $(MACHINE_UUID)) \
		-l com1,stdio \
		-s 0:0,hostbridge \
		-s 1:0,ahci-hd,file://$(shell pwd)/$(MACHINE_DISK),format=qcow \
		-s 2:0,virtio-net \
		-s 3,ahci-cd,$(shell pwd)/$(RAW_ISO) \
		-s 31,lpc \
		-f kexec,$(ISO_MOUNT_DIR)/boot/bzImage,$(ISO_MOUNT_DIR)/boot/initrd,"earlyprintk=serial console=ttyS0 $(shell cat $(ISO_MOUNT_DIR)/loader/entries/nixos-iso.conf | grep '^options' | cut -d ' ' -f 2-)"

run: $(MACHINE)
	[ -f $(MACHINE_PIDFILE) ] && sudo kill -0 $(shell cat $(MACHINE_PIDFILE)) && \
			echo "Machine running!" && exit 1 || \
		rm -rf $(MACHINE_PIDFILE)
	sudo nohup -- bin/hyperkit -A -m $(MEMORY) -c $(CPUS) -u \
 		-F $(MACHINE_PIDFILE) \
		-U $(shell cat $(MACHINE_UUID)) \
		-l com1,autopty=$(MACHINE_CONSOLE),log=$(MACHINE_CONSOLE).log \
		-s 0:0,hostbridge \
		-s 1:0,ahci-hd,file://$(shell pwd)/$(MACHINE_DISK),format=qcow \
		-s 2:0,virtio-net \
		-s 31,lpc \
		-f kexec,$(MACHINE_KERNEL),$(MACHINE_INITRD),"earlyprintk=serial console=ttyS0 loglevel=4 init=/nix/var/nix/profiles/system/init" 2>&1 > $(MACHINE)/hyperkit.log &
