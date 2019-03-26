#!/bin/bash

#Old Driver invocation model:
#Init: <driver executable> init
#Attach: <driver executable> attach <json options>
#Detach: <driver executable> detach <mount device>
#Mount: <driver executable> mount <target mount dir> <mount device> <json options>
#Unmount: <driver executable> unmount <mount dir>

# Driver invocation model:
# init
# getvolumename <json:"volumeName,omitempty">
# isattached <json:"attached,omitempty>
# attach
# waitforattach
# mountdevice
# detach
# unmountdevice
# mount
# unmount
# expandvolume
# expandfs


usage() {
	err "{\"status\": \"Failed\",\"message\": \"usage $# $*\"}"
	exit 1
}

err() {
	echo -ne $* 1>&2
}

log() {
	echo -ne $* >&1
}

ismounted() {
	MOUNT=`findmnt -n ${MNTPATH} 2>/dev/null | cut -d' ' -f1`
	if [ "${MOUNT}" == "${MNTPATH}" ]; then
		echo "1"
	else
		echo "0"
	fi
}

attach() {
	VOLUMEID=$(echo $1 | jq -r '.volumeID')
	SIZE=$(echo $1 | jq -r '.size')
	VG=$(echo $1|jq -r '.volumegroup')

	DMDEV="/dev/${VOLUMEID}"
	if [ ! -b "${DMDEV}" ]; then
		err "{\"status\": \"Failure\", \"message\": \"Volume ${VOLUMEID} does not exist\"}"
		exit 1
	fi
	log "{\"status\": \"Success\", \"device\":\"${DMDEV}\"}"
	exit 0
}

detach() {
	log "{\"status\": \"Success\"}"
	exit 0
}

domount() {
	MNTPATH=$1
	DMDEV=$2
	FSTYPE=$(echo $3|jq -r '.["kubernetes.io/fsType"]')

	if [ ! -b "${DMDEV}" ]; then
		err "{\"status\": \"Failure\", \"message\": \"${DMDEV} does not exist\"}"
		exit 1
	fi

	if [ $(ismounted) -eq 1 ] ; then
		log "{\"status\": \"Success\"}"
		exit 0
	fi

	VOLFSTYPE=`blkid -o udev ${DMDEV} 2>/dev/null|grep "ID_FS_TYPE"|cut -d"=" -f2`
	if [ "${VOLFSTYPE}" == "" ]; then
		mkfs -t ${FSTYPE} ${DMDEV}
		if [ $? -ne 0 ]; then
			err "{ \"status\": \"Failure\", \"message\": \"Failed to create fs ${FSTYPE} on device ${DMDEV}\"}"
			exit 1
		fi
	fi

	mkdir -p ${MNTPATH} &> /dev/null

	mount ${DMDEV} ${MNTPATH} &> /dev/null
	if [ $? -ne 0 ]; then
		err "{ \"status\": \"Failure\", \"message\": \"Failed to mount device ${DMDEV} at ${MNTPATH}\"}"
		exit 1
	fi
	log "{\"status\": \"Success\"}"
	exit 0
}

getvolumename() {
	log "{\"status\": \"Success\", \"volumeName\" :\"test\"}"
	exit 0	
}

unmount() {
	MNTPATH=$1
	if [ $(ismounted) -eq 0 ] ; then
		log "{\"status\": \"Success\"}"
		exit 0
	fi

	umount ${MNTPATH} &> /dev/null
	if [ $? -ne 0 ]; then
		err "{ \"status\": \"Failed\", \"message\": \"Failed to unmount volume at ${MNTPATH}\"}"
		exit 1
	fi
	rmdir ${MNTPATH} &> /dev/null

	log "{\"status\": \"Success\"}"
	exit 0
}

op=$1
if [ "$op" = "init" ]; then
	log "{\"status\": \"Success\"}"
	exit 0
fi

if [ $# -lt 2 ]; then
	usage
fi

shift

case "$op" in
	attach)
		attach $*
		;;
	detach)
		detach $*
		;;
	waitforattach)
		shift
		attach $*
		;;
	mount)
		log "{\"status\": \"Success\"}"
		exit 0
		;;
	mountdevice)
		domount $*
		;;
	unmount)
		unmount $*
		;;
	unmountdevice)
		unmount $*
		;;
	isattached)
		err "{\"status\": \"Failed\",\"message\": \"op:isattached $# $*\"}"
		exit 1
		ismounted $*
		;;
	getvolumename)
		getvolumename $*
		;;
	*)
		usage
esac

exit 1
