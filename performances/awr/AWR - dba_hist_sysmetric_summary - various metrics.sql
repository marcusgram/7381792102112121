-- AWR - dba_hist_sysmetric_summary - various metrics.sql
-- edited 16-Oct-2013 RDCornejo
select distinct metric_name from dba_hist_sysmetric_summary where lower(metric_name) like '%'|| lower(:metric_name) ||'%';

-- ideas from http://oracledoug.com/metric_baselines_10g.pdf


-- Response Time and performance metrics:
with metrics as
(
select snap_id, dbid, instance_number
--, sum(case metric_name when 'SQL Service Response Time' then round(average) end) "SQL Service Response Time"
, sum(case metric_name when 'Response Time Per Txn' then round(average) end) "Response Time Per Txn"
, sum(case metric_name when 'Database Time Per Sec' then round(average) end) "Database Time Per Sec"
, sum(case metric_name when 'Database Wait Time Ratio' then round(average) end) "Database Wait Time Ratio"
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
--, "SQL Service Response Time"
, "Response Time Per Txn"
, "Database Time Per Sec"
, "Database Wait Time Ratio"
from metrics, snaps
where 1=1
--  and rownum = 1
  and metrics.snap_id = snaps.snap_id
  and metrics.dbid = snaps.dbid 
  and metrics.instance_number = snaps.instance_number 
;

select distinct metric_name from dba_hist_sysmetric_summary where lower(metric_name) like '%'|| lower(:metric_name) ||'%';

-- Workload volume/throughput metrics:
-- -----------------------------------
with metrics as
(
select snap_id, dbid, instance_number
, sum(case metric_name when 'User Transaction Per Sec' then round(average) end) "User Transaction Per Sec"
, sum(case metric_name when 'Physical Reads Per Sec' then round(average) end) "Physical Reads Per Sec"
, sum(case metric_name when 'Physical Writes Per Sec' then round(average) end) "Physical Writes Per Sec"
, sum(case metric_name when 'Redo Generated Per Sec' then round(average) end) "Redo Generated Per Sec"
, sum(case metric_name when 'User Calls Per Sec' then round(average) end) "User Calls Per Sec"
, sum(case metric_name when 'Network Traffic Volume Per Sec' then round(average) end) "Network Traffic Volume Per Sec"
, sum(case metric_name when 'Current Logons Count' then round(average) end) "Current Logons Count"
, sum(case metric_name when 'Executions Per Sec' then round(average) end) "Executions Per Sec"
, sum(case metric_name when 'Physical Writes Direct Lobs Per Sec' then round(average) end) "Physical Writes Direct Lobs PS"
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
, "User Transaction Per Sec"
, "Physical Reads Per Sec"
, "Physical Writes Per Sec"
, "Redo Generated Per Sec"
, "User Calls Per Sec"
, "Network Traffic Volume Per Sec"
, "Current Logons Count"
, "Executions Per Sec"
, "Physical Writes Direct Lobs PS"
from metrics, snaps
where 1=1
--  and rownum = 1
  and metrics.snap_id = snaps.snap_id
  and metrics.dbid = snaps.dbid 
  and metrics.instance_number = snaps.instance_number 
;





-- I/O workload metrics:
with metrics as
(
select snap_id, dbid, instance_number
, sum(case metric_name when 'Physical Read Total Bytes Per Sec' then round(average) end) "Physical Read Total Bps"
--, sum(case metric_name when 'Physical Read Bytes Per Sec' then round(average) end) Physical_Read_Bps
, sum(case metric_name when 'Physical Write Total Bytes Per Sec' then round(average) end) "Physical Write Total Bps"
--, sum(case metric_name when 'Physical Write Bytes Per Sec' then round(average) end) Physical_Write_Bps
, sum(case metric_name when 'Physical Read Total IO Requests Per Sec' then round(average) end) "Physical Read IOPS"
, sum(case metric_name when 'Physical Write Total IO Requests Per Sec' then round(average) end) "Physical Write IOPS"
, sum(case metric_name when 'Physical Reads Direct Per Sec' then round(average) end) "Physical Reads Direct Per Sec"
, sum(case metric_name when 'Physical Writes Direct Per Sec' then round(average) end) "Physical Writes Direct Per Sec"
--, sum(case metric_name when 'Physical Reads Direct Lobs Per Sec' then round(average) end) Physical_Reads_Direct_Lobs_PS
--, sum(case metric_name when 'Physical Writes Direct Lobs Per Sec' then round(average) end) Physical_Writes_Direct_Lobs_PS
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
, "Physical Read Total Bps"
, "Physical Write Total Bps"
, "Physical Read IOPS"
, "Physical Write IOPS"
, "Physical Reads Direct Per Sec"
, "Physical Writes Direct Per Sec"
from metrics, snaps
where 1=1
--  and rownum = 1
  and metrics.snap_id = snaps.snap_id
  and metrics.dbid = snaps.dbid 
  and metrics.instance_number = snaps.instance_number 
;


