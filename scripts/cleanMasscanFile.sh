# Takes two arguments. Currently only used to cleanup Masscan results. 
# ./cleanFile.sh [input] [output]
# Currently a one liner and not very useful to justify a file on its own, but can potentially be extended when more scanners are used that
# require different ways of cleaning up the file. 
sed -e '2,$!d' -e '$d' $1 | cut -d " " -f4 | sort -V | uniq | shuf > $2
