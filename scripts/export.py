# An export script for IVRE NDJSON files. Run as below:
# python3 export.py [file] [searchterm]
# example: "python3 export.py test.ndjson cve-2021" will write to a file
import ndjson # Not a standard json library. Run "pip3 install ndjson" before running using the script. See: https://pypi.org/project/ndjson/
import re
import sys


filename = sys.argv[1] 
searchterm = sys.argv[2]


with open(filename) as f:
    ips = ndjson.load(f)

for i in range(len(ips)):
    output_file = sys.argv[1] + "_filtered"
    f = open(output_file, "a")
    f.write(ips[i]['addr'] + "\t")
    ip = ndjson.dumps((ips[i].items()), indent=4)
    cleaned_ip = ip.replace("\\n", "\n")
    x = re.findall(rf".*{re.escape(searchterm)}.*\n",cleaned_ip) # raw string, python 3.6 and higher required
    for i in range(len(x)):
         f.write(x[i])
    f.write("----------------------------------------------------------------------------\n")
    f.close()

print(sys.argv)
print(len(sys.argv))

