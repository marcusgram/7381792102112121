REM:**********************************************************************************************
REM: Script : Undo Informations
REM: Author: Kumar Menon
REM: Date Submitted: 16-July-2009
REM:FileName: Undoinfo.sql
REM:
REM: NOTE: PLEASE TEST THIS SCRIPT BEFORE USE.
REM: Author will not be responsible for any damage that may be cause by this script.
****************************************************************************************************


spool d:\\undoinfo.txt
SELECT (UR * (UPS * DBS)) + (DBS * 24) AS \"Bytes\" 
FROM (SELECT value AS UR FROM v$parameter WHERE name = 'undo_retention'), 
(SELECT (SUM(undoblks)/SUM(((end_time - begin_time)*86400))) AS UPS FROM v$undostat), 
(SELECT value AS DBS FROM v$parameter WHERE name = 'db_block_size') ;

SELECT r.name rbs, 
NVL(s.username, 'None') oracle_user, 
s.osuser client_user, 
p.username unix_user, 
TO_CHAR(s.sid)||','||TO_CHAR(s.serial#) as sid_serial, 
p.spid unix_pid, 
t.used_ublk * TO_NUMBER(x.value)/1024 as undo_kb 
FROM v$process p, 
v$rollname r, 
v$session s, 
v$transaction t, 
v$parameter x 
WHERE s.taddr = t.addr 
AND s.paddr = p.addr(+) 
AND r.usn = t.xidusn(+) 
AND x.name = 'db_block_size' 
ORDER 
BY r.name ; 

select l.sid, s.segment_name from dba_rollback_segs s, v$transaction t, v$lock l 
where t.xidusn=s.segment_id and t.addr=l.addr ;
select to_char(begin_time,'hh24:mi:ss'),to_char(end_time,'hh24:mi:ss') 
, maxquerylen,ssolderrcnt,nospaceerrcnt,undoblks,txncount from v$undostat 
order by undoblks ;
set lines 160 pages 40 
col machine format A20 
col username format A15 
select xidusn, xidslot, trans.status, start_time, ses.sid, ses.username, ses.machine ,proc.spid, used_ublk 
from v$transaction trans, v$session ses , v$process proc 
where trans.ses_addr =ses.saddr and ses.paddr=proc.addr 
order by start_time ;

select to_char(begin_time,'hh24:mi:ss'),to_char(end_time,'hh24:mi:ss') 
, maxquerylen,ssolderrcnt,nospaceerrcnt,undoblks,txncount from v$undostat 
order by undoblks ;
Promot \"following to show how much undo is being used:\"

set pagesize 24 
set lin 132 
set verify off 
col owner format a13 
col segment_name format a25 heading 'Segment Name' 
col segment_type format a15 heading 'Segment Type' 
col tablespace_name format a15 heading 'Tablespace Name' 
col extents format 99999999 heading 'Extent' 
select 
owner, segment_name, segment_type, tablespace_name, 
(bytes / 1048576) \"Mbytes\", 
extents 
from sys.dba_segments 
where tablespace_name = '&UNDO01' 
order by owner, segment_name ;

spool off
