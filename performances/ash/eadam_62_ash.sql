-- Reports ASH aggregates for range of snaps

SET FEED OFF VER OFF LIN 2000 PAGES 50000 TIMI OFF LONG 40000 LONGC 200 TRIMS ON AUTOT OFF;
SET TERM ON ECHO OFF;
COL dbname FOR A12;
COL db_unk_name FOR A12;
COL platform_name FOR A21;
COL instance_name FOR A16;
COL host_name FOR A30;
COL version FOR A10;
COL capture_time FOR A14;
SELECT LPAD(eadam_seq_id, 4, '0') eadam,
       LPAD(eadam_seq_id_1, 4, '0') src1,
       LPAD(eadam_seq_id_2, 4, '0') src2,
       dbname,
       db_unique_name db_unk_name,
       platform_name,
       instance_name,
       host_name,
       version,
       capture_time
  FROM dba_hist_xtr_control_s
 ORDER BY 1;
PRO
PRO Parameter 1:
PRO EADAM_SEQ_ID:
PRO
DEF eadam_seq_id = '&1';
PRO
SPO eadam_snapshots.txt;
SELECT snap_id,
       TO_CHAR(MIN(begin_interval_time), 'YYYY-MM-DD HH24:MI')||' to '||
       TO_CHAR(MIN(end_interval_time), 'HH24:MI') begin_to_end
  FROM dba_hist_snapshot_s
 WHERE eadam_seq_id = &&eadam_seq_id.
 GROUP BY
       snap_id
 ORDER BY
       snap_id;
SPO OFF;
PRO
PRO Parameter 2:
PRO SNAP_ID_FROM:
PRO
DEF snap_id_0 = '&2';
PRO
PRO Parameter 3:
PRO SNAP_ID_TO:
PRO
DEF snap_id_1 = '&3';
PRO
PRO Parameter 4:
PRO Instance Number (opt):
PRO
DEF instance_nbr = '&4';
PRO
VAR instance_nbr NUMBER;
EXEC :instance_nbr := TO_NUMBER(TRIM('&&instance_nbr.'));
PRO
COL samples FOR 999,999,999,999,999
COL state FOR A7;
COL wait_class FOR A14;
COL event FOR A40;
SELECT COUNT(*) samples,
       session_state state
  FROM dba_hist_active_sess_hist_s
 WHERE eadam_seq_id = &&eadam_seq_id. 
   AND snap_id BETWEEN &&snap_id_0. AND &&snap_id_1.
   AND instance_number = NVL(TO_NUMBER(TRIM('&&instance_nbr.')), instance_number)
 GROUP BY
       session_state
 ORDER BY
       session_state;

SPO eadam_ash_&&eadam_seq_id._&&snap_id_0._&&snap_id_1..txt

SELECT MIN(begin_interval_time) begin_interval_time
  FROM dba_hist_snapshot_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND snap_id = &&snap_id_0.
   AND instance_number = NVL(TO_NUMBER(TRIM('&&instance_nbr.')), instance_number);
   
SELECT MIN(end_interval_time) end_interval_time
  FROM dba_hist_snapshot_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND snap_id = &&snap_id_1.
   AND instance_number = NVL(TO_NUMBER(TRIM('&&instance_nbr.')), instance_number);

COL total_samples NEW_V total_samples FOR 999,999,999,999,999;
SELECT COUNT(*) total_samples
  FROM dba_hist_active_sess_hist_s
 WHERE eadam_seq_id = &&eadam_seq_id.
   AND snap_id BETWEEN &&snap_id_0. AND &&snap_id_1.
   AND instance_number = NVL(TO_NUMBER(TRIM('&&instance_nbr.')), instance_number);

PRO
PRO DBA_HIST_ACTIVE_SESS_HISTORY (rollup by session_state, wait_class and event)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET PAGES 50000;
COL samples FOR 999,999,999,999,999;
COL percent FOR A10;
COL state FOR A7;
COL wait_class FOR A14;
COL event FOR A70;
COL total FOR A17;
SELECT --GROUPING(session_state), GROUPING(wait_class), GROUPING(event),
       COUNT(*) samples,
       TO_CHAR(ROUND(COUNT(*) * 100 / &&total_samples., 1), '9,990.0')||' %' percent,
       CASE 
       WHEN GROUPING(session_state) = 1 THEN 'Total'
       WHEN GROUPING(wait_class) = 1 THEN '  Sub Total'
       WHEN GROUPING(event) = 1 THEN '    Sub Sub Total'
       END total,
       session_state state, wait_class, event
  FROM dba_hist_active_sess_hist_s
 WHERE eadam_seq_id = &&eadam_seq_id. 
   AND snap_id BETWEEN &&snap_id_0. AND &&snap_id_1.
   AND instance_number = NVL(TO_NUMBER(TRIM('&&instance_nbr.')), instance_number)
 GROUP BY
       ROLLUP(session_state, wait_class, event)
HAVING COUNT(*) * 100 / &&total_samples. > 0.05
   AND (session_state = 'WAITING' OR GROUPING(wait_class) = 1);

