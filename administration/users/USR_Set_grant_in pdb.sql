-- >---
-- >title: Oracle dba grants for PLSQL and SQL development training
-- >metadata:
-- >    description: 'Oracle dba grants for PLSQL and SQL development training'
-- >    keywords: 'Oracle dba grants for PLSQL and SQL development training example code, tutorials'
-- >author: Venkata Bhattaram / tinitiate.com
-- >code-alias: user-grants
-- >slug: oracle/plsql/user-grants
-- >---

-- ># User the Pluggable Database 
alter session set container = pdborcl;
alter database open;

-- >## Grants on dba views


-- >## Grants on V$ views
-- >* **IMPORTANT NOTE** Oracle v$ views are named V_$VIEWNAME 
-- >  and they have synonyms in format V$VIEWNAME and you can’t give privilage on a synonym.
-- >```sql
grant select on v_$session to tinitiate;
grant select on v_$database to tinitiate;
grant select on v_$instance to tinitiate;

grant select on dba_indexes to tinitiate;
grant select on dba_mviews to tinitiate;
grant select on dba_mview_logs to tinitiate;
grant select on dba_refresh to tinitiate;
grant select on dba_tab_partitions to tinitiate;
grant select on dba_tab_subpartitions to tinitiate;
grant select on dba_tab_partitions to tinitiate;
grant select on dba_tab_subpartitions to tinitiate;
grant select on dba_ind_partitions to tinitiate;
-- >```


-- >## Grants to create DB objects
-- >### Grants for creating and managing materialized views
-- >```sql
grant create materialized view to tinitiate;
grant query rewrite to tinitiate;
-- >```

-- >### Grants for creating directory
-- >```sql
grant create any directory to tinitiate;
-- >```

-- >## Grants to use Explain Plan
-- >```sql
grant execute on dbms_xplan to tinitiate;
grant execute on dbms_stats to tinitiate;
grant select on v_$session to tinitiate;
grant select on v_$sql to tinitiate;
grant select on v_$sql_plan to tinitiate;
grant select on v_$sql_plan_statistics_all to tinitiate;
grant select on v_$parameter to tinitiate;
-- >```
select user from dual;




