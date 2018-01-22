-- AWR - Expensive SQL for a snap_id.sql
-- Updated 24-Oct-2013 RDCornejo 
-- gets most expensive queries for a snap_id range [from  DBA_HIST_SQLSTAT ] ; highest elapsed time first 
-- Usage notes:
-- leave optional subset conditions null if not available: hour range; snap_id range; username
-- edit the final order by to get a "profile"
select schema  
   , plan_hash_value
   , sql_id
   , clock_time
   , time_per_exec
--   , cpu_sec
   , plsql_sec
   , executions
   , buffer_gets
   , scan
   , sql_text
   , to_char(min_time, 'mm/dd/yyyy HH24:MI:SS') min_time
   , to_char(max_time ,'mm/dd/yyyy HH24:MI:SS') max_time
   , min_snap_id
   , max_snap_id
from
(
select schema  
   , plan_hash_value
   , sql_id
   , sub.elapsed_sec
   , CASE 
     WHEN elapsed_sec > 86399
          THEN elapsed_sec || ' sec' 
     WHEN elapsed_sec <= 86399
          THEN to_char(to_date(round(elapsed_sec) ,'SSSSS'), 'HH24:MI:SS') 
     END as clock_time
   , case when executions <> 0
     then CASE 
     WHEN round(elapsed_sec/executions) > 86399
          THEN round(elapsed_sec/executions) || ' sec' 
     WHEN round(elapsed_sec/executions) <= 86399
          THEN to_char(to_date(round(elapsed_sec/executions) ,'SSSSS'), 'HH24:MI:SS') 
     END 
     end as time_per_exec
   , cpu_sec
   , plsql_sec
   , executions
   , buffer_gets
   , (select max('FULL') scan from dba_hist_sql_plan sp 
      where sp.sql_id = sub.sql_id and sp.operation like '%TABLE%'
        and sp.options in ('FULL', 'ALL')) as scan
   , (select max(DBMS_LOB.SUBSTR(sql_text,4000)) from dba_hist_sqltext st where st.sql_id = sub.sql_id) sql_text
--   , (select sql_text from dba_hist_sqltext st where st.sql_id = sub.sql_id and rownum=1) sql_text
   , min_time
   , max_time
   , min_snap_id
   , max_snap_id
from
   ( -- sub to sort before rownum
     select
        sql_id
        , plan_hash_value
        , round(sum(elapsed_time_delta)/1000000) as elapsed_sec
        , round(sum(cpu_time_delta)    /1000000) as cpu_sec 
        , round(sum(plsexec_time_delta)/1000000) as plsql_sec 
        , sum(executions_delta) as executions
        , sum(buffer_gets_delta) as buffer_gets
        , max(parsing_schema_name) as schema
        , max(BEGIN_INTERVAL_TIME) max_time
        , min(BEGIN_INTERVAL_TIME) min_time
        , min(snap_id) min_snap_id
        , max(snap_id) max_snap_id
     from
        dba_hist_snapshot natural join dba_hist_sqlstat
     where 1=1
          and snap_id between nvl(:start_snap_id, snap_id) and nvl(:end_snap_id, snap_id) 
     group by
        sql_id, plan_hash_value
     order by elapsed_sec desc
--        buffer_gets desc
--        executions desc
--        schema, 

   ) sub
where 1=1
  and schema like ('%'|| upper(:username) || '%' )
--  and rownum <= 200
)
-- use this if you want to look at a single SQL_ID
--where sql_id = nvl(:sql_id, sql_id)

-- use this order by to get a "profile"
--order by min_time, min_ash_time, elapsed_sec desc
;

-- ASH time version -- can be slow
-- gets most expensive queries for a snap_id range [from  DBA_HIST_SQLSTAT ] ; highest elapsed time first 
-- Usage notes:
-- leave snap_id range null for all snap_id's
-- edit the final order by to get a "profile"
--, may need to be commented out
select schema  
   , plan_hash_value
   , sql_id
   , clock_time
   , to_char(trunc(sysdate)+(cast(max_ash_time as date) - cast(min_ash_time as date)),'HH24:MI:SS')  as ash_duration
   , case when executions <> 0
     then CASE 
     WHEN round(elapsed_sec/executions) > 86399
          THEN round(elapsed_sec/executions) || ' sec' 
     WHEN round(elapsed_sec/executions) <= 86399
          THEN to_char(to_date(round(elapsed_sec/executions) ,'SSSSS'), 'HH24:MI:SS') 
     END 
     end as time_per_exec
--   , cpu_sec
   , plsql_sec
   , executions
   , case when executions <> 0 then round(elapsed_sec/executions, 2) end sec_per_exec
   , buffer_gets
   , scan
   , sql_text
   , to_char(min_time, 'mm/dd/yyyy HH24:MI:SS') min_time
   , nvl(to_char(min_ash_time, 'mm/dd/yyyy HH24:MI:SS'), '.') min_ash_time
   , nvl(to_char(max_ash_time, 'mm/dd/yyyy HH24:MI:SS'), '.') max_ash_time
   , to_char(max_time ,'mm/dd/yyyy HH24:MI:SS') max_time
   , min_snap_id
   , max_snap_id
