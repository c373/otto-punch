#!/bin/bash

feh --scale-down -zoom $1 &
id=$!
echo "Press enter to continue:"
read void
kill $id
