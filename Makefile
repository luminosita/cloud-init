KVM_IMAGES_PATH=/var/lib/libvirt/images

$( shell mkdir -p bin )

# generates cloud-init seed image
generate-seed:
	@cloud-localds -v --network-config=network-config-v2.yaml bin/seed.img user-data.yaml meta-data.yaml \
		sudo cp bin/seed.img $(KVM_IMAGES_PATH)/${instance-name}/seed.img

# create virtual machine with cloud-init seed image
create-vm:
	virt-install \
		--virt-type kvm \
		--name node-1 \
		--ram 2048 \
		--vcpus=2 \
		--boot hd,menu=on \
		--os-variant ubuntu-lts-latest \
		--disk path=$(KVM_IMAGES_PATH)/${instance-name}/boot.qcow2,format=qcow2 \
		--disk path=$(KVM_IMAGES_PATH)/${instance-name}/seed.img,format=raw \
		--graphics none \
		--network network=default \
		--noautoconsole

.PHONY: vm
# generates seed and creates vm with cloud-init
vm: generate-seed create-vm

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
