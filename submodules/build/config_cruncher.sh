#!/bin/sh
# config_cruncher
# Generates Verilog code for a configuration ROM
# Can be used under both dash and bash

# Based on config_cruncher in llc-suite, which is
# Copyright (c) 2004, The Regents of the University of California.
# See http://recycle.lbl.gov/llc-suite/ for more information.

# bail out on errors: useful for debugging, but makes the
# script fail when run with cygwin's bash-2.05b.0(1)-release
set -e

outfile="$1"
build_num_loc="$2"

dsp_flavor=${DSP_FLAVOR:-2}

# HARDWARE mnemonics
BOARD_mebt=1
BOARD_interim=2
BOARD_fcm=3
BOARD_avnet=4
BOARD_uxo=5
BOARD_llrf4=6
BOARD_av5t=7
BOARD_sp601=8
BOARD_sp605=9
BOARD_ml505=10
BOARD_ml506=11
BOARD_fllrf=12
BOARD_spec=13
BOARD_lx150t=14
BOARD_cutewr=15
BOARD_llrf46=16
BOARD_ac701=17
BOARD_ml605=18
BOARD_kc705=19
BOARD_test=99

# USER_NUM codes, must be less than 256
USER_ldoolitt=1
USER_larry=1
USER_lrdoolit=1
USER_cswanson=2
USER_kasemir=3
USER_hengjie=4
USER_qcf=4
USER_crofford=5
USER_meddeler=6
USER_baptiste=7
USER_llrf_oper=8
USER_hyaver=9
USER_dim=10
USER_begcbp=11
USER_ghuang=12
USER_luser=13
USER_kstefan=14
USER_cserrano=15
USER_asalom=16
USER_du=17
USER_yangjin=18
USER_lilima=19
USER_ernesto=20

# Convert text string in $HARDWARE to numeric
eval "BOARD_TYPE=\${BOARD_$HARDWARE:-0}"
if [ "$BOARD_TYPE" = 0 ]; then
    echo "Warning: board type $HARDWARE unknown, BOARD_TYPE set to 0" >&2
fi

# TOOL should be set for us by the Makefile
if [ -z "$TOOL" ]; then
  echo "Warning: \$TOOL not configured, set to 0" >&2
fi

# Kinda Unix-centric.  Oh, well.
# The invocation of tr gets rid of hyphens in usernames, which would
# otherwise confuse the shell variable expansion.
LLC_USER=`echo $USER | tr '-' '_'`
eval "USER_NUM=\${USER_$LLC_USER:-0}"
if [ "$USER_NUM" = 0 ]; then
    echo "Warning: user $USER unknown, USER_NUM set to 0" >&2
fi

tool_ver=0
if [ "$TOOL" = 2 ]; then
    xilinx_home=$XILINX
    if [ -r "$XILINX_SETTINGS" ]; then xilinx_home=`shift $#; . $XILINX_SETTINGS >/dev/null; echo $XILINX`; fi
    tool_string=`if [ -r $xilinx_home/readme.txt ]; then awk 'FNR==1{gsub("\r","");print $0}' $xilinx_home/readme.txt; elif [ -r $xilinx_home/fileset.txt ]; then awk '/ version=/{a=$NF; sub("version=","",a); print "XST", a}' $xilinx_home/fileset.txt; fi`
    tool_ver=`echo $tool_string | awk '{a=match($0,"[0-9]+.[0-9]+"); b=substr($0,a,RLENGTH); split(b,c,"."); print c[1]*16+c[2];}'`
    echo "xilinx_home=$xilinx_home  tool_string=$tool_string  tool_ver=$tool_ver" >&2
fi

# note this is UTC
DATE=`date -u +"%Y_%m_%d_%H_%M"`

