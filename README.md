# Examples with KVM

It seems everytime I deal with KVM, I have to look up how to do certain things.
These are examples and links I found useful.

## Create a VM inside Ubuntu 16.04 machine

In this case, I create a Centos 7 VM.

First install some packages:

```
sudo apt-get update
sudo apt-get install -y qemu-kvm libvirt-bin virtinst bridge-utils cpu-checker sshpass unar
```

Create a cloud init file so you can set the password.  I set it to "Password" but you
should set it to something stronger.  Then create the iso for your cloud init file.

```
cat << END > cloud-init1.txt
#cloud-config
password: Password
chpasswd: { expire: False }
ssh_pwauth: True
hostname: centos1
END

cloud-localds centos1.iso cloud-init1.txt
```

Create a command to create the VM quietly:

```
cat << END > create_vm.sh
sudo virt-install --name centos1 \
                  --disk ~/centos1.qcow2,device=disk,bus=virtio \
                  --disk ~/centos1.iso,device=cdrom \
                  --memory 1024 \
                  --os-type linux --os-variant centos7.0 --virt-type kvm --noautoconsole
END
```

Download a Centos 7 image and make a qmeu image backed by your original.  You can chose any
image -- I prefer the small one and then extract it.

```
sudo wget http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-20140929_01.qcow2
qemu-img create -f qcow2 -b CentOS-7-x86_64-GenericCloud-20140929_01.qcow2 centos1.qcow2

or get a smaller one and use `unar` to extract:

sudo wget http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2.xz
unar CentOS-7-x86_64-GenericCloud.qcow2.xz
qemu-img create -f qcow2 -b CentOS-7-x86_64-GenericCloud.qcow2 centos1.qcow2

```

Run your virt-install command to startup the VM; feel free to tweak it a bit (e.g., give it more RAM):

```
sudo virt-install --name centos1 --memory 1024 --disk ~/centos1.qcow2,device=disk,bus=virtio --disk ~/centos1.iso,device=cdrom --os-type linux --os-variant centos7.0 --virt-type kvm --noautoconsole

or

source create_vm.sh
```

Get the IP address of your VM from virsh:

```
domid=$(sudo virsh list |grep centos| awk '{print $1}')
ip=$(sudo virsh domifaddr $domid|grep vnet|awk '{print $4}'|sed 's/\/24//')
```

ssh into your VM using sshpass:

```
cp ~/.ssh/config ~/.ssh/backup_ssh_config123
cat << END > .ssh/config
Host 192.168.122.*
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
END

sshpass -p Password ssh centos@$ip "some command"
sshpass -p Password ssh centos@$ip "ls -l /tmp"
```

Destroy it when you're done:

```
sudo virsh destroy centos1
sudo virsh undefine centos1
```

## Allow root login

```
sudo apt-get install -y expect
./setRoot $ip Password

```

## References

Installing kvm basics: https://www.cyberciti.biz/faq/installing-kvm-on-ubuntu-16-04-lts-server/

virt-install help: http://manpages.ubuntu.com/manpages/bionic/man1/virt-install.1.html

Nice one lineers for creating various linux flavored VMs: https://raymii.org/s/articles/virt-install_introduction_and_copy_paste_distro_install_commands.html
