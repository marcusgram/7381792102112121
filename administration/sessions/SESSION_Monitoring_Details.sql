
----------------------------------------------------------------------------------------------------------------
--A simple way to monitor sessions in database. I choose those specific columns by experience, follow below why. 
--Column explanation 
--LOGON: It is formatted on Days + 01:20:45 (1 hour, 20 mins and 45 secs). I like to have a feeling with a glimpse of how much time this session is running. 
--SID: All sessions have the session id. 
--SPID: It is the UNIX process id. In case you want to kill the process: $>kill -9 spid 
--CLPRID: It is the client process id that created the session, for example the process id of a form in the operating system where the form is running! If the client comes from a window OS is something like that 3812:1808 
--USERNAME, STATUS, OSUSER, MACHINE, PROGRAM, MODULE: Are self explanatory. 
--ACTION: In Oracle E-Business Suite it is the Form and login name of users 
--SQL_HASH_VALUE: We will need it when start tuning session sql 
--KILL_SQL: And last but very common. The sql statement for killing session already formatted.
---------------------------------------------------------------------------------------------------------------



SELECT DECODE(TRUNC(SYSDATE - LOGON_TIME), 0, NULL, TRUNC(SYSDATE - LOGON_TIME) || ' Days' || ' + ') ||
TO_CHAR(TO_DATE(TRUNC(MOD(SYSDATE-LOGON_TIME,1) * 86400), 'SSSSS'), 'HH24:MI:SS') LOGON,
v$session.SID, v$session.SERIAL#, v$process.SPID spid, v$session.process CLPRID,
v$session.USERNAME, STATUS, OSUSER, MACHINE, v$session.PROGRAM, MODULE, action, SQL_HASH_VALUE,
'alter system kill session ' || '''' || v$session.SID || ', ' || v$session.SERIAL# || '''' || ' immediate;' kill_sql
FROM v$session, v$process
WHERE v$session.paddr = v$process.addr
--AND v$process.spid = 23832
--and v$session.process = '26432'
--AND v$session.status = 'INACTIVE'
--AND v$session.username LIKE '%KAPARELIS SPYROS%'
--AND v$session.SID = 11369
--and v$session.sid in (select sid from v$session where SADDR in (select session_addr from v$sort_usage)) --(v$temp_usage)
--and v$session.osuser like 'oracle%'
--and osuser='uidea'
--AND v$session.module LIKE '%qot%'
--and v$session.machine like '%PLHROFORIK92%'
--AND v$session.program LIKE '%QMN%'
--AND v$session.action LIKE 'FRM%'
--and action like 'INS%'
ORDER BY logon_time ASC;


