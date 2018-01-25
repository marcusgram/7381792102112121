
select snap_id,
       Substr(begin_interval_time,1,15) as begintime,
       Substr(end_interval_time,1,15) as endtime
from dba_hist_snapshot order by 1,2,3
/


SNAP_ID BEGINTIME       ENDTIME       
---------- --------------- ---------------
     48071 15/01/18 21:00: 15/01/18 22:00:
     48072 15/01/18 22:00: 15/01/18 23:00:
     48073 15/01/18 23:00: 16/01/18 00:00:
     48074 16/01/18 00:53: 16/01/18 01:04:
     48075 16/01/18 01:04: 16/01/18 02:00:
     48076 16/01/18 02:00: 16/01/18 03:00:
     48077 16/01/18 03:00: 16/01/18 04:00:
     48078 16/01/18 04:00: 16/01/18 05:00:


---------------------------------------------------------------
-- List AWR snapshots for specified number of days by instance
---------------------------------------------------------------

col start_time for a30
col end_time for a30

accept p_inst number default 1 prompt 'Instance Number (default 1)     : '
accept p_days number default 7 prompt 'Report Interval (default 7 days): '

	select snap_id,  
		   case when (startup_time = prev_startup_time) or rownum = 1 then '' 
			   else 'Database bounce' end as bounce,
		   start_time, replace(end_time-start_time,'+000000000 ','') duration, snap_level
	from (
	select snap_id, s.instance_number, begin_interval_time start_time, 
		   end_interval_time end_time, snap_level, flush_elapsed,
		   lag(s.startup_time) over (partition by s.dbid, s.instance_number 
		   					   order by s.snap_id) prev_startup_time,
		   s.startup_time
	from  dba_hist_snapshot s, v$instance i
	where begin_interval_time between sysdate-&p_days and sysdate 
	and   s.instance_number = i.instance_number
	and   s.instance_number = &p_inst
	order by snap_id
	)
	order by snap_id, start_time ;

clear columns
clear breaks
undef p_inst
undef p_days



  SNAP_ID BOUNCE          START_TIME                     DURATION                 SNAP_LEVEL
---------- --------------- ------------------------------ ------------------------ ----------
      2058                 18/01/18 10:00:39,123000000    01:00:03.098                      1
      2059                 18/01/18 11:00:42,221000000    01:00:02.855                      1
      2060                 18/01/18 12:00:45,076000000    01:00:02.809                      1
      2061                 18/01/18 13:00:47,885000000    01:00:02.712                      1
      2062                 18/01/18 14:00:50,597000000    01:00:02.733                      1
      2063                 18/01/18 15:00:53,330000000    01:00:02.511                      1
      2064                 18/01/18 16:00:55,841000000    01:00:02.726                      1
