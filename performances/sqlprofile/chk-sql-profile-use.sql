
accept p_name prompt 'Enter the profile name or leave blank to see all: '


select inst_id, 'V$SQL' loc, sql_id, plan_hash_value, child_number, executions, sql_profile
from   gv$sql
where  sql_profile is not null 
and    sql_profile = nvl('&p_name',sql_profile)
union all
select instance_number, 'AWR' loc, sql_id, plan_hash_value, null, executions_total, sql_profile
from   dba_hist_sqlstat
where  sql_profile is not null 
and    sql_profile = nvl('&p_name',sql_profile)
order by sql_profile;

unef p_name

