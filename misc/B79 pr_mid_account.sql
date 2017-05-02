create or replace procedure pr_mid_account(
  p_beginmonth      varchar2,
  p_endmonth        varchar2,
  p_product_id      varchar2)
is
  v_beginmonth      varchar2(20);
  v_endmonth        varchar2(20);
begin
  /***** 调用方式：
  只能按月份调用，
  delete from mid_account_bymonth where stat_month='2016-08';
  begin pr_mid_account('2015-01','2016-08','B79'); end;
  *****/

  pr_ilog('pr_mid_account','deal start...');
  --日期类型合法性校验
  v_beginmonth:=p_beginmonth;
  v_endmonth  :=nvl(p_endmonth,p_beginmonth);
  v_beginmonth:=to_char(to_date(v_beginmonth,'yyyy-mm'),'yyyy-mm');
  v_endmonth  :=to_char(to_date(v_endmonth  ,'yyyy-mm'),'yyyy-mm');
  if v_beginmonth>v_endmonth or v_beginmonth is null then
    pr_ilog('pr_mid_account','Input start month or end month is not correct!');
    return;
  end if;

  --产品ID合法性校验
  if p_product_id not in('B79','P02') then
    pr_ilog('pr_mid_account','Input p_product_id is not correct!');
    return;
  end if;

pr_ilog('pr_mid_account','['||v_beginmonth||'-'||v_endmonth||'] deleting...');
delete from mid_account_bymonth where stat_month>=v_beginmonth and stat_month<=v_endmonth;

/*****存款处理****/
/*--111101:手工存款      111105:在线支付          113001:点卡支付
  --111801:微信支付      111901:支付宝支付        112001:财付通支付*/
pr_ilog('pr_mid_account','['||v_beginmonth||'-'||v_endmonth||'] merge deposit...');
merge into mid_account_bymonth a
using (
--存款SELECT开始位置
with t as (
select row_number() over (partition by to_char(created_date,'yyyy-mm'),customer_id order by created_date asc) rn
      ,to_char(created_date,'yyyy-mm') stat_month, customer_id,amount,created_date,decode(remarks,'P100103','1') df_flag
  from t_credit_logs
 where trans_code in('111101','111105','113001','111801','111901','112001')
   and created_date>=add_months(to_date(v_beginmonth,'yyyy-mm'),0)
   and created_date< add_months(to_date(v_endmonth  ,'yyyy-mm'),1)
   ),a as (
select stat_month,customer_id,count(*) d_cnt,sum(amount) d_amount from t group by stat_month,customer_id
   ),b as (
select stat_month,customer_id
      ,sum(decode(rn,1,amount,null)) d1_amount
      ,sum(decode(rn,2,amount,null)) d2_amount
      ,sum(decode(rn,3,amount,null)) d3_amount
      ,sum(decode(rn,4,amount,null)) d4_amount
      ,sum(decode(rn,5,amount,null)) d5_amount
      ,max(decode(rn,1,created_date,null)) d1_date
      ,max(decode(rn,2,created_date,null)) d2_date
      ,max(decode(rn,3,created_date,null)) d3_date
      ,max(decode(rn,4,created_date,null)) d4_date
      ,max(decode(rn,5,created_date,null)) d5_date
      ,max(df_flag) df_flag
      ,sum(decode(df_flag,'1',amount,null))       df_amount
      ,max(decode(df_flag,'1',created_date,null)) df_date
 from t
where rn<=5
group by stat_month,customer_id
     )
select a.stat_month,a.customer_id,a.d_cnt,a.d_amount
      ,d1_amount,d2_amount,d3_amount,d4_amount,d5_amount
      ,d1_date  ,d2_date  ,d3_date  ,d4_date  ,d5_date
      ,df_flag,df_amount,df_date
 from a left join b on(a.stat_month=b.stat_month and a.customer_id=b.customer_id)
--存款SELECT结束位置
       ) b
   on (a.stat_month = b.stat_month and a.customer_id=b.customer_id)
 when matched then
      update set a.d_cnt    =b.d_cnt
                ,a.d_amount =b.d_amount
                ,a.d1_amount=b.d1_amount
                ,a.d2_amount=b.d2_amount
                ,a.d3_amount=b.d3_amount
                ,a.d4_amount=b.d4_amount
                ,a.d5_amount=b.d5_amount
                ,a.d1_date  =b.d1_date
                ,a.d2_date  =b.d2_date
                ,a.d3_date  =b.d3_date
                ,a.d4_date  =b.d4_date
                ,a.d5_date  =b.d5_date
                ,a.df_flag  =b.df_flag
                ,a.df_amount=b.df_amount
                ,a.df_date  =b.df_date
 when not matched then
      insert(a.product_id,a.stat_month,a.customer_id,a.d_cnt,a.d_amount,a.d1_amount,a.d2_amount,a.d3_amount,a.d4_amount,a.d5_amount,a.d1_date,a.d2_date,a.d3_date,a.d4_date,a.d5_date,a.df_flag,a.df_amount,a.df_date)
      values(p_product_id,b.stat_month,b.customer_id,b.d_cnt,b.d_amount,b.d1_amount,b.d2_amount,b.d3_amount,b.d4_amount,b.d5_amount,b.d1_date,b.d2_date,b.d3_date,b.d4_date,b.d5_date,b.df_flag,b.df_amount,b.df_date);



