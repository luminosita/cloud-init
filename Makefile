KVM_BASE_IMAGES_PATH=/var/lib/libvirt/images/base
KVM_IMAGES_PATH=/var/lib/libvirt/images
KVM_INSTANCE_BOOT_SIZE=10G

BOOT_IMAGE ?= ubuntu-22.10-server-cloudimg-amd64-disk-kvm.qcow2

INSTANCE_PATH=$(KVM_IMAGES_PATH)/$(INSTANCE_NAME)
BOOT_PATH=$(KVM_BASE_IMAGES_PATH)/$(BOOT_IMAGE)

INSTANCE_HOST_ID ?= 50

export KVM_INSTANCE_ID=$(shell uuidgen || echo i-abcdefg)

define _metadata_script
cat > meta-data.yaml <<EOF
instance-id: $KVM_INSTANCE_ID
local-hostname: $INSTANCE_NAME
EOF
endef
export metadata_script = $(value _metadata_script)

define _network_script
cat > network-config-v2.yaml <<EOF
network:
  version: 2
  ethernets:
	enp1s0:
	  addresses: [10.10.50.$INSTANCE_HOST_ID/24]
	  nameservers:
		addresses: [10.10.50.1,8.8.8.8]
	  routes:
		- to: default
		  via: 10.10.50.1
EOF
endef
export network_script = $(value _network_script)

check-env:
ifndef INSTANCE_NAME
	$(error INSTANCE_NAME is undefined)
endif
ifndef INSTANCE_HOST_ID
	$(error INSTANCE_HOST_ID is undefined)
endif

config-metadata: check-env
	@eval "$$metadata_script"

config-network: check-env
	@eval "$$network_script"

config-files: config-metadata config-network

# generates meta data
seed-image: config-files
	mkdir -p bin; \
	echo "instance-id: $(KVM_INSTANCE_ID)" > meta-data.yaml; \
	echo "local-hostname: $(INSTANCE_NAME)" >> meta-data.yaml
	cloud-localds -v --network-config=network-config-v2.yaml bin/seed.img user-data.yaml meta-data.yaml
	sudo cp bin/seed.img $(INSTANCE_PATH)/seed.img

boot-image: seed-image
	sudo /usr/bin/qemu-img convert -f qcow2 -O qcow2 $(BOOT_PATH) $(INSTANCE_PATH)/boot.qcow2; \
	sudo /usr/bin/qemu-img resize $(INSTANCE_PATH)/boot.qcow2 $(KVM_INSTANCE_BOOT_SIZE)

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

# starts vm
start: check-env
	virsh start $(INSTANCE_NAME)

# stops vm
stop: check-env
	virsh shutdown $(INSTANCE_NAME)

# restarts vm
restart: check-env
	virsh reboot $(INSTANCE_NAME)

# delete vm
delete: check-env stop
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
