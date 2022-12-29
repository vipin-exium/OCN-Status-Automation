#!/bin/bash
echo
exium-cli status
echo "--------------DNS test - 100.100.100.100--------------"
ping -c 5 100.100.100.100
echo
echo
echo "----------SPA Access test - 10.0.0.5----------"
ping -c 5 10.0.0.5
echo
echo
echo "----------Google DNS test - 8.8.8.8----------"
ping -c 5 8.8.8.8
echo
echo
wget -q --spider http://www.google.com
if [ $? -eq 0 ]; then
                echo "Internet is Accessible - [Successful]"
                echo
            else
                echo "Not Able To Access Internet - [Failed]"
                echo
fi
