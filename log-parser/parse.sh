#!/bin/bash

# Script path.
THIS_PATH=`dirname "$0"`;
THIS_PATH=`( cd "$THIS_PATH" && pwd )`;

# Setings - Everything must be related to this script path.
COMPARISON_TOOL="meld";
HEX_FILE="../../microbit.hex";
PYOCD_PATH="../../pyOCD";
OUTPUT_PATH="./output";
LOG_JOCD__PATH="jocd.txt";
LOG_PYOCD_PATH="pyocd.txt";
INCLUDE_RAW_DATA=0;
INCLUDE_YYY=0;
COMPARE_AT_END=0;
HEAD_N=0;
TAIL_N=0;

function flash {
        source $THIS_PATH/$PYOCD_PATH/env/bin/activate;
        python $THIS_PATH/$PYOCD_PATH/pyOCD/tools/flash_tool.py $THIS_PATH/$HEX_FILE > $THIS_PATH/$LOG_PYOCD_PATH;
}

function usage {
	echo -e "Usage:
	parse.sh [options]
	
Options:
	 * flash \t(flash using pyOCD and save its log)
	 * tool COMMAND (define the comparison tool and compare at the end - example: ./parse.sh tool meld). If not set default will be used - setup this file to edit)
	 * compare \t(open comparison tool at the end)
	 * raw \t\t(include raw data - all tx and rx bytes)
	 * yyy \t\t(include bytes received in readPacket method)
	 * pyocd PATH \t(set the path of pyocd. If not set default will be used - setup this file to edit)
	 * hex PATH \t(set the path of hex file. If not set default will be used - setup this file to edit)
	 * head N \t(get the first N lines)
	 * tail N \t(get the last N lines)
	 * help \t(show this message)";
	exit -1;
}

# Load args.
while (( "$#" )); do
	case "$1" in
	"flash")
		flash
		;;
	"tool")
		shift
		if [ "$#" == 0 ]
		then
			usage;
		fi
		COMPARISON_TOOL=$1;
		COMPARE_AT_END=1;
		;;
	"compare")
		COMPARE_AT_END=1;
		;;
	"nocompare")
		;;
	"raw")
		INCLUDE_RAW_DATA=1;
		;;
	"yyy")
		INCLUDE_YYY=1;
		;;
	"pyocd")
		shift
		if [ "$#" == 0 ]
		then
			usage;
		fi
		PYOCD_PATH=$1;
		;;
	"hex")
		shift
		if [ "$#" == 0 ]
		then
			usage;
		fi
		HEX_FILE=$1;
		;;
	"head")
		shift
		if [ "$#" == 0 ]
		then
			usage;
		fi
		HEAD_N=$1;
		;;
	"tail")
		shift
		if [ "$#" == 0 ]
		then
			usage;
		fi
		TAIL_N=$1;
		;;
	"help")
		usage;
		;;
	*)
		echo "Unexpected parameter $1";
		usage;
		;;
	esac
	shift
done

GREP_PATTERN='###!!!###';
if [[ $INCLUDE_RAW_DATA -eq 1 ]]
then
	GREP_PATTERN=$GREP_PATTERN'|###XXX###';
fi

if [[ $INCLUDE_YYY -eq 1 ]]
then
    GREP_PATTERN=$GREP_PATTERN'|###YYY###';
fi

# Create file if they don't exists (so this script don't crash)
mkdir -p $THIS_PATH/$OUTPUT_PATH;
touch $THIS_PATH/$LOG_JOCD__PATH;
touch $THIS_PATH/$LOG_PYOCD_PATH;

STRING_START_LOG="flashtool() start"
STRING_END_LOG="flashtool() leave"
STRING_START_WAITING="Flash::waitForCompletion() while state == TARGET_RUNNING"
STRING_END_WAITING="Flash::waitForCompletion() end of while state == TARGET_RUNNING"

                                 # Get only the selected lines (ehe ones that contains with GREP_PATTERN)
                                 #						 # Sed: remove the GREP_PATTERN from the beginning of each line.
                                 #						 #																			# Sed: remove all lines before flashtool() start, and after flashtool() leave, keeping only the lines between these lines.
                                 #						 #                                                                          # 												  # Sed: remove all the lines between the waiting loop and and the end of this loop.
                                 #						 #                                                                          # 												  #																												  # Pipe the filtered data to the output file.
cat $THIS_PATH/$LOG_JOCD__PATH | grep -E $GREP_PATTERN | sed 's/.*###!!!### //' | sed 's/.*###XXX### //' | sed 's/.*###YYY### //' | sed -n "/$STRING_START_LOG/,/$STRING_END_LOG/p" | sed -e "/^$STRING_START_WAITING/,/^$STRING_END_WAITING/{/^$STRING_START_WAITING/!{/^$STRING_END_WAITING/!d}}" > $THIS_PATH/$OUTPUT_PATH/$LOG_JOCD__PATH
cat $THIS_PATH/$LOG_PYOCD_PATH | grep -E $GREP_PATTERN | sed 's/.*###!!!### //' | sed 's/.*###XXX### //' | sed 's/.*###YYY### //' | sed -n "/$STRING_START_LOG/,/$STRING_END_LOG/p" | sed -e "/^$STRING_START_WAITING/,/^$STRING_END_WAITING/{/^$STRING_START_WAITING/!{/^$STRING_END_WAITING/!d}}" > $THIS_PATH/$OUTPUT_PATH/$LOG_PYOCD_PATH


# If "head" or "tail" was selected, than get only these lines.
if [[ $HEAD_N -ne 0 ]]
then
    cat $THIS_PATH/$OUTPUT_PATH/$LOG_JOCD__PATH | head "-$HEAD_N" > $THIS_PATH/$OUTPUT_PATH/_$LOG_JOCD__PATH;
    cat $THIS_PATH/$OUTPUT_PATH/$LOG_PYOCD_PATH | head "-$HEAD_N" > $THIS_PATH/$OUTPUT_PATH/_$LOG_PYOCD_PATH;
        mv $THIS_PATH/$OUTPUT_PATH/_$LOG_JOCD__PATH $THIS_PATH/$OUTPUT_PATH/$LOG_JOCD__PATH
        mv $THIS_PATH/$OUTPUT_PATH/_$LOG_PYOCD_PATH $THIS_PATH/$OUTPUT_PATH/$LOG_PYOCD_PATH
else
    if [[ $TAIL_N -ne 0 ]]
    then
        cat $THIS_PATH/$OUTPUT_PATH/$LOG_JOCD__PATH | tail "-$TAIL_N" > $THIS_PATH/$OUTPUT_PATH/_$LOG_JOCD__PATH;
        cat $THIS_PATH/$OUTPUT_PATH/$LOG_PYOCD_PATH | tail "-$TAIL_N" > $THIS_PATH/$OUTPUT_PATH/_$LOG_PYOCD_PATH;
        mv $THIS_PATH/$OUTPUT_PATH/_$LOG_JOCD__PATH $THIS_PATH/$OUTPUT_PATH/$LOG_JOCD__PATH
        mv $THIS_PATH/$OUTPUT_PATH/_$LOG_PYOCD_PATH $THIS_PATH/$OUTPUT_PATH/$LOG_PYOCD_PATH
    fi
fi

# If compare was selected, open the comparison tool.
if [[ $COMPARE_AT_END -eq 1 ]]; then
	$($COMPARISON_TOOL $THIS_PATH/$OUTPUT_PATH/$LOG_PYOCD_PATH $THIS_PATH/$OUTPUT_PATH/$LOG_JOCD__PATH &);
fi