/*****取款处理****/
pr_ilog('pr_mid_account','['||v_beginmonth||'-'||v_endmonth||'] merge withdrawl...');
merge into mid_account_bymonth a using (
      --取款SELECT开始位置
      select to_char(created_date,'yyyy-mm') stat_month ,customer_id,count(*) w_cnt,sum(amount) w_amount
        from t_withdrawal_requests
       where flag='2'
         and created_date>=add_months(to_date(v_beginmonth,'yyyy-mm'),0)
         and created_date< add_months(to_date(v_endmonth  ,'yyyy-mm'),1)
       group by to_char(created_date,'yyyy-mm'),customer_id
      --取款SELECT结束位置
      ) b on (a.stat_month = b.stat_month and a.customer_id=b.customer_id)
 when matched then
      update set a.w_cnt=b.w_cnt,a.w_amount=b.w_amount
 when not matched then
      insert(a.product_id,a.stat_month,a.customer_id,a.w_cnt,a.w_amount)
      values(p_product_id,b.stat_month,b.customer_id,b.w_cnt,b.w_amount);


/*****普通优惠, 所有优惠=普通优惠+洗码优惠****/
pr_ilog('pr_mid_account','['||v_beginmonth||'-'||v_endmonth||'] merge promotion...');
merge into mid_account_bymonth a using (
      --普通优惠SELECT开始位置
      select to_char(created_date,'yyyy-mm') stat_month ,customer_id,sum(amount) pro_amount
        from t_promotion_requests
       where flag='2'
         and created_date>=add_months(to_date(v_beginmonth,'yyyy-mm'),0)
         and created_date< add_months(to_date(v_endmonth  ,'yyyy-mm'),1)
       group by to_char(created_date,'yyyy-mm'),customer_id
      --普通优惠SELECT结束位置
      ) b on (a.stat_month = b.stat_month and a.customer_id=b.customer_id)
 when matched then
      update set a.pro_amount=b.pro_amount
 when not matched then
      insert(a.product_id,a.stat_month,a.customer_id,a.pro_amount)
      values(p_product_id,b.stat_month,b.customer_id,b.pro_amount);


/*****洗码优惠处理 , 所有优惠=普通优惠+洗码优惠****/
pr_ilog('pr_mid_account','['||v_beginmonth||'-'||v_endmonth||'] merge rebate...');
merge into mid_account_bymonth a using (
      --洗码优惠SELECT开始位置
      select to_char(created_date,'yyyy-mm') stat_month ,customer_id,sum(amount) reb_amount
        from t_rebate_requests
       where flag='2'
         and created_date>=add_months(to_date(v_beginmonth,'yyyy-mm'),0)
         and created_date< add_months(to_date(v_endmonth  ,'yyyy-mm'),1)
       group by to_char(created_date,'yyyy-mm'),customer_id
      --洗码优惠SELECT结束位置
      ) b on (a.stat_month = b.stat_month and a.customer_id=b.customer_id)
 when matched then
      update set a.reb_amount=b.reb_amount
 when not matched then
      insert(a.product_id,a.stat_month,a.customer_id,a.reb_amount)
      values(p_product_id,b.stat_month,b.customer_id,b.reb_amount);


