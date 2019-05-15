#!/bin/bash

set -x

cd

sudo apt-get update
sudo apt-get install -y qemu-kvm libvirt-bin virtinst bridge-utils cpu-checker sshpass expect

cat << END > cloud-init1.txt
#cloud-config
password: Password
chpasswd: { expire: False }
ssh_pwauth: True
hostname: centos1
END

cloud-localds centos1.iso cloud-init1.txt

sudo wget http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-20140929_01.qcow2
qemu-img create -f qcow2 -b CentOS-7-x86_64-GenericCloud-20140929_01.qcow2 centos1.qcow2

sudo virt-install --name centos1 --memory 2048 --disk ~/centos1.qcow2,device=disk,bus=virtio --disk ~/centos1.iso,device=cdrom --os-type linux --os-variant centos7.0 --virt-type kvm --noautoconsole

domid=$(sudo virsh list |grep centos| awk '{print $1}')
echo $domid

for i in {1..60}; do
  sleep 10
  t=$(sudo virsh list | grep centos1 | grep running | wc -l)
  if [ $t -eq 0 ]; then
    echo "Waiting a little longer for VM to be running"
    continue
  fi

  ip=$(sudo virsh domifaddr $domid|grep vnet|awk '{print $4}'|sed 's/\/24//')
  if [ -z $ip ] ; then
    echo "Waiting a little longer to get an IP"
  else
    break
  fi
done

if [ -z $ip ] ; then
  echo "VM is still not up after a long time; aborting"
  exit 1
else
  echo "Centos7 VM IP=$ip"
fi

cp ~/.ssh/config ~/.ssh/backup_ssh_config123
sudo cat << END > .ssh/config
Host 192.168.122.*
   StrictHostKeyChecking no
   UserKnownHostsFile=/dev/null
END

git clone https://github.com/dperique/kvm_examples.git
./kvm_examples/setRoot.sh $ip Password

sshpass -p Password ssh root@$ip "cat /etc/centos-release"
sshpass -p Password ssh root@$ip "yum install -y tcpdump"
