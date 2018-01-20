
-------------------------------------------------------------
-- Lister les sessions actives par temps d'activité ordre DEC
-------------------------------------------------------------

select 
sid,username,
sql.sql_id,
FIRST_LOAD_TIME,
to_char(logon_time,'dd-mm-yy hh:mi:ss') "LOGON",
floor(last_call_et/3600)||':'||
floor(mod(last_call_et,3600)/60)||':'||
mod(mod(last_call_et,3600),60) "DUREE (hh:mm:ss)",
disk_reads,
buffer_gets,
wait_class,
state,
user_io_wait_time,
program,
sql_text
from 
v$session,
v$sql sql
where sql_hash_value = sql.hash_value
and sql_address = sql.address
and status = 'ACTIVE'
and type='USER'
and disk_reads > 0
and username not in ('SYS','SYSTEM','OEMPF','EIM_BATCH','REPRISE_PCOM','SADMIN')
order by last_call_et 
;




---------------------------------------------------------
-- Lister les sessions actives avec leur durée d'activité
---------------------------------------------------------

set echo off
set linesize 95
set head on
set feedback on
col sid head "Sid" form 9999 trunc
col serial# form 99999 trunc head "Ser#"
col username form a8 trunc
col osuser form a7 trunc
col machine form a20 trunc head "Client|Machine"
col program form a15 trunc head "Client|Program"
col login form a11
col "last call"  form 9999999 trunc head "Last Call|In Secs"
col status form a6 trunc

select sid,serial#,substr(username,1,10) username,substr(osuser,1,10) osuser,
	 substr(program||module,1,15) program,substr(machine,1,22) machine,
	 to_char(logon_time,'ddMon hh24:mi') login,
	 last_call_et "last call",status
from v$session where status='ACTIVE'
order by 1
/
                              Client          Client                           Last Call
  Sid   Ser# USERNAME OSUSER  Program         Machine              LOGIN         In Secs STATUS
----- ------ -------- ------- --------------- -------------------- ----------- --------- ------
    1      1          oracle  oracle@parva411 parva4119817         15Dec 13:31   8541663 ACTIVE
    2      1          oracle  oracle@parva411 parva4119817         15Dec 13:31   8541662 ACTIVE







-------------------------------------------------------------
-- Lister les sessions actives avec + de 2 heures d'activité
-------------------------------------------------------------

set linesize
select 
sid,username,
sql.sql_id,
FIRST_LOAD_TIME,
to_char(logon_time,'dd-mm-yy hh:mi:ss') "LOGON",
floor(last_call_et/3600)||':'||
floor(mod(last_call_et,3600)/60)||':'||
mod(mod(last_call_et,3600),60) "DUREE (hh:mm:ss)",
disk_reads,
buffer_gets,
wait_class,
state,
user_io_wait_time,
program
--,sql_text
from 
v$session,
v$sql sql
where sql_hash_value = sql.hash_value
and sql_address = sql.address
and status = 'ACTIVE'
and type='USER'
and disk_reads > 0
and last_call_et > 1000
and username not in ('SYS','SYSTEM','OEMPF','EIM_BATCH','REPRISE_PCOM','SADMIN')
order by last_call_et desc;


