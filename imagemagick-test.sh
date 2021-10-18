#!/bin/bash

echo -n 'Please enter unit: '
read unit

while [ "$confirm_unit" != "y" ]
do
	echo -n "Confirm: $unit (y/n)? "
	read confirm_unit

	if [ "$confirm_unit" = "n" ]
	then
		echo -n "Please enter unit: "
		read unit
	fi
done

echo -e "\nWorking in, $unit!"

get_info () {

	echo -e "\nProcessing $1...\n"
	echo -n "Describe issue location: "
	read location
	echo -n "Describe issue: "
	read issue

	while [ "$confirm" != "y" ]
	do
		echo -en "Confirm: $unit - $location : $issue (y/n)? "
		read confirm

		if [ "$confirm" = "n" ]
		then
			process_image $1
		elif [ "$confirm" = "y" ]
		then
			return 1
		fi
	done
}

rename_file () {

	i=$4
	if [ -f "$2 - $3$4.jpg" ]
	then
		let "i+=1"
		rename_file "$1" "$2" "$3" "$i" 
	else
		mv -v "$1" "$2 - $3$4.jpg"
	fi
}

for f in *.jpg
do
	confirm="no"	
	get_info "$f"

	#process image
	convert "$f" -pointsize 24 -gravity South -background Gray -fill White -splice 0x28 -annotate +0+2 "$issue" "$f.new"

	#mv -fv "$f.new" "$unit - $location.jpg"
	rename_file "$f.new" "$unit" "$location"

done
