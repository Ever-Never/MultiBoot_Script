#!/sbin/sh

# Set the ROM name 
ROM_NAME=
export ROM_NAME


mmcblk1p2=`ls /dev/block/mmcblk1p2`

# Mount the ext4 partition
if [ $mmcblk1p2 == "/dev/block/mmcblk1p2" ]
then

	mkdir -p /ext4p
	mkdir -p /sdcard/MultiBoot/$ROM_NAME
	mkdir -p /boot /boot_dir
	
	mount -t ext4 /dev/block/mmcblk1p2 /ext4p
	mkdir -p /ext4p/$ROM_NAME/system /ext4p/$ROM_NAME/data /ext4p/$ROM_NAME/cache
2
	mount --bind /ext4p/$ROM_NAME/system /system
	mount --bind /ext4p/$ROM_NAME/data /data
	
	mount --bind /sdcard/MultiBoot/$ROM_NAME /boot
	mount --bind /sdcard/MultiBoot /boot_dir
#delete the old system
	rm -rf /system/*

#clean the dalvik-cache	
	rm  -rf /data/dalvik-cache/*

#all the dir has ready write some info for updater-script
	echo "MultiBoot=true" >> /tmp/nfo.prop
else

#no ext4 partition found	
	echo "MultiBoot=false" >> /tmp/nfo.prop
fi
