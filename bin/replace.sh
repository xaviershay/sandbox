#!/bin/bash
 #	This script will search and replace all regular files for a string 
 #	supplied by the user and replace it with another string. 
 #	
 #	Written by Daniel McCarthy
 #	daniel.mccarthy@linuxphile.org
 #
function usage {
    echo ""
    echo "Search/replace script"
    echo "    Written by Daniel McCarthy"
    echo "      daniel.mccarthy@linuxphile.org"
    echo "      http://linuxphile.org"
    echo ""
    echo "Not enough parameters provided."
    echo "Usage: ./$0 searchstring replacestring"
    echo "Remember to escape any special characters in the searchstring or the replacestring"
    echo ""
}

 #check for required parameters
if  [ ${#1} -gt 0  ]  &&  [ ${#2} -gt 0  ];
then
    
    for f in `find . -path '*/.svn' -prune -o -path '*/vendor' -prune -o -path '*~' -prune -o \( -size -100000c -type f \) -print0 | xargs -0 grep -l $1`;
    do
	cp $f $f.bak
	echo "The string $1 will be replaced with $2 in $f"
	sed s/$1/$2/g < $f.bak > $f
	rm $f.bak
    done
    
else
 #print usage informamtion 
    usage
fi