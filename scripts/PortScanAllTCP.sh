#!/bin/bash

# A word of warning. This file performs ALL TCP scans. So even those such as RDP, test-ssl and Nuclei that might 
# end up freezing on some hosts. 
# A simple solution would be to exclude these scans with an if statement and afterwards run them manually to check if they freeze.

tcp_targets=($(grep -B 4 'scans\s*=\s*"SV"' /etc/ivre.conf | grep 'NMAP_SCAN_TEMPLATES' | grep '".*"' -o | sed 's/.//;s/.$//'))
length_tcp=${#tcp_targets[@]} # list of nmap scan templates
for ((i=0; i != length_tcp; i++)) do
        temporary=${tcp_targets[i]} 
        printf "t\n%s\ny" "$temporary" | ./PortScan.sh
done

