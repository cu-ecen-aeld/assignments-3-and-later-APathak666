#!/bin/sh

if [ $# -lt 2 ]; then
	echo "Not enough arguments"
	exit 1
fi

filesdir="$1"
searchstr="$2"

if [ ! -d "$filesdir" ]; then
	echo "Not a valid directory"
	exit 1
fi

X=$(find $filesdir -type f | wc -l)
Y=$(grep -r "$filesdir" -e "$searchstr" | wc -l)

echo "The number of files are $X and the number of matching lines are $Y"

