importvm() {
	echo -e "${GREEN}Exporting $1 from $esxi ${CLEAR}"
	mkdir ./imports/$1
	./ovftool/ovftool vi://$user:$pass@$esxi/$1 ./imports/$1/$1.ovf

	echo -e "${GREEN}Importing $1 into $store ${CLEAR}"
	nextid=`pvesh get /cluster/nextid`
	qm importovf $nextid ./imports/$1/$1.ovf $store

	rm -rf ./imports/$1
}

#colors
GREEN='\033[0;32m'
CLEAR='\033[0m' #no color

# Check if ovftools is installed, if not install it
apt install unzip -y > /dev/null
if [ ! -f ovftool/ovftool ]; then
	wget https://github.com/rgl/ovftool-binaries/raw/main/archive/VMware-ovftool-4.6.3-24031167-lin.x86_64.zip
	unzip VMware*
	rm -rf VMware*
fi

# Set up working directory
mkdir imports
if [ ! -f inventory.txt ]; then
	echo -e ":Windows:\n:Linux:" >> inventory.txt
	echo -e "${GREEN}Please configure inventory.txt!${CLEAR}"
	exit
fi

# Take user input for creds and parameters
echo "Enter ESXI User:"
read user
echo "Enter ESXI Pass:"
read -s pass
echo "Enter ESXI IP:"
read esxi
echo "Name of proxmox storage for imported VMs:"
read store

# Export and import windows VMs
for vm in $(sed -n '/:Windows:/d;/:/q;p' inventory.txt); do
	importvm $vm
	echo -e "${GREEN}Setting Windows Specific Settings${CLEAR}"
	qm set $nextid -sata0 $store:vm-$nextid-disk-0
	qm set $nextid -boot order=sata0
	qm set $nextid -bootdisk sata0
	qm set $nextid -scsihw virtio-scsi-pci
	qm set $nextid -bios ovmf
	qm set $nextid -delete scsi0
	qm set $nextid -agent 1
done

# Export and import linux VMs
for vm in $(sed -n '/:Linux:/d;$p' inventory.txt); do
	importvm $vm
done
