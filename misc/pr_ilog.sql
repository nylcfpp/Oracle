create or replace procedure pr_ilog(p_app varchar2,p_content varchar2,p_commit varchar2 default 'commit') is
  v_error_code   varchar2 (20);
  v_error_msg    varchar2 (255);
begin
  if lower(p_content)='exception' then
    v_error_code:= sqlcode;
    v_error_msg := sqlerrm;
    rollback;
  end if;
  insert into bas_ilog (app_name,log_date,log_content,error_code, error_msg)
         values (p_app,to_char(systimestamp,'yyyy-mm-dd hh24:mi:ss.ff2'),p_content,v_error_code,v_error_msg);
  if p_commit='commit' then
    commit;
  end if;
  /*
  示范使用代码1：
  pr_ilog('pr_xxx','deal start...');
  pr_ilog('pr_xxx','deal end...');

  示范使用代码2 , exception异常调用：
  exception when others then
    pr_ilog('pr_xxx','exception');
    pr_ilog(fn_getself,'exception');

  --silog , ilogs
  select cast( (cast(date_cur  as date)-cast(date_pre as date))*24*3600 + extract (second from date_cur -date_pre )
         as number(10,2)) diff , x.*
   from (
    select t.*
          ,to_timestamp(lag(t.log_date,1,null) over(order by log_date) ,'yyyy-mm-dd hh24:mi:ss.ff2') date_pre
          ,to_timestamp(t.log_date,'yyyy-mm-dd hh24:mi:ss.ff2') date_cur
     from bas_ilog t
     where log_date > to_char(sysdate - 1,'yyyy-mm-dd hh24:mi:ss')
   ) x
  */
end;


/*
-- Create table
create table BAS_ILOG
(
  app_name    VARCHAR2(255),
  log_date    VARCHAR2(25) not null,
  log_content VARCHAR2(255),
  error_code  VARCHAR2(20),
  error_msg   VARCHAR2(512)
)
tablespace TS_DBITCOIN
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
-- Add comments to the table 
comment on table BAS_ILOG
  is '用于记录系统中的各种错误信息';
-- Add comments to the columns 
comment on column BAS_ILOG.app_name
  is '程序名称';
comment on column BAS_ILOG.log_date
  is '日志日期';
comment on column BAS_ILOG.log_content
  is '日志内容';
comment on column BAS_ILOG.error_code
  is '错误代码';
comment on column BAS_ILOG.error_msg
  is '错误信息';
*/