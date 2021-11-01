# Takes two arguments. 
# ./cleanFile.sh [input] [output]
sed -e '2,$!d' -e '$d' $1 | cut -d " " -f4 | sort -V | uniq | shuf > $2
