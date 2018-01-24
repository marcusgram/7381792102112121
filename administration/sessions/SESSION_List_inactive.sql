
select s.sid, s.serial#, s.username, s.status, s.terminal, t.start_time
 from v$session s, v$transaction t
 where s.taddr = t.addr
 and   s.username is not null
 and   s.username not in ('SYS', 'SYSTEM')
 and   s.status  = 'INACTIVE'
 and   (sysdate - s.last_call_et / 86400) < sysdate-1/48
 and   exists (select null from v$locked_object lo where s.sid = lo.session_id)
 and   to_date(t.start_time, 'mm/dd/yy hh24:mi:ss') < sysdate-1/48
/
