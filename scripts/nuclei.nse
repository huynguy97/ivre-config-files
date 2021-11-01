local shortport = require "shortport"
local stdnse = require "stdnse" 

description = [[
This script requires Nuclei and runs Nuclei. By default it tries to check whether it is a webserver and if true Nuclei will run on the hostname. The reason behind this is that most of the current Nuclei templates (2286 as of writing) are http templates. Thus running on hostname is the most accurate way. There is one script argument "nuclei.always" to force this script to run even on non-websevers. This is disabled by default as it would cause a lot of load. If the host is not a webserver or the hostname cannot be resolved by Nmap in some way, it will run on the ip. Nuclei is ran without intrusive scripts and with 1/5th of the default values. However, for some webservers the reduced values might still be rather load heavy so being cautious is advised.    
]] 

author = "Huy Nguyen" 

license = "Same as Nmap--See https://nmap.org/book/man-legal.html"

portrule = function(host,port) 
	return true
end 

action = function(host,port) 
	local handle = ""
        local always = stdnse.get_script_args("nuclei.always") -- can be yes if you want nuclei to always run, BUT this is very heavy load for a host if it has a lot of open ports. 
	local hostname = stdnse.get_hostname(host) -- if no hostname exists, nmap returns the input ip
	
	if     port.number == 80 then -- nuclei can run on any host, but for webservers we need to append http/http accordingly. 
		handle = io.popen("nuclei -u http://" .. hostname .. " -nc -silent -etags intrusive -rl 30 -rlm 1000 -bs 8 -c 8") -- these values are tuned down from the default higher values
	elseif port.number == 443 then 
		handle = io.popen("nuclei -u https://" .. hostname .. " -nc -silent -etags intrusive -rl 30 -rlm 1000 -bs 8 -c 8")
	elseif always == "yes" then      
		handle = io.popen("nuclei -u " .. hostname .. " -nc -silent -etags intrusive -rl 30 -rlm 1000 -bs 8 -c 8") -- runs on input ip if no webserver is found
	end 
	local result = handle:read("*a") 
	handle:close()
	return result
end 

