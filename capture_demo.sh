#!bin/bash

date_name=$(date +"%S_%M_%H")

folder='/mnt/d/photos'

path=$folder/$date_name.jpg
gphoto2 --capture-image-and-download --filename $path