PRO
PRO DBA_HIST_ACTIVE_SESS_HISTORY (group by operation)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SET PAGES 50;
COL operation FOR A40;
SELECT COUNT(*) samples,
       TO_CHAR(ROUND(COUNT(*) * 100 / &&total_samples., 1), '9,990.0')||' %' percent,
       SUBSTR(sql_plan_operation||' '||sql_plan_options, 1, 40) operation
  FROM dba_hist_active_sess_hist_s
 WHERE eadam_seq_id = &&eadam_seq_id. 
   AND snap_id BETWEEN &&snap_id_0. AND &&snap_id_1.
   AND instance_number = NVL(TO_NUMBER(TRIM('&&instance_nbr.')), instance_number)
   AND sql_plan_operation IS NOT NULL
 GROUP BY
       sql_plan_operation,
       sql_plan_options
HAVING COUNT(*) * 100 / &&total_samples. > 0.05
 ORDER BY
       sql_plan_operation,
       sql_plan_options;

PRO
PRO DBA_HIST_ACTIVE_SESS_HISTORY (group by operation and session_state)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COL session_state FOR A13;
SELECT COUNT(*) samples,
       TO_CHAR(ROUND(COUNT(*) * 100 / &&total_samples., 1), '9,990.0')||' %' percent,
       SUBSTR(sql_plan_operation||' '||sql_plan_options, 1, 40) operation,
       session_state
  FROM dba_hist_active_sess_hist_s
 WHERE eadam_seq_id = &&eadam_seq_id. 
   AND snap_id BETWEEN &&snap_id_0. AND &&snap_id_1.
   AND instance_number = NVL(TO_NUMBER(TRIM('&&instance_nbr.')), instance_number)
   AND sql_plan_operation IS NOT NULL
 GROUP BY
       sql_plan_operation,
       sql_plan_options,
       session_state 
HAVING COUNT(*) * 100 / &&total_samples. > 0.05
 ORDER BY
       sql_plan_operation,
       sql_plan_options,
       session_state;

PRO
PRO DBA_HIST_ACTIVE_SESS_HISTORY (group by operation, session_state and wait_class)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COL wait_class FOR A24;
SELECT COUNT(*) samples,
       TO_CHAR(ROUND(COUNT(*) * 100 / &&total_samples., 1), '9,990.0')||' %' percent,
       SUBSTR(sql_plan_operation||' '||sql_plan_options, 1, 40) operation,
       session_state||' '||wait_class wait_class
  FROM dba_hist_active_sess_hist_s
 WHERE eadam_seq_id = &&eadam_seq_id. 
   AND snap_id BETWEEN &&snap_id_0. AND &&snap_id_1.
   AND instance_number = NVL(TO_NUMBER(TRIM('&&instance_nbr.')), instance_number)
   AND sql_plan_operation IS NOT NULL
 GROUP BY
       sql_plan_operation,
       sql_plan_options,
       session_state, 
       wait_class
HAVING COUNT(*) * 100 / &&total_samples. > 0.05
 ORDER BY
       sql_plan_operation,
       sql_plan_options,
       session_state, 
       wait_class;

PRO
PRO DBA_HIST_ACTIVE_SESS_HISTORY (group by operation, session_state, wait_class and event)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COL event FOR A70;
SELECT COUNT(*) samples,       
       TO_CHAR(ROUND(COUNT(*) * 100 / &&total_samples., 1), '9,990.0')||' %' percent,
       SUBSTR(sql_plan_operation||' '||sql_plan_options, 1, 40) operation,
       session_state||' '||wait_class||' '||
       CASE WHEN event IS NOT NULL THEN '"'||event||'"' END event
  FROM dba_hist_active_sess_hist_s
 WHERE eadam_seq_id = &&eadam_seq_id. 
   AND snap_id BETWEEN &&snap_id_0. AND &&snap_id_1.
   AND instance_number = NVL(TO_NUMBER(TRIM('&&instance_nbr.')), instance_number)
   AND sql_plan_operation IS NOT NULL
 GROUP BY
       sql_plan_operation,
       sql_plan_options,
       session_state, 
       wait_class, 
       event
HAVING COUNT(*) * 100 / &&total_samples. > 0.05
 ORDER BY
       sql_plan_operation,
       sql_plan_options,
       session_state, 
       wait_class, 
       event;

PRO
PRO DBA_HIST_ACTIVE_SESS_HISTORY I/O waits (group by operation, wait_class, event and obj#)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT COUNT(*) samples,
       TO_CHAR(ROUND(COUNT(*) * 100 / &&total_samples., 1), '9,990.0')||' %' percent,
       SUBSTR(sql_plan_operation||' '||sql_plan_options, 1, 40) operation,
       SUBSTR(wait_class||' '||
       CASE WHEN event IS NOT NULL THEN '"'||event||'"' END, 1, 60) event,
       current_obj#
  FROM dba_hist_active_sess_hist_s
 WHERE eadam_seq_id = &&eadam_seq_id. 
   AND snap_id BETWEEN &&snap_id_0. AND &&snap_id_1.
   AND instance_number = NVL(TO_NUMBER(TRIM('&&instance_nbr.')), instance_number)
   AND sql_plan_operation IS NOT NULL
   AND session_state = 'WAITING'
   AND wait_class IN ('Application', 'Cluster', 'Concurrency', 'User I/O')
   AND current_obj# IS NOT NULL
 GROUP BY
       sql_plan_operation,
       sql_plan_options,
       wait_class, 
       event,
       current_obj#
HAVING COUNT(*) * 100 / &&total_samples. > 0.05
 ORDER BY
       sql_plan_operation,
       sql_plan_options,
       wait_class, 
       event,
       current_obj#;

SPO OFF;
UNDEF 1 2 3 4

