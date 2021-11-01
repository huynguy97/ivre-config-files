# Technical notes IVRE internship
This document serves as a readme with more technical details than the general report. 
# Scanning
## Phase 1: Host discovery with Masscan & Zmap

In the first phase Masscan and Zmap are used to quickly find which hosts are online. These hosts are then passed onto Nmap. These scans should be seen as a quick way to get a general overview. Therefore, not a lot of specific scripts are ran.  
### Masscan 
Is used for TCP and uses the masscan config file `generalscan.conf` to control the scan rate and which ports are scanned. This config file contains 256 commonly used ports.  A default rate of 50.000 is chosen as this seems to a good balance between speed and accuracy. 
[See also the following for a good discussion and research regarding performance and accuracy.](https://captmeelo.com/pentest/2019/07/29/port-scanning.html ) 
After Masscan is done the bash script `cleanFile.sh` is called which cleans up the Masscan output such that Nmap can read it. 
### Zmap 
Is used for UDP as Masscan does not seem to work with UDP. Masscan version 1.05 and 1.32 were tried, but both don't seem to work. [See also this Github issue]( https://github.com/robertdavidgraham/masscan/issues/182)
Thus Zmap was chosen for UDP scans. Zmap version 3.0.0 Beta 1 was used as this was strongly recommended by the developers. However, the beta sometimes crashes with a segmentation fault when scanning. Zmap scans fast enough so restarting a scan every now and then is not too much a problem. 

## Phase 2: Nmap for more specific scans
As mentioned before, all of the results (list of IPs which are shuffled) of Masscan and Zmap are passed onto Nmap. Afterwards two types of scans are ran:
1. General scans. A service version scan and OS detection. The Nmap service version scan is performed with certain scripts. 
The [default Nmap scripts](https://nmap.org/nsedoc/categories/default.html), [unusual-port](https://nmap.org/nsedoc/scripts/unusual-port.html) and [vulners](https://nmap.org/nsedoc/scripts/vulners.html) are used. Note that vulners does not know about any other context such as backports and can be rather inaccurate because of that. 
The other general scan that is done is OS detection. 
2. For the specific scans, there are too many Nmap scripts being used for that so [see the nmap scan templates for all details](https://github.com/huynguy97/ivre-config-files/blob/main/ivre-conf.txt). 
 
Relevant findings, including issues:
* Nmap scanning port 3389 RDP freezes at some point. I do not know why and trying various options such as reducing the scanning speed or reducing the amount of processes or even manually running Nmap instead of letting IVRE run Nmap do not seem to help. This seems to be an Nmap [issue](https://github.com/nmap/nmap/issues/1385). Setting timeouts do not help. 
* Port 500 IPSec is done with the help of [ike-scan](https://github.com/royhills/ike-scan). The output of ike-scan is converted into a list of IPs which is then passed onto Nmap. However, Nmap freezes when ran under IVRE. Manually running Nmap does seem to work.  
* Port 53 dns can find open resolvers with [the following Nmap script](https://nmap.org/nsedoc/scripts/dns-recursion.html).
* UDP scans relies on Zmap having a UDP probe for a certain service. If such UDP probe exists, then it can be passed onto Nmap. An alternative would be to use Masscan for UDP scanning, but that does not work currently. 


# Other tools. 
Some other tools and scanners were also used. At first the idea was to use an ELK stack to store these results as IVRE does not support other tools and scanners other than a select few.
However, a workaround was found that works as follows:

1. Write an Nmap script that runs these external scanners or tools. As Nmap scripts are Lua, it is easy to [create a pipe](https://stackoverflow.com/questions/9676113/lua-os-execute-return-value) and run bash commands. 
2. Format the output so that it is readable and importable in IVRE.  
3. Use IVRE to run Nmap and execute these scripts. 

A positive of this approach is that it is rather easy and can be quickly set up. 
A downside of this is that these Nmap scripts can become a bit complex if you want to pass on every possible option from an external tool. 

The following tools are used:
1. [WhatWeb](https://github.com/urbanadventurer/WhatWeb). Useful for finding out what kind of web technology is being used. For example, if there is a WordPress vulnerability that pops up it is possible to quickly find out which sites use WordPress.
2. [ssh-audit](https://github.com/jtesta/ssh-audit). Analyses SSH configurations, algorithms used and various other SSH information. 
3. [test-ssl](https://github.com/drwetter/testssl.sh). An SSL vulnerability scanner. However, it returns a lot of information. I have chosen to only return results of the severity HIGH or worse by default.  
4. [wp-scanner](https://github.com/projectdiscovery/nuclei). A WordPress scanner.    
5. [Nuclei](https://github.com/projectdiscovery/nuclei). A vulnerability scanner. 

Relevant findings, including issues: 
* test-ssl sometimes does not finish. Against host 130.89.190.39 (a printer or something) and 185.116.125.96 test-ssl seems to freeze. As test-ssl is still in developement it is perhaps not unexpected to encouter some issues. Due to these hosts causing issues, it unfortunately also caused my other scans to crash and as a result there are roughly 300 hosts missing. Nonetheless, being able to run test-ssl on the other ~12.000 hosts is still a good result. A simple solution would be to set `host-timeout` in Nmap. 
* IVRE has built in Nuclei support, but this was so buggy and frustrating to work with that I decided to build in Nuclei support myself. Positives of this is that every single Nuclei output is supported this way. Even ones that might be released in the future. As long as the output format does not change, my script should work.
* Nuclei apparently has rather aggressive defaults for some hosts so I halved the defaults after complaints from Amsterdam UMC. This should double the scan time from 14~ hours to 28~ hours. 
* Nuclei crashes against host http://data.groenmonitor.nl

# IVRE 
It helps to read about the [web interface](https://doc.ivre.rocks/en/latest/usage/web-ui.html) and as I have added some other scanners myself there is an extra tab "External". This should make searching for results from external tools easier. It also includes some other small things that I have added such as honeypot filtering.  

All scans are grouped up in a category. These categories have the same names as the [nmap_scan_templates](https://github.com/huynguy97/ivre-config-files/blob/main/ivre-conf.txt). For example, when running a template named ```http``` will also create a category in IVRE named `http`. 

# Scripts and config files
A summary of all scripts and config files used. See also on github. 

## Bash scripts
`Portscan.sh` =  a simple bash script that can run every scan. It calls various other scripts and config files that will be explained below. Must run with sudo rights for Masscan and Nmap. All of the parameters can be changed at the beginning of the file. It is slightly hardcoded to only accept nmap_scan_templates that adhere to the "correct" template. So if you add a template and follow the examples everything should work fine. 
`cleanFile.sh` = this script is just a oneliner that cleans up the Masscan output such that Nmap can properly read it. Also shuffles the IPs. 

## Masscan config files. 
For Masscan there are two config files that control the scan speed and exclude files. 
`tcpscan.conf` = used for small TCP scans. For example, scanning only SSH port 22 or only HTTP ports 80/443. Default scan rate of 5.000.
`generalscan.conf` = used for the bigger TCP scans. For example, the general scan on 256 ports. Default scan rate of 50.000. 

## Nmap 
`/etc/ivre.conf` = contains all nmap_scan_templates. Which is how IVRE configures Nmap scans. These templates are passed onto Nmap for scans. See also [here](https://doc.ivre.rocks/en/latest/install/config.html) and [here](https://github.com/ivre/ivre/blob/master/ivre/nmapopt.py). 
`whatweb.nse` = runs [whatweb](https://github.com/urbanadventurer/WhatWeb). Script arguments can be supplied to change aggression level. By default it runs stealthy. 
`nuclei.nse` = runs [nuclei](https://github.com/projectdiscovery/nuclei)
`test-ssl.nse` = runs [test-ssl](https://testssl.sh). Script arguments can be supplied to change output. By default only outputs severity HIGH or worse. 
`ssh-audit.nse` = runs [ssh-audit](https://github.com/jtesta/ssh-audit)

# Potentially useful tools and sources. 
I came across a lot of tools and scanners that are potentially useful, but I have not looked at them all of them myself. 

https://www.trustwave.com/en-us/resources/blogs/spiderlabs-blog/still-scanning-ip-addresses-you-re-doing-it-wrong/

https://www.trustwave.com/en-us/resources/blogs/spiderlabs-blog/are-you-really-scanning-what-you-think/

https://book.hacktricks.xyz/

https://www.reddit.com/r/Pentesting/comments/9ondj5/a_good_pentesting_tools_list/

https://pentest-standard.readthedocs.io/en/latest/intelligence_gathering.html

https://research.securitum.com/nmap-and-12-useful-nse-scripts/

https://www.reddit.com/r/netsecstudents/comments/96boky/does_anyone_have_a_curated_list_of_tools_they_use/

Also special thanks to the IVRE and Nuclei devs for personally answering my questions. 