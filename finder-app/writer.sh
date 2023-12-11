#!/bin/sh

if [ $# -lt 2 ]; then
	echo "Not enough arguments"
	exit 1
fi

writefile="$1"
writestr="$2"

#mkdir -p $writefile

install -Dv /dev/null "$writefile" > /dev/null
echo "$writestr" >| "$writefile"


if [ $? -ne 0 ]; then
	echo "File error"
	exit 1
fi
