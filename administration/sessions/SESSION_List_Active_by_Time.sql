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
