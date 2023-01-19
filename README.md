### General virt-manager CLI commands
List available VMs
```bash
$ virsh list --all
```

List available networks
```bash
$ virsh net-list --all
```
### Network configuration
```bash
$ virsh net-edit default
```
Network configuration example
```xml
<network>
    <name>default</name>
    <uuid>d357b602-9c52-472d-9890-dd91c480d15d</uuid>
    <forward mode='nat'/>
    <bridge name='virbr0' stp='on' delay='0'/>
    <mac address='52:54:00:7c:76:78'/>
    <dns>
        <host ip='10.10.50.31'>
            <hostname>kube1.home.lab</hostname>
        </host>
        <host ip='10.10.50.32'>
            <hostname>kube2.home.lab</hostname>
        </host>
        <host ip='10.10.50.33'>
            <hostname>kube3.home.lab</hostname>
        </host>
    </dns>
    <ip address='10.10.50.1' netmask='255.255.255.0'>
        <dhcp>
            <range start='10.10.50.100' end='10.10.50.200'/>
        </dhcp>
    </ip>
</network>
```
Apply network changes after editing configuration
```bash
$ virsh net-destroy default && virsh net-start default
```
To enable correct DNS resolutions on Ubuntu 22.04 apply the following patch. Netplan configuration will be applied correctly.
```bash
$ sudo mv /etc/resolv.conf /etc/resolv.conf.BAK
$ sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
$ systemctl restart systemd-resolved
$ resolvectl
```
Once the network is setup, create VMs. VMs are using `default` network. 

### VM Configuration
Copy `user-data.yaml` from `sample` folder and alter it with local cloud-init configuration options.

Create hash passwords
```bash
$ mkpasswd -m sha-512
```
_**Read OSX section for specific setup on Mac**_

Start script to see all options
```bash
$ sh make-images.sh
```
, or create three nodes with prefix `node` and starting host id 30 
```bash
$ sh make-images.sh -c 3 -p node -s 30 -t create
```
Different VM commands
```bash
$ INSTANCE_NAME=node-1 make start
$ INSTANCE_NAME=node-1 make stop
$ INSTANCE_NAME=node-1 make restart
$ INSTANCE_NAME=node-1 make create
$ INSTANCE_NAME=node-1 make delete
```
, or
```bash
$ sh make-images.sh -c 3 -p node -s 30 -t start
$ sh make-images.sh -c 3 -p node -s 30 -t stop
$ sh make-images.sh -c 3 -p node -s 30 -t restart
$ sh make-images.sh -c 3 -p node -s 30 -t create
$ sh make-images.sh -c 3 -p node -s 30 -t delete
```
### Examples
#### Use different VM network subnet. 

Edit default network
```bash
$ virsh net-edit default
```
Specify new network prefix as environment variable
```bash
$ export NETWORK_PREFIX=192.168.122
$ sh make-images.sh -c 3 -p node -s 30 -t create
```
#### Use different base VM image

Download new base image to `/var/lib/libvirt/images/base`. Use new base image name to create VMs with environment variable
```bash
$ export BASE_IMAGE=jammy-server-cloudimg-amd64-disk-kvm.img
$ sh make-images.sh -c 3 -p node -s 30 -t create
```

#### OSX
Script cannot create VMs directly on Mac. Use base image in UTM to clone new VMs. Attach seed image as CD-ROM drive to customize each VM.

Generate VM seed images. Use `192.168.64`as network prefix. Specify correct NIC. 
```bash
$ NETWORK_PREFIX=192.168.64 INSTANCE_NAME=node-1 NETWORK_NIC=enp0s1 make seed-image
```
, or
```bash
$ export NETWORK_PREFIX=192.168.64 
$ export NETWORK_NIC=enp0s1
$ sh make-images.sh -c 3 -p node -s 30 -t seed-image
```
Seed images are created in `node-x/bin` folder. Use seed image to mount CD-ROM drive when cloning base image in UTM

**_!!! Change MAC address for each cloned VM !!!_**
