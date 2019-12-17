# mount the cdrom
#mkdir /mnt/isomount
#mount /dev/cdrom /mnt/isomount
#if [  $? == 0 ]; then
   # Create user-data file 
   > user-data
   > temp-file
   cat > user-data << EOL
   #cloud-config
   write_files:
   - path: /mnt/prov.ini
     permissions:  '0644'
     content: |
   EOL
   cat user-data
   grep -ir "Property oe:key" ovf-env.xml | awk {'print $3, $4'}> all_sorted_values
   while read -r entry; do mykey=`echo $entry | awk {'print $1'} | cut -d '=' -f2`; myvalue=`echo $entry | awk {'print $2'} | cut -d '=' -f2`; echo "    $mykey": $myvalue >> user-data; done < all_sorted_values
   sed 's/"//g' user-data > temp-file
   sed 's/\/>//g' temp-file > user-data
#fi
# unmount the cdrom

#umount /mnt/isomount
# reboot the system
#reboot
