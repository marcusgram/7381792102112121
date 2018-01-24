-------------------------------------
-- get waits event on active sessions
-------------------------------------
column sid format 99999
column username format a20
column serial format 999999
column hash_value format 9999999999999
column event format a25
column p1 format 9999999999999
column p2 format 9999999999
column p3 format 999999
select s.sid sid,
       s.serial# serial,
       nvl(s.username,s.program) username,
       s.terminal,
       s.sql_hash_value hash_value,
       substr(decode(w.wait_time,
                     0, w.event,
                     'ON CPU'),1,25) event ,
       w.p1 p1,
       w.p2 p2,
       w.p3 p3
from v$session s,
v$session_wait w
where w.sid=s.sid
  and s.status='ACTIVE'
  and s.type='USER'
order by 1,2,3
/
