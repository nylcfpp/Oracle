create or replace procedure pr_mid_orders (
  p_platform_type  varchar2,
  p_begindate      varchar2,
  p_enddate        varchar2 default null,
  p_createuser     varchar2 default null)
is
  v_begindate      varchar2(20);
  v_enddate        varchar2(20);
  v_platform_type  varchar2(200);
  v_platform_table varchar2(200);
  v_platform_where varchar2(2000);
  v_sqltext        varchar2(4000);

  begin
    /***** 调用方式：
    begin pr_mid_orders('nmg'   ,'20160601'); end;
    begin pr_mid_orders('agin'  ,'20160601','20160630'); end;
    begin pr_mid_orders('ag'    ,'20160601','20160630'); end;
    select * from orders_ag where billtime>=date'2016-06-01' and billtime<date'2016-07-01' and  platform_type='AG'
    select * from mid_orders
    select * from bas_ilog;
    *****/
    --平台类型合法性校验
    v_platform_type:=lower(nvl(p_platform_type,'null'));
    if v_platform_type not in('ag','agin','agtel','sun','bbin','sabah','pt','nmg','hbr','png','yoplay','bg','nyx','endo','ttg' ) then
      pr_ilog('pr_mid_orders','platform_type is not correct!');
      return;
    end if;
    --日期类型合法性校验
    v_begindate:=p_begindate;
    v_enddate  :=nvl(p_enddate,p_begindate);
    v_begindate:=to_char(to_date(v_begindate,'yyyymmdd'),'yyyymmdd');
    v_enddate  :=to_char(to_date(v_enddate  ,'yyyymmdd'),'yyyymmdd');

    if v_platform_type in ('ag','agin') then
      v_platform_table:='orders_ag';
      v_platform_where:='(agcode is null or agcode not in (''517001001001002'',''129001001001001'',''517001001001004'',''074001001001002'',''074001001001004'',''try'',''074001001001006'',''131001001001001''))';
    elsif  v_platform_type='sun' then
      v_platform_table:='orders_'||v_platform_type;
      v_platform_where:='(agcode is null or agcode not in (''2''))';
    else
      v_platform_table:='orders_'||v_platform_type;
      v_platform_where:='1=1';
    end if;

    pr_ilog('pr_mid_orders','['||v_begindate||'-'||v_enddate||'] refresh '||v_platform_type||'...');
    delete from mid_orders
    where platform_type=upper(v_platform_type)
          and billtime >=to_date(v_begindate||' 00:00:00','yyyymmdd hh24:mi:ss')
          and billtime <=to_date(v_enddate  ||' 23:59:59','yyyymmdd hh24:mi:ss');
    v_sqltext:=
    'insert into mid_orders
          (product_id
          ,billtime
          ,loginname
          ,platform_type
          ,game_kind
          ,gametype
          ,device_type
          ,bill_status
          ,order_total
          ,account
          ,valid_account
          ,cus_account
          ,net_amount_bonus
          ,currency
          ,createdate
          ,createuser)
    select product_id            --产品ID
          ,trunc(billtime,''dd'') billtime  --注单日期
          ,loginname             --登录名
          ,platform_type         --平台类型
          ,game_kind             --游戏种类
          ,gametype              --游戏类型
          ,device_type           --登陆设备类型
          ,flag      bill_status --注单状态
          ,count(1)  order_total --注单总数
          ,sum(account)          --投注额
          ,sum(valid_account)    --有效投注额
          ,sum(cus_account)      --客户输赢度
          ,sum(net_amount_bonus) --奖池
          ,currency              --货币
          ,sysdate createdate    --记录创建时间
          ,'''||p_createuser||''' --记录创建者
 from '||v_platform_table||'
where platform_type='''||upper(v_platform_type)||'''
  and billtime >=to_date('''||v_begindate||' 00:00:00'',''yyyy-mm-dd hh24:mi:ss'')
  and billtime <=to_date('''||v_enddate  ||' 23:59:59'',''yyyy-mm-dd hh24:mi:ss'')
  and '||v_platform_where||'
group by product_id,trunc(billtime,''dd''),loginname,platform_type,game_kind,gametype,gametype,device_type,flag,currency';
    --dbms_output.put_line(v_sqltext);
    execute immediate v_sqltext;









    commit;





    merge into mid_orders o
    using product_customer_level l
    on (o.loginname = l.loginname and o.product_id=l.product_id)
    when matched then
    update set o.customerlevel=l.customerlevel ,o.createdate=sysdate
      where o.billtime>=to_date(v_begindate||' 00:00:00','yyyy-mm-dd hh24:mi:ss')
            and o.billtime< to_date(v_enddate  ||' 23:59:59','yyyy-mm-dd hh24:mi:ss');
    commit;
    /*exception when others then
      pr_ilog('pr_mid_orders','Exception');*/
  end;
