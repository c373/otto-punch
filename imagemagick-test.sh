#!/bin/bash

while [ ! -d "$dir_path" ]
do
	echo -n 'Please enter path to work in or "exit" to quit: '
	read dir_path
done


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

echo -e "$unit - Punch List" >> "$unit - Punch List.txt"

echo -e "\nWorking in, $unit!"

log_info() {

	echo -en "\n\t$1. $2, $3" >> "$unit - Punch List.txt"

}

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
			get_info $1
		elif [ "$confirm" = "y" ]
		then
			return 1
		fi
	done
}

rename_file () {

	local i=$4
	if [ -f "$2 - $3$4.jpg" ]
	then
		let "i+=1"
		rename_file "$1" "$2" "$3" "$i" 
	else
		mv -v "$1" "$2 - $3$4.jpg"
	fi
}

i=1
for f in $dir_path/*.jpg
do

	feh -x --auto-rotate --geometry 640x400 --scale-down -zoom "$f" &
	id=$!

	confirm="n"	
	get_info "$f"

	#process image
	convert "$f" -pointsize 72 -gravity South -background Gray -fill White -splice 0x30 -annotate +0+2 "$issue" "$f.new"

	convert "$f.new" -rotate -90 "$f.new"

	#mv -fv "$f.new" "$unit - $location.jpg"
	rename_file "$f.new" "$unit" "$location"

	log_info "$i" "$location" "$issue"
	
	kill $id

	let "i+=1"
done
