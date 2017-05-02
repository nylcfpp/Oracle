#!/bin/bash
# ********************************
# * autoawrrpt.sh
# ********************************
# Usage: autoawrrpt.sh -s [instance_name]
#          -f [from time]
#          -t [to time]
#          -p [report type, html or text]
#          -h [oracle home]
#          -n [tns admin]
#
#         time format: 'yyyymmddhh24'.
#         E.g 2011030417 means 05pm, Mar 04, 2011
#/autoawrrpt.sh -s orcl -f 2013092917 -t 2013092918 -p HTML -h /home/ora11g/product/11.1.0
#
# **********************
# get parameters
# **********************
  while getopts ":s:f:t:p:h:n" opt
  do
    case $opt in
    s) instance=$OPTARG
       ;;
    f) from=$OPTARG
       ;;
    t) to=$OPTARG
       ;;
    p) type=$OPTARG
       type=$(echo $type|tr "[:upper:]" "[:lower:]")
       ;;
    h) oracle_home=$OPTARG
       ;;
    n) tns_admin=$OPTARG
       ;;
    '?') echo "$0: invalid option -$OPTARG">&2
       exit 1
       ;;
    esac
done
if [ "$instance" = "" ]
then
  echo "instance name(-s) needed"
  echo "program exiting..."
  exit 1
fi
if [ "$from" = "" ]
then
  echo "from time (-f} needed"
  echo "program exiting..."
  exit 1
fi
if [ "$to" = "" ]
then
  echo "to time (-t) needed"
  echo "program exiting..."
  exit 1
fi
if [ "${oracle_home}" = "" ]
then
  echo "oracle home (-h) needed"
  echo "program exiting..."
  exit 1
fi
sqlplus="${oracle_home}/bin/sqlplus"
echo $sqlplus
if [ "$type" = "" ]
then
  type="html"
fi
# ********************
# trim function
# ********************
function trim()
{
  local result
  result=`echo $1|sed 's/^ *//g' | sed 's/ *$//g'`
  echo $result
}
# *******************************
# read interchange ID & passwd
# *******************************
#read_act()
#{
#echo "interchange ID: "
#read user
#echo "password: "
#stty -echo
#read pswd
#stty echo
#}
# *******************************
# get begin and end snapshot ID
# *******************************
define_dur()
{
begin_id=`$sqlplus -s /nolog<<EOF
  conn /as sysdba
  set pages 0
  set head off
  set feed off
  select max(SNAP_ID) from DBA_HIST_SNAPSHOT where
    BEGIN_INTERVAL_TIME<=to_date($from,'yyyymmddhh24');
EOF`
ret_code=$?
if [ "$ret_code" != "0" ]
then
  echo "sqlplus failed with code $ret_code"
  echo "program exiting..."
  exit 10
fi
end_id=`$sqlplus -s /nolog<<EOF
  conn /as sysdba
  set pages 0
  set head off
  set feed off
  select min(SNAP_ID) from DBA_HIST_SNAPSHOT where
    END_INTERVAL_TIME>=to_date($to,'yyyymmddhh24');
  spool off
EOF`
ret_code=$?
if [ "$ret_code" != "0" ]
then
  echo "sqlplus failed with code $ret_code"
  echo "program exiting..."
  exit 10
fi
begin_id=$(trim ${begin_id})
end_id=$(trim ${end_id})
# echo "begin_id: $begin_id  end_id: $end_id"
}
# *******************************
# generate AWR report
# *******************************
generate_awr()
{
  awrsql="${oracle_home}/rdbms/admin/awrrpt.sql"
  if [ ! -e $awrsql ]
  then
    echo "awrrpt.sql does not exist, exiting..."
    exit 20
  fi
  tmp1_id=${begin_id}
  #echo "begin_id is: $begin_id"
  #echo "tmp1_id is: $tmp1_id"
  while [ ${tmp1_id} -lt ${end_id} ]
  do
    let tmp2_id=${tmp1_id}+1
    if [ $type = "text" ]
    then
      report_name="awrrpt_${instance}_${tmp1_id}_${tmp2_id}.txt"
    else
      report_name="awrrpt_${instance}_${tmp1_id}_${tmp2_id}.html"
    fi
    #echo $report_name
$sqlplus -s "/as sysdba">/dev/null<<EOF
      set term off
      define report_type=$type
      define num_days=1
      define begin_snap=${tmp1_id}
      define end_snap=${tmp2_id}
      define report_name=${report_name}
      @${oracle_home}/rdbms/admin/awrrpt.sql
      exit;
EOF
    tmp1_id=${tmp2_id}
  done
}
# *******************************
# main routing
# *******************************
#read_act
define_dur
generate_awr