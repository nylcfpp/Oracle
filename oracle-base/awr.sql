set echo off;
set veri off;
set feedback off;
set termout on;
set heading off;

variable rpt_options number;

define NO_OPTIONS = 0;
-- define ENABLE_ADDM = 8;

rem according to your needs, the value can be 'text' or 'html'
define report_type='html';
begin
:rpt_options := &NO_OPTIONS;
end;
/

variable dbid number;
variable inst_num number;
variable bid number;
variable eid number;
begin
select max(snap_id)-1 into :bid from dba_hist_snapshot;
select max(snap_id) into :eid from dba_hist_snapshot;
select dbid into :dbid from v$database;
select instance_number into :inst_num from v$instance;
end;
/

column ext new_value ext noprint
column fn_name new_value fn_name noprint;
column lnsz new_value lnsz noprint;

select 'txt' ext from dual where lower('&report_type') = 'text';
select 'html' ext from dual where lower('&report_type') = 'html';
select 'awr_report_text' fn_name from dual where lower('&report_type') = 'text';
select 'awr_report_html' fn_name from dual where lower('&report_type') = 'html';
select '80' lnsz from dual where lower('&report_type') = 'text';
select '1500' lnsz from dual where lower('&report_type') = 'html';

set linesize &lnsz;

column report_name new_value report_name noprint;

select 'sp_'||:bid||'_'||:eid||'.'||'&ext' report_name from dual;
set termout off;
spool &report_name;

select output from table(dbms_workload_repository.&fn_name(:dbid, :inst_num,:bid, :eid,:rpt_options ));
spool off;
set termout on;
clear columns sql;
ttitle off;
btitle off;
repfooter off;
undefine report_name
undefine report_type
undefine fn_name
undefine lnsz
undefine NO_OPTIONS