from
(
select schema  
   , plan_hash_value
   , sql_id
   , sub.elapsed_sec
   , CASE 
     WHEN elapsed_sec > 86399
          THEN elapsed_sec || ' sec' 
     WHEN elapsed_sec <= 86399
          THEN to_char(to_date(round(elapsed_sec) ,'SSSSS'), 'HH24:MI:SS') 
     END as clock_time
   , cpu_sec
   , plsql_sec
   , executions
   , buffer_gets
   , (select max('FULL SCAN') scan from dba_hist_sql_plan sp 
      where sp.sql_id = sub.sql_id and sp.operation like '%TABLE%'
        and sp.options in ('FULL', 'ALL')) as scan
   , (select max(DBMS_LOB.SUBSTR(sql_text,4000)) from dba_hist_sqltext st where st.sql_id = sub.sql_id) sql_text
--   , (select sql_text from dba_hist_sqltext st where st.sql_id = sub.sql_id and rownum=1) sql_text
   , min_time
   , max_time
   , (select min(SAMPLE_TIME) from DBA_HIST_ACTIVE_SESS_HISTORY ash
      where ash.sql_id = sub.sql_id 
        and ash.snap_id between :start_snap_id and :end_snap_id) MIN_ASH_TIME
   , (select max(SAMPLE_TIME) from DBA_HIST_ACTIVE_SESS_HISTORY ash 
      where ash.sql_id = sub.sql_id 
        and ash.snap_id between :start_snap_id and :end_snap_id) MAX_ASH_TIME
   , min_snap_id
   , max_snap_id
from
   ( -- sub to sort before rownum
     select
        sql_id
        , plan_hash_value
        , round(sum(elapsed_time_delta)/1000000) as elapsed_sec
        , round(sum(cpu_time_delta)    /1000000) as cpu_sec 
        , round(sum(plsexec_time_delta)/1000000) as plsql_sec 
        , sum(executions_delta) as executions
        , sum(buffer_gets_delta) as buffer_gets
        , max(parsing_schema_name) as schema
        , max(BEGIN_INTERVAL_TIME) max_time
        , min(BEGIN_INTERVAL_TIME) min_time
        , min(snap_id) min_snap_id
        , max(snap_id) max_snap_id
     from
        dba_hist_snapshot natural join dba_hist_sqlstat
     where 1=1
          and snap_id between :start_snap_id and :end_snap_id 
     group by
        sql_id, plan_hash_value
     order by elapsed_sec desc
--        buffer_gets desc
--        executions desc
--        schema, 
   ) sub
where 1=1
  and schema like ('%'|| upper(:username) || '%' )
--  and rownum <= 200
)
-- use this order by to get a "profile"
--order by min_time, min_ash_time, elapsed_sec desc
;


-- version used when I'm tracking particular SQL_id's:
-- ---------------------------------------------------
/*
with sql_list as
(
-- example SQL_IDs for USPRD775 evaluation
select '73gynpdhqu0wa' sql_id,     1     ord from dual union
select 'c05tgudta6v2z' sql_id,     2     ord from dual union
select 'bn0nvnufhdwap' sql_id,     3     ord from dual union
select '9hj0qjt65rvwc' sql_id,     4     ord from dual union
select 'adfc7088tfgt0' sql_id,     5     ord from dual union
select '40r7pxcv8rkk9' sql_id,     6     ord from dual union
select '8w35as1cr3du8' sql_id,     7     ord from dual union
select 'bmbfwzu0b6p5a' sql_id,     8     ord from dual union
select '6b7kc4abt8g78' sql_id,     9     ord from dual union
select '5yrrmc0hqvsma' sql_id,     10     ord from dual
)
*/
with sql_list as
-- example SQL_ID's for USPRD492 evaluation
(
select '5v3bc0ag9zpcc' sql_id, 01 ord from dual union
select '7t1zm6zty0fkb' sql_id, 02 ord from dual union
select '9hhpv97yv36fb' sql_id, 03 ord from dual union
select '7k8wkwszbqamf' sql_id, 04 ord from dual union
select 'f75ja8qds1r1h' sql_id, 05 ord from dual union
select '7x4yvmryc6msk' sql_id, 06 ord from dual union
select '0cq642y8pjcza' sql_id, 07 ord from dual union
select 'f4p7cawrx2881' sql_id, 08 ord from dual union
select 'bhsg4hmqkd0vj' sql_id, 09 ord from dual union
select '2hqpm6st51vsd' sql_id, 10 ord from dual union
select '6p3v9u93vawt8' sql_id, 11 ord from dual union
select '1qcb71648vvwc' sql_id, 12 ord from dual union
select '3ac1fz39n2ku5' sql_id, 13 ord from dual union
select '17rh2y23b9z1v' sql_id, 14 ord from dual union
select '3hftfn07bk1zm' sql_id, 15 ord from dual union
select 'gyvphvdgsmdm5' sql_id, 16 ord from dual union
select '8mu4dtm8u6021' sql_id, 17 ord from dual union
select '4aga4pzcp5vcb' sql_id, 18 ord from dual union
select '9m2cuqv22zhx1' sql_id, 19 ord from dual union
select 'afb07kjumqgcn' sql_id, 20 ord from dual union
select '06x17rvdc8jqg' sql_id, 21 ord from dual union
select '484r1gdxc85du' sql_id, 22 ord from dual union
select '4h0n7jna8w1fc' sql_id, 23 ord from dual union
select '6p3v9u93vawt8' sql_id, 24 ord from dual 
) 
select schema  
   , plan_hash_value
   , ord
   , sql_list.sql_id
   , nvl(clock_time,'no data') clock_time
   , time_per_exec
   , to_char(trunc(sysdate)+(cast(max_ash_time as date) - cast(min_ash_time as date)),'HH24:MI:SS')  as ash_duration
