#!/bin/bash
# This script is a simple tool for removing a large amount of files quickly and safely.
progFolder="/root/scripts/rmsafe"
JOB="${progFolder}/job"
tempFolder="/home/temp/rmsafe"
temp="${tempFolder}/failtemp"
ftemp="${tempFolder}/ftemp"
dtemp="${tempFolder}/dtemp"

# Vars
JOBS="${progFolder}/jobfile"
#JOBS="${progFolder}/jobfile"
#JOBS="${progFolder}/jobfile"
#JOBS="${progFolder}/jobfile"
ADMIN="AnonAdmin"
NJOB="default" #Name of current job-to be created
DATE=`date +%s`
part="0"

# Imports
. ${progFolder}/colors

# Usage function
usage() {
    echo -e "${bldblu}Usage:${bldcya}"
    echo -e "  rmsafe.sh [options] location"
    echo ""
    echo -e "${bldblu}  Options:${bldcya}"
    echo -e "    -e - Returns if the path given is file or directory"
    echo -e "    -p | [--prep] - Running the prep functions"
    echo -e "    -h - Displays this usage page"
    echo ""
    echo -e "${bldblu}Example:${bldcya}"
    echo -e "      rmsafe.sh /home/cpuser/public_html/blog"
    echo -e "${rst}"
    exit 1
}

# function to check if a directoyr exists
function exists {
if [[ -d $1 ]]; then
    echo "$1 is a directory"
    #prep;
    safeList $LOCATION;
elif [[ -f $1 ]]; then
    echo "$1 is a file; use normal rm."
    exit 1
else
    echo "$1 is not valid"
    exit 1
fi
}
# --report function for viewing reports by saved name
#
# --delete [or -dall] function for deleting based on a report
#
# -dfiles function for deleting only the files.
# -ddirs function for deleting only the folders.
# -dall function for deleting all the content.
#
# -jobs function for listing all jobs

prep() {
    # Get the LWalias - Admins Jabber handle
    read -p "Who are you? Enter your Name or Alias: " -e -i ${ADMIN} ADMIN;
    # Grab a name for the Removal job
    read -p "Custom job name?: " -e -i ${NJOB} NJOB;
    if [[ ${DEBUG} -eq "1" ]]; then
      echo "Admin Name:" ${ADMIN};
      echo "Job Name: "${NJOB};
      echo "Timestamp: " ${DATE};
      echo "Current Part: " ${part};
    fi
}

bumpDat() {
    #echo "Before: ${part}"
    part=$(($1+1))
    #echo "After: ${part}"
}

lFiles() {
  find $1 -type f > ${temp};
  cat ${temp} | sort -r > ${ftemp}
  # Debug
  cat ${ftemp}
}

lDirs() {
  find $1 -type d > ${temp};
  cat ${temp} | sort -r > ${dtemp}
}

safeList() {
  # search the location given for Files
    echo "Finding all files in $1";
    lFiles $1;
    echo "File list sorted and saved to temp."
    # Next line fr Debugging
    #cat ${ftemp}
  # search the location given for Directories
    echo "Finding all directories in $1";
    lDirs $1;
    echo "Folder list sorted and saved to temp."
    # Next line fr Debugging
    #cat ${dtemp}
  # use the vars from prep()
    
}

popdata() {
  cat ${ftemp} > ${JOB}/${ADMIN}-${NJOB}-files-${DATE}-${part}
  cat ${dtemp} > ${JOB}/${ADMIN}-${NJOB}-dir-${DATE}-${part}
}

#delReport(){
# use the safeList content to make a block of text
# used to send to the customer for verification of the deletion
#}

#rmReport() {
# similar to above; used to show the actions that were taken
#}


# function to determine what to do when the script is ran
while getopts ":e:hptd" opt; do
  case "${opt}" in
    d)
      DEBUG=1
    ;;
  esac
done;
OPTIND=1;
# Anything in the case above has priority over flags below
while getopts ":e:hptd" opt; do
  case "${opt}" in
    e)
      prep
      bumpDat ${part};
      LOCATION=${OPTARG}
      exists $LOCATION;
      popdata;
    ;;
    h)
      usage;
    ;;
    p)
      prep;
    ;;
    t)
      FINDER=1;
    ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage;
      exit 1
    ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
    ;;
  esac
done;

[ -z $1 ] && { usage; }
