KVM_BASE_IMAGES_PATH=/var/lib/libvirt/images/base
KVM_IMAGES_PATH=/var/lib/libvirt/images
KVM_INSTANCE_ID=$(shell uuidgen || echo i-abcdefg)
KVM_INSTANCE_BOOT_SIZE=10G

BOOT_IMAGE ?= ubuntu-22.10-server-cloudimg-amd64-disk-kvm.qcow2

INSTANCE_PATH=$(KVM_IMAGES_PATH)/$(INSTANCE_NAME)
BOOT_PATH=$(KVM_BASE_IMAGES_PATH)/$(BOOT_IMAGE)

$( shell mkdir -p bin )

check-env:
ifndef INSTANCE_NAME
	$(error INSTANCE_NAME is undefined)
endif

echo1: check-env
	echo $(INSTANCE_NAME); \
	echo $(BOOT_IMAGE); \
	echo $(BOOT_PATH)

# generates meta data
seed-image: check-env
	echo "instance-id: $(KVM_INSTANCE_ID)" > meta-data.yaml; \
	echo "local-hostname: $(INSTANCE_NAME)" >> meta-data.yaml
	cloud-localds -v --network-config=network-config-v2.yaml bin/seed.img user-data.yaml meta-data.yaml
	sudo cp bin/seed.img $(INSTANCE_PATH)/seed.img

boot-image: seed-image
	sudo qemu-img convert -f qcow2 $(BOOT_PATH) $(INSTANCE_PATH)/boot.qcow2; \
	sudo qemu-img $(INSTANCE_PATH)/boot.qcow2 resize $(KVM_INSTANCE_BOOT_SIZE)

# create virtual machine with cloud-init seed image
create: boot-image
	virt-install \
		--virt-type kvm \
		--name $(INSTANCE_NAME) \
		--ram 2048 \
		--vcpus=2 \
		--boot hd,menu=on \
		--os-variant ubuntu-lts-latest \
		--disk path=$(INSTANCE_PATH)/boot.qcow2,format=qcow2 \
		--disk path=$(INSTANCE_PATH)/seed.img,format=raw \
		--graphics none \
		--network network=default \
		--noautoconsole

# destroys vm
destroy: check-env
	virsh destroy $(INSTANCE_NAME); \
	virsh undefine $(INSTANCE_NAME); \
	virsh pool-destroy $(INSTANCE_NAME); \
	virsh pool-undefine $(INSTANCE_NAME)

# show help
help:
	@echo ''
	@echo 'Usage:'
	@echo ' make [target]'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
	helpMessage = match(lastLine, /^# (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")-1); \
			helpMessage = substr(lastLine, RSTART + 2, RLENGTH); \
			printf "\033[36m%-22s\033[0m %s\n", helpCommand,helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help