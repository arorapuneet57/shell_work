# mount the cdrom
mkdir -p /config_drive/openstack/latest
mount /dev/sr0 /config_drive

# check config_drive properly mounted
if [  $? != 0 ]; then
   echo "config_drive not mounted, check if /dev/sr0 is available or not "
   exit 0
fi

# declare variables
OPENSTACK_DIR="/config_drive/openstack/latest"
USER_DATA="$OPENSTACK_DIR/user-data"
OVF_XML_PATH="/config_drive/ovf-env.xml"

# clean the content of files
> $USER_DATA
> temp-file

# create cloud-init script and put it in /config_drive/openstack/latest/user-data folder
cat > $USER_DATA << EOL
#cloud-config
write_files:
- path: /mnt/prov.ini
  permissions:  '0644'
  content: |
EOL

grep -ir "Property oe:key" $OVF_XML_PATH | grep -v "hostname" | grep -v "fqdn" | awk {'print $3, $4'} > all_sorted_values
while read -r entry; do mykey=`echo $entry | awk {'print $1'} | cut -d '=' -f2`; myvalue=`echo $entry | awk {'print $2'} | cut -d '=' -f2`; echo "    $mykey": $myvalue >> $USER_DATA;  done < all_sorted_values
grep -ir "Property oe:key" $OVF_XML_PATH | egrep  "hostname|\"fqdn"  | awk {'print $3, $4'} > all_sorted_values
while read -r entry; do mykey=`echo $entry | awk {'print $1'} | cut -d '=' -f2`; myvalue=`echo $entry | awk {'print $2'} | cut -d '=' -f2`; echo "$mykey": $myvalue >> $USER_DATA;  done < all_sorted_values
echo "manage_etc_hosts: true" >> $USER_DATA

# remove the '"' and '/>' from out file 
sed 's/"//g' $USER_DATA > temp-file
sed 's/\/>//g' temp-file > $USER_DATA

# unmount the config_drive
#umount /config_drive

# remove lock from vm-init to execute cloud-init script during next boot
rm -f /root/vm-init/.lock

# reboot the machine 
reboot
