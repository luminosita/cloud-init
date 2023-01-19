List available VMs
```bash
$ virsh list --all
```

List available networks
```bash
$ virsh net-list --all
```
Edit network configuration
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
Once the network is setup, create VMs. VMs are using `default` network. Start script to see all options
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