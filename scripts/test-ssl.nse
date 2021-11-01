local shortport = require "shortport"
local stdnse = require "stdnse"

description = [[ 
This script requires test-ssl and runs test-ssl. By default it only shows results of severity HIGH or worse. Using the script argument "test-ssl.severity" it can be set to "LOW", "MEDIUM", "HIGH" or "CRITICAL". 
Note that test-ssl is very thorough and takes a lot of time to run. It can also run on every port where SSL is detected.  
]]

author = "Huy Nguyen"

license = "Same as Nmap--See https://nmap.org/book/man-legal.html"

portrule = shortport.ssl  

action = function(host,port)
	local severity = stdnse.get_script_args("test-ssl.severity")
	local handle = ""
	local stamp = os.time(os.date("!*t"))
	if (severity == "LOW" or severity == "MEDIUM" or severity == "HIGH" or severity == "CRITICAL") then 
		handle = io.popen("/home/ubuntu/testssl.sh/testssl.sh --warnings batch --severity " .. severity .. " --jsonfile /home/ubuntu/testssl.sh/scans/" .. host.ip .. ":" ..  port.number .. "-" .. stamp .. " " .. host.ip .. ":" .. port.number .. " > /dev/null; cat /home/ubuntu/testssl.sh/scans/" .. host.ip .. ":" .. port.number .. "-" .. stamp) 
	else 
		handle = io.popen("/home/ubuntu/testssl.sh/testssl.sh --warnings batch --severity HIGH --jsonfile /home/ubuntu/testssl.sh/scans/" .. host.ip .. ":" ..  port.number .. "-" .. stamp .. " " .. host.ip .. ":" .. port.number .. " > /dev/null; cat /home/ubuntu/testssl.sh/scans/" .. host.ip .. ":" .. port.number .. "-" .. stamp) 
	end 
	local result = handle:read("*a") 
	handle:close()
	return result
end 
