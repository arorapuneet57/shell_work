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
        fi 

        # Set Hostname
        date +"%m.%d.%Y %T " ; echo "Setting Hostname..."
        hostnamectl set-hostname $HOSTNAME --static

        # Notification for future
        date +"%m.%d.%Y %T "
        echo "This script will not be executed on next boot if $STATE file exists"
        echo "If you want to execute this configuration on Next boot remove $STATE file"

        date +"%m.%d.%Y %T " ; echo "Creating State file"
        date > /opt/ovfset/state

        # Wait a bit and reboot
        sleep 5
#        reboot
fi
