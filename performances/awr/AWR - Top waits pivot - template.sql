Select data.snap_id
, to_char(begin_interval_time, 'mm/dd/yyyy HH24') || ':00:00'  collection_time
-- insert code for the max decode ...
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
(
-- insert the code for the in list

)
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

