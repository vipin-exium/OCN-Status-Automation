# OCN-Status-Automation
This script automates the testing of each and every xE(exedge) available in the exium-cli(xClient) application available for linux
The script will try to connect to each OCN and does various testing required for checking the status of the exedges.

Actions Performed -
1) Try to connect to exedge
2) Pings DNS - 100.100.100.100
3) Pings SPA - 10.0.0.5
4) gathers all the results
5) puts into #exedge-monitoring-results channel in slack [Exium workspace]
                    
Note : The script utilizes linux client for connecting and checking the status of OCN
       If any of the OCN is down pls double check using the windows or linux client
       Because sometimes the linux client will fail to connect to the exedge but the windows client will not experience any failures