/*****更新customer表冗余信息****/
pr_ilog('pr_mid_account','['||v_beginmonth||'-'||v_endmonth||'] merge t_customers info...');
merge into mid_account_bymonth a using (
      --SELECT起始位置
      select c.customer_id,c.login_name,c.real_name,c.created_date,c.customer_type,l.customer_level,c.currency,c.last_login_date,p.parent_name
        from t_customers c
            ,(select customer_id,max(flag) customer_level  from t_customer_levels where level_id = 'L001' group by customer_id) l
            ,(select customer_id parent_id,login_name parent_name from t_customers ) p
       where c.customer_id=l.customer_id(+)
         and c.parent_id  =p.parent_id(+)
      --SELECT结束位置
      ) b on (a.customer_id=b.customer_id)
 when matched then
      update set a.login_name       =b.login_name
                ,a.c_real_name      =b.real_name
                ,a.c_created_date   =b.created_date
                ,a.c_customer_type  =b.customer_type
                ,a.c_customer_level =b.customer_level
                ,a.c_currency       =b.currency
                ,a.c_parent_name    =b.parent_name
                ,a.c_last_login_date=b.last_login_date;


update mid_account_bymonth set CREATE_DATE=sysdate,create_user='system'
 where stat_month>=v_beginmonth and stat_month<=v_endmonth;

/*****更新mid_account_5deposit表****/
pr_ilog('pr_mid_account','['||v_beginmonth||'-'||v_endmonth||'] insert mid_account_5deposit...');
delete from mid_account_5deposit;
insert into mid_account_5deposit(login_name,customer_id,d1_amount,d2_amount,d3_amount,d4_amount,d5_amount,
                                 d1_date,d2_date,d3_date,d4_date,d5_date,df_amount,df_date)
with t as (
select row_number() over (partition by customer_id order by created_date asc,credit_log_id asc) rn
     ,customer_id,amount,created_date,decode(remarks,'P100103','1') df_flag
 from t_credit_logs
where trans_code in('111101','111105','113001','111801','111901','112001')
   ),a as (
select customer_id
      ,sum(decode(rn,1,amount,null)) d1_amount
      ,sum(decode(rn,2,amount,null)) d2_amount
      ,sum(decode(rn,3,amount,null)) d3_amount
      ,sum(decode(rn,4,amount,null)) d4_amount
      ,sum(decode(rn,5,amount,null)) d5_amount
      ,max(decode(rn,1,created_date,null)) d1_date
      ,max(decode(rn,2,created_date,null)) d2_date
      ,max(decode(rn,3,created_date,null)) d3_date
      ,max(decode(rn,4,created_date,null)) d4_date
      ,max(decode(rn,5,created_date,null)) d5_date
      ,sum(decode(df_flag,'1',amount,null))       df_amount
      ,max(decode(df_flag,'1',created_date,null)) df_date
 from t
where rn<=5
group by customer_id
     )
select b.login_name,a.*
  from a,t_customers b
 where a.customer_id=b.customer_id(+);

  pr_ilog('pr_mid_account','deal end.');
  commit;
exception when others then
  pr_ilog('pr_mid_account','Exception');
end;



/*
麻烦帮忙调取2015年7月至12月所有开户的数据，需要字段如下：
上级、注册域名、登录名、星级、注册日期、存款次数、总存款、总取款
*/
 select p.parent_name,a.login_name,a.reserve2,l.flag,a.created_date,b.d_cnt,b.d_amount,b.w_amount
  from t_customers a,mid_account_byall b
      ,(select customer_id parent_id,login_name parent_name from t_customers ) p  --上级 
      ,(select customer_id,max(flag) flag  from b79dawg.t_customer_levels where level_id = 'L001' group by customer_id) l
 where a.created_date>=date'2015-07-01'  and a.created_date<date'2016-01-01'
   and a.parent_id=p.parent_id(+)
   and a.customer_id=l.customer_id(+)
   and a.login_name=b.login_name(+)
   --and a.name=c.login_name(+)
   --and a.name=d.login_name(+)
   --and a.name=e.login_name(+)
 order by a.created_date
 