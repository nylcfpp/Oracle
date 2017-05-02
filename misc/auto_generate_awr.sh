#!/bin/bash 

# File name     :  auto_generate_awr.sh
# Author        :  Ricky
# Last Modified :  2015-11-26

# e.g:/home/oracle/oracle_script/awrrpt/auto_generate_awr.sh 201511260800 201511261000 1
#    will create 2 AWR report files:
#        awrrpt_1_4836_4837.html  awrrpt_1_4837_4838.html

#    201511260800 201511261000 means 8:00am-10:00am
#    1                         means interval
#5 0 * * * /home/oracle/oracle_script/awrrpt/auto_generate_awr.sh $(date "+\%Y\%m\%d\%H\%M" -d -1day) $(date "+\%Y\%m\%d\%H\%M" -d -1hour) 1
# to save dir
export SAVE_DIR=/home/oracle/oracle_script/awrrpt
export ORACLE_SID=agdc2
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_1
export sqlplus=${ORACLE_HOME}/bin/sqlplus
export LOGFILE=/home/oracle/oracle_script/awrrpt/auto_generate_awr.sh.log

export from=$1
export to=$2
export i=$3

generate()
{
begin_id=`$sqlplus -s / as sysdba<<EOF
  set pages 0
  set head off
  set feed off
  select max(SNAP_ID) from DBA_HIST_SNAPSHOT where
    BEGIN_INTERVAL_TIME<=to_date($from,'yyyymmddhh24mi');
EOF`

ret_code=$?
if [ "$ret_code" != "0" ]
then
  echo "1.sqlplus failed with code $ret_code"
  echo "program exiting..."
  exit 10
fi

end_id=`$sqlplus -s / as sysdba<<EOF
  conn / as sysdba
  set pages 0
  set head off
  set feed off
  select min(SNAP_ID) from DBA_HIST_SNAPSHOT where
    END_INTERVAL_TIME>=to_date($to,'yyyymmddhh24mi');
EOF`

ret_code=$?
if [ "$ret_code" != "0" ]
then
  echo "2.sqlplus failed with code $ret_code"
  echo "program exiting..." exit 10
fi

#echo "begin_id is: >$begin_id<"
#echo "end_id is: >$end_id<"

begin_id=`echo ${begin_id}|sed 's/^ *//g' | sed 's/ *$//g'`
end_id=`echo ${end_id}|sed 's/^ *//g' | sed 's/ *$//g'`

tmp1=${begin_id}
echo "begin time is: ${tmp1}"
echo "end time is  : ${end_id}"
echo "interval is  : $i"

while [ ${tmp1} -lt ${end_id} ]
do
  let tmp2=${tmp1}+${i}
  $sqlplus -s / as sysdba>/dev/null<<EOF
        set term off
        define report_type=html
        define num_days=1
        define begin_snap=${tmp1}
        define end_snap=${tmp2}
        define report_name=awrrpt_1_${tmp1}_${tmp2}.html
        @${ORACLE_HOME}/rdbms/admin/awrrpt.sql
        exit;
EOF
  echo "created file: `pwd`/awrrpt_1_${tmp1}_${tmp2}.html"
  tmp1=${tmp2}
done

ret_code=$?
if [ "$ret_code" != "0" ]
then
  echo "3.sqlplus failed with code $ret_code"
  echo "program exiting..."
  exit 10
fi
}


exec >> ${LOGFILE}

echo "****************************************************"
echo "* START GENERATE AWR REPORT                        *"
echo "* DATE: " `date +"%Y/%m/%d %H:%M:%S"`"                       *"
echo "****************************************************"
cd ${SAVE_DIR}
generate
tar czf "`hostname`_awr_`date "+%Y%m%d%H%M"`.tar.gz" *.html --remove-files
echo
echo " zip files ..."
echo "****************************************************"
echo "* END GENERATE AWR REPORT                          *"
echo "* DATE: " `date +"%Y/%m/%d %H:%M:%S"`"                       *"
echo "****************************************************"
echo;echo 
