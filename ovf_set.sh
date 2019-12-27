#!/bin/bash

STATE='/opt/ovfset/state'

if [ -e $STATE ]
    then
        date +"%m.%d.%Y %T "
        echo "$STATE file exists. Doing nothing."
        exit 1
    else
        echo "+++++++++++++++++++++++++++++++++++++++++++"
        echo "++++++++++++ OVF Config script ++++++++++++"
        echo "+ System will be rebooted after execution +"
        echo "+++++++++++++++++++++++++++++++++++++++++++"

        echo "nameserver 10.132.71.1" > /etc/resolv.conf
        echo "search eng.vmware.com vmware.com" >> /etc/resolv.conf
        # create XML file with settings
        date +"%m.%d.%Y %T " ; echo "Fetcing values"
        vmtoolsd --cmd "info-get guestinfo.ovfenv" > /tmp/ovf_env.xml
        TMPXML='/tmp/ovf_env.xml'

        # gathering values
        date +"%m.%d.%Y %T "; echo "Sorting..."
        IP=`cat $TMPXML| grep ip.0 |awk -F'"' '{print $4}'`
        PREFIX=`cat $TMPXML| grep prefix.0 |awk -F'"' '{print $4}'`
        GW=`cat $TMPXML| grep gateway |awk -F'"' '{print $4}'`
        HOSTNAME=`cat $TMPXML| grep hostname |awk -F'"' '{print $4}'`
        DNS0=`cat $TMPXML| grep dns.0 |awk -F'"' '{print $4}'`
        DNS1=`cat $TMPXML| grep dns.1 |awk -F'"' '{print $4}'`
        DNSSEARCH=`cat $TMPXML| grep dns.search |awk -F'"' '{print $4}'`
        MAC=`cat $TMPXML| grep Adapter |awk -F'"' '{print $2}'`
        VSPHERE_SERVER=`cat $TMPXML| grep VSPHERE_SERVER |awk -F'"' '{print $4}'`
        VSPHERE_USERNAME=`cat $TMPXML| grep VSPHERE_USERNAME |awk -F'"' '{print $4}'`
        VSPHERE_PASSWORD=`cat $TMPXML| grep VSPHERE_PASSWORD |awk -F'"' '{print $4}'`
        VSPHERE_DATACENTER=`cat $TMPXML| grep VSPHERE_DATACENTER |awk -F'"' '{print $4}'`
        VSPHERE_DATASTORE=`cat $TMPXML| grep VSPHERE_DATASTORE |awk -F'"' '{print $4}'`
        VSPHERE_NETWORK=`cat $TMPXML| grep VSPHERE_NETWORK |awk -F'"' '{print $4}'`
        VSPHERE_RESOURCE_POOL=`cat $TMPXML| grep VSPHERE_RESOURCE_POOL |awk -F'"' '{print $4}'`
        VSPHERE_FOLDER=`cat $TMPXML| grep VSPHERE_FOLDER |awk -F'"' '{print $4}'`
        VSPHERE_TEMPLATE=`cat $TMPXML| grep VSPHERE_TEMPLATE |awk -F'"' '{print $4}'`
        MGMT_NODE=`cat $TMPXML| grep MGMT_NODE |awk -F'"' '{print $4}'`
        WORKER_NODE1=`cat $TMPXML| grep WORKER_NODE1 |awk -F'"' '{print $4}'`
        WORKER_NODE2=`cat $TMPXML| grep WORKER_NODE2 |awk -F'"' '{print $4}'`
        #NETWORK_NAME=`cat $TMPXML| grep NETWORK_NAME |awk -F'"' '{print $4}'`
        MGMT_FILENAME='/home/vagrant/machine_non_dhcp.yaml'
        WORKER_FILENAME='/home/vagrant/worker_machine_non_dhcp.yaml'
        sed -i "s/VSPHERE_SERVER='.*.'/VSPHERE_SERVER='$VSPHERE_SERVER'/g" /home/vagrant/clusterapi/envvars.txt 
        sed -i "s/VSPHERE_USERNAME='.*.'/VSPHERE_USERNAME='$VSPHERE_USERNAME'/g" /home/vagrant/clusterapi/envvars.txt 
        sed -i "s/VSPHERE_PASSWORD='.*.'/VSPHERE_PASSWORD='$VSPHERE_PASSWORD'/g" /home/vagrant/clusterapi/envvars.txt 
        sed -i "s/VSPHERE_DATACENTER='.*.'/VSPHERE_DATACENTER='$VSPHERE_DATACENTER'/g" /home/vagrant/clusterapi/envvars.txt 
        sed -i "s/VSPHERE_DATASTORE='.*.'/VSPHERE_DATASTORE='$VSPHERE_DATASTORE'/g" /home/vagrant/clusterapi/envvars.txt 
        sed -i "s/VSPHERE_NETWORK='.*.'/VSPHERE_NETWORK='$VSPHERE_NETWORK'/g" /home/vagrant/clusterapi/envvars.txt 
        sed -i "s/VSPHERE_RESOURCE_POOL='.*.'/VSPHERE_RESOURCE_POOL='$VSPHERE_RESOURCE_POOL'/g" /home/vagrant/clusterapi/envvars.txt 
        sed -i "s/VSPHERE_FOLDER='.*.'/VSPHERE_FOLDER='$VSPHERE_FOLDER'/g" /home/vagrant/clusterapi/envvars.txt 
        sed -i "s/VSPHERE_TEMPLATE='.*.'/VSPHERE_TEMPLATE='$VSPHERE_TEMPLATE'/g" /home/vagrant/clusterapi/envvars.txt
        if [ "$MGMT_NODE" != "" ]; then
           python /home/vagrant/change_net_ops.py $MGMT_FILENAME $MGMT_NODE $DNS0 $GW $VSPHERE_NETWORK $VSPHERE_TEMPLATE
           python /home/vagrant/change_net_ops.py  $WORKER_FILENAME $WORKER_NODE1 $DNS0 $GW $VSPHERE_NETWORK $WORKER_NODE2 $VSPHERE_TEMPLATE
           echo "dhcp disabled" > /home/vagrant/dhcp_disabled
        fi
     #   sed -i "s/ipAddrs: .*.'/ipAddrs: '$MGMT_NODE'\/24/g" /home/vagrant/machine_non_dhcp.yaml
     #   sed -i "s/gateway4: .*.'/gateway4: '$GW'/g" /home/vagrant/machine_non_dhcp.yaml
     #   sed -i "s/- networkName: .*./- networkName: '$NETWORK_NAME'/g" /home/vagrant/machine_non_dhcp.yaml
     #   sed -i "s/nameservers: .*.'/nameservers: '$DNS0'/g" /home/vagrant/machine_non_dhcp.yaml
     #   sed -i "s/gateway4: .*.'/gateway4: '$GW'/g" /home/vagrant/machine_non_dhcp.yaml
     #   sed -i "s/ipAddrs: .*.'/ipAddrs: '$MGMT_NODE'/g" /home/vagrant/machine_non_dhcp.yaml
        
        # NMCLI fetch existing netwrok interface device name
        date +"%m.%d.%Y %T "; echo "Gathering info about network interfaces..."
        IFACE=`nmcli dev|grep ethernet|awk '{print $1}'`

        # NMCLI fetch existing connection name. This will have to be recreated.
        CON=`nmcli -t -f NAME c show`
        # NMCLI remove connection
        nmcli con delete "$CON"

        # Create new connection
        date +"%m.%d.%Y %T " ; echo "Setting Network settings...."
        # Check if IP and PREFIX variables exist and are not empty
        if [ -z ${IP+x} ] && [ -z ${PREFIX+x} ]; then
                date +"%m.%d.%Y %T " ; echo "No IP information found. Trying DHCP"
                # IF empty configure connection to use DHCP
                nmcli con add con-name "$IFACE" ifname "$IFACE" type ethernet
            else
                date +"%m.%d.%Y %T " ; echo "Setting..."
                # If variables exist, configure interface with IP and netmask and GW. Also set DNS settings in same step.
                nmcli con add con-name "$IFACE" ifname $IFACE type ethernet ip4 $IP/$PREFIX gw4 $GW && echo "IP set to $IP/$PREFIX. GW set to $GW"
                nmcli con mod "$IFACE" ipv4.dns "$DNS0,$DNS1" && echo "DNS set to $DNS0,$DNS1"
                nmcli con mod "$IFACE" ipv4.dns-search "$DNSSEARCH" && echo "DNS SEARCH set to $DNSSEARCH"
                echo "in else part Puneet"
                ifconfig $IFACE $IP/$PREFIX up
                route add default gw $GW dev $IFACE
        fi 

        # Set Hostname
        date +"%m.%d.%Y %T " ; echo "Setting Hostname..."
        #hostnamectl set-hostname $HOSTNAME --static

        # Notification for future
        date +"%m.%d.%Y %T "
        echo "This script will not be executed on next boot if $STATE file exists"
        echo "If you want to execute this configuration on Next boot remove $STATE file"

        date +"%m.%d.%Y %T " ; echo "Creating State file"
        date > /opt/ovfset/state

	cp /etc/resolv.conf /root/resolv.conf
        rm -rf /etc/resolv.conf
        cp /root/resolv.conf /etc/resolv.conf
        echo "nameserver 10.132.71.1" > /etc/resolv.conf
        echo "search eng.vmware.com vmware.com" >> /etc/resolv.conf
        cat /etc/resolv.conf
        # Wait a bit and reboot
        sleep 5
fi
echo "nameserver 10.132.71.1" > /etc/resolv.conf
echo "search eng.vmware.com vmware.com" >> /etc/resolv.conf
