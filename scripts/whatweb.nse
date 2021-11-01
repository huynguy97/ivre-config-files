local shortport = require "shortport"
local stdnse = require "stdnse"

description = [[
This script requires WhatWeb and runs WhatWeb. By default it runs on the hostname and if no hostname is available it runs on the ip address found. There is one script argument that can be passed for more aggressive scans. This argument is "whatweb.aggression" and can be either 3 or 4. By default 1 is ran, which is "stealthy". 
]]

portrule = shortport.http

action = function(host,port) 
	local aggressive = stdnse.get_script_args("whatweb.aggression")
	local handle = ""
	local hostname = stdnse.get_hostname(host)
	
 	print(stdnse.get_hostname(host))	
	if aggressive == "3" or aggressive == "4" then -- more aggressive whatweb dection, might be intrusive so use with care.  
		if port.number == 80 then 
			handle = io.popen("whatweb --color=never http://" .. hostname .. " -a " .. aggressive)
		elseif port.number == 443 then 
		 	handle = io.popen("whatweb --color=never https://" .. hostname .. " -a " .. aggressive)
		end 
	elseif port.number == 80 then 
			handle = io.popen("whatweb --color=never http://" .. hostname)
	elseif port.number == 443 then 
			handle = io.popen("whatweb --color=never https://" .. hostname)
	end
	
	local result = handle:read("*a")
	local result_split = string.gsub(result, "],", "]\n")
	entries = {}
	for entry in result_split:gmatch("[^\r\n]+") do
		table.insert(entries,entry)
	end
	handle:close()
	return entries
end
