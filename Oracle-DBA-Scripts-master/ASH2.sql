-- how much history do we have:
select min(sample_time) from V$ACTIVE_SESSION_HISTORY

--rac环境记得带上GV$ACTIVE_SESSION_HISTORY

--查询最近比较慢的SQL
SELECT SESSION_ID||','||SESSION_SERIAL# "SID,SERIAL#",
       round(DELTA_TIME / 1000000,2) DELTA, --上一次采样到这次采样的时间间隔
       round(DELTA_READ_IO_BYTES / 1000000,2) DELTA_R,
       round(DELTA_WRITE_IO_BYTES / 1000000,2) DELTA_W,
       round(TM_DELTA_TIME / 1000000,2) TM,
       round(TM_DELTA_DB_TIME / 1000000,2) TMD_DB,
       round(TM_DELTA_CPU_TIME / 1000000,2) TMD_CPU,
       60 * EXTRACT(MINUTE FROM SAMPLE_TIME - SQL_EXEC_START) +
       EXTRACT(SECOND FROM SAMPLE_TIME - SQL_EXEC_START) EXECUTE,
       round(pga_allocated/1024/1024,2)||'M' pga,
       round(temp_space_allocated/1024/1024,2)||'M' temp,
       SAMPLE_ID,
       TO_CHAR(SAMPLE_TIME, 'hh24:mi:ss.ff2') SAMPLE_TIME,
       SQL_EXEC_START,
       SQL_ID,
       sql_child_number,sql_plan_hash_value,
       SQL_OPNAME,
       SQL_PLAN_OPERATION,
       SQL_PLAN_OPTIONS,
       WAIT_CLASS,
       EVENT,
       P1TEXT,
       P1,
       P2TEXT,
       P2,
       CURRENT_OBJ#,
       CURRENT_BLOCK#,
       CURRENT_FILE#,
       XID,
       IN_PARSE,
       IN_HARD_PARSE,
       IN_SQL_EXECUTION,
       IN_PLSQL_EXECUTION,
       WAIT_TIME,
       SESSION_STATE,
       TIME_WAITED,
       --blocking_session_status,blocking_session,
       PROGRAM,
       MODULE,
       MACHINE
  FROM GV$ACTIVE_SESSION_HISTORY T
 WHERE SESSION_TYPE = 'FOREGROUND'
   AND SAMPLE_TIME > SYSDATE - 10 / 1440
   ORDER BY SESSION_ID, SESSION_SERIAL#, SAMPLE_ID;
/*
ALTER SYSTEM KILL SESSION '7,15';
SELECT SID,SERIAL#,STATUS,SERVER FROM GV$SESSION;
GV$ACTIVE_SESSION_HISTORY <http://docs.oracle.com/cd/E11882_01/server.112/e40402/dynviews_1007.htm>
*/
--绑定变量
SELECT * FROM  v$sql_bind_capture WHERE sql_id='54uhg2qz57hpv';

-- top events
select event,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where sample_time> sysdate-1/24 
and user_id>0
group by event
order by count(*) desc;


-- top sql
select sql_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY where sample_time> sysdate-1/24 
and user_id>0
group by sql_id
order by count(*) desc;


-- see specific samples
select sample_time,user_id,sql_id,event from DBA_HIST_ACTIVE_SESS_HISTORY
where 1=1
--and sample_time> to_date('03-MAR-11 15:30','dd-mon-yy hh24:mi')
and sample_time> sysdate-1/24
--and user_id>0
--and session_id=371
order by sample_time;

-- look for hot buffers
-- file#,block#,class#
select p1,p2,p3,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY
where sample_time> sysdate-7
and user_id>0
and event='buffer busy waits'
group by p1,p2,p3 
order by count(*)



           SELECT SEGMENT_NAME, SEGMENT_TYPE FROM DBA_EXTENTS            
                WHERE FILE_ID = 1  AND 231928 BETWEEN BLOCK_ID AND                  
                      BLOCK_ID + BLOCKS - 1;  
					  
					  
					  

-- top SQL waiting for a specific events
select sql_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY
where sample_time> sysdate-1/24
and user_id>0
and event  is null
group by sql_id 
order by count(*)

-- top programs waiting for a specific events
select program,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY
where sample_time> to_date('03-MAR-11 15:30','dd-mon-yy hh24:mi')
and  sample_time< to_date('03-MAR-11 16:30','dd-mon-yy hh24:mi')
and user_id>0
and event='buffer busy waits'
group by program
order by count(*)

-- top users waiting for a specific events
select user_id,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY
where sample_time> to_date('03-MAR-11 15:30','dd-mon-yy hh24:mi')
and  sample_time< to_date('03-MAR-11 16:30','dd-mon-yy hh24:mi')
and user_id>0
and event='buffer busy waits'
group by user_id
order by count(*)  2    3    4    5    6    7  ;

-- Everyone waiting for specific event
select sample_time,user_id,sql_id,event,p1,blocking_session from V$ACTIVE_SESSION_HISTORY
where event like 'library%'

-- Who is waiting for specific event the most:
select SESSION_ID,user_id,sql_id,round(sample_time,'hh'),count(*) from V$ACTIVE_SESSION_HISTORY
where event like 'log file sync'
group by  SESSION_ID,user_id,sql_id,round(sample_time,'hh')
order by count(*) desc





select event,count(*) from DBA_HIST_ACTIVE_SESS_HISTORY
where sample_time> to_date('03-MAR-11 15:30','dd-mon-yy hh24:mi')
and  sample_time< to_date('03-MAR-11 16:00','dd-mon-yy hh24:mi')
and user_id>0
group by event
order by count(*) desc


select to_char(trunc(sample_time, 'hh24') + round((cast(sample_time as date)- trunc(cast(sample_time as date), 'hh24'))*60*24/5)*5/60/24, 'dd/mm/yyyy hh24:mi'),count(*) from DBA_HIST_ACTIVE_SESS_HISTORY
where sample_time> to_date('03-MAR-11 15:30','dd-mon-yy hh24:mi')
and  sample_time< to_date('03-MAR-11 16:30','dd-mon-yy hh24:mi')
and user_id=209
and event='buffer busy waits'
group by to_char(trunc(sample_time, 'hh24') + round((cast(sample_time as date)- trunc(cast(sample_time as date), 'hh24'))*60*24/5)*5/60/24, 'dd/mm/yyyy hh24:mi')
order by count(*)


select sql_id,count(*) from V$ACTIVE_SESSION_HISTORY
where sample_time> to_date('08-FEB-10 13:00','dd-mon-yy hh24:mi')
and  sample_time< to_date('08-FEB-10 16:00','dd-mon-yy hh24:mi')
and user_id>0
group by sql_id
order by count(*) desc

select * from dba_views where view_name like 'DBA_HIST%'

select sh.sample_time,sh.SESSION_ID,user_id,sh.sql_id,event,p1,blocking_session,PROGRAM,sql_text
from DBA_HIST_ACTIVE_SESS_HISTORY sh
left outer join  DBA_HIST_SQLTEXT  sq on sq.sql_id=sh.sql_id 
where 1=1 
and sample_time> to_date('08-FEB-10 00:00','dd-mon-yy hh24:mi')
and  sample_time< to_date('08-FEB-10 23:00','dd-mon-yy hh24:mi')
and user_id=61
--and sql_id='809u1jtt54kfy'
order by sample_time


select trunc(sample_time),
sum(case when INSTANCE_NUMBER=1 then 1 else 0 end) inst1,
sum(case when INSTANCE_NUMBER=2 then 1 else 0 end) inst2
from DBA_HIST_ACTIVE_SESS_HISTORY sh
where 1=1 
and user_id=61
group by trunc(sample_time)
order by trunc(sample_time)



select * from DBA_HIST_SQLTEXT where sql_id='d15cdr0zt3vtp';
where dbms_lob.instr(sql_text, 'GLOBAL',1,1) > 0

desc DBA_HIST_ACTIVE_SESS_HISTORY 

EXEC DBMS_MONITOR.session_trace_enable(session_id =>1234, serial_num=>1234, waits=>TRUE, binds=>FALSE);

select sample_time,user_id,sql_id,event,p1,blocking_session from V$ACTIVE_SESSION_HISTORY
where event like 'library%'

select * from v$active_session_history where session_id=306
6969666696
select SESSION_ID,user_id,sql_id,round(sample_time,'hh'),count(*) from V$ACTIVE_SESSION_HISTORY
where event like 'log file sync'
group by  SESSION_ID,user_id,sql_id,round(sample_time,'hh')
order by count(*) desc


select * from dba_users; 61
