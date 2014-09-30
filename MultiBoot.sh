#!/bin/bash
if [ $# -ne 2 ]
then
	echo "usage: MultiBoot.sh zipPath ROM_NAME"
	echo "eg:  MultiBoot.sh test.zip  BaiduOS " 
	echo "	zipPath is the converted rom"
	echo "	ROM_NAME is used for different rom"
else
	ZIP=$1
	ROM_NAME=$2
	mkdir -p temp
	mkdir -p boot
	chmod 755 boot
	chmod -R 755 tools/*
	chmod 755 temp
	echo  ">>>>>release the zip to temp"
	unzip -n $1 -d temp   1>/dev/null
	cd temp
	MOUNTPIONTER=`sed -n '/^mount/p' META-INF/com/google/android/updater-script | grep data | cut -d '/' -f 4 | cut -d '"' -f 1`
	echo ">>>>>internal storge :$MOUNTPIONTER"
	if [ -e "boot.img" ]
		then
		echo ">>>>>modify boot.img "
		mkdir -p kernel/bootsd
		mkdir -p kernel/DirectSD
		mkdir -p kernel/MultiBoot
		cp boot.img ../boot
		cd  ..
		cd boot
		./../tools/unpack-MT65xx.pl boot.img 1>/dev/null
		cd boot.img-ramdisk
		#remove mount data system cache 
		sed -i '/data/d' fstab
		sed -i '/system/d' fstab
		#sed -i '/cache/d'  fstab
		# for Honer 3C
		if  [ -e "init.ssd_nomuser.rc" ]
			then
			mv  init.ssd_nomuser.rc  init.ssd.rc
		fi
		#cp  -rf ../../tools/init .
		#add busybox e2fsck to sbin
		cp ../../tools/busybox sbin
		cp ../../tools/e2fsck sbin 
		cp ../../tools/initrcmod .
		cp init.rc ../initrcbackup 
		#modify for root permmission
		echo ">>>>>change init.rc to install rom to DirectSD(sdcard ext4 partition)"
		sed -i 's/ro.secure=1/ro.secure=0/' default.prop
		sed -i '/on fs_property:ro.mount.fs=EXT4/ r initrcmod' init.rc
		#sed -i 's/mount ext4 \/emmc@android \/system wait commit=1,noauto_da_alloc/mount ext4 \/dev\/block\/mmcblk1p2 \/system wait commit=1,noauto_da_alloc/' init.rc
		#sed -i 's/mount ext4 \/emmc@android \/system noatime ro remount wait/mount ext4 \/dev\/block\/mmcblk1p2 \/system noatime ro remount wait/' init.rc
		#sed -i 's/mount ext4 \/emmc@usrdata \/data noatime nosuid nodev wait noauto_da_alloc,discard/mount ext4 \/dev\/block\/mmcblk1p3 \/data noatime nosuid nodev wait noauto_da_alloc,discard/' init.rc
		sed -i '/mount.*\/emmc@android/ s/emmc@android/dev\/block\/mmcblk1p2/' init.rc 
		sed -i '/mount.*\/emmc@usrdata/ s/emmc@usrdata/dev\/block\/mmcblk1p3/' init.rc 

		rm initrcmod
		cd ..
		./../tools/repack-MT65xx.pl -boot boot.img-kernel.img boot.img-ramdisk new_boot.img 1>/dev/null  
		cp new_boot.img ../temp/kernel/DirectSD/boot.img
		rm new_boot.img
		cd boot.img-ramdisk
		cp -rf ../initrcbackup init.rc
		cp ../../tools/initrcmodnand .
		sed -i '/data/d' fstab
		sed -i '/system/d' fstab
		sed -i '/cache/d'  fstab
		echo ">>>>>change init.rc to install rom to sdcard ext4 partition(NativeSD)" 
		sed -i '/on fs$/ r initrcmodnand' init.rc
		sed -i 's/MultiBoot\/ROMNAME/MultiBoot\/'$ROM_NAME'/g' init.rc
		rm initrcmodnand
		cd ..
		./../tools/repack-MT65xx.pl -boot boot.img-kernel.img boot.img-ramdisk new_boot.img 1>/dev/null 
		cp new_boot.img ../temp/kernel/bootsd/boot.img 
		rm new_boot.img
		cd boot.img-ramdisk
		cp -rf ../initrcbackup init.rc
		cp ../../tools/initrcmodnand .
		sed -i '/data/d' fstab
		sed -i '/system/d' fstab
		sed -i '/cache/d'  fstab
		echo ">>>>>change init.rc to install rom to NAND(MultiBoot)" 
		sed -i '/on fs$/ r initrcmodnand' init.rc
		sed -i 's/MultiBoot\/ROMNAME/MultiBoot\/'$ROM_NAME'/g' init.rc
		sed -i 's/mmcblk1p2/'$MOUNTPIONTER'/g' init.rc
		rm initrcmodnand
		cd ..
		./../tools/repack-MT65xx.pl -boot boot.img-kernel.img boot.img-ramdisk new_boot.img 1>/dev/null 
		cp new_boot.img ../temp/kernel/MultiBoot/boot.img 
		cd ../temp
	fi
	cp -rf ../tools/installNativeSD.sh .
	cp -rf ../tools/installDirectSD.sh .
	cp -rf ../tools/installMultiBoot.sh .
	sed -i 's/^ROM_NAME=/ROM_NAME='$ROM_NAME'/' installNativeSD.sh
	sed -i 's/^ROM_NAME=/ROM_NAME='$ROM_NAME'/' installMultiBoot.sh
	sed -i 's/^ROM_NAME=/ROM_NAME='$ROM_NAME'/' installDirectSD.sh
	sed -i 's/block\/mmcblk1p2/block\/'$MOUNTPIONTER'/g' installMultiBoot.sh
	#mkdir -p kernel/boot
	#mv boot.img kernel/boot/boot.img
	cd ../tools
	#add files
	echo ">>>>>add neccessary files"
	mv ../temp/META-INF/com/google/android/update-binary ../temp/META-INF/com/google/android/update-binary-installer
	cp -rf aroma ../temp/META-INF/com/google/android/aroma
	cp -rf aroma-config ../temp/META-INF/com/google/android/aroma-config
	cp -rf updater-script-tmp ../temp/META-INF/com/google/android/updater-script-tmp
	#cp -rf update-binary-installer ../temp/META-INF/com/google/android/update-binary-installer
	cp -rf update-binary ../temp/META-INF/com/google/android/update-binary
	cd ../temp/META-INF/com/google/android

	#modify script
	echo ">>>>>modify updater-script"
	sed -n '/getprop("ro/p' updater-script >> assert.txt
	sed -i  '/getprop("ro/d'  updater-script
	sed -n '/^format("/p' updater-script >> FormatAndMount.txt
	sed -n '/^mount/p'  updater-script >> FormatAndMount.txt
	sed -i '/show_progress/d' updater-script
	sed -i '/ui_print/d' updater-script
	#delete boot
	sed -i '/package_extract_file("boot.img/d' updater-script
	sed -i '/write_raw_image("\/tmp\/boot.img/d' updater-script
	sed -i '/delete("\/tmp\/boot.img/d' updater-script
	sed -i '/package_extract_dir("system", "\/system")/d' updater-script
	sed -i '/package_extract_dir("data", "\/data"/d' updater-script
	#delete mount
	sed -i '/^mount(/d' updater-script
	sed -i '/^format/d' updater-script
	sed -i '/unmount/d' updater-script
	sed -i '/ui_print("@  Mounting System");/r FormatAndMount.txt' updater-script-tmp
	#sed -i '/^format.*\/system/ s/, "\/system"//' updater-script-tmp 
	sed -i '/ui_print("@  symlink") ;/r updater-script' updater-script-tmp
	sed -i '/run_program("\/sbin\/mkdir", "\/tmp");/r assert.txt' updater-script-tmp
	#modify romname
	sed -i 's/^ini_set("rom_name",             "MIUI");/ini_set("rom_name",             "'$ROM_NAME'");/' aroma-config
	rm *.txt
	mv -f updater-script-tmp updater-script
	cd ../../../..
	if  [ -e "scatter.txt" ]
		then
		rm  *.txt
	fi  
	mkdir -p sdcard/MultiBoot
	mkdir -p ../out
	echo ">>>>>compress zip"
	zip -r $1 ./*  1>/dev/null
	mv $1 ../out/$2_MultiBoot.zip
	#clean 
	cd ..
	echo ">>>>>clean files "
	rm -rf boot
	rm -rf temp
	echo ">>>>>meke comepletely please check out the out dir "
	echo ">>>>>if have problem please visite my sina weibo" 
	echo ">>>>>my sina weibo is EverNever_NCWU "
fi
