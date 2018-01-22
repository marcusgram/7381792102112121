


SELECT TO_CHAR(TRUNC(begin_interval_time, 'DD'),'YYYY-MM-DD') DAY ,
  SUM(elapsed_time_delta) elapsed_time ,
  SUM(CPU_TIME_DELTA) CPU_TIME ,
  SUM(iowait_delta) IOWAIT
FROM dba_hist_sqlstat stat,
  dba_hist_snapshot snap
WHERE sql_id     = :sql_id
AND snap.snap_id = stat.snap_id
GROUP BY TO_CHAR(TRUNC(begin_interval_time, 'DD'),'YYY-MM-DD')
ORDER BY 1;


