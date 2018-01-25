

/* Modifying Snapshot Settings :

-- Basic Settings:
INTERVAL affects how often in minutes that snapshots are automatically
generated.

RETENTION affects how long in minutes that snapshots are stored in the
workload repository.

TOPNSQL affects the number of Top SQL to flush for each SQL criteria
(Elapsed Time, CPU Time, Parse Calls, Shareable Memory, and Version Count).

The value for this setting will not be affected by the statistics/flush level and will
override the system default behaviour for the AWR SQL collection.
*/

-------------------------------------------
-- View the current AWR retention settings:
-------------------------------------------
SELECT * FROM dba_hist_wr_control;

      DBID SNAP_INTERV RETENTION   TOPNSQL  
---------- ----------- ----------- ----------
 345719047 0 1:0:0.0   90 0:0:0.0  DEFAULT   
2708337181 0 1:0:0.0   8 0:0:0.0   DEFAULT 


----------------------------------------------------------
--To adjust the settings, use the MODIFY_SNAPSHOT_SETTINGS
----------------------------------------------------------
BEGIN
DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS
(retention => 43200,
interval => 10,
topnsql => 50);
END;
/

/* In this example, the retention period is specified as 43200 minutes 
(30 days), the interval between each snapshot is specified as 10 minutes,
and the number of Top SQL to flush for each SQL criteria as 50. */



-----------------------------------------------------
-- Create baseline, save the data for future analysis
-----------------------------------------------------
exec dbms_workload_repository.create_baseline (start_snap_id => 1003, end_snap_id => 1013,baseline_name => 'baseline_OCT10');

--To see stored baselines use dba_hist_baseline view
 
--------------------------------------------------
--Export AWR data and Import to different database
-------------------------------------------------- 
exec DBMS_SWRF_INTERNAL.AWR_EXTRACT (dmpfile=> awr_data.dmp', mpdir => 'DIR_BDUMP', bid => 1003, eid => 1013);
exec DBMS_SWRF_INTERNAL.AWR_LOAD (SCHNAME => 'AWR_TEST', dmpfile => 'awr_data.dmp',dmpdir => 'DIR_BDUMP');
