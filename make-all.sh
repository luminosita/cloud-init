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
	id=`expr $start_id + $i`
	INSTANCE_NAME=$prefix-$i INSTANCE_HOST_ID=$id make $target
	i=`expr $i + 1`
done