--   , cpu_sec
   , plsql_sec
   , executions
   , buffer_gets
   , scan
   , sql_text
   , to_char(min_time, 'mm/dd/yyyy HH24:MI:SS') min_time
   , nvl(to_char(min_ash_time, 'mm/dd/yyyy HH24:MI:SS'), '.') min_ash_time
   , nvl(to_char(max_ash_time, 'mm/dd/yyyy HH24:MI:SS'), '.') max_ash_time
   , to_char(max_time ,'mm/dd/yyyy HH24:MI:SS') max_time
from
(
select schema  
   , plan_hash_value
   , sql_id
   , sub.elapsed_sec
   , CASE 
     WHEN elapsed_sec > 86399
          THEN elapsed_sec || ' sec' 
     WHEN elapsed_sec <= 86399
          THEN to_char(to_date(round(elapsed_sec) ,'SSSSS'), 'HH24:MI:SS') 
     END as clock_time
      , case when executions <> 0
     then CASE 
     WHEN round(elapsed_sec/executions) > 86399
          THEN round(elapsed_sec/executions) || ' sec' 
     WHEN round(elapsed_sec/executions) <= 86399
          THEN to_char(to_date(round(elapsed_sec/executions) ,'SSSSS'), 'HH24:MI:SS') 
     END 
     end as time_per_exec
   , cpu_sec
   , plsql_sec
   , executions
   , buffer_gets
   , (select max('FULL SCAN') scan from dba_hist_sql_plan sp 
      where sp.sql_id = sub.sql_id and sp.operation like '%TABLE%'
        and sp.options in ('FULL', 'ALL')) as scan
   , (select max(DBMS_LOB.SUBSTR(sql_text,4000)) from dba_hist_sqltext st
       where st.sql_id = sub.sql_id) sql_text
   , min_time
   , max_time
   , (select min(SAMPLE_TIME) from DBA_HIST_ACTIVE_SESS_HISTORY ash
      where ash.sql_id = sub.sql_id 
        and ash.snap_id between :start_snap_id and :end_snap_id) MIN_ASH_TIME
   , (select max(SAMPLE_TIME) from DBA_HIST_ACTIVE_SESS_HISTORY ash 
      where ash.sql_id = sub.sql_id 
        and ash.snap_id between :start_snap_id and :end_snap_id) MAX_ASH_TIME
from
   ( -- sub to sort before rownum
     select
        sql_id
        , plan_hash_value
        , round(sum(elapsed_time_delta)/1000000) as elapsed_sec
        , round(sum(cpu_time_delta)    /1000000) as cpu_sec 
        , round(sum(plsexec_time_delta)/1000000) as plsql_sec 
        , sum(executions_delta) as executions
        , sum(buffer_gets_delta) as buffer_gets
        , max(parsing_schema_name) as schema
        , max(BEGIN_INTERVAL_TIME) max_time
        , min(BEGIN_INTERVAL_TIME) min_time
     from
        dba_hist_snapshot natural join dba_hist_sqlstat
     where 1=1
          and snap_id between :start_snap_id and :end_snap_id 
     group by
        sql_id, plan_hash_value
     order by elapsed_sec desc
--        buffer_gets desc
--        executions desc
--        schema, 

   ) sub
where 1=1
  and schema like ('%'|| upper(:username) || '%' )
--  and rownum <= 200
) full_query
, sql_list
where full_query.sql_id (+) = sql_list.sql_id
order by ord
-- use this order by to get a "profile"
--order by min_time, min_ash_time, elapsed_sec desc
;
