#!/bin/sh

usage() {                                 # Function: Print a help message.
  echo "Usage: $0 -c VM_COUNT -p VM_NAME_PREFIX -s VM_START_NETWORK_HOST_ID -t TARGET" 1>&2 
}
exit_abnormal() {                         # Function: Exit with error.
  usage
  exit 1
}

count=0
prefix=""
start_id=0
target=""

while getopts "c:p:s:t:" flag
do
	case "${flag}" in
		c) count=${OPTARG};;
		p) prefix=${OPTARG};;
		s) start_id=${OPTARG};;
		t) target=${OPTARG};;
    		:)                                    # If expected argument omitted:
      			echo "Error: -${OPTARG} requires an argument."
      			exit_abnormal                       # Exit abnormally.
      		;;
    		*)                                    # If unknown (any other) option:
      			exit_abnormal                       # Exit abnormally.
      		;;
	esac
done

if [ -z "$target" -o -z "$prefix" -o $count -lt 1 -o $start_id -lt 5 ]
then
   usage
   exit
fi

i=1

while [ $i -le $count ]
do
	host_id=`expr $start_id + $i`
	host_name="$prefix-$i"

	echo ""
	echo ""
	echo "Processing '$target' target for VM image: $host_name with Host Id: $host_id"
	echo ""
	echo ""
	INSTANCE_NAME=$host_name INSTANCE_HOST_ID=$host_id make $target

	if [ $? -eq 0 ]; then
		echo ""
		echo ""
		echo "VM image: $host_name with Host Id: $host_id successfully processed"
		echo ""
		echo ""
	else
		echo "VM image: $host_name with Host Id: $host_id failed to process"
	fi
	
	i=`expr $i + 1`
done
