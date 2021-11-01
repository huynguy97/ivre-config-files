#!/bin/bash
stamp=`date +"%d-%m-%y-%H-%M-%S"` # This is used to distinguish the scans 
output=port$1-$stamp # This is used to distinguish the scans 

# Variables that can be used to point towards various files  
scan_templates=/etc/ivre.conf # This is the default location of nmap scan templates. 
output_scan_folder=/home/ubuntu/hostScans # Folder created to place the masscan/zmap results
processes=40 # Default is 30 as defined by IVRE. 40 seems to work as well without crashing. Adjust accordingly depending on cpu/ram. Too much procceses might also make the scans very loud.  
ips_to_scan=/home/ubuntu/ips.txt

template_choice(){
	awk '/NMAP_SCAN_TEMPLATES/{ print $0 }' $scan_templates | grep '".*"' -o
	echo "------------------------------"
	echo "Which scan do you want to run?"
}


general_scan(){
	ivre runscans --categories general-scan-$stamp --nmap-template service --output CommandLine
	echo "---------------------------------------------------------------------------------"
	echo "The above Nmap command will be ran after Masscan is done, please confirm y/n." 
	read confirm
	if [ "$confirm" = "y" ] || [ "$confirm" = "yes" ] 	
	then 	
		masscan -c generalscan.conf -iL $ips_to_scan -oL $output_scan_folder/massGeneral-$stamp.txt
		echo "-------------------------------------------------------------"
		echo "Done with Masscan. Cleaning up the output so Nmap can read it"
		echo "-------------------------------------------------------------"
		cd $output_scan_folder
		./cleanFile.sh massGeneral-$stamp.txt massGeneral-$stamp-cleaned.txt #i cleanFile.sh takes two arguments. Which file to clean and where to output the cleaned file. Also shuffles the ips around. 
		cd /home/ubuntu
		ivre runscans --categories generalScan-$stamp --file $output_scan_folder/massGeneral-$stamp-cleaned.txt --nmap-template service --output XMLFork --processes $processes
		ivre scan2db -c service -r /home/ubuntu/scans/generalScan-$stamp
		ivre db2view nmap --category service 
	else 
		echo "Aborting scan"
	fi
}

tcp_scan(){
	grep -B 4 'scans\s*=\s*"SV"' $scan_templates | grep 'NMAP_SCAN_TEMPLATES' | grep '".*"' -o
	echo "----------------------------------"
	echo "Which TCP scan do you want to run?"
	read choice 
	ivre runscans --output CommandLine --file $ips_to_scan --nmap-template $choice
	if [ $? -eq 0 ]
	then 
		echo "Please confirm y/n that this is the scan you want to run"
		read confirm
		if [ "$confirm" = "y" ] || [ "$confirm" = "yes" ] 	
		then 
						
			ports=$(grep -A 7 "NMAP_SCAN_TEMPLATES\s*\[\"$choice\"\]" $scan_templates | grep 'ports\s*=\s*"\(.*\)"*' | grep '[0-9]*' -o)
			massPorts=$(echo $ports | sed 's/\s\+/,/g')
			echo $massPorts
			masscan -c tcpscan.conf -iL $ips_to_scan -oL $output_scan_folder/mass-$stamp.txt -p $massPorts
        		cd hostScans/
			./cleanFile.sh mass-$stamp.txt mass-$stamp-cleaned.txt
			cd /home/ubuntu	
			ivre runscans --categories mass-$choice-$stamp --file $output_scan_folder/mass-$stamp-cleaned.txt --nmap-template $choice --output XMLFork --processes $processes 
			ivre scan2db -c $choice -r /home/ubuntu/scans/mass-$choice-$stamp
			ivre db2view nmap --category $choice
		else 
			echo "Aborting scan"
		fi
	else 
		echo "Incorrect scan template, please try again"
	fi	
}

udp_scan(){
    echo "Which zmap UDP probe file do you want to use? See https://github.com/zmap/zmap/tree/main/examples/udp-probes for the list of probes. Please type the complete file name. E.g. openvpn_1194.pkt"
    read probe 
    grep -B 4 'scans\s*=\s*"UV"' $scan_templates | grep 'NMAP_SCAN_TEMPLATES' | grep '".*"' -o
    echo "----------------------------------"
    echo "Which UDP scan do you want to run?"
    read choice
    ivre runscans --output CommandLine --file $ips_to_scan --nmap-template $choice
    if [ $? -eq 0 ] 
    then  
    	echo "Please confirm y/n that this is the scan you want to run"
    	read confirm
    	if [ "$confirm" = "y" ] || [ "$confirm" = "yes" ]
    	then
        	ports=$(grep -A 7 "NMAP_SCAN_TEMPLATES\s*\[\"$choice\"\]" $scan_templates | grep 'ports\s*=\s*"\(.*\)"*' | grep '[0-9]*' -o)
        	zmapPorts=$(echo $ports | sed 's/\s\+/,/g')
        	echo $zmapPorts
        	#zmap scan doen
		zmap -M udp -p $zmapPorts --allowlist-file=$ips_to_scan --probe-args=file:/home/ubuntu/zmap-3.0.0-beta1/examples/udp-probes/$probe --blocklist-file=/home/ubuntu/exlude.txt -o $output_scan_folder/mu-$stamp.txt	
        	ivre runscans --categories ss-$stamp --file $output_scan_folder/mu-$stamp.txt --nmap-template $choice --output CommandLine --processes $processes
    	else 
	    echo "Aborting scan"
    	fi
    else 
	    echo "Incorrect scan template inputted"
    fi
}

echo "Do you want to run a general (g), specific TCP (t) or UDP (u) port scan?"

read type 

if [ "$type" = "general" ] || [ "$type" = "g" ] 
then 
	general_scan
elif [ "$type" = "tcp" ]   || [ "$type" = "t" ] 
then	
	tcp_scan
elif [ "$type" = "udp" ] || [ "$type" = "u" ] 
then 
	udp_scan
else
	echo "Did not recognise input. Please try general (g) or specific (s)."
fi
