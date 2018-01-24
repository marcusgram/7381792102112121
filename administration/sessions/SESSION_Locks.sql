SELECT
  p.spid unix_pid,
  c.sid,
  c.serial# "Serial",
  NVL( lockwait, 'ACTIVE') "Wait",
  Substr(object_name,1,20) "Object",
  object_type "Object Type",
  Substr(owner,1,10) "Owner",
  DECODE( locked_mode,2,'Row Share',
                      3,'Row Exclusive',
                      4,'Share',
                      5,'Share Row Exclusive',
                      6,'Exclusive', 'Unknown') "Lock Mode",
--  Substr(oracle_username,1,10) "Locker",
--  program "Program",
  os_user_name "OS Username"
FROM v$locked_object a, all_objects b, v$session c, v$process p
WHERE a.object_id = b.object_id
  AND c.sid       = a.session_id
  AND c.paddr     = p.addr(+)
  AND c.sid       = &sid
ORDER BY Substr(owner,1,10) ASC,
         Substr(object_name,1,20) ASC,
         NVL( lockwait, 'ACTIVE') DESC
/




column lock_type format a12
column mode_held format a10
column mode_requested format a10
column blocking_others format a20
column username format a10
SELECT	session_id
,	lock_type
,	mode_held
,	mode_requested
,	blocking_others
,	lock_id1
FROM	dba_lock l
WHERE 	lock_type NOT IN ('Media Recovery', 'Redo Thread')
/
