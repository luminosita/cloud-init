KVM_IMAGES_PATH=/var/lib/libvirt/images
KVM_INSTANCE_ID=$(shell uuidgen || echo i-abcdefg)

$( shell mkdir -p bin )

echo123:
	@echo $(KVM_INSTANCE_ID)

# generates meta data
generate-meta-data: 
	echo "instance-id: $(KVM_INSTANCE_ID)" > meta-data.yaml \

# generates cloud-init seed image
generate-seed: generate-meta-data
	cloud-localds -v --network-config=network-config-v2.yaml bin/seed.img user-data.yaml meta-data.yaml

seed-image: generate-seed	
	sudo cp bin/seed.img $(KVM_IMAGES_PATH)/${instance_name}/seed1.img

# create virtual machine with cloud-init seed image
create-vm:
	virt-install \
		--virt-type kvm \
		--name node-1 \
		--ram 2048 \
		--vcpus=2 \
		--boot hd,menu=on \
		--os-variant ubuntu-lts-latest \
		--disk path=$(KVM_IMAGES_PATH)/${instance_name}/boot.qcow2,format=qcow2 \
		--disk path=$(KVM_IMAGES_PATH)/${instance_name}/seed.img,format=raw \
		--graphics none \
		--network network=default \
		--noautoconsole

.PHONY: vm
# generates seed and creates vm with cloud-init
vm: generate-seed create-vm

# destroys vm
destroy:
	@virsh destroy $(instance_name) \
	virsh undefine $(instance_name) \
	virsh pool-destroy $(instance_name) \
	virsh pool-undefine $(instance_name)

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
