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

begin pr_mid_account('2015-07','2015-12','B79'); end;