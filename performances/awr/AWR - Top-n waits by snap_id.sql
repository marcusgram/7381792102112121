---------------------------------------------------------------
-- Query to find Top N wait events in database by snap_id
-- Updated 29-Oct-2013 RDCornejo [added PCT]
-- Usage: provide integer number for top # of waits
--       can leave blank (optional):
--        -  hour range (e.g. 3 - 15 for  03:00 to 15:00 hours)
--        -  snap_id range
----------------------------------------------------------------
with et as 
(SELECT et1.instance_number
, et1.snap_id
, et1.VALUE - et2.VALUE total_time_waited
FROM dba_hist_sys_time_model et1 JOIN dba_hist_sys_time_model et2
  ON et1.snap_id = et2.snap_id + 1
 AND et1.instance_number = et2.instance_number
 AND et1.stat_id = et2.stat_id
WHERE (et1.dbid, et1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and (et2.dbid, et2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  AND et1.stat_name = 'DB time'
  AND et1.VALUE - et2.VALUE > 0
)
, ee as
(SELECT ee1.instance_number
, ee1.snap_id
, ee1.event_name
, ee1.time_waited_micro - ee2.time_waited_micro event_time_waited
, ee1.total_waits - ee2.total_waits total_waits
FROM dba_hist_system_event ee1 JOIN dba_hist_system_event ee2 ON ee1.snap_id = ee2.snap_id + 1
 AND ee1.instance_number = ee2.instance_number
 AND ee1.event_id = ee2.event_id
WHERE (ee1.dbid, ee1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and (ee2.dbid, ee2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  AND ee1.wait_class_id <> 2723168908
  AND ee1.time_waited_micro - ee2.time_waited_micro > 0
UNION
SELECT st1.instance_number
, st1.snap_id
, st1.stat_name event_name
, st1.VALUE - st2.VALUE event_time_waited
, 1 total_waits
FROM dba_hist_sys_time_model st1 JOIN dba_hist_sys_time_model st2
  ON st1.instance_number = st2.instance_number
 AND st1.snap_id = st2.snap_id + 1
 AND st1.stat_id = st2.stat_id
WHERE (st1.dbid, st1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and (st2.dbid, st2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  AND st1.stat_name = 'DB CPU'
  AND st1.VALUE - st2.VALUE > 0
)
, m as
(SELECT ee.instance_number
, ee.snap_id
, ee.event_name
, ROUND (ee.event_time_waited / 1000000) event_time_waited
, ee.total_waits
, ROUND ((ee.event_time_waited * 100) / et.total_time_waited, 1) pct
, ROUND ((ee.event_time_waited / ee.total_waits) / 1000 ) avg_wait
FROM  ee JOIN et
  ON ee.instance_number = et.instance_number
 AND ee.snap_id = et.snap_id
)
, w_snap_time as
(
SELECT  s.snap_id, s.begin_interval_time
, m.instance_number
, m.event_name
, m. event_time_waited
, m.total_waits
, m.pct
, m. avg_wait
FROM  m JOIN dba_hist_snapshot s ON m.snap_id = s.snap_id
WHERE (s.dbid, s.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and (to_number(to_char(begin_interval_time, 'HH24')) between nvl(:begin_hour, 0) and  nvl(:end_hour, 24) 
    or to_number(to_char(begin_interval_time, 'HH24')) between nvl(:begin_hour2, 0) and  nvl(:end_hour2, 24))
)
, deltas as 
(
select snap_id, begin_interval_time, event_name, sum(event_time_waited) total_wait_time
, row_number() over (partition by snap_id order by sum(event_time_waited) desc) row_number
, round(ratio_to_report(sum(event_time_waited)) over (partition by snap_id) * 100, 2) Ratio
from w_snap_time
group by snap_id , begin_interval_time, event_name
order by snap_id desc, total_wait_time desc
)
select snap_id "Snap Id"
, trunc(begin_interval_time, 'HH24') "Begin Interval Time"
, Event_name "Event Name"
, Total_wait_time "Total Wait Time"
, row_number "Row Nbr"
, Ratio "Ratio"
from deltas
where row_number <= :top_n
  and snap_id between nvl(:start_snap_id, snap_id) and nvl(:end_snap_id, snap_id)
order by snap_id desc, Total_wait_time desc
;



------------------------------------------------------
-- the top-N daily events
-- ---------------------------------------------------
with et as 
(SELECT et1.instance_number
, et1.snap_id
, et1.VALUE - et2.VALUE total_time_waited
FROM dba_hist_sys_time_model et1 JOIN dba_hist_sys_time_model et2
  ON et1.snap_id = et2.snap_id + 1
 AND et1.instance_number = et2.instance_number
 AND et1.stat_id = et2.stat_id
WHERE (et1.dbid, et1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and (et2.dbid, et2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  AND et1.stat_name = 'DB time'
  AND et1.VALUE - et2.VALUE > 0
)
, ee as
(SELECT ee1.instance_number
, ee1.snap_id
, ee1.event_name
, ee1.time_waited_micro - ee2.time_waited_micro event_time_waited
, ee1.total_waits - ee2.total_waits total_waits
FROM dba_hist_system_event ee1 JOIN dba_hist_system_event ee2 ON ee1.snap_id = ee2.snap_id + 1
 AND ee1.instance_number = ee2.instance_number
 AND ee1.event_id = ee2.event_id
WHERE (ee1.dbid, ee1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and (ee2.dbid, ee2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  AND ee1.wait_class_id <> 2723168908
  AND ee1.time_waited_micro - ee2.time_waited_micro > 0
UNION
SELECT st1.instance_number
, st1.snap_id
, st1.stat_name event_name
, st1.VALUE - st2.VALUE event_time_waited
, 1 total_waits
FROM dba_hist_sys_time_model st1 JOIN dba_hist_sys_time_model st2
  ON st1.instance_number = st2.instance_number
 AND st1.snap_id = st2.snap_id + 1
 AND st1.stat_id = st2.stat_id
WHERE (st1.dbid, st1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and (st2.dbid, st2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  AND st1.stat_name = 'DB CPU'
  AND st1.VALUE - st2.VALUE > 0
)
, m as
(SELECT ee.instance_number
, ee.snap_id
, ee.event_name
, ROUND (ee.event_time_waited / 1000000) event_time_waited
, ee.total_waits
, ROUND ((ee.event_time_waited * 100) / et.total_time_waited, 1) pct
, ROUND ((ee.event_time_waited / ee.total_waits) / 1000 ) avg_wait
FROM  ee JOIN et
  ON ee.instance_number = et.instance_number
 AND ee.snap_id = et.snap_id
)
, w_snap_time as
(
SELECT  s.snap_id, s.begin_interval_time
, m.instance_number
, m.event_name
, m. event_time_waited
, m.total_waits
, m.pct
, m. avg_wait
FROM  m JOIN dba_hist_snapshot s ON m.snap_id = s.snap_id
WHERE (s.dbid, s.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and to_number(to_char(begin_interval_time, 'HH24')) between nvl(:hour_start,0) and nvl(:hour_end, 24)
)
, deltas as 
(
select snap_id, begin_interval_time, event_name, sum(event_time_waited) total_wait_time,
row_number() over (partition by snap_id order by sum(event_time_waited) desc) rn 
from w_snap_time
group by snap_id , begin_interval_time, event_name
order by snap_id desc, total_wait_time desc
)
, snap_aggregate as
(
select snap_id, trunc(begin_interval_time, 'HH24') begin_interval_time, Event_name, Total_wait_time from deltas
where rn <= :top_n
order by snap_id desc, Total_wait_time desc
)
, day_aggregate as
( select 
to_date(to_char(begin_interval_time,'dd/mm/yyyy'),'dd/mm/yyyy') day
, event_name
, sum(Total_wait_time) total_wait_time
, row_number() over (partition by to_date(to_char(begin_interval_time,'dd/mm/yyyy'),'dd/mm/yyyy') order by sum(total_wait_time) desc) rn
from snap_aggregate
group by to_date(to_char(begin_interval_time,'dd/mm/yyyy'),'dd/mm/yyyy'), event_name
)
select * from day_aggregate
where rn <= :top_n
;



------------------------------------------------------
-- overall top-N events for all the top-N daily events
-- ---------------------------------------------------
with et as 
(SELECT et1.instance_number
, et1.snap_id
, et1.VALUE - et2.VALUE total_time_waited
FROM dba_hist_sys_time_model et1 JOIN dba_hist_sys_time_model et2
  ON et1.snap_id = et2.snap_id + 1
 AND et1.instance_number = et2.instance_number
 AND et1.stat_id = et2.stat_id
WHERE (et1.dbid, et1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and (et2.dbid, et2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  AND et1.stat_name = 'DB time'
  AND et1.VALUE - et2.VALUE > 0
)
, ee as
(SELECT ee1.instance_number
, ee1.snap_id
, ee1.event_name
, ee1.time_waited_micro - ee2.time_waited_micro event_time_waited
, ee1.total_waits - ee2.total_waits total_waits
FROM dba_hist_system_event ee1 JOIN dba_hist_system_event ee2 ON ee1.snap_id = ee2.snap_id + 1
 AND ee1.instance_number = ee2.instance_number
 AND ee1.event_id = ee2.event_id
WHERE (ee1.dbid, ee1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and (ee2.dbid, ee2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  AND ee1.wait_class_id <> 2723168908
  AND ee1.time_waited_micro - ee2.time_waited_micro > 0
UNION
SELECT st1.instance_number
, st1.snap_id
, st1.stat_name event_name
, st1.VALUE - st2.VALUE event_time_waited
, 1 total_waits
FROM dba_hist_sys_time_model st1 JOIN dba_hist_sys_time_model st2
  ON st1.instance_number = st2.instance_number
 AND st1.snap_id = st2.snap_id + 1
 AND st1.stat_id = st2.stat_id
WHERE (st1.dbid, st1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and (st2.dbid, st2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  AND st1.stat_name = 'DB CPU'
  AND st1.VALUE - st2.VALUE > 0
)
, m as
(SELECT ee.instance_number
, ee.snap_id
, ee.event_name
, ROUND (ee.event_time_waited / 1000000) event_time_waited
, ee.total_waits
, ROUND ((ee.event_time_waited * 100) / et.total_time_waited, 1) pct
, ROUND ((ee.event_time_waited / ee.total_waits) / 1000 ) avg_wait
FROM  ee JOIN et
  ON ee.instance_number = et.instance_number
 AND ee.snap_id = et.snap_id
)
, w_snap_time as
(
SELECT  s.snap_id, s.begin_interval_time
, m.instance_number
, m.event_name
, m. event_time_waited
, m.total_waits
, m.pct
, m. avg_wait
FROM  m JOIN dba_hist_snapshot s ON m.snap_id = s.snap_id
WHERE (s.dbid, s.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and to_number(to_char(begin_interval_time, 'HH24')) between nvl(:hour_start,0) and nvl(:hour_end, 24)
)
, deltas as 
(
select snap_id, begin_interval_time, event_name, sum(event_time_waited) total_wait_time,
row_number() over (partition by snap_id order by sum(event_time_waited) desc) rn 
from w_snap_time
group by snap_id , begin_interval_time, event_name
order by snap_id desc, total_wait_time desc
)
, snap_aggregate as
(
select snap_id, trunc(begin_interval_time, 'HH24') begin_interval_time, Event_name, Total_wait_time from deltas
where rn <= :top_n
order by snap_id desc, Total_wait_time desc
)
, day_aggregate as
( select 
to_date(to_char(begin_interval_time,'dd/mm/yyyy'),'dd/mm/yyyy') day
, event_name
, sum(Total_wait_time) total_wait_time
, row_number() over (partition by to_date(to_char(begin_interval_time,'dd/mm/yyyy'),'dd/mm/yyyy') order by sum(total_wait_time) desc) rn
from snap_aggregate
group by to_date(to_char(begin_interval_time,'dd/mm/yyyy'),'dd/mm/yyyy'), event_name
)
, overall_agregate as
(select event_name
, sum(Total_wait_time) total_wait_time
, row_number() over (partition by event_name order by sum(total_wait_time) desc) rn
from day_aggregate
where rn <= :top_n
group by event_name
)
select * from overall_agregate
where rn <= :top_n
;


------------------------------------------------
-- generate a sql fragment for top-N wait events
-- hour range version
------------------------------------------------
with et as 
(SELECT et1.instance_number
, et1.snap_id
, et1.VALUE - et2.VALUE total_time_waited
FROM dba_hist_sys_time_model et1 JOIN dba_hist_sys_time_model et2
  ON et1.snap_id = et2.snap_id + 1
 AND et1.instance_number = et2.instance_number
 AND et1.stat_id = et2.stat_id
WHERE (et1.dbid, et1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and (et2.dbid, et2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  AND et1.stat_name = 'DB time'
  AND et1.VALUE - et2.VALUE > 0
)
, ee as
(SELECT ee1.instance_number
, ee1.snap_id
, ee1.event_name
, ee1.time_waited_micro - ee2.time_waited_micro event_time_waited
, ee1.total_waits - ee2.total_waits total_waits
FROM dba_hist_system_event ee1 JOIN dba_hist_system_event ee2 ON ee1.snap_id = ee2.snap_id + 1
 AND ee1.instance_number = ee2.instance_number
 AND ee1.event_id = ee2.event_id
WHERE (ee1.dbid, ee1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and (ee2.dbid, ee2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  AND ee1.wait_class_id <> 2723168908
  AND ee1.time_waited_micro - ee2.time_waited_micro > 0
UNION
SELECT st1.instance_number
, st1.snap_id
, st1.stat_name event_name
, st1.VALUE - st2.VALUE event_time_waited
, 1 total_waits
FROM dba_hist_sys_time_model st1 JOIN dba_hist_sys_time_model st2
  ON st1.instance_number = st2.instance_number
 AND st1.snap_id = st2.snap_id + 1
 AND st1.stat_id = st2.stat_id
WHERE (st1.dbid, st1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and (st2.dbid, st2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  AND st1.stat_name = 'DB CPU'
  AND st1.VALUE - st2.VALUE > 0
)
, m as
(SELECT ee.instance_number
, ee.snap_id
, ee.event_name
, ROUND (ee.event_time_waited / 1000000) event_time_waited
, ee.total_waits
, ROUND ((ee.event_time_waited * 100) / et.total_time_waited, 1) pct
, ROUND ((ee.event_time_waited / ee.total_waits) / 1000 ) avg_wait
FROM  ee JOIN et
  ON ee.instance_number = et.instance_number
 AND ee.snap_id = et.snap_id
)
, w_snap_time as
(
SELECT  s.snap_id, s.begin_interval_time
, m.instance_number
, m.event_name
, m. event_time_waited
, m.total_waits
, m.pct
, m. avg_wait
FROM  m JOIN dba_hist_snapshot s ON m.snap_id = s.snap_id
WHERE (s.dbid, s.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
  and to_number(to_char(begin_interval_time, 'HH24')) between nvl(:hour_start,0) and nvl(:hour_end, 24)
)
, deltas as 
(
select snap_id, begin_interval_time, event_name, sum(event_time_waited) total_wait_time,
row_number() over (partition by snap_id order by sum(event_time_waited) desc) rn 
from w_snap_time
group by snap_id , begin_interval_time, event_name
order by snap_id desc, total_wait_time desc
)
, snap_aggregate as
(
select snap_id, trunc(begin_interval_time, 'HH24') begin_interval_time, Event_name, Total_wait_time from deltas
where rn <= :top_n
order by snap_id desc, Total_wait_time desc
)
, day_aggregate as
( select 
to_date(to_char(begin_interval_time,'dd/mm/yyyy'),'dd/mm/yyyy') day
, event_name
, sum(Total_wait_time) total_wait_time
, row_number() over (partition by to_date(to_char(begin_interval_time,'dd/mm/yyyy'),'dd/mm/yyyy') order by sum(total_wait_time) desc) rn
from snap_aggregate
group by to_date(to_char(begin_interval_time,'dd/mm/yyyy'),'dd/mm/yyyy'), event_name
)
, overall_agregate as
(select event_name, total_wait_time
from
(select event_name
, sum(Total_wait_time) total_wait_time
, row_number() over (partition by event_name order by sum(total_wait_time) desc) rn
from day_aggregate
where rn <= :top_n
group by event_name
)
where rn <= :top_n
)
, the_Decode as
(
select 1 position, rownum row_num, ', max(decode(event_name,''' || event_name || ''', time_waited_micro, null)) ' 
|| translate(event_name, ' :&/*-()', '_') cmd
from overall_agregate
)
, the_in_list as
(
select 2 position, rownum row_num, ', ''' || event_name || '''' cmd
from overall_agregate
)
select * from the_decode
union 
select * from the_in_list
order by 1, 2
;

--------------------------------------------------------------------------------------------------------
-- generate a sql fragment for top-N wait events (can be used to pivot events across snapshot periods:
-- in snap_id range
-- -----------------------------------------------------------------------------------------------------
with the_Decode as
(
select 1 position, rownum row_num, ', max(decode(event_name,''' || event_name || ''', time_waited_micro, null)) ' 
|| translate(event_name, ' :&/*-()', '_') cmd
from
(
select event_name, count(1) numDays_top5, round(avg(total_wait_time)) avg_tot_Wait_time
from
(
select Day, Event_name, Total_wait_time from (
select day, event_name, sum(event_time_waited) total_wait_time,
row_number() over (partition by day order by sum(event_time_waited) desc) rn from (
SELECT   to_date(to_char(begin_interval_time,'dd/mm/yyyy'),'dd/mm/yyyy') day, s.begin_interval_time, m.*
    FROM (SELECT ee.instance_number, ee.snap_id, ee.event_name,
                 ROUND (ee.event_time_waited / 1000000) event_time_waited,
                 ee.total_waits,
                 ROUND ((ee.event_time_waited * 100) / et.total_time_waited,
                        1
                       ) pct,
                 ROUND ((ee.event_time_waited / ee.total_waits) / 1000
                       ) avg_wait
            FROM (SELECT ee1.instance_number, ee1.snap_id, ee1.event_name,
                           ee1.time_waited_micro
                         - ee2.time_waited_micro event_time_waited,
                         ee1.total_waits - ee2.total_waits total_waits
                    FROM dba_hist_system_event ee1 JOIN dba_hist_system_event ee2
                         ON ee1.snap_id = ee2.snap_id + 1
                       AND ee1.instance_number = ee2.instance_number
                       AND ee1.event_id = ee2.event_id
                    WHERE (ee1.dbid, ee1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
                       and (ee2.dbid, ee2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
                       AND ee1.wait_class_id <> 2723168908
                       AND ee1.time_waited_micro - ee2.time_waited_micro > 0
                       and ee1.snap_id between nvl(:start_snap_id, ee1.snap_id) and nvl(:end_snap_id, ee1.snap_id)
                       and ee2.snap_id between nvl(:start_snap_id, ee2.snap_id) and nvl(:end_snap_id, ee2.snap_id)
                  UNION
                  SELECT st1.instance_number, st1.snap_id,
                         st1.stat_name event_name,
                         st1.VALUE - st2.VALUE event_time_waited,
                         1 total_waits
                    FROM dba_hist_sys_time_model st1 JOIN dba_hist_sys_time_model st2
                         ON st1.instance_number = st2.instance_number
                       AND st1.snap_id = st2.snap_id + 1
                       AND st1.stat_id = st2.stat_id
                    WHERE (st1.dbid, st1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
                       and (st2.dbid, st2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
                       AND st1.stat_name = 'DB CPU'
                       AND st1.VALUE - st2.VALUE > 0
                       and st1.snap_id between nvl(:start_snap_id, st1.snap_id) and nvl(:end_snap_id, st1.snap_id)
                       and st2.snap_id between nvl(:start_snap_id , st2.snap_id)and nvl(:end_snap_id, st2.snap_id)
                         ) ee
                 JOIN
                 (SELECT et1.instance_number, et1.snap_id,
                         et1.VALUE - et2.VALUE total_time_waited
                    FROM dba_hist_sys_time_model et1 JOIN dba_hist_sys_time_model et2
                         ON et1.snap_id = et2.snap_id + 1
                       AND et1.instance_number = et2.instance_number
                       AND et1.stat_id = et2.stat_id
                    WHERE (et1.dbid, et1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
                       and (et2.dbid, et2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
                       AND et1.stat_name = 'DB time'
                       AND et1.VALUE - et2.VALUE > 0
                       and et1.snap_id between nvl(:start_snap_id, et1.snap_id) and nvl(:end_snap_id, et1.snap_id)
                       and et2.snap_id between nvl(:start_snap_id , et2.snap_id)and nvl(:end_snap_id, et2.snap_id)
                         ) et
                 ON ee.instance_number = et.instance_number
               AND ee.snap_id = et.snap_id
                 ) m
         JOIN
         dba_hist_snapshot s ON m.snap_id = s.snap_id
     WHERE (s.dbid, s.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
) group by day ,event_name
order by day desc, total_wait_time desc
)
where rn <= :top_n
)
group by event_name
order by 3 desc
)
where rownum <= :top_n
)
, the_in_list as
(
select 2 position, rownum row_num, ', ''' || event_name || '''' cmd
from
(
select event_name, count(1) numDays_top5, round(avg(total_wait_time)) avg_tot_Wait_time
from
(
select Day, Event_name, Total_wait_time from (
select day, event_name, sum(event_time_waited) total_wait_time,
row_number() over (partition by day order by sum(event_time_waited) desc) rn from (
SELECT   to_date(to_char(begin_interval_time,'dd/mm/yyyy'),'dd/mm/yyyy') day, s.begin_interval_time, m.*
    FROM (SELECT ee.instance_number, ee.snap_id, ee.event_name,
                 ROUND (ee.event_time_waited / 1000000) event_time_waited,
                 ee.total_waits,
                 ROUND ((ee.event_time_waited * 100) / et.total_time_waited,
                        1
                       ) pct,
                 ROUND ((ee.event_time_waited / ee.total_waits) / 1000
                       ) avg_wait
            FROM (SELECT ee1.instance_number, ee1.snap_id, ee1.event_name,
                           ee1.time_waited_micro
                         - ee2.time_waited_micro event_time_waited,
                         ee1.total_waits - ee2.total_waits total_waits
                    FROM dba_hist_system_event ee1 JOIN dba_hist_system_event ee2
                         ON ee1.snap_id = ee2.snap_id + 1
                       AND ee1.instance_number = ee2.instance_number
                       AND ee1.event_id = ee2.event_id
                    WHERE (ee1.dbid, ee1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
                       and (ee2.dbid, ee2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
                       AND ee1.wait_class_id <> 2723168908
                       AND ee1.time_waited_micro - ee2.time_waited_micro > 0
                       and ee1.snap_id between nvl(:start_snap_id, ee1.snap_id) and nvl(:end_snap_id, ee1.snap_id)
                       and ee2.snap_id between nvl(:start_snap_id , ee2.snap_id)and nvl(:end_snap_id, ee2.snap_id)
    UNION
                  SELECT st1.instance_number, st1.snap_id,
                         st1.stat_name event_name,
                         st1.VALUE - st2.VALUE event_time_waited,
                         1 total_waits
                    FROM dba_hist_sys_time_model st1 JOIN dba_hist_sys_time_model st2
                         ON st1.instance_number = st2.instance_number
                       AND st1.snap_id = st2.snap_id + 1
                       AND st1.stat_id = st2.stat_id
                    WHERE (st1.dbid, st1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
                       and (st2.dbid, st2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
                       AND st1.stat_name = 'DB CPU'
                       AND st1.VALUE - st2.VALUE > 0
                       and st1.snap_id between nvl(:start_snap_id, st1.snap_id) and nvl(:end_snap_id, st1.snap_id)
                       and st2.snap_id between nvl(:start_snap_id , st2.snap_id)and nvl(:end_snap_id, st2.snap_id)
                                 ) ee
                 JOIN
                 (SELECT et1.instance_number, et1.snap_id,
                         et1.VALUE - et2.VALUE total_time_waited
                    FROM dba_hist_sys_time_model et1 JOIN dba_hist_sys_time_model et2
                         ON et1.snap_id = et2.snap_id + 1
                       AND et1.instance_number = et2.instance_number
                       AND et1.stat_id = et2.stat_id
                    WHERE (et1.dbid, et1.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
                       and (et2.dbid, et2.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
                       AND et1.stat_name = 'DB time'
                       AND et1.VALUE - et2.VALUE > 0
                       and et1.snap_id between nvl(:start_snap_id, et1.snap_id) and nvl(:end_snap_id, et1.snap_id)
                       and et2.snap_id between nvl(:start_snap_id , et2.snap_id)and nvl(:end_snap_id, et2.snap_id)
                          ) et
                 ON ee.instance_number = et.instance_number
               AND ee.snap_id = et.snap_id
                 ) m
         JOIN
         dba_hist_snapshot s ON m.snap_id = s.snap_id
     WHERE (s.dbid, s.instance_number) = (select d.dbid, i.instance_number from v$database d, v$instance i)
) group by day ,event_name
order by day desc, total_wait_time desc
)
where rn <= :top_n
)
group by event_name
order by 3 desc
)
where rownum <= :top_n
)
select position, row_num, CMD from the_decode
union
select position, row_num, CMD from the_in_list
order by position, row_num
;


----------------
-- top 5 pivoted
----------------
Select snap_id
, max(decode(event_name,'DB CPU', time_waited_micro, null)) DB_CPU
, max(decode(event_name,'db file scattered read', time_waited_micro, null)) db_file_scattered_read
, max(decode(event_name,'db file sequential read', time_waited_micro, null)) db_file_sequential_read
, max(decode(event_name,'Backup: sbtwrite2', time_waited_micro, null)) Backup_sbtwrite2
, max(decode(event_name,'direct path write temp', time_waited_micro, null)) direct_path_write_temp
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
('db file scattered read', 'db file sequential read','Backup: sbtwrite2','direct path write temp')

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
)
group by snap_id
order by snap_id desc
;

-- top 10 pivoted:
-- -------------------------------------------------------------------------------
Select data.snap_id
, to_char(begin_interval_time, 'mm/dd/yyyy HH24') || ':00:00'  collection_time
, max(decode(event_name,'db file sequential read', time_waited_micro, null)) db_file_sequential_read
, max(decode(event_name,'DB CPU', time_waited_micro, null)) DB_CPU
, max(decode(event_name,'db file parallel write', time_waited_micro, null)) db_file_parallel_write
, max(decode(event_name,'enq: DX - contention', time_waited_micro, null)) enq_DX___contention
, max(decode(event_name,'log file parallel write', time_waited_micro, null)) log_file_parallel_write
, max(decode(event_name,'db file parallel read', time_waited_micro, null)) db_file_parallel_read
, max(decode(event_name,'enq: TX - row lock contention', time_waited_micro, null)) enq_TX___row_lock_contention
, max(decode(event_name,'direct path read', time_waited_micro, null)) direct_path_read
, max(decode(event_name,'db file scattered read', time_waited_micro, null)) db_file_scattered_read
, max(decode(event_name,'log file sync', time_waited_micro, null)) log_file_sync
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
('db file sequential read'
, 'DB CPU'
, 'db file parallel write'
, 'enq: DX - contention'
, 'log file parallel write'
, 'db file parallel read'
, 'enq: TX - row lock contention'
, 'direct path read'
, 'db file scattered read'
, 'log file sync')
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



---------
-- events
---------
select
       btime, event_name,
       (time_ms_end-time_ms_beg)/nullif(count_end-count_beg,0) avg_ms,
       (count_end-count_beg) ct
from (
select
       e.event_name,
       to_char(s.BEGIN_INTERVAL_TIME,'DD-MON-YY HH24:MI')  btime,
       total_waits count_end,
       time_waited_micro/1000 time_ms_end,
       Lag (e.time_waited_micro/1000)
              OVER( PARTITION BY e.event_name ORDER BY s.snap_id) time_ms_beg,
       Lag (e.total_waits)
              OVER( PARTITION BY e.event_name ORDER BY s.snap_id) count_beg
from
       DBA_HIST_SYSTEM_EVENT e,
       DBA_HIST_SNAPSHOT s
where
       s.snap_id=e.snap_id
   --and e.wait_class in ( 'User I/O', 'System I/O')
   -- and e.event_name in (  'db file sequential read',
   --                      'db file scattered read',
   --                      'db file parallel read',
   --                      'direct path read',
   --                      'direct path read temp',
   --                      'direct path write',
   --                     'direct path write temp')
   and e.event_name in (  'db file scattered read')
   and e.dbid=s.dbid
order by e.event_name, begin_interval_time
)
where (count_end-count_beg) > 0
order by btime desc, event_name
;
