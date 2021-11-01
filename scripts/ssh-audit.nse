local shortport = require "shortport" 
local stdnse = require "stdnse"

description = [[
This script requires ssh-audit and runs ssh-audit. By default it shows the complete result, but using the script argument "ssh-audit.level" which can have values "info", "warn" and "fail" it will show values of that level or higher.
]] 

author = "Huy Nguyen"

license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
portrule = shortport.ssh 

action = function (host,port)
	local level = stdnse.get_script_args("ssh-audit.level")
	local handle = ""
	if (level == "info" or level == "warn" or level == "fail") then 
		handle = io.popen("ssh-audit -b -n -l " .. level .. " " .. host.ip .. ":" .. port.number)
	else 
		handle = io.popen("ssh-audit -b -n " .. host.ip .. ":" .. port.number)
	end 
	local result = handle:read("*a")
	handle:close()
	return result
end
