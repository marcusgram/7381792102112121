
select snap_id,
       Substr(begin_interval_time,1,15) as begintime,
       Substr(end_interval_time,1,15) as endtime
from dba_hist_snapshot order by 1,2,3
/



