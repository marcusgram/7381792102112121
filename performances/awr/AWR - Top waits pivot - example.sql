Select data.snap_id
, to_char(begin_interval_time, 'mm/dd/yyyy HH24') || ':00:00'  collection_time
, max(decode(event_name,'PX Deq Credit: send blkd', time_waited_micro, null)) PX_Deq_Credit_send_blkd
, max(decode(event_name,'DB CPU', time_waited_micro, null)) DB_CPU
, max(decode(event_name,'direct path write temp', time_waited_micro, null)) direct_path_write_temp
, max(decode(event_name,'SQL*Net message from dblink', time_waited_micro, null)) SQLNet_message_from_dblink
, max(decode(event_name,'direct path read', time_waited_micro, null)) direct_path_read
, max(decode(event_name,'log file sync', time_waited_micro, null)) log_file_sync
, max(decode(event_name,'log file parallel write', time_waited_micro, null)) log_file_parallel_write
, max(decode(event_name,'Backup: sbtwrite2', time_waited_micro, null)) Backup_sbtwrite2
, max(decode(event_name,'direct path read temp', time_waited_micro, null)) direct_path_read_temp
, max(decode(event_name,'db file scattered read', time_waited_micro, null)) db_file_scattered_read
from (
SELECT ee1.snap_id, ee1.event_name,
                           ee1.time_waited_micro - ee2.time_waited_micro time_waited_micro
                    FROM dba_hist_system_event ee1 JOIN dba_hist_system_event ee2
                         ON ee1.snap_id = ee2.snap_id + 1
                       AND ee1.instance_number = ee2.instance_number
                       AND ee1.event_id = ee2.event_id
                       AND ee1.wait_class_id <> 2723168908
                       AND ee1.time_waited_micro - ee2.time_waited_micro > 0
                       and ee1.event_name in 
('PX Deq Credit: send blkd'
,'DB CPU'
,'direct path write temp'
,'SQL*Net message from dblink'
,'direct path read'
,'log file sync'
,'log file parallel write'
,'Backup: sbtwrite2'
,'direct path read temp'
,'db file scattered read')
union
                  SELECT st1.snap_id,
                         st1.stat_name event_name,
                         st1.VALUE - st2.VALUE time_waited_micro
                    FROM dba_hist_sys_time_model st1 JOIN dba_hist_sys_time_model st2
                         ON st1.instance_number = st2.instance_number
                       AND st1.snap_id = st2.snap_id + 1
                       AND st1.stat_id = st2.stat_id
                       AND st1.stat_name = 'DB CPU'
                       AND st1.VALUE - st2.VALUE > 0
) data
, dba_hist_snapshot snap
where snap.snap_id = data.snap_id
group by data.snap_id, to_char(begin_interval_time, 'mm/dd/yyyy HH24') || ':00:00' 
order by data.snap_id desc
;

