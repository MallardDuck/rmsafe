#!/bin/bash
# This script is a simple tool for removing a large amount of files quickly and safely.
author="Dan Pock"
ver="0.0.1a"
progFolder="/root/scripts/rmsafe"
JOB="${progFolder}/jobs"
tempFolder="/home/temp/rmsafe"
temp="${tempFolder}/failtemp"
ftemp="${tempFolder}/ftemp"
dtemp="${tempFolder}/dtemp"
utemp="${tempFolder}/utemp"
ltemp="${tempFolder}/ltemp"

# Vars
JOBS="${progFolder}/jobfile"
ADMIN="AnonAdmin"
AIP=`echo $SSH_CLIENT|awk '{print$1}'`
NJOB="default" #Name of current job-to be created
DATE=`date +%y%m%d%H%S`
part="0"
ecnt="0"
header="\n %-1s %-16s %8s %10s %13s %8s\n"
format="%2s %-16s %8s %7s %20s %8s \n"
# Imports
. ${progFolder}/colors

# Header
header() {
        echo -e "${blu}Linux Safe rm v$ver"
        echo "            (C) 2015, Dan Pock <dpock@liquidweb.com>"
        echo -e "${bldcya}This program may be freely redistributed under the terms of the GNU GPL v2"
        echo ""
        echo -e ${bgmag}${bla}${line}${rst}
}

# Usage function
usage() {
    echo -e "${bldblu}Usage:${bldcya}"
    echo -e "  rmsafe.sh [options] location"
    echo ""
    echo -e "${bldblu}  Options:${bldcya}"
    echo -e "    -p - Runs the prep functions; sets things up if first run"
    echo -e "    -e - Creates the inital job files; if the path is a valid dir"
    echo -e "    -l - Finds and displays all current jobs that were found"
    echo -e "    -a - Finds and displays all jobs created by the current admin"
    echo -e "    -s - Select the Job and the function to be run"
    echo -e "    -d - Turns on the Debugging flag; extra verbose mode"
    echo -e "    -h - Displays this usage (or the help) page"
    echo ""
    echo -e "${bldblu}Example:${bldcya}"
    echo -e "      rmsafe.sh -e /home/cpuser/public_html/blog"
    echo -e "${rst}"
    exit 1
}