#if [ -r $build_num_loc ]; then
#    read BUILD_NUM < $build_num_loc
#else
#    echo "$0: need build_num file" >&2
#    exit 1
#fi
#if [ -z "$BUILD_NUM" ]; then
#    echo "$0: need valid number in build_num file" >&2
#    exit 1
#fi
# echo "BUILD_NUM = (${BUILD_NUM})"
# Get version tag using git
if git log -0 2>/dev/null; then
	#LATEST_COMMIT_SHA1=`git log -1 --format="format:%H" | fold -w2`
	LATEST_COMMIT_SHA1=`git rev-parse HEAD | fold -w 2`
    set +e
	GIT_VERSION_TAG=`git describe --tag > /dev/null 2>&1`
    set -e
    if test $? -ne 0; then
        echo "config_cruncher: No tags found in git tree" >&2
        VERSION_NUMBER=0
        GIT_VERSION_TAG=0
    else
	VERSION_NUMBER=`echo $GIT_VERSION_TAG | awk -F"[.]" 'END{ print $1}' | sed 's/.*[^0-9]\([0-9][0-9]*\).*/\1/g'`
    fi
    #echo "GIT_VERSION_TAG = $GIT_VERSION_TAG"
	GIT_STATUS=`git status | tail -n1 | cut -c 1-8`
	if [ "$GIT_STATUS" != 'nothing ' ]; then
		DIRTY=1
		CLEANESS="dirty"
	else
		DIRTY=0
		CLEANESS="clean"
	fi

	COMMITS_AFTER_TAG_CLEANESS=`echo $GIT_VERSION_TAG | awk -v dirty=$DIRTY -F"[-]" 'END{x=$2; if (x>127)x=127; if (dirty) x=x+128; print x}'`
	COMMITS_AFTER_TAG=`echo $GIT_VERSION_TAG | awk -F"[-]" 'END{print $2};'`
else
	COMMITS_AFTER_TAG_CLEANESS="0"
	VERSION_NUMBER="0"
	LATEST_COMMIT_SHA1=`echo "0000000000000000000000000000000000000000" | fold -w 2`
	CLEANESS="not in a git repo"
	COMMITS_AFTER_TAG="N/A"
fi

(  # start subshell
cat <<EOT
// Machine generated from config_cruncher
\`timescale 1ns / 1ns

module config_romx(
	input [4:0] address,
	output reg [7:0] data
);

always @(address) case(address)
EOT

(
echo "85"     # magic 0x55
echo "$dsp_flavor"      # application type LLRF2, or other specified
# The following command spits out five lines: year, month, day, hour, minute.
# This time stamp system will have reduced utility starting in the year 2256.
echo "$DATE" | tr '_' '\n' | awk '{if (NR==1) $1=$1-2000; print $1+0}'
echo "$COMMITS_AFTER_TAG_CLEANESS"
echo "${tool_ver}"
echo "$USER_NUM"
# start of application-specific data
echo "${BOARD_TYPE:-0}"
echo "${VERSION_NUMBER}"
echo "$LATEST_COMMIT_SHA1"
#echo "${GIT_VERSION_TAG} | fold -w 1"
for i in `seq 1 1 0`; do echo 16; done
) | awk 'BEGIN{
  c[0]="magic"
  c[1]="dsp flavor"
  c[2]="year"
  c[3]="month"
  c[4]="day"
  c[5]="hour"
  c[6]="minute"
  c[7]="code is ('"$CLEANESS"'), ('"$COMMITS_AFTER_TAG"') commits after the latest tag"
  c[8]="tool rev ('"$tool_string"')"
  c[9]="user ('"$USER"')"
  c[10]="board type ('"$HARDWARE"')"
  c[11]="version number"
  c[12]="start of SHA1"
  c[13]="..."
  c[14]="..."
  c[15]="..."
  c[16]="..."
  c[17]="..."
  c[18]="..."
  c[19]="..."
  c[20]="..."
  c[21]="..."
  c[22]="..."
  c[23]="..."
  c[24]="..."
  c[25]="..."
  c[26]="..."
  c[27]="..."
  c[28]="..."
  c[29]="..."
  c[30]="..."
  c[31]="end of SHA1"

}
{ if ((NR-1)>11 && (NR-1)<32) printf "\t5'\''h%2.2x: data = 8'\''h%s;  //  0x%s", NR-1, $1, $1
  else {printf "\t5'\''h%2.2x: data = %3d;    //  0x%.2x", NR-1, $1, $1}
 cc=c[NR-1]
 if (cc != "") printf "  %s", cc
 printf "\n"
}'

cat <<EOT
endcase

endmodule
EOT
) >$outfile  # end subshell

# simple test for gross errors
if [ `grep -c "5'h" $outfile` != 32 ]; then
   echo "internal error: config_cruncher output file was the wrong length" >&2
 # rm $outfile
   exit 1
fi
