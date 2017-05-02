create or replace procedure pr_mid_orders_dealmuti(
  p_platform_type varchar,
  p_begindate     varchar2,
  p_enddate       varchar2 default null,
  p_createuser    varchar2 default null)
is
  v_begindate     varchar2(20);
  v_enddate       varchar2(20);
  v_platform_type varchar2(200);
begin
  /**** 调用方式：
  begin pr_mid_orders_dealmuti('all','20160601'); end;
  begin pr_mid_orders_dealmuti('all','20160601','20160630'); end;
  begin pr_mid_orders_dealmuti('nmg,pt,ag,agin','20160601','20160630'); end;
  select * from orders_ag where billtime>=date'2016-06-01' and billtime<date'2016-07-01' and  platform_type='AG'
  select * from mid_orders;
  select * from bas_ilog;
  *****/
  --平台类型合法性校验
  v_platform_type:=lower(nvl(p_platform_type,'null'))||',';  --为了精确like匹配，加逗号做后缀

  --日期类型合法性校验
  v_begindate:=p_begindate;
  v_enddate  :=nvl(p_enddate,p_begindate);
  v_begindate:=to_char(to_date(v_begindate,'yyyymmdd'),'yyyymmdd');
  v_enddate  :=to_char(to_date(v_enddate  ,'yyyymmdd'),'yyyymmdd');
  if v_begindate>v_enddate or v_begindate is null then
    pr_ilog('pr_mid_orders_dealmuti','Input Date is not correct!');
    return;
  end if;

  pr_ilog('pr_mid_orders_dealmuti','deal start...');
  /**************实际执行的业务逻辑代码,开始***********************/
  if v_platform_type='all,' or v_platform_type like '%agin,%'   then pr_mid_orders('agin'   ,v_begindate,v_enddate,p_createuser); end if;
  if v_platform_type='all,' or v_platform_type like '%ag,%'     then pr_mid_orders('ag'     ,v_begindate,v_enddate,p_createuser); end if;
  if v_platform_type='all,' or v_platform_type like '%agtel,%'  then pr_mid_orders('agtel'  ,v_begindate,v_enddate,p_createuser); end if;
  if v_platform_type='all,' or v_platform_type like '%sun,%'    then pr_mid_orders('sun'    ,v_begindate,v_enddate,p_createuser); end if;
  if v_platform_type='all,' or v_platform_type like '%bbin,%'   then pr_mid_orders('bbin'   ,v_begindate,v_enddate,p_createuser); end if;
  if v_platform_type='all,' or v_platform_type like '%sabah,%'  then pr_mid_orders('sabah'  ,v_begindate,v_enddate,p_createuser); end if;
  if v_platform_type='all,' or v_platform_type like '%pt,%'     then pr_mid_orders('pt'     ,v_begindate,v_enddate,p_createuser); end if;
  if v_platform_type='all,' or v_platform_type like '%nmg,%'    then pr_mid_orders('nmg'    ,v_begindate,v_enddate,p_createuser); end if;
  if v_platform_type='all,' or v_platform_type like '%hbr,%'    then pr_mid_orders('hbr'    ,v_begindate,v_enddate,p_createuser); end if;
  if v_platform_type='all,' or v_platform_type like '%png,%'    then pr_mid_orders('png'    ,v_begindate,v_enddate,p_createuser); end if;
  if v_platform_type='all,' or v_platform_type like '%yoplay,%' then pr_mid_orders('yoplay' ,v_begindate,v_enddate,p_createuser); end if;
  if v_platform_type='all,' or v_platform_type like '%bg,%'     then pr_mid_orders('bg'     ,v_begindate,v_enddate,p_createuser); end if;
  if v_platform_type='all,' or v_platform_type like '%nyx,%'    then pr_mid_orders('nyx'    ,v_begindate,v_enddate,p_createuser); end if;
  if v_platform_type='all,' or v_platform_type like '%endo,%'   then pr_mid_orders('endo'   ,v_begindate,v_enddate,p_createuser); end if;
  if v_platform_type='all,' or v_platform_type like '%ttg,%'    then pr_mid_orders('ttg'    ,v_begindate,v_enddate,p_createuser); end if;
  /**************实际执行的业务逻辑代码，结束***********************/
  pr_ilog('pr_mid_orders_dealmuti','deal end.');
/*exception when others then
  pr_ilog('pr_mid_orders_dealmuti','Exception');*/
end;