# function to check if a directoyr exists
function exists {
if [[ -d $1 ]]; then
  if [[ ${DEBUG} -eq "1" ]]; then
    echo "$1 is a directory"
  fi
elif [[ -f $1 ]]; then
    echo -e "${bldylw}$1 is a file; use normal rm."
    echo -e "${rst}"
    exit 1
else
    echo -e "${bldred}$1 is not valid"
    echo -e "${rst}"
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

# So far this is un-used but I'd like for it to be run automatically
# once the full script is done it will be more clear how cleaning will be done
rmOld() {
  find ${JOB} -mtime +7 -delete
}

prep() {
  rm -rf ${tempFolder};
  mkdir -p ${tempFolder};
  touch ${temp}
  touch ${ftemp}
  touch ${dtemp}
  touch ${utemp}
  touch ${ltemp}
  echo "Prep Done. Temps Cleared";
}

countDis(){
  ecnt=$(($1+1))
}

bumpDat() {
  if [[ ${DEBUG} -eq "1" ]]; then
    echo "====== DEBUG ======";
    echo "Before: ${part}"
  fi
  part=$(($1+1))
  if [[ ${DEBUG} -eq "1" ]]; then
    echo "After: ${part}"
  fi
}

lFiles() {
  echo -e "JPATH=${1}\n#### End Var ####\n" > ${ftemp};
  find $1 -type f > ${temp};
  cat ${temp} | sort -r >> ${ftemp}
  # Debugging
  if [[ ${DEBUG} -eq "1" ]]; then
    echo "====== DEBUG ======";
    cat ${ftemp}
  fi
}

lDirs() {
  echo -e "JPATH=${1}\n#### End Var ####\n" > ${dtemp};
  find $1 -type d > ${temp};
  cat ${temp} | sort -r >> ${dtemp}
  # Debugging
  if [[ ${DEBUG} -eq "1" ]]; then
    echo "====== DEBUG ======";
    cat ${dtemp}
  fi
}

sfChk() {
    if [[ "$ADMIN" -eq "AnonAdmin" ]]; then
      if [[ ${DEBUG} -eq "1" ]]; then
	echo "Admin is Anon; Setting Admin var to IP"
      fi
      ADMIN="${AIP}"
      if [[ ${DEBUG} -eq "1" ]]; then
	echo "Admin is now ${ADMIN}"
      fi
    fi
}


safeList() {
  # search the location given for Files
    echo "Finding all files in $1";
    lFiles $1;
    echo "File list sorted and saved to temp."
  # search the location given for Directories
    echo "Finding all directories in $1";
    lDirs $1;
    echo "Folder list sorted and saved to temp."
  # use the vars from prep()
    
}

poplists() {
  cat ${ftemp} > ${JOB}/${ADMIN}-${NJOB}-${part}-${DATE}.file
  cat ${dtemp} > ${JOB}/${ADMIN}-${NJOB}-${part}-${DATE}.dir
}

userList() {
  echo "The current user is: ${AIP}";
  lJump=1
  list;
  grep ${AIP} ${ltemp}
}

list() {
  if [[ ${lJump} -ne 1 ]];then
    echo "Finding all Jobs"
  fi
  cat ${JOBS} > ${temp}
  echo "" > ${ltemp}
  printf "$header" "#" "User IP" "JobName" "JobPart" "Time & Date" "Path"
  echo ${line}
  lj=0
  for i in $(cat ${temp});do
    lj=$(($lj+1))
    jobPath=`head -1 $i.dir`
    curLn=`echo $i | cut -d\- -f 1-5 --output-delimiter=' '`
    usIP=`echo ${curLn}|awk '{print $1}'|cut -d\/ -f6`;
    usJob=`echo ${curLn}|awk '{print $2}'`
    usPart=`echo ${curLn}|awk '{print $3}'`
    usDate=`echo ${curLn}|awk '{print $4}'`
    pDate=`echo ${usDate}|sed -r 's/^(.*)([0-9]{2})([0-9]{2})([0-9]{2})\w*([0-9]{2})([0-9]{2})(.*)$/\5:\6 \3-\5-20\1\2/g'`
    pPath=`echo $jobPath|sed 's/JPATH=//g'`
    if [[ ${DEBUG} -eq "1" ]]; then
      echo "UserIP: $usIP || Job: $usJob || Part: $usPart || RawDate: $usDate || PrettyDate: $pDate || Path: $jobPath";
      echo "Real Output here: ";
    fi
  printf "$format" "${lj}" "${usIP}" "${usJob}" "${usPart}" "${pDate}" "${pPath}" >> ${ltemp}
  #printf "$format" "${usIP}" "${usJob}" "${usPart}" "${pDate}"
  done
  if [[ ${lJump} -ne 1 ]];then
    cat ${ltemp}
  fi
}

updateJobs() {
  echo "Updating Jobsfile"
  find ${JOB} -type f|cut -d\. -f 1-4|sort|uniq > ${JOBS}
  ctJOB=`cat ${JOBS}|wc -l`
  if [[ ${DEBUG} -eq "1" ]]; then
    cat ${JOBS}
    echo "Number of Jobs: $ctJOB"
    echo "Done Updating Jobs"
  fi
}

prompts=("Please enter your choice: [All]" "What are you trying to do?: ")

pickJob() {
  options=("All" "Mine")
  PS3="${prompts[0]}"
  read -p "Select from All Jobs or Your Jobs: [All|Mine] " -e -i All pJab 
  case $pJab in
    "All")
      list;
      read -p "Select Job to execute: " -e mJab
        doIT=`cat ${JOBS}|head -$mJab|tail -1`
        if [[ ${DEBUG} -eq "1" ]]; then
          echo "The job to run is: $doIT"
        fi
      doJob $doIT;
      exit;
    ;;
    "Mine")
      userList;
      read -p "Select Job to execute: " -e mJab
        doIT=`cat ${JOBS}|head -$mJab|tail -1`
        if [[ ${DEBUG} -eq "1" ]]; then
          echo "The job to run is: $doIT"
        fi
      doJob $doIT;
      exit;
    ;;
    *)
      list;
      exit;
    ;;
  esac
}

doJob() {
  unset options;
  options=("run" "report" "update" "remove" "exit");
  PS3=${prompts[1]}
  if [[ ${DEBUG} -eq "1" ]]; then
    echo "Now starting the action selection."
    echo "Input is: $1";
  fi
  jPath=$1
  # Done w/Vars next pick what to do
  echo "What would you like to do with this job?: "
  select wut in ${options[@]}; do
    case $wut in
      "run")
        echo -e "${bldred}WARNING:${rst} ${mag}Once you select and it is processed there's no going back!${rst}"
      ;;
      "report")
        echo -e "${bldmag}Info:${rst} ${grn}So the next thing will be a Markdown'd report you can send to the customer.${rst}";
        echo -e "${grn}If you're a ${rst}${bgwhi}${blu}nub${rst}${grn}, then you should ${bldylw}DEFINITLY ${rst}${grn}use this for customer approval.${rst}";
        if [[ ${DEBUG} -eq "1" ]];then
          echo "The path used is: ${jPath}";
        fi
        read -p "Type of report:[Files|Dirs|Both] " -e -i Files doType;
        if [[ ${DEBUG} -eq "1" ]];then
          echo "The type of markdown will be: ${doType}";
        fi
        mkitDwn ${doType} ${jPath};
      ;;
      "update")
        echo "[WIP] I know how cool this sounds, sorry it's not realy yet. [ETA soon]"
        exit;
      ;;
      "remove")
        echo "[WIP] removing jobs will be added soon. [ETA soon]"
        exit
      ;;
      "exit")
        echo "Leaving now."
        exit;
      ;;
    esac
  done 
}

mkitDwn() {
  myType=${1};
  myPath=${2};
  pPath=`head -1 $myPath.file|sed 's/JPATH=//g'`
  if [[ ${DEBUG} -eq "1" ]]; then
    echo "The type of markdown will be: ${myType}";
    echo "The path used is: ${myPath}";
  fi
  clear;
  echo -e ${bldblu}${line}${rst};
  echo "Copy the follwing Bold Magenta text.";
  echo -e ${bldblu}${line}${rst};
  case "${myType}" in
    "Dirs")
      echo -e "${bldred}The dirs that will be removed are as follows: ${rst}";
      echo -e ${bldmag};
      echo "\`\`\`";
        l=`cat ${myPath}.dir|wc -l`
        cat ${myPath}.dir|tail -$((${l}-3))|sort
      echo "\`\`\`";
      disclaim;
      notes ${myPath} ${pPath};
    ;;
    "Files")
      echo -e "${bldred}The files that will be removed are as follows: ${rst}";
      echo -e ${bldmag};
      echo "\`\`\`";
        l=`cat ${myPath}.file|wc -l`
        cat ${myPath}.file|tail -$((${l}-3))|sort
      echo "\`\`\`";
      disclaim;
      notes ${myPath} ${pPath};
    ;;
    "Both")
      echo -e "${bldred}The files that will be removed are as follows: ${rst}";
      echo -e ${bldmag};
      echo "\`\`\`";
        l=`cat ${myPath}.file|wc -l`
        cat ${myPath}.file|tail -$((${l}-3))|sort
      echo "\`\`\`";
      echo -e "${bldred}The dirs that will be removed are as follows: ${rst}";
      echo -e ${bldmag};
      echo "\`\`\`";
        unset l
        l=`cat ${myPath}.dir|wc -l`
        cat ${myPath}.dir|tail -$((${l}-3))|sort
      echo "\`\`\`";
      disclaim;
      notes ${myPath} ${pPath};
    ;;
  esac
  echo -e "${rst}";
  exit;
}

disclaim() {
  echo "If you do accept that we will permanently remove these files[and/or directories], then please reply saying \"You have my authorization to delete the files and directories listed\" Once you have replied to this support ticket with the proper authorization then I will be more than happy to proceed with the removal of the content you have requested we delete."
}

notes() {
 echo -e "${rst}";
 echo -e ${line};
 echo "Some good stuff to put in your notes for later:"
 echo "The report sent to the customer was generated with the SafeRM script; the version used was v${ver}"
 echo "JobFile Name: ${1}"
 echo "JobWorking Path: ${2}"
 echo "Time Requesting Approval: " `date`;
}

#delReport(){
# use the safeList content to make a block of text
# used to send to the customer for verification of the deletion
#}

#rmReport() {
# similar to above; used to show the actions that were taken
#}


# function to determine what to do when the script is ran
while getopts ":e:hpdu" opt; do
  case "${opt}" in
    d)
      DEBUG=1
    ;;
    u)
      DEBUG=1
    ;;
    e)
      countDis ${ecnt};
    ;;
  esac
done;
OPTIND=1;
updateJobs;
# Anything in the case above has priority over flags below
while getopts ":e:hpaldsu" opt; do
  case "${opt}" in
    e)
      header;
      bumpDat ${part}
      LOCATION=${OPTARG}
      exists $LOCATION;
      safeList $LOCATION;
      poplists;
    ;;
    h)
      header;
      usage;
    ;;
    p)
      header;
      prep;
    ;;
    a)
      header;
      userList;
    ;;
    l)
      header;
      list;
    ;;
    s)
      pickJob;
    ;;
    \?)
      header;
      echo "Invalid option: -$OPTARG" >&2
      usage;
      exit 1
    ;;
    :)
      header;
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
    ;;
  esac
done;

[ -z $1 ] && { header;usage; }
