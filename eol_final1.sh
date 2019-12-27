# declare variables
MOUNT_DIR="/tmp/config"
#OPENSTACK_DIR="/root/vm-init/results"
OPENSTACK_DIR="/tmp"
USER_DATA="$OPENSTACK_DIR/user_data"
OVF_XML_PATH="$MOUNT_DIR/ovf-env.xml"

# mount the cdrom
mkdir -p $MOUNT_DIR
# mount /dev/sr0 /config
mount /dev/cdrom $MOUNT_DIR

# check config_drive properly mounted
if [  $? != 0 ]; then
   echo "config_drive not mounted, check if /dev/sr0 is available or not > /home/vm-root/output.txt"
   exit 0
fi

# clean the content of files
> $USER_DATA
> temp-file

# create cloud-init script and put it in /config_drive/openstack/latest/user_data folder
cat > $USER_DATA << EOL
#cloud-config
write_files:
- path: /mnt/prov.ini
  permissions:  '0644'
  content: |
EOL

grep -ir "Property oe:key" $OVF_XML_PATH | grep -v "hostname" | grep -v "fqdn" | awk {'print $2, $3'} > all_sorted_values
echo "all sorted conetnt content" > /home/vm-root/output.txt
while read -r entry; do mykey=`echo $entry | awk {'print $1'} | cut -d '=' -f2`; myvalue=`echo $entry | awk {'print $2'} | cut -d '=' -f2`; echo "    $mykey": $myvalue >> $USER_DATA;  done < all_sorted_values
grep -ir "Property oe:key" $OVF_XML_PATH | egrep  "hostname|\"fqdn"  | awk {'print $2, $3'} > all_sorted_values
while read -r entry; do mykey=`echo $entry | awk {'print $1'} | cut -d '=' -f2`; myvalue=`echo $entry | awk {'print $2'} | cut -d '=' -f2`; echo "$mykey": $myvalue >> $USER_DATA;  done < all_sorted_values
echo "manage_etc_hosts: true" >> $USER_DATA

# remove the '"' and '/>' from out file
sed 's/"//g' $USER_DATA > temp-file
sed 's/\/>//g' temp-file > $USER_DATA

echo "user_data content" >> /home/vm-root/output.txt
cat $USER_DATA >> /home/vm-root/output.txt
# unmount the config_drive
umount $MOUNT_DIR
rm -rf $MOUNT_DIR

touch /tmp/OVF_READ

# remove lock from vm-init to execute cloud-init script during next boot
rm -f /root/vm-init/.lock

# reboot the machine
reboot
