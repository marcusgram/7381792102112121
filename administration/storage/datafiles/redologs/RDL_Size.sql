

-- Query to obtain redo generation per day.
SELECT    TO_CHAR(FIRST_TIME, 'DD-MON-YYYY') as "Date", SUM(blocks * block_size)/1024/1024/1024 as "Total Redo (GB)"
FROM      v$archived_log
WHERE     DEST_ID = 1
AND       FIRST_TIME > SYSDATE - interval '&days' day
GROUP BY  TO_CHAR(FIRST_TIME, 'DD-MON-YYYY')
ORDER BY  TO_DATE(TO_CHAR(FIRST_TIME, 'DD-MON-YYYY'));

-- Query to obtain redo generation per hour.
SET PAGESIZE 1000 LINESIZE 155
BREAK ON DAY SKIP 1
COMPUTE SUM LABEL 'TOTAL' AVG LABEL 'AVERAGE' OF "Total Redo (GB)" ON DAY
SELECT    TO_CHAR(FIRST_TIME, 'DD-MON-YYYY') as "Day", TO_CHAR(FIRST_TIME, 'HH24') as "Hour", SUM(blocks * block_size)/1024/1024/1024 as "Total Redo (GB)"
FROM      gv$archived_log
WHERE     DEST_ID = 1
AND       FIRST_TIME > SYSDATE - interval '&hours' hour
GROUP BY  TO_CHAR(FIRST_TIME, 'DD-MON-YYYY'), TO_CHAR(FIRST_TIME, 'HH24')
ORDER BY  TO_DATE(TO_CHAR(FIRST_TIME, 'DD-MON-YYYY')), TO_CHAR(FIRST_TIME, 'HH24');

-- Query to obtain redo generation per minute.
SET PAGESIZE 1000 LINESIZE 155
BREAK ON DAY SKIP 1
COMPUTE SUM LABEL 'TOTAL' AVG LABEL 'AVERAGE' OF "Total Redo (GB)" ON DAY
SELECT    TO_CHAR(FIRST_TIME, 'DD-MON-YYYY') as "Day", TO_CHAR(FIRST_TIME, 'HH24:MI') as "Hour", SUM(blocks * block_size)/1024/1024/1024 as "Total Redo (GB)"
FROM      gv$archived_log
WHERE     DEST_ID = 1
AND       FIRST_TIME > SYSDATE - interval '&hours' hour
GROUP BY  TO_CHAR(FIRST_TIME, 'DD-MON-YYYY'), TO_CHAR(FIRST_TIME, 'HH24:MI')
ORDER BY  TO_DATE(TO_CHAR(FIRST_TIME, 'DD-MON-YYYY')), TO_CHAR(FIRST_TIME, 'HH24:MI');

-- Query to obtain redo generation per sec.
SELECT    *
FROM      (
          SELECT    begin_time, end_time, value/1024/1024 "REDO (MB)"
          FROM      dba_hist_sysmetric_history
          WHERE     metric_name = 'Redo Generated Per Sec'
          UNION
          SELECT    begin_time, end_time, value/1024/1024 "REDO (MB)"
          FROM      v$sysmetric_history
          WHERE     metric_name = 'Redo Generated Per Sec'
          ORDER BY  begin_time
          )
WHERE     begin_time > SYSDATE - interval '&mins' minute;
