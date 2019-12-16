#!/bin/bash 
servers=$1

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
fi

for i in "${servers[@]}"; do

    echo $i
    if [ "$i" != " " ]; then 
        netstat_out = $(netstat -at | grep ':22' | grep "ESTABLISH" )
        echo $netstat_out
    esle
        echo "command line having empty values" 
    fi

done
