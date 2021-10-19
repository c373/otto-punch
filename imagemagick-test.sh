#!/bin/bash

#request the path that contains the photos
while [ ! -d "$dir_path" ]
do
	echo -n 'Please enter path to work in or "exit" to quit: '
	read dir_path

	if [ "$dir_path" = "exit" ]
	  then
		exit 1
	fi
done

#setup the punchlist.txt file
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

#create the punch list file
echo -e "$unit - Punch List" >> "$unit - Punch List.txt"

echo -e "\nWorking in, $unit!"

log_info() {
	
	#add item to the punchlist file
	echo -en "\n\t$1. $2, $3" >> "$unit - Punch List.txt"

}

get_info () {

	#collect location and issue info
	echo -e "\nProcessing $1...\n"
	echo -n "Describe issue location: "
	read location
	echo -n "Describe issue: "
	read issue

	#ensure the info is correct
	while [ "$confirm" != "y" ]
	do
		echo -en "Confirm: $unit - $location, $issue (y/n)? "
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

#helper function to rename the file with an appended number if the proposed filename already exists
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

#issue count
i=1

if [ ! -d "archive" ]
  then
	mkdir "archive"
fi

#iterate through all jpegs in the directory
for f in $dir_path/*.jpg
do
	#cleanup filename
	f=$( basename -- "$f" )
	
	echo -e "\nBacking up $f..."
	cp -fv "$f" "archive/$f"

	#show image that is being processed
	feh -x --auto-rotate --geometry 640x800 --scale-down -zoom "$f" &
	
	#save the pid for future control
	id=$!

	confirm="n"	
	get_info "$f"

	#check orientation of the photo
	orientation=$( identify -format '%[EXIF:*]' "$f" | grep "Orientation=" | tail -c 2 )

	#rotate the file according to EXIF for processing will be reverted later
	if [ "$orientation" = "6" ]
	  then
		convert "$f" -rotate 90 "$f"

	elif [ "$orientation" = "8" ]
	  then
		convert "$f" -rotate -90 "$f"

	elif [ "$orientation" = "3" ]
	  then
		convert "$f" -rotate -180 "$f"
	fi

	#identify image size
	width=$( identify -format "%w" "$f" )
	height=$( identify -format "%h" "$f" )

	if (( width > height ))
	  then
		longedge=$width
	else
		longedge=$height
	fi

	echo "longedge:$longedge"

	pointsize=$((longedge/30))
	offset=$((pointsize/2))
	splice_height=$((pointsize+offset))

	echo "pointsize:$pointsize"
	echo "splice_height:$splice_height"

	#add label and output to a seperate file
	convert "$f" -pointsize "$pointsize" -gravity South -background "#FFA500" -fill White -splice "0x$splice_height" -annotate "+0+$offset" "$unit - $issue" "$f.new"

	#revert rotations...
	if [ "$orientation" = "6" ]
	  then
		convert "$f.new" -rotate -90 "$f.new"

	elif [ "$orientation" = "8" ]
	  then
		convert "$f.new" -rotate 90 "$f.new"

	elif [ "$orientation" = "3" ]
	  then
		convert "$f.new" -rotate 180 "$f.new"
	fi

	#rename the output file
	rename_file "$f.new" "$unit" "$location"
	#cleanup
	rm "$f"

	#add issue to the punchlist file
	log_info "$i" "$location" "$issue"
	
	#close the feh process with the image preview
	kill $id

	#increment photo count
	((i++))
done
