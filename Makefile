KVM_BASE_IMAGES_PATH=/var/lib/libvirt/images/base
KVM_IMAGES_PATH=/var/lib/libvirt/images
KVM_INSTANCE_BOOT_SIZE=10G

BASE_IMAGE ?= ubuntu-22.10-server-cloudimg-amd64-disk-kvm.qcow2

INSTANCE_PATH=$(KVM_IMAGES_PATH)/$(INSTANCE_NAME)
BASE_PATH=$(KVM_BASE_IMAGES_PATH)/$(BASE_IMAGE)

INSTANCE_HOST_ID ?= 50

NETWORK_PREFIX ?= 10.10.50

export HOST_ID=$(INSTANCE_HOST_ID)
export NET_PREFIX=$(NETWORK_PREFIX)
export KVM_INSTANCE_ID=$(shell uuidgen || echo i-abcdefg)

define _metadata_script
cat > $INSTANCE_NAME/meta-data.yaml <<EOF
instance-id: $KVM_INSTANCE_ID
local-hostname: $INSTANCE_NAME
EOF
endef
export metadata_script = $(value _metadata_script)

define _network_script
cat > $INSTANCE_NAME/network-config-v2.yaml <<EOF
network:
  version: 2
  ethernets:
    enp1s0:
      addresses: [$NET_PREFIX.$HOST_ID/24]
      nameservers:
        addresses: [$NET_PREFIX.1,8.8.8.8]
      routes:
        - to: default
          via: $NET_PREFIX.1
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

check-base-image:
ifeq (,$(wildcard $(BASE_PATH)))
	$(error Base image does not exist: $(BASE_PATH))
endif
	@echo "Base image exists: $(BASE_PATH)"

config-files: 	
	@mkdir -p $(INSTANCE_NAME); \
	eval "$$metadata_script"; \
	eval "$$network_script"; \

# generates meta data
seed-image: config-files
	mkdir -p $(INSTANCE_NAME)/bin; \
	sudo mkdir -p $(INSTANCE_PATH); \
	mkisofs -v -output "$(INSTANCE_NAME)/bin/seed.img" -volid cidata -joliet -rock $(INSTANCE_NAME)/meta-data.yaml $(INSTANCE_NAME)/network-config-v2.yaml user-data.yaml
	sudo cp $(INSTANCE_NAME)/bin/seed.img $(INSTANCE_PATH)/seed.img

boot-image: check-base-image seed-image
	sudo /usr/bin/qemu-img convert -f qcow2 -O qcow2 $(BASE_PATH) $(INSTANCE_PATH)/boot.qcow2; \
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
	virsh pool-undefine $(INSTANCE_NAME); \
	sudo rm -rf $(INSTANCE_PATH)

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
