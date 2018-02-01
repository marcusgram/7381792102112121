

set tab off
set verify off
set linesize 300
set trimspool on
set serveroutput on

select dbid, instance_number, 
        min(snap_id) First_Snap_Id, 
        to_char(min(begin_interval_time),'DD-Mon-YYYY HH24:MI:SS') begin_interval_time,
        max(snap_id) Last_Snap_Id, 
        to_char(max(begin_interval_time),'DD-Mon-YYYY HH24:MI:SS') begin_interval_time
from	dba_hist_snapshot
group by dbid, instance_number
order by 1,2,3
/

prompt
accept dbid 	prompt 	"ENTER the database ID (DBID)                                : "
accept instnum	prompt	"ENTER the instance number                                   : "
accept DTmin	prompt	"ENTER the approximate starting date/hour (DD-Mon-YYYY HH24) : "
accept DTmax	prompt	"ENTER the approximate ending   date/hour (DD-Mon-YYYY HH24) : "

select	snap_id,
		to_char(begin_interval_time,'DD-Mon-YYYY HH24:MI:SS'),
		to_char(end_interval_time,'DD-Mon-YYYY HH24:MI:SS')		
from	dba_hist_snapshot snap
where	dbid            = &dbid
  and	instance_number = &instnum
  and	begin_interval_time >= to_date('&DTmin','DD-Mon-YYYY HH24') - INTERVAL '1' HOUR
  and	end_interval_time   <= to_date('&DTmax','DD-Mon-YYYY HH24') + INTERVAL '1' HOUR
order by 1
/

accept snap_start prompt "ENTER the beginning snap_id                 : "
accept snap_end   prompt "ENTER the ending    snap_id                 : "
