/* all plans that use an object */
select * from 
(
select sql_id, 0 step_id, 
    -1 depth, 
    DBMS_LOB.SUBSTR(sql_text,4000) plan_step,
    null access_predicates,
    null cost,
    null cardinality,
    null bytes,
    null io_cost,
    null cpu_cost
from DBA_HIST_SQLTEXT sa
where 1=1
and sa.sql_id in 
(select sql_id from DBA_HIST_SQL_PLAN where object_name = upper(:object_name))
union
select distinct sp.sql_id,
    sp.id step_id,
    sp.depth, 
    lpad('-', sp.depth,'-') || sp.operation || ' ' || sp.options || ' ' || object_name plan_step,
    sp.access_predicates,
    sp.cost,
    sp.cardinality,
    sp.bytes,
    sp.io_cost,
    sp.cpu_cost
from DBA_HIST_SQL_PLAN sp
where 1=1
and sp.sql_id in 
(select sql_id from DBA_HIST_SQL_PLAN where object_name = upper(:object_name))
)
order by  sql_id, step_id, depth
;

select plan_step from 
(
select sql_id, 0 step_id, 
    -1 depth, 
    DBMS_LOB.SUBSTR(sql_text,4000) plan_step,
    null access_predicates,
    null cost,
    null cardinality,
    null bytes,
    null io_cost,
    null cpu_cost
from DBA_HIST_SQLTEXT sa
where 1=1
and sa.sql_id in 
(select sql_id from DBA_HIST_SQL_PLAN where object_name = upper(:object_name))
union
select distinct sp.sql_id,
    sp.id step_id,
    sp.depth, 
    lpad('-', sp.depth,'-') || sp.operation || ' ' || sp.options || ' ' || object_name plan_step,
    sp.access_predicates,
    sp.cost,
    sp.cardinality,
    sp.bytes,
    sp.io_cost,
    sp.cpu_cost
from DBA_HIST_SQL_PLAN sp
where 1=1
and sp.sql_id in 
(select sql_id from DBA_HIST_SQL_PLAN where object_name = upper(:object_name))
)
order by  sql_id, step_id, depth
;

-- for a snap_id range:
-- object BPLDATA
-- just the sql and id's
select stext.sql_id
, DBMS_LOB.SUBSTR(sql_text,4000) sql_text
, min(SNAP_ID) , max(snap_id) 
, max(SQL_PROFILE) SQL_PROFILE
, min(PARSING_SCHEMA_NAME) PARSING_SCHEMA_NAME
--, max(PARSING_SCHEMA_NAME)
, max(FETCHES_TOTAL) FETCHES
, max(SORTS_TOTAL) SORTS
, max(EXECUTIONS_TOTAL) EXECUTIONS 
, max(PX_SERVERS_EXECS_TOTAL) PX_SERVERS_EXECS
, max(LOADS_TOTAL) LOADS
, max(INVALIDATIONS_TOTAL) INVALIDATIONS
, max(PARSE_CALLS_TOTAL) PARSE_CALLS
, max(DISK_READS_TOTAL) DISK_READS
, max(BUFFER_GETS_TOTAL) BUFFER_GETS
, max(ROWS_PROCESSED_TOTAL) ROWS_PROCESSED
, max(CPU_TIME_TOTAL) CPU_TIME
, max(ELAPSED_TIME_TOTAL) ELAPSED_TIME
, max(IOWAIT_TOTAL) IOWAIT
, max(CLWAIT_TOTAL) CLWAIT
, max(APWAIT_TOTAL) APWAIT
, max(CCWAIT_TOTAL) CCWAIT
, max(DIRECT_WRITES_TOTAL) DIRECT_WRITES
, max(PLSEXEC_TIME_TOTAL) PLSEXEC_TIME
, max(JAVEXEC_TIME_TOTAL) JAVEXEC_TIME
from DBA_HIST_SQLTEXT stext
, dba_hist_sqlstat sstat
where 1=1
and stext.sql_id in 
(select sql_id from DBA_HIST_SQL_PLAN where object_name = upper(:object_name))
and stext.sql_id = sstat.sql_id (+)
group by stext.sql_id, DBMS_LOB.SUBSTR(sql_text,4000)
having min(SNAP_ID) >= nvl(:start_snap_id, min(SNAP_ID))
   and max(snap_id) <= nvl(:end_snap_id,   max(SNAP_ID)) 
order by  3
;



select sql_id, step_id, depth, plan_step, access_predicates
, cost, cardinality, bytes, io_cost, cpu_cost
from
(
select * from 
(
select distinct sp.sql_id,
    null step_id,
    null depth, 
    'SQL CODE:' plan_step,
    -1 num,
    null access_predicates,
    null cost,
    null cardinality,
    null bytes,
    null io_cost,
    null cpu_cost
from DBA_HIST_SQL_PLAN sp
where 1=1
and sp.sql_id in 
(select sql_id from DBA_HIST_SQL_PLAN where object_name = upper(:object_name))
union
select sql_id, piece step_id, 
    null depth, 
    sql_text plan_step,
    1 num,
    null access_predicates,
    null cost,
    null cardinality,
    null bytes,
    null io_cost,
    null cpu_cost
from gv$sqltext_with_newlines
where 1=1
and sql_id in 
(select sql_id from DBA_HIST_SQL_PLAN where object_name = upper(:object_name))
union
select sql_id, -1 step_id, 
    null depth, 
    to_char(sql_text) plan_step,
    1 num,
    null access_predicates,
    null cost,
    null cardinality,
    null bytes,
    null io_cost,
    null cpu_cost
from DBA_HIST_SQLTEXT
where 1=1
and sql_id in 
(select sql_id from DBA_HIST_SQL_PLAN where object_name = upper(:object_name))
union
select distinct sp.sql_id,
    null step_id,
    null depth, 
    'EXECUTION PLAN:' plan_step,
    1.5 num,
    null access_predicates,
    null cost,
    null cardinality,
    null bytes,
    null io_cost,
    null cpu_cost
from DBA_HIST_SQL_PLAN sp
where 1=1
and sp.sql_id in 
(select sql_id from DBA_HIST_SQL_PLAN where object_name = upper(:object_name))
union
select distinct sp.sql_id,
    sp.id step_id,
    sp.depth, 
    lpad('-', sp.depth,'-') || sp.operation || ' ' || sp.options || ' ' || object_name plan_step,
    2 num,
    sp.access_predicates,
    sp.cost,
    sp.cardinality,
    sp.bytes,
    sp.io_cost,
    sp.cpu_cost
from DBA_HIST_SQL_PLAN sp
where 1=1
and sp.sql_id in 
(select sql_id from DBA_HIST_SQL_PLAN where object_name = upper(:object_name))
)
order by  sql_id, num, step_id, depth
)
;
