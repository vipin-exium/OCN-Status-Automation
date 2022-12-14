#!/bin/bash
# To continue with the tests we must logged into the exium-client using the workspace name and username
# create Data folder to store the required files for the script
i=1
echo
echo "+OCN-Automation Started..."
echo "+Getting current user name..."
current_username=$(whoami)
mkdir -p /home/${current_username}/ocn_automation
echo "+Folder ocn_automaton created..."
echo "+Deleting previous files inside ocn-automation directory..."
rm -f -R /home/${current_username}/ocn_automation/*
echo "+Files deleted successfully..."
slackrawdnsfile=/home/${current_username}/ocn_automation/slackrawdns
slackrawspafile=/home/${current_username}/ocn_automation/slackrawspa
detailedlogfile=/home/${current_username}/ocn_automation/detailed_log
rawconnectionstatusfile=/home/${current_username}/ocn_automation/rawconnectionstatus
pingspafile=/home/${current_username}/ocn_automation/pingspa
pingdnsfile=/home/${current_username}/ocn_automation/pingdns
internetconnectionfile=/home/${current_username}/ocn_automation/internetconnectionstatus
# Internet access check
wget -q --spider http://www.google.com
if [ $? -eq 1 ];  
then  
echo "-No Internet Connection is Available.!!!"
echo "-----Terminating OCN-Status-Check-----"
echo "No Internet Connection is Available"  >> $slackmessagefile
echo "Terminating OCN-Status-Check" >> $slackmessagefile
exit
else
echo -e "+Active Internet connection found..."
fi    
echo "+Collecting available servers..."
# display the available server list
echo "----------Available Servers------------------------------"
exium-cli servers
echo "---------------------------------------------------------"
# get OCN-servers names and save to available-servers-list file
exium-cli servers | sed 1d > /home/${current_username}/ocn_automation/available-servers-list
cat /home/${current_username}/ocn_automation/available-servers-list | awk '{print $1,$2}' > /home/${current_username}/ocn_automation/servername
cat /home/${current_username}/ocn_automation/available-servers-list | awk '{print $3}' | cat > /home/${current_username}/ocn_automation/servers
if [ $? -eq 0 ]; 
then  
echo "+OCN-Servers list created successfully..."
fi 
# check current connection status of the client
connectionstatus=$(exium-cli status | grep Active | cut -d ":" -f 2 | sed 's/ //g')
if [ $connectionstatus = 'Active' ];
then
connectionflag=1
else
connectionflag=0
fi
# disconnecting if its already connected
if [ $connectionflag -eq 1 ];
then
echo "-Disconnecting Active Connection..."
exium-cli disconnect
else 
echo "+No Active connection found..."
fi
now=$(date)
# OCN-Automation starts from here
echo
echo "---------------Starting OCN-Automation - $now---------------"

echo
echo "---------------Starting OCN-Automation - $now---------------" >> $detailedlogfile
echo >> $detailedlogfile
echo "SPA - [10.0.0.5] Ping Results" >> $slackrawspafile
echo >> $slackrawspafile
echo "DNS - [100.100.100.100] Ping Results" >> $slackrawdnsfile
echo >> $slackrawdnsfile
serverfile=/home/${current_username}/ocn_automation/servers
servernamefile=/home/${current_username}/ocn_automation/servername
filename=$serverfile
while read line; do
    sleep 30
    echo
    currentservername=$(cat $servernamefile | awk '{print $1,$2}' | sed -n $i'p')
    # connect to the corresponding ocn
    echo "---------------Connecting to OCN $line [$currentservername] ---------------"
    echo "--------------- Connecting to $line [$currentservername] ---------------" >> $detailedlogfile
    exium-cli connect -s $line
    sleep 30
    # check current connection status of the client
    connectionstatusocn=$(exium-cli status | grep Active | cut -d ":" -f 2 | sed 's/ //g')
    if [ $connectionstatusocn = 'Active' ];
    then
    connectionflagocn=1
    else
    connectionflagocn=0
    fi
    if [ $connectionflagocn -eq 1 ];
        then
        echo "+Successfully connected to $line [$currentservername] ..."
        echo "--------------- Successfully Connected - $line [$currentservername] ---------------" >> $detailedlogfile
        echo "Connection Successfull - $line [$currentservername]" >> $rawconnectionstatusfile
        # pinging DNS 100.100.100.100
        echo "---------------Ping Result For DNS - $line [$currentservername] ---------------" >> $detailedlogfile
        ping -c 10 100.100.100.100 > $pingdnsfile
        cat $pingdnsfile | tee -a $detailedlogfile > /dev/null
        echo "$line - $currentservername" >> $slackrawdnsfile
        cat $pingdnsfile | tail -n 2 | head -n1 >> $slackrawdnsfile
        echo >> $slackrawdnsfile
        echo >> $detailedlogfile
        sleep 30
        # pinging SPA 10.0.0.5
        echo "---------------Ping Result For SPA - $line [$currentservername] ---------------" >> $detailedlogfile
        ping -c 10 10.0.0.5 > $pingspafile
        cat $pingspafile | tee -a $detailedlogfile > /dev/null
        echo "$line - $currentservername" >> $slackrawspafile
        cat $pingspafile | tail -n 2 | head -n1 >> $slackrawspafile
        echo >> $detailedlogfile
        echo >> $slackrawspafile
        sleep 30
        # Checking Internet connection
        echo "---------------Checking Internet Connection---------------"
        wget -q --spider http://www.google.com
        if [ $? -eq 0 ]; then
            echo "---------------Internet is Accessible - $line [$currentservername] ---------------"
            echo "---------------Internet is Accessible - $line [$currentservername] ---------------" >> $detailedlogfile
            echo "______________________________________________________________________________________________" >> $detailedlogfile
            echo >> $detailedlogfile
            echo "Internet is Accessible - $line - $currentservername" >> $internetconnectionfile 
        else
            echo "---------------Not Able To Access Internet - $line [$currentservername] ---------------"
            echo "---------------Not able to access Internet - $line [$currentservername] ---------------" >> $detailedlogfile
            echo "______________________________________________________________________________________________" >> $detailedlogfile
            echo >> $detailedlogfile
            echo "Internet is Not Accessible - $line - [$currentservername]" >> $internetconnectionfile
        fi
        exium-cli disconnect
    else 
        echo "---------------Failed to connect - $line [$currentservername] ---------------"
        echo "---------------Failed to Connect - $line [$currentservername] ---------------" >> $detailedlogfile
        echo "Connection Failed - $line [$currentservername]" >> $rawconnectionstatusfile
        # connect to the same ocn for the second time
        echo "+Connecting to OCN $line [$currentservername] ---[Second Time]---"
        exium-cli connect -s $line
        sleep 30
        # check current connection status of the client
        connectionstatusocnsecond=$(exium-cli status | grep Active | cut -d ":" -f 2 | sed 's/ //g')
        if [ $connectionstatusocnsecond = 'Active' ];
            then
            connectionflagocnsecond=1
            else
            connectionflagocnsecond=0
            fi
        if [ $connectionflagocnsecond -eq 1 ];
            then
            echo
            echo "+Successfully Connected - $line [$currentservername] ---[Second Time]---"
            echo "+Successfully Connected - $line [$currentservername] ---[Second Time]---" >> $detailedlogfile
            echo "Connection Successfull - $line [$currentservername] - [Second Time]" >> $rawconnectionstatusfile

            # pinging DNS 100.100.100.100
            echo "---------------Ping Result For DNS - $line [$currentservername] ---[Second Time]------------------" >> $detailedlogfile
            ping -c 10 100.100.100.100 > $pingdnsfile
            cat $pingdnsfile | tee -a $detailedlogfile > /dev/null
            echo "$line - $currentservername" >> $slackrawdnsfile
            cat $pingdnsfile | tail -n 2 | head -n1 >> $slackrawdnsfile
            echo >> $slackrawdnsfile
            echo >> $detailedlogfile
            sleep 30
            # pinging SPA 10.0.0.5
            echo "---------------Ping Result For SPA - $line [$currentservername] ---[Second Time]------------------" >> $detailedlogfile
            ping -c 10 10.0.0.5 > $pingspafile
            cat $pingspafile | tee -a $detailedlogfile > /dev/null
            echo "$line - $currentservername" >> $slackrawspafile
            cat $pingspafile | tail -n 2 | head -n1 >> $slackrawspafile
            echo >> $detailedlogfile
            echo >> $slackrawspafile
            sleep 30
            # Checking Internet connection
            echo "+Checking Internet Connection ---[Second Time]---"
            wget -q --spider http://www.google.com
            if [ $? -eq 0 ]; then
                echo "---------------Internet is Accessible - $line [$currentservername] ---[Second Time]------------------"
                echo "Internet is Accessible - $line [$currentservername] ---[Second Time]---" >> $detailedlogfile
                echo "______________________________________________________________________________________________" >> $detailedlogfile
                echo >> $detailedlogfile
                echo "Internet is Accessible - $line - $currentservername" >> $internetconnectionfile
            else
                echo "---------------Not able to access Internet - $line [$currentservername] ---[Second Time]------------------"
                echo "Not Able To Access Internet - $line [$currentservername] ---[Second Time]---" >> $detailedlogfile
                echo "______________________________________________________________________________________________" >> $detailedlogfile
                echo >> $detailedlogfile
                echo "Internet is Not Accessible - $line - $currentservername" >> $internetconnectionfile
            fi
            exium-cli disconnect
        else 
            echo "-Failed to Connect - $line [$currentservername] ---[Second Time]---"
            echo "Failed to Connect - $line [$currentservername] ---[Second Time]---" >> $detailedlogfile
            echo "______________________________________________________________________________________________" >> $detailedlogfile
            echo >> $detailedlogfile
            echo "Connection Failed - $line [$currentservername]" >> $rawconnectionstatusfile
        fi
    fi
i=$((i+1))   
done < $filename
exium-cli disconnect > /dev/null
echo
echo "---------------OCN Automation Finished---------------"
echo >> $detailedlogfile
echo "---------------OCN Automation Finished---------------" >> $detailedlogfile

#report generation starts from here
#success messages 
#sending results of the automation script using bot to slack channel exedge-monitoring-results
./slackbot -c exedge-monitoring-results -m "`cat /home/${current_username}/ocn_automation/rawconnectionstatus`"
echo "+Connection Status Results Sent..."
sleep 3
./slackbot -c exedge-monitoring-results -m "`cat /home/${current_username}/ocn_automation/slackrawdns`"
echo "+DNS Results Sent..."
sleep 3
./slackbot -c exedge-monitoring-results -m "`cat /home/${current_username}/ocn_automation/internetconnectionstatus`"
echo "+Internet Connection Results Sent..."
sleep 3
./slackbot -c exedge-monitoring-results -m "`cat /home/${current_username}/ocn_automation/slackrawspa`"
echo "+SPA Results Sent..."
exit