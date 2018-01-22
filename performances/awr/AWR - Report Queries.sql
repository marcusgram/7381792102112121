-- AWR - Report Queries.sql
-- -----------------------------
-- 05-JUN-2013 RDCornejo
-- 17-Oct-2013 Edited by RDCornejo

-- accumulating queries that can provide data similar to the AWR reports
-- -----------------------------------------------------------------------
-- Current Instance
select d.dbid            dbid
     , d.name            db_name
     , i.instance_number inst_num
     , i.instance_name   inst_name
from v$database d,
     v$instance i
;


-- heading section:
-- works for 11g and 10g General information about the instance
select name "DB Name"
, dbid "DB Id"
, instance_name "Instance"
, instance_number "Inst num"
, to_char(startup_time, 'DD-Mon-YYYY HH24:MI') "Startup Time"
, version "Release"
, decode((select count(*) node_count from gv$active_instances), 0, 'NO', 'YES') "RAC"
from v$database,  v$instance 
;

-- 11g General information about the machine/operating system
select host_name "Host Name"
, platform_name "Platform"
, (select value from v$osstat where stat_name = 'NUM_CPUS') "CPUs"
, (select value from v$osstat where stat_name = 'NUM_CPU_CORES') "Cores"
, (select value from v$osstat where stat_name = 'NUM_CPU_SOCKETS') "Sockets"
, (select round((value/(1024*1024*1024)), 2) from v$osstat where stat_name = 'PHYSICAL_MEMORY_BYTES') "Memory (GB)"
 from dba_hist_database_instance
where 1=1
and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
;

-- 10g General information about the machine/operating system
select host_name "Host Name"
--, platform_name "Platform"
, (select value from v$osstat where stat_name = 'NUM_CPUS') "CPUs"
, (select value from v$osstat where stat_name = 'NUM_CPU_CORES') "Cores"
, (select value from v$osstat where stat_name = 'NUM_CPU_SOCKETS') "Sockets"
, (select round((value/(1024*1024*1024)), 2) from v$osstat where stat_name = 'PHYSICAL_MEMORY_BYTES') "Memory (GB)"
 from dba_hist_database_instance
where 1=1
and (dbid, instance_number, startup_time)  = (select dbid, instance_number, startup_time from v$database, v$instance)
;

-- what snapshots have AWR data from DBA_HIST_SNAPSHOT:
-- snapshots are taken at end_interval_time
SELECT instance_number, snap_id
, to_char(begin_interval_time,'DD-MON-YYYY HH24:MI') Begin_Interval_time
, to_char(end_interval_time,  'DD-MON-YYYY HH24:MI') End_Interval_time
FROM dba_hist_snapshot
where 1=1
and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
ORDER BY 2 desc, 1
;

-- the snapshot periods
-- ------------------------------------------------------
select 'Begin Snap:' col1
, snap_id
, to_char(begin_interval_time,'DD-MON-YYYY HH24:MI:SS') Snap_Time
, (
select round(average)
from dba_hist_sysmetric_summary
where metric_name = 'Session Count'
and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
and snap_id = :start_snap_id  
) Sessions
, (
select round(max(decode(metric_name,'Current Open Cursors Count', average, null))   /
  max(decode(metric_name,'Session Count', average, null)), 1) cusrors_per_session
from dba_hist_sysmetric_summary
where metric_name in ('Session Count', 'Current Open Cursors Count')
and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
and snap_id = :start_snap_id  
) cursors_per_session
from dba_hist_snapshot 
where snap_id = :start_snap_id 
and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
union
select 'End Snap:' col1
, snap_id
, to_char(begin_interval_time,'DD-MON-YYYY HH24:MI:SS') Snap_Time
, (
select round(average)
from dba_hist_sysmetric_summary
where metric_name = 'Session Count'
and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
and snap_id = :end_snap_id  
) Sessions
, (
select round(max(decode(metric_name,'Current Open Cursors Count', average, null))   /
  max(decode(metric_name,'Session Count', average, null)), 1) cusrors_per_session
from dba_hist_sysmetric_summary
where metric_name in ('Session Count', 'Current Open Cursors Count')
and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
and snap_id = :end_snap_id  
) cursors_per_session
from dba_hist_snapshot 
where snap_id = :end_snap_id 
and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
union
select 'Elapsed:' col1
, null snap_id
, round(( max(cast(begin_interval_time as date)) - min(cast(begin_interval_time as date)))*24*60, 2) ||' (mins)' Snap_Time
, null Sessions
, null cursors_per_session
from dba_hist_snapshot 
where snap_id between :start_snap_id  and :end_snap_id 
and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
union
select 'DB Time:' col1
, null snap_id
, round((max(value) - min(value)) / (100 * 60), 2) || ' (mins)' Snap_Time
, null Sessions
, null cursors_per_session
from dba_hist_sysstat
where 1=1 
and stat_name  = 'DB time'
and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
and snap_id between :start_snap_id  and :end_snap_id 
order by 2, 1 desc
;



-- Load Profile: query similar data to load profile section of AWR Report
with load_profile as
(
select 'Database Time Per Sec'                      metric_name, 'DB Time' short_name, .01 coeff, 1 typ, 1 m_rank from dual union all
select 'CPU Usage Per Sec'                          metric_name, 'DB CPU' short_name, .01 coeff, 1 typ, 2 m_rank from dual union all
select 'Redo Generated Per Sec'                     metric_name, 'Redo size' short_name, 1 coeff, 1 typ, 3 m_rank from dual union all
select 'Logical Reads Per Sec'                      metric_name, 'Logical reads' short_name, 1 coeff, 1 typ, 4 m_rank from dual union all
select 'DB Block Changes Per Sec'                   metric_name, 'Block changes' short_name, 1 coeff, 1 typ, 5 m_rank from dual union all
select 'Physical Reads Per Sec'                     metric_name, 'Physical reads' short_name, 1 coeff, 1 typ, 6 m_rank from dual union all
select 'Physical Writes Per Sec'                    metric_name, 'Physical writes' short_name, 1 coeff, 1 typ, 7 m_rank from dual union all
select 'User Calls Per Sec'                         metric_name, 'User calls' short_name, 1 coeff, 1 typ, 8 m_rank from dual union all
select 'Total Parse Count Per Sec'                  metric_name, 'Parses' short_name, 1 coeff, 1 typ, 9 m_rank from dual union all
select 'Hard Parse Count Per Sec'                   metric_name, 'Hard Parses' short_name, 1 coeff, 1 typ, 10 m_rank from dual union all
select 'Logons Per Sec'                             metric_name, 'Logons' short_name, 1 coeff, 1 typ, 11 m_rank from dual union all
select 'Executions Per Sec'                         metric_name, 'Executes' short_name, 1 coeff, 1 typ, 12 m_rank from dual union all
select 'User Rollbacks Per Sec'                     metric_name, 'Rollbacks' short_name, 1 coeff, 1 typ, 13 m_rank from dual union all
select 'User Transaction Per Sec'                   metric_name, 'Transactions' short_name, 1 coeff, 1 typ, 14 m_rank from dual union all
select 'User Rollback UndoRec Applied Per Sec'      metric_name, 'Applied urec' short_name, 1 coeff, 1 typ, 15 m_rank from dual union all
select 'Redo Generated Per Txn'                     metric_name, 'Redo size' short_name, 1 coeff, 2 typ, 3 m_rank from dual union all
select 'Logical Reads Per Txn'                      metric_name, 'Logical reads' short_name, 1 coeff, 2 typ, 4 m_rank from dual union all
select 'DB Block Changes Per Txn'                   metric_name, 'Block changes' short_name, 1 coeff, 2 typ, 5 m_rank from dual union all
select 'Physical Reads Per Txn'                     metric_name, 'Physical reads' short_name, 1 coeff, 2 typ, 6 m_rank from dual union all
select 'Physical Writes Per Txn'                    metric_name, 'Physical writes' short_name, 1 coeff, 2 typ, 7 m_rank from dual union all
select 'User Calls Per Txn'                         metric_name, 'User calls' short_name, 1 coeff, 2 typ, 8 m_rank from dual union all
select 'Total Parse Count Per Txn'                  metric_name, 'Parses' short_name, 1 coeff, 2 typ, 9 m_rank from dual union all
select 'Hard Parse Count Per Txn'                   metric_name, 'Hard Parses' short_name, 1 coeff, 2 typ, 10 m_rank from dual union all
select 'Logons Per Txn'                             metric_name, 'Logons' short_name, 1 coeff, 2 typ, 11 m_rank from dual union all
select 'Executions Per Txn'                         metric_name, 'Executes' short_name, 1 coeff, 2 typ, 12 m_rank from dual union all
select 'User Rollbacks Per Txn'                     metric_name, 'Rollbacks' short_name, 1 coeff, 2 typ, 13 m_rank from dual union all
select 'User Transaction Per Txn'                   metric_name, 'Transactions' short_name, 1 coeff, 2 typ, 14 m_rank from dual union all
select 'User Rollback Undo Records Applied Per Txn' metric_name, 'Applied urec' short_name, 1 coeff, 2 typ, 15 m_rank from dual
) 
, load_table as
(
select short_name
, max(case when typ = 1 then metric_name else null end) as per_Second
, max(case when typ = 2 then metric_name else null end) as per_Transaction
, max(coeff) coeff
, max(m_rank) m_rank
from load_profile
group by short_name
)
select short_name
, 
( select round(avg(average), coeff) 
from dba_hist_sysmetric_summary m    
where 1=1 
  and m.metric_name = per_Second 
  and (dbid, instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and snap_id between :start_snap_id and :end_snap_id
)
as per_Second
, 
( select round(avg(average), coeff) 
from dba_hist_sysmetric_summary m    
where 1=1 
  and m.metric_name = per_transaction 
  and (dbid, instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and snap_id between :start_snap_id and :end_snap_id
)
as per_transaction 
from load_table
order by m_rank
;

-- track the Per Sec Load Profile metric over time:
-- ------------------------------------------------
with metrics as
(
select snap_id, dbid, instance_number
, sum(case metric_name when 'Database Time Per Sec' then round(average) end) DB_Time_per_sec
, sum(case metric_name when 'CPU Usage Per Sec' then round(average) end) DB_CPU_per_sec
, sum(case metric_name when 'Redo Generated Per Sec' then round(average) end) Redo_size_per_sec
, sum(case metric_name when 'Logical Reads Per Sec' then round(average) end) Logical_reads_per_sec
, sum(case metric_name when 'DB Block Changes Per Sec' then round(average) end) Block_changes_per_sec
, sum(case metric_name when 'Physical Reads Per Sec' then round(average) end) Physical_reads_per_sec
, sum(case metric_name when 'Physical Writes Per Sec' then round(average) end) Physical_writes_per_sec
, sum(case metric_name when 'User Calls Per Sec' then round(average) end) User_calls_per_sec
, sum(case metric_name when 'Total Parse Count Per Sec' then round(average) end) Parses_per_sec
, sum(case metric_name when 'Hard Parse Count Per Sec' then round(average) end) Hard_Parses_per_sec
, sum(case metric_name when 'Logons Per Sec' then round(average) end) Logons_per_sec
, sum(case metric_name when 'Executions Per Sec' then round(average) end) Executes_per_sec
, sum(case metric_name when 'User Rollbacks Per Sec' then round(average) end) Rollbacks_per_sec
, sum(case metric_name when 'User Transaction Per Sec' then round(average) end) Transactions_per_sec
, sum(case metric_name when 'User Rollback UndoRec Applied Per Sec' then round(average) end) Applied_urec_per_sec
from dba_hist_sysmetric_summary
group by snap_id, dbid, instance_number
order by snap_id
)
, snaps as
(
select snap_id, dbid, instance_number, begin_interval_time, end_interval_time
from dba_hist_snapshot
where 1=1
  and (dbid, instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and snap_id between nvl(:start_snap_id, snap_id) and nvl(:end_snap_id, snap_id) 
  and (to_number(to_char(begin_interval_time, 'HH24')) between nvl(:begin_hour, 0) and  nvl(:end_hour, 24) 
    or to_number(to_char(begin_interval_time, 'HH24')) between nvl(:begin_hour2, 0) and  nvl(:end_hour2, 24))
)
select snaps.snap_id
, to_char(snaps.begin_interval_time,'YYYY-MM-DD HH24:MI') as begin_hour
, to_char(snaps.end_interval_time,'YYYY-MM-DD HH24:MI') as end_hour
,db_time_per_sec ,db_cpu_per_sec ,redo_size_per_sec ,logical_reads_per_sec ,block_changes_per_sec 
,physical_reads_per_sec ,physical_writes_per_sec ,user_calls_per_sec ,parses_per_sec ,hard_parses_per_sec
,logons_per_sec ,executes_per_sec ,rollbacks_per_sec ,transactions_per_sec ,applied_urec_per_sec
from metrics, snaps
where 1=1
--  and rownum = 1
  and metrics.snap_id = snaps.snap_id
  and metrics.dbid = snaps.dbid 
  and metrics.instance_number = snaps.instance_number 
;

-- track the Per Txn Load Profile metric over time:
-- ------------------------------------------------
with metrics as
(
select snap_id, dbid, instance_number
, sum(case metric_name when 'Redo Generated Per Txn' then round(average) end) Redo_size_per_Txn
, sum(case metric_name when 'Logical Reads Per Txn' then round(average) end) Logical_reads_per_Txn
, sum(case metric_name when 'DB Block Changes Per Txn' then round(average) end) Block_changes_per_Txn
, sum(case metric_name when 'Physical Reads Per Txn' then round(average) end) Physical_reads_per_Txn
, sum(case metric_name when 'Physical Writes Per Txn' then round(average) end) Physical_writes_per_Txn
, sum(case metric_name when 'User Calls Per Txn' then round(average) end) User_calls_per_Txn
, sum(case metric_name when 'Total Parse Count Per Txn' then round(average) end) Parses_per_Txn
, sum(case metric_name when 'Hard Parse Count Per Txn' then round(average) end) Hard_Parses_per_Txn
, sum(case metric_name when 'Logons Per Txn' then round(average) end) Logons_per_Txn
, sum(case metric_name when 'Executions Per Txn' then round(average) end) Executes_per_Txn
, sum(case metric_name when 'User Rollbacks Per Txn' then round(average) end) Rollbacks_per_Txn
, sum(case metric_name when 'User Transaction Per Txn' then round(average) end) Transactions_per_Txn
, sum(case metric_name when 'User Rollback Undo Records Applied Per Txn' then round(average) end) Applied_urec_per_Txn
from dba_hist_sysmetric_summary
group by snap_id, dbid, instance_number
order by snap_id
)
, snaps as
(
select snap_id, dbid, instance_number, begin_interval_time, end_interval_time
from dba_hist_snapshot
where 1=1
  and (dbid, instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and snap_id between nvl(:start_snap_id, snap_id) and nvl(:end_snap_id, snap_id) 
  and (to_number(to_char(begin_interval_time, 'HH24')) between nvl(:begin_hour, 0) and  nvl(:end_hour, 24) 
    or to_number(to_char(begin_interval_time, 'HH24')) between nvl(:begin_hour2, 0) and  nvl(:end_hour2, 24))
)
select snaps.snap_id
, to_char(snaps.begin_interval_time,'YYYY-MM-DD HH24:MI') as begin_hour
, to_char(snaps.end_interval_time,'YYYY-MM-DD HH24:MI') as end_hour
,redo_size_per_txn,logical_reads_per_txn,block_changes_per_txn,physical_reads_per_txn
,physical_writes_per_txn,user_calls_per_txn,parses_per_txn,hard_parses_per_txn
,logons_per_txn,executes_per_txn,rollbacks_per_txn,transactions_per_txn,applied_urec_per_txn
from metrics, snaps
where 1=1
--  and rownum = 1
  and metrics.snap_id = snaps.snap_id
  and metrics.dbid = snaps.dbid 
  and metrics.instance_number = snaps.instance_number 
;

-- Operating System Statistics
select * from dba_hist_osstat
where 1=1
  and snap_id between nvl(:start_snap_id, snap_id) and nvl(:end_snap_id, snap_id) 
  and stat_name = :STAT_NAME
order by snap_id, stat_id
;

with db as (select d.dbid, i.instance_number from v$database d, v$instance i)
, bstat as
(
select * from dba_hist_osstat
where 1=1
  and (dbid, instance_number) = (select dbid, instance_number from db)
  and snap_id = :start_snap_id
  and stat_name = :STAT_NAME
)
, estat as
(
select * from dba_hist_osstat
where 1=1
  and (dbid, instance_number) = (select dbid, instance_number from db)
  and snap_id = :end_snap_id
  and stat_name = :STAT_NAME
)
select bstat.stat_name, estat.value - bstat.value total
from bstat, estat
where 1=1
  and bstat.stat_name = estat.stat_name
order by bstat.stat_name
;


-- O.S. Statistics: http://dbastreet.com/blog/?p=849
select
to_char(begintime,'DD-MON-YY HH24:MI:SS') begintime,
to_char(endtime,'DD-MON-YY HH24:MI:SS') endtime,
inst,
snapid,
round((utdiff/(utdiff+itdiff+stdiff+iowtdiff+ntdiff))*100)  USER_TIME_pct,
round((ntdiff/(utdiff+itdiff+stdiff+iowtdiff+ntdiff))*100)  NICE_TIME_pct,
round((stdiff/(utdiff+itdiff+stdiff+iowtdiff+ntdiff))*100)  SYS_TIME_pct,
round((iowtdiff/(utdiff+itdiff+stdiff+iowtdiff+ntdiff))*100)  IOWAIT_TIME_pct,
(100-
(
 round((utdiff/(utdiff+itdiff+stdiff+iowtdiff+ntdiff))*100)+
 round((ntdiff/(utdiff+itdiff+stdiff+iowtdiff+ntdiff))*100)+
 round((stdiff/(utdiff+itdiff+stdiff+iowtdiff+ntdiff))*100)+
 round((iowtdiff/(utdiff+itdiff+stdiff+iowtdiff+ntdiff))*100)
)) IDLE_TIME_pct
from
(
select begintime,endtime,(extract(Minute from endtime-begintime)*60+extract(Second from endtime-begintime)) secs,
snapid,inst,
ut-(nvl(lag(ut) over (partition by inst order by inst,snapid),0)) utdiff,
bt-(nvl(lag(bt) over (partition by inst order by inst,snapid),0)) btdiff,
it-(nvl(lag(it) over (partition by inst order by inst,snapid),0)) itdiff,
st-(nvl(lag(st) over (partition by inst order by inst,snapid),0)) stdiff,
iowt-(nvl(lag(iowt) over (partition by inst order by inst,snapid),0)) iowtdiff,
nt-(nvl(lag(nt) over (partition by inst order by inst,snapid),0)) ntdiff,
vin-(nvl(lag(vin) over (partition by inst order by inst,snapid),0)) vindiff,
vout-(nvl(lag(vout) over (partition by inst order by inst,snapid),0)) voutdiff
from
(
select sn.begin_interval_time begintime,
     sn.end_interval_time EndTime,oss.snap_id SnapId,oss.instance_number Inst,
     sum(decode(oss.stat_name,'USER_TIME',value,0)) ut,
     sum(decode(oss.stat_name,'BUSY_TIME',value,0)) bt,
     sum(decode(oss.stat_name,'IDLE_TIME',value,0)) it,
     sum(decode(oss.stat_name,'SYS_TIME',value,0)) st,
     sum(decode(oss.stat_name,'IOWAIT_TIME',value,0)) iowt,
     sum(decode(oss.stat_name,'NICE_TIME',value,0)) nt,
     sum(decode(oss.stat_name,'VM_IN_BYTES',value,0)) vin,
     sum(decode(oss.stat_name,'VM_OUT_BYTES',value,0)) vout
from dba_hist_osstat oss, dba_hist_snapshot sn
where 1=1
  and (oss.dbid, oss.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and oss.snap_id between :start_snap_id - 1 and :end_snap_id
and   oss.dbid = sn.dbid
and   oss.instance_number =  sn.instance_number
and   oss.snap_id = sn.snap_id
and   oss.stat_name in (
'USER_TIME',
'BUSY_TIME',
'IDLE_TIME',
'SYS_TIME',
'IOWAIT_TIME',
'NICE_TIME',
'VM_IN_BYTES',
'VM_OUT_BYTES'
)
group by sn.begin_interval_time,sn.end_interval_time,oss.snap_id,oss.instance_number
order by oss.instance_number,oss.snap_id
)
)
where snapid between :start_snap_id and :end_snap_id
order by inst,snapid
;



-- Elapsed Time/DB Time/Concurrent Active Users http://dbastreet.com/blog/?p=849
select
to_char(begintime,'DD-MON-YY HH24:MI:SS') begintime,
to_char(endtime,'DD-MON-YY HH24:MI:SS') endtime,
inst,
snapid,
round(dbtdiff/(1000000*60),2) dbt,
round(secs/60) mins
, decode(round(secs/60),0,null, null,null, round(dbtdiff/(1000000*60*round(secs/60))) ) concactive
from
(
select begintime,endtime,(extract(Minute from endtime-begintime)*60+extract(Second from endtime-begintime)) secs,
snapid,inst,
dbt-(nvl(lag(dbt) over (partition by inst order by inst,snapid),0)) dbtdiff
from
(
select sn.begin_interval_time begintime,
     sn.end_interval_time EndTime,tm.snap_id SnapId,tm.instance_number Inst,
     sum(decode(tm.stat_name,'DB time',value,0)) dbt
from dba_hist_sys_time_model tm,dba_hist_snapshot sn
where 1=1
  and (tm.dbid, tm.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and tm.snap_id between :start_snap_id - 1 and :end_snap_id
and   tm.dbid = sn.dbid
and   tm.instance_number =  sn.instance_number
and   tm.snap_id = sn.snap_id
and   tm.stat_name in (
'DB time'
)
group by sn.begin_interval_time,sn.end_interval_time,tm.snap_id,tm.instance_number
order by tm.instance_number,tm.snap_id
)
)
where snapid between :start_snap_id and :end_snap_id
order by inst,snapid
;
 
-- Top 5 Foreground Waits ; time_waited_micro_fg http://dbastreet.com/blog/?p=849
-- Top 5 Waits ; time_waited_micro
with se as (
     select sn.begin_interval_time begintime,
        sn.end_interval_time EndTime,se.snap_id SnapId,se.instance_number Inst,
        se.event_name stat,se.time_waited_micro value,
        nvl(lag(se.time_waited_micro) over(partition by se.instance_number,se.event_name
        order by se.instance_number,se.snap_id,se.event_name),0) prevval,
        se.time_waited_micro -
        nvl(lag(se.time_waited_micro) over(partition by se.instance_number,se.event_name
        order by se.instance_number,se.snap_id,se.event_name),0) valuediff
     from dba_hist_system_event se,dba_hist_snapshot sn
     where 1=1
       and (se.dbid, se.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
       and se.snap_id between :start_snap_id - 1 and :end_snap_id
     and   se.dbid = sn.dbid
     and   se.instance_number =  sn.instance_number
     and   se.snap_id = sn.snap_id
     and   se.wait_class != 'Idle'
     order by se.snap_id,se.instance_number,se.event_name
     ) ,
     sdbcpu as (
         select sn.begin_interval_time begintime,sn.end_interval_time EndTime,
         stm.snap_id snapid,stm.instance_number inst,stm.stat_name stat
         ,stm.value value
         ,nvl(lag(stm.value) over(partition by stm.instance_number order by stm.instance_number,stm.snap_id),0) prevval
         ,stm.value-
         nvl(lag(stm.value) over(partition by stm.instance_number order by stm.instance_number,stm.snap_id),0) valuediff
         from dba_hist_sys_time_model stm,dba_hist_snapshot sn
         where
         stm.stat_name = ('DB CPU')
           and (stm.dbid, stm.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
           and stm.snap_id between :start_snap_id - 1 and :end_snap_id
         and stm.dbid = sn.dbid
         and stm.instance_number = sn.instance_number
         and stm.snap_id = sn.snap_id
         order by stm.snap_id,stm.instance_number
     ) ,
     sunion as (
         select begintime,endtime,snapid,inst,stat,valuediff from se
         union all
         select begintime,endtime,snapid,inst,stat,valuediff from sdbcpu
         order by 3,4
     ),
     spct as (
     select begintime,endtime,snapid,inst,stat,valuediff,
     round(ratio_to_report(valuediff) over (partition by snapid,inst),4) as pct
     from sunion
     order by 3,4 asc,7  desc
     )
     select * from (
     select to_char(begintime,'DD-MON-RR HH24:MI:SS') begintime
     ,to_char(endtime,'DD-MON-RR HH24:MI:SS') endtime,snapid,inst,stat,valuediff,round(pct*100,2) pct,
     row_number() over (partition by snapid,inst order by snapid,inst asc,pct desc) as rnum
     from spct
     )
     where 1=1
       and rnum <= :top_n 
       and snapid between :start_snap_id and :end_snap_id
;

select * from dba_hist_sysmetric_summary
where 1=1 and
metric_name = 'Average Active Sessions'
order by 1
;


-- Physical and Logical I/O  http://dbastreet.com/blog/?p=849
select to_char(begintime,'DD-MON-RR HH24:MI') begintime,to_char(endtime,'DD-MON-RR HH24:MI') endtime
,(extract(Minute from endtime-begintime)*60+extract(Second from endtime-begintime)) secs,
snapid,inst,
prd-nvl(lag(prd) over (partition by inst order by inst,snapid),0) phys_read,
pwrt-nvl(lag(pwrt) over (partition by inst order by inst,snapid),0) phys_write,
iordreq-nvl(lag(iordreq) over (partition by inst order by inst,snapid),0) io_read_requests,
iowrtreq-nvl(lag(iowrtreq) over (partition by inst order by inst,snapid),0) io_write_requests,
prmbr-nvl(lag(prmbr) over (partition by inst order by inst,snapid),0) multi_block_read,
cgets-nvl(lag(cgets) over (partition by inst order by inst,snapid),0) consistent_gets,
dbgets-nvl(lag(dbgets) over (partition by inst order by inst,snapid),0) db_block_gets
from
(
select sn.begin_interval_time begintime,
     sn.end_interval_time EndTime,ss.snap_id SnapId,ss.instance_number Inst,
     sum(decode(ss.stat_name,'physical read total bytes',value,0)) prd,
     sum(decode(ss.stat_name,'physical write total bytes',value,0)) pwrt,
     sum(decode(ss.stat_name,'physical read total IO requests',value,0)) iordreq,
     sum(decode(ss.stat_name,'physical write total IO requests',value,0)) iowrtreq,
     sum(decode(ss.stat_name,'physical read total multi block requests',value,0)) prmbr,
     sum(decode(ss.stat_name,'consistent gets',value,0)) cgets,
     sum(decode(ss.stat_name,'db block gets',value,0)) dbgets
from dba_hist_sysstat ss,dba_hist_snapshot sn
where 1=1 
  and (ss.dbid, ss.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
           and ss.snap_id between :start_snap_id - 1 and :end_snap_id
and   ss.dbid = sn.dbid
and   ss.instance_number =  sn.instance_number
and   ss.snap_id = sn.snap_id
and   ss.stat_name in (
'physical read total bytes',
'physical write total bytes',
'physical read total IO requests',
'physical write total IO requests',
'physical read total multi block requests',
'consistent gets',
'db block gets'
)
group by sn.begin_interval_time,sn.end_interval_time,ss.snap_id,ss.instance_number
order by ss.instance_number,ss.snap_id
)
where snapid between :start_snap_id and :end_snap_id
order by 4,5
;

-- top 10 SQL by elapsed time: http://dbastreet.com/blog/?p=849
select * from (
select ss.snap_id snapid,ss.instance_number inst,ss.sql_id  sqlid
       ,round(sum(ss.elapsed_time_delta)) elapsed
       ,nvl(round(sum(ss.executions_delta)),1) execs
       ,round(sum(ss.buffer_gets_delta)) gets
       ,round(sum(ss.rows_processed_delta)) rowsp
       ,round(sum(ss.disk_reads_delta)) reads
       ,dense_rank() over(partition by snap_id,instance_number order by sum(ss.elapsed_time_delta) desc) sql_rank
from
dba_hist_sqlstat ss
where 1=1 
  and (ss.dbid, ss.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
           and ss.snap_id between :start_snap_id - 1 and :end_snap_id
group by ss.snap_id,ss.instance_number,ss.sql_id
)
where sql_rank <= :top_n and snapid between :start_snap_id and :end_snap_id
;



select distinct metric_name 
from dba_hist_sysmetric_summary
where 1=1 and
(upper(metric_name)  like upper('%session%'))
order by 1
;
select distinct stat_name 
from dba_hist_sysstat
where 1=1 and
(upper(stat_name)  like upper('%DB TIME%'))
order by 1
;

select distinct metric_name 
from dba_hist_sysmetric_summary
where 1=1 and
(upper(metric_name)  like upper('%read%'))
order by 1
;


-- load profile:
select lpad(short_name, 20, ' ') short_name
     , per_sec
     , per_tx from
    (select short_name
          , max(decode(typ, 1, value)) per_sec
          , max(decode(typ, 2, value)) per_tx
          , max(m_rank) m_rank 
       from
        (select /*+ use_hash(s) */ 
                m.short_name
              , s.value * coeff value
              , typ
              , m_rank
           from v$sysmetric s,
               (select 'Database Time Per Sec'                      metric_name, 'DB Time' short_name, .01 coeff, 1 typ, 1 m_rank from dual union all
                select 'CPU Usage Per Sec'                          metric_name, 'DB CPU' short_name, .01 coeff, 1 typ, 2 m_rank from dual union all
                select 'Redo Generated Per Sec'                     metric_name, 'Redo size' short_name, 1 coeff, 1 typ, 3 m_rank from dual union all
                select 'Logical Reads Per Sec'                      metric_name, 'Logical reads' short_name, 1 coeff, 1 typ, 4 m_rank from dual union all
                select 'DB Block Changes Per Sec'                   metric_name, 'Block changes' short_name, 1 coeff, 1 typ, 5 m_rank from dual union all
                select 'Physical Reads Per Sec'                     metric_name, 'Physical reads' short_name, 1 coeff, 1 typ, 6 m_rank from dual union all
                select 'Physical Writes Per Sec'                    metric_name, 'Physical writes' short_name, 1 coeff, 1 typ, 7 m_rank from dual union all
                select 'User Calls Per Sec'                         metric_name, 'User calls' short_name, 1 coeff, 1 typ, 8 m_rank from dual union all
                select 'Total Parse Count Per Sec'                  metric_name, 'Parses' short_name, 1 coeff, 1 typ, 9 m_rank from dual union all
                select 'Hard Parse Count Per Sec'                   metric_name, 'Hard Parses' short_name, 1 coeff, 1 typ, 10 m_rank from dual union all
                select 'Logons Per Sec'                             metric_name, 'Logons' short_name, 1 coeff, 1 typ, 11 m_rank from dual union all
                select 'Executions Per Sec'                         metric_name, 'Executes' short_name, 1 coeff, 1 typ, 12 m_rank from dual union all
                select 'User Rollbacks Per Sec'                     metric_name, 'Rollbacks' short_name, 1 coeff, 1 typ, 13 m_rank from dual union all
                select 'User Transaction Per Sec'                   metric_name, 'Transactions' short_name, 1 coeff, 1 typ, 14 m_rank from dual union all
                select 'User Rollback UndoRec Applied Per Sec'      metric_name, 'Applied urec' short_name, 1 coeff, 1 typ, 15 m_rank from dual union all
                select 'Redo Generated Per Txn'                     metric_name, 'Redo size' short_name, 1 coeff, 2 typ, 3 m_rank from dual union all
                select 'Logical Reads Per Txn'                      metric_name, 'Logical reads' short_name, 1 coeff, 2 typ, 4 m_rank from dual union all
                select 'DB Block Changes Per Txn'                   metric_name, 'Block changes' short_name, 1 coeff, 2 typ, 5 m_rank from dual union all
                select 'Physical Reads Per Txn'                     metric_name, 'Physical reads' short_name, 1 coeff, 2 typ, 6 m_rank from dual union all
                select 'Physical Writes Per Txn'                    metric_name, 'Physical writes' short_name, 1 coeff, 2 typ, 7 m_rank from dual union all
                select 'User Calls Per Txn'                         metric_name, 'User calls' short_name, 1 coeff, 2 typ, 8 m_rank from dual union all
                select 'Total Parse Count Per Txn'                  metric_name, 'Parses' short_name, 1 coeff, 2 typ, 9 m_rank from dual union all
                select 'Hard Parse Count Per Txn'                   metric_name, 'Hard Parses' short_name, 1 coeff, 2 typ, 10 m_rank from dual union all
                select 'Logons Per Txn'                             metric_name, 'Logons' short_name, 1 coeff, 2 typ, 11 m_rank from dual union all
                select 'Executions Per Txn'                         metric_name, 'Executes' short_name, 1 coeff, 2 typ, 12 m_rank from dual union all
                select 'User Rollbacks Per Txn'                     metric_name, 'Rollbacks' short_name, 1 coeff, 2 typ, 13 m_rank from dual union all
                select 'User Transaction Per Txn'                   metric_name, 'Transactions' short_name, 1 coeff, 2 typ, 14 m_rank from dual union all
                select 'User Rollback Undo Records Applied Per Txn' metric_name, 'Applied urec' short_name, 1 coeff, 2 typ, 15 m_rank from dual) m
          where m.metric_name = s.metric_name
            and s.intsize_csec > 5000
            and s.intsize_csec < 7000)
      group by short_name)
 order by m_rank
;


select distinct name from dba_hist_sgastat
;

select snap_id, name, bytes 
from dba_hist_sgastat 
where name in ('buffer_cache')
and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
and snap_id between :start_snap_id and :end_snap_id
order by snap_id desc
;

select snap_id, name, bytes
from dba_hist_sgastat 
where name in ('buffer_cache')
and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
;

-- Cache Sizes
select 'Buffer Cache:' " "
, (select round(sum(bytes)/(1024*1024))   || 'M' val from dba_hist_sgastat 
   where name in ('buffer_cache') 
     and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
     and snap_id = :start_snap_id ) "Begin"
, (select round(sum(bytes)/(1024*1024))   || 'M' val from dba_hist_sgastat 
   where name in ('buffer_cache') 
     and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
     and snap_id = :end_snap_id) "End"
, 'Std Block Size:' "  "
, '8K' "   "
from dual
union
select 'Shared Pool Size:' " "
, (select round(sum(value)/(1024*1024))   || 'M' val 
   from dba_hist_sga 
   where snap_id = :start_snap_id
     and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
   ) "Begin"
, (select round(sum(value)/(1024*1024))   || 'M' val 
   from dba_hist_sga 
   where snap_id = :end_snap_id
     and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
   ) "End"
, 'Log Buffer:' "  "
, (select round(sum(bytes)/(1024))   || 'K' val from dba_hist_sgastat 
   where name in ('log_buffer') 
     and (dbid, instance_number)  = (select dbid, instance_number from v$database, v$instance)
     and snap_id = :end_snap_id) "   "
from dual
;

-- queries used to develop ideas:
-- load profile metrics
with load_profile as
(
select 'Database Time Per Sec'                      metric_name, 'DB Time' short_name, .01 coeff, 1 typ, 1 m_rank from dual union all
select 'CPU Usage Per Sec'                          metric_name, 'DB CPU' short_name, .01 coeff, 1 typ, 2 m_rank from dual union all
select 'Redo Generated Per Sec'                     metric_name, 'Redo size' short_name, 1 coeff, 1 typ, 3 m_rank from dual union all
select 'Logical Reads Per Sec'                      metric_name, 'Logical reads' short_name, 1 coeff, 1 typ, 4 m_rank from dual union all
select 'DB Block Changes Per Sec'                   metric_name, 'Block changes' short_name, 1 coeff, 1 typ, 5 m_rank from dual union all
select 'Physical Reads Per Sec'                     metric_name, 'Physical reads' short_name, 1 coeff, 1 typ, 6 m_rank from dual union all
select 'Physical Writes Per Sec'                    metric_name, 'Physical writes' short_name, 1 coeff, 1 typ, 7 m_rank from dual union all
select 'User Calls Per Sec'                         metric_name, 'User calls' short_name, 1 coeff, 1 typ, 8 m_rank from dual union all
select 'Total Parse Count Per Sec'                  metric_name, 'Parses' short_name, 1 coeff, 1 typ, 9 m_rank from dual union all
select 'Hard Parse Count Per Sec'                   metric_name, 'Hard Parses' short_name, 1 coeff, 1 typ, 10 m_rank from dual union all
select 'Logons Per Sec'                             metric_name, 'Logons' short_name, 1 coeff, 1 typ, 11 m_rank from dual union all
select 'Executions Per Sec'                         metric_name, 'Executes' short_name, 1 coeff, 1 typ, 12 m_rank from dual union all
select 'User Rollbacks Per Sec'                     metric_name, 'Rollbacks' short_name, 1 coeff, 1 typ, 13 m_rank from dual union all
select 'User Transaction Per Sec'                   metric_name, 'Transactions' short_name, 1 coeff, 1 typ, 14 m_rank from dual union all
select 'User Rollback UndoRec Applied Per Sec'      metric_name, 'Applied urec' short_name, 1 coeff, 1 typ, 15 m_rank from dual union all
select 'Redo Generated Per Txn'                     metric_name, 'Redo size' short_name, 1 coeff, 2 typ, 3 m_rank from dual union all
select 'Logical Reads Per Txn'                      metric_name, 'Logical reads' short_name, 1 coeff, 2 typ, 4 m_rank from dual union all
select 'DB Block Changes Per Txn'                   metric_name, 'Block changes' short_name, 1 coeff, 2 typ, 5 m_rank from dual union all
select 'Physical Reads Per Txn'                     metric_name, 'Physical reads' short_name, 1 coeff, 2 typ, 6 m_rank from dual union all
select 'Physical Writes Per Txn'                    metric_name, 'Physical writes' short_name, 1 coeff, 2 typ, 7 m_rank from dual union all
select 'User Calls Per Txn'                         metric_name, 'User calls' short_name, 1 coeff, 2 typ, 8 m_rank from dual union all
select 'Total Parse Count Per Txn'                  metric_name, 'Parses' short_name, 1 coeff, 2 typ, 9 m_rank from dual union all
select 'Hard Parse Count Per Txn'                   metric_name, 'Hard Parses' short_name, 1 coeff, 2 typ, 10 m_rank from dual union all
select 'Logons Per Txn'                             metric_name, 'Logons' short_name, 1 coeff, 2 typ, 11 m_rank from dual union all
select 'Executions Per Txn'                         metric_name, 'Executes' short_name, 1 coeff, 2 typ, 12 m_rank from dual union all
select 'User Rollbacks Per Txn'                     metric_name, 'Rollbacks' short_name, 1 coeff, 2 typ, 13 m_rank from dual union all
select 'User Transaction Per Txn'                   metric_name, 'Transactions' short_name, 1 coeff, 2 typ, 14 m_rank from dual union all
select 'User Rollback Undo Records Applied Per Txn' metric_name, 'Applied urec' short_name, 1 coeff, 2 typ, 15 m_rank from dual
) 
select distinct metric_name 
from dba_hist_sysmetric_summary -- dba_hist_sysmetric_history
where metric_name in (select metric_name from load_profile)
;

-- load profile metrics with order
with load_profile as
(
select 'Redo Generated Per Sec' metric_name, 1.1 ord from dual union
select 'Redo Generated Per Txn' metric_name, 1.2 ord from dual union
select 'Logical Reads Per Sec' metric_name, 2.1 ord from dual union
select 'Logical Reads Per Txn' metric_name, 2.2 ord from dual union
select 'DB Block Changes Per Sec' metric_name, 3.1 ord from dual union
select 'DB Block Changes Per Txn' metric_name, 3.2 ord from dual union
select 'Physical Reads Per Sec' metric_name, 4.1 ord from dual union
select 'Physical Reads Per Txn' metric_name, 4.2 ord from dual union
select 'Physical Writes Per Sec' metric_name, 5.1 ord from dual union
select 'Physical Writes Per Txn' metric_name, 5.2 ord from dual union
select 'User Calls Per Sec' metric_name, 6.1 ord from dual union
select 'User Calls Per Txn' metric_name, 6.2 ord from dual union

select 'Total Parse Count Per Sec' metric_name, 7.1 ord from dual union
select 'Total Parse Count Per Txn' metric_name, 7.2 ord from dual union

select 'Hard Parse Count Per Sec' metric_name, 8.1 ord from dual union
select 'Hard Parse Count Per Txn' metric_name, 8.2 ord from dual union

select 'Disk Sort Per Sec' metric_name, 9.1 ord from dual union
select 'Disk Sort Per Txn' metric_name, 9.2 ord from dual union
select 'Total Sorts Per User Call' metric_name, 9.4 ord from dual union
select 'Memory Sorts Ratio' metric_name, 9.5 ord from dual union

select 'Logons Per Sec' metric_name, 10.1 ord from dual union
select 'Logons Per Txn' metric_name, 10.2 ord from dual union

select 'Executions Per Sec' metric_name, 11.1 ord from dual union
select 'Executions Per Txn' metric_name, 11.2 ord from dual union

select 'User Transaction Per Sec' metric_name, 12.1 ord from dual union

select 'DB Block Changes Per Sec' metric_name, 99.1 ord from dual union
select 'Physical Read Total IO Requests Per Sec' metric_name, 99.2 ord from dual union

select 'User Rollbacks Per Sec' metric_name, 99.21 ord from dual union
select 'User Rollbacks Percentage' metric_name, 99.22 ord from dual union

select 'Recursive Calls Per Sec' metric_name, 99.31 ord from dual union
select 'User Calls Per Sec' metric_name, 99.32 ord from dual union

select 'Rows Per Sort' metric_name, 99.4 ord from dual union

select 'xxx' metric_name, 9999 ord  from dual
)
, load_type as 
(
select 'DB Time(s):' from dual union
select 'DB CPU(s):' from dual union
select 'Redo size:' from dual union
select 'Logical reads:' from dual union
select 'Block changes:' from dual union
select 'Physical reads:' from dual union
select 'Physical writes:' from dual union
select 'User calls:' from dual union
select 'Parses:' from dual union
select 'Hard parses:' from dual union
select 'W/A MB processed:' from dual union
select 'Logons:' from dual union
select 'Executes:' from dual union
select 'Rollbacks:' from dual union
select 'Transactions:' from dual 
)

select m.metric_name , ord
from dba_hist_sysmetric_summary m , load_profile l
where m.metric_name = l.metric_name 
group by m.metric_name , ord
order by ord
;

with load_profile as
(
select 'Database Time Per Sec'                      metric_name, 'DB Time' short_name, .01 coeff, 1 typ, 1 m_rank from dual union all
select 'CPU Usage Per Sec'                          metric_name, 'DB CPU' short_name, .01 coeff, 1 typ, 2 m_rank from dual union all
select 'Redo Generated Per Sec'                     metric_name, 'Redo size' short_name, 1 coeff, 1 typ, 3 m_rank from dual union all
select 'Logical Reads Per Sec'                      metric_name, 'Logical reads' short_name, 1 coeff, 1 typ, 4 m_rank from dual union all
select 'DB Block Changes Per Sec'                   metric_name, 'Block changes' short_name, 1 coeff, 1 typ, 5 m_rank from dual union all
select 'Physical Reads Per Sec'                     metric_name, 'Physical reads' short_name, 1 coeff, 1 typ, 6 m_rank from dual union all
select 'Physical Writes Per Sec'                    metric_name, 'Physical writes' short_name, 1 coeff, 1 typ, 7 m_rank from dual union all
select 'User Calls Per Sec'                         metric_name, 'User calls' short_name, 1 coeff, 1 typ, 8 m_rank from dual union all
select 'Total Parse Count Per Sec'                  metric_name, 'Parses' short_name, 1 coeff, 1 typ, 9 m_rank from dual union all
select 'Hard Parse Count Per Sec'                   metric_name, 'Hard Parses' short_name, 1 coeff, 1 typ, 10 m_rank from dual union all
select 'Logons Per Sec'                             metric_name, 'Logons' short_name, 1 coeff, 1 typ, 11 m_rank from dual union all
select 'Executions Per Sec'                         metric_name, 'Executes' short_name, 1 coeff, 1 typ, 12 m_rank from dual union all
select 'User Rollbacks Per Sec'                     metric_name, 'Rollbacks' short_name, 1 coeff, 1 typ, 13 m_rank from dual union all
select 'User Transaction Per Sec'                   metric_name, 'Transactions' short_name, 1 coeff, 1 typ, 14 m_rank from dual union all
select 'User Rollback UndoRec Applied Per Sec'      metric_name, 'Applied urec' short_name, 1 coeff, 1 typ, 15 m_rank from dual union all
select 'Redo Generated Per Txn'                     metric_name, 'Redo size' short_name, 1 coeff, 2 typ, 3 m_rank from dual union all
select 'Logical Reads Per Txn'                      metric_name, 'Logical reads' short_name, 1 coeff, 2 typ, 4 m_rank from dual union all
select 'DB Block Changes Per Txn'                   metric_name, 'Block changes' short_name, 1 coeff, 2 typ, 5 m_rank from dual union all
select 'Physical Reads Per Txn'                     metric_name, 'Physical reads' short_name, 1 coeff, 2 typ, 6 m_rank from dual union all
select 'Physical Writes Per Txn'                    metric_name, 'Physical writes' short_name, 1 coeff, 2 typ, 7 m_rank from dual union all
select 'User Calls Per Txn'                         metric_name, 'User calls' short_name, 1 coeff, 2 typ, 8 m_rank from dual union all
select 'Total Parse Count Per Txn'                  metric_name, 'Parses' short_name, 1 coeff, 2 typ, 9 m_rank from dual union all
select 'Hard Parse Count Per Txn'                   metric_name, 'Hard Parses' short_name, 1 coeff, 2 typ, 10 m_rank from dual union all
select 'Logons Per Txn'                             metric_name, 'Logons' short_name, 1 coeff, 2 typ, 11 m_rank from dual union all
select 'Executions Per Txn'                         metric_name, 'Executes' short_name, 1 coeff, 2 typ, 12 m_rank from dual union all
select 'User Rollbacks Per Txn'                     metric_name, 'Rollbacks' short_name, 1 coeff, 2 typ, 13 m_rank from dual union all
select 'User Transaction Per Txn'                   metric_name, 'Transactions' short_name, 1 coeff, 2 typ, 14 m_rank from dual union all
select 'User Rollback Undo Records Applied Per Txn' metric_name, 'Applied urec' short_name, 1 coeff, 2 typ, 15 m_rank from dual
) 
, load_table as
(
select short_name
, max(case when typ = 1 then metric_name else null end) as per_Second
, max(case when typ = 2 then metric_name else null end) as per_Transaction
, max(coeff) coeff
, max(m_rank) m_rank
from load_profile
group by short_name
)
select short_name, per_Second, per_transaction, coeff 
from load_table
order by m_rank
;



-- Baselines can be seen using the DBA_HIST_BASELINE view as seen in the following example:
SELECT baseline_id, baseline_name, start_snap_id, end_snap_id
FROM dba_hist_baseline
;

-- OLD VERSION of load profile similar data to load profile section of AWR Report
with load_profile as
(
select 'Redo Generated Per Sec' metric_name, 1.1 ord from dual union
select 'Redo Generated Per Txn' metric_name, 1.2 ord from dual union
select 'Logical Reads Per Sec' metric_name, 2.1 ord from dual union
select 'Logical Reads Per Txn' metric_name, 2.2 ord from dual union
select 'DB Block Changes Per Sec' metric_name, 3.1 ord from dual union
select 'DB Block Changes Per Txn' metric_name, 3.2 ord from dual union
select 'Physical Reads Per Sec' metric_name, 4.1 ord from dual union
select 'Physical Reads Per Txn' metric_name, 4.2 ord from dual union
select 'Physical Writes Per Sec' metric_name, 5.1 ord from dual union
select 'Physical Writes Per Txn' metric_name, 5.2 ord from dual union
select 'User Calls Per Sec' metric_name, 6.1 ord from dual union
select 'User Calls Per Txn' metric_name, 6.2 ord from dual union

select 'Total Parse Count Per Sec' metric_name, 7.1 ord from dual union
select 'Total Parse Count Per Txn' metric_name, 7.2 ord from dual union

select 'Hard Parse Count Per Sec' metric_name, 8.1 ord from dual union
select 'Hard Parse Count Per Txn' metric_name, 8.2 ord from dual union

select 'Disk Sort Per Sec' metric_name, 9.1 ord from dual union
select 'Disk Sort Per Txn' metric_name, 9.2 ord from dual union
select 'Total Sorts Per User Call' metric_name, 9.4 ord from dual union
select 'Memory Sorts Ratio' metric_name, 9.5 ord from dual union

select 'Logons Per Sec' metric_name, 10.1 ord from dual union
select 'Logons Per Txn' metric_name, 10.2 ord from dual union

select 'Executions Per Sec' metric_name, 11.1 ord from dual union
select 'Executions Per Txn' metric_name, 11.2 ord from dual union

select 'User Transaction Per Sec' metric_name, 12.1 ord from dual union

select 'DB Block Changes Per Sec' metric_name, 99.1 ord from dual union
select 'Physical Read Total IO Requests Per Sec' metric_name, 99.2 ord from dual union

select 'User Rollbacks Per Sec' metric_name, 99.21 ord from dual union
select 'User Rollbacks Percentage' metric_name, 99.22 ord from dual union

select 'Recursive Calls Per Sec' metric_name, 99.31 ord from dual union
select 'User Calls Per Sec' metric_name, 99.32 ord from dual union

select 'Rows Per Sort' metric_name, 99.4 ord from dual union

select 'xxx' metric_name, 9999 ord  from dual
)
select ord, m.metric_name, avg(average) 
from dba_hist_sysmetric_summary m , load_profile l     
where 1=1 
  and m.metric_name = l.metric_name 
  and (dbid, instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and snap_id between :start_snap_id and :end_snap_id
group by ord, m.metric_name
order by ord
;
