


SELECT begin_interval_time,
  sql_id,
  event,
  cnt
FROM
  (SELECT begin_interval_time,
    sql_id,
    event,
    cnt,
    rank() over (partition BY begin_interval_time order by total_sql DESC) r,
    total_sql
  FROM
    (SELECT begin_interval_time,
      sql_id,
      DECODE(session_state,'WAITING',event,'ON CPU') event,
      COUNT(*) cnt,
      SUM(COUNT(*)) over (partition BY begin_interval_time,sql_id) total_sql
    FROM dba_hist_active_sess_history ash,
      dba_hist_snapshot d
    WHERE --program = 'xxxxxxxxx' and event = 'db file sequential read'
      ash.snap_id = d.snap_id
    AND sql_id   IS NOT NULL
    GROUP BY begin_interval_time,
      sql_id,
      DECODE(session_state,'WAITING',event,'ON CPU')
    HAVING COUNT(*) > 1
    ORDER BY begin_interval_time,
      cnt DESC
    )
  )
WHERE r < 10
ORDER BY begin_interval_time,
  r,
  cnt DESC;
