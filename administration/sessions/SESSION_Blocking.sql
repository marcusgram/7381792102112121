--------------------------------------------------------------------------------------
--query to get list of blocking sessions with BLOCKER, WAITER and OBJECT being blocked:
--It works on Single Instance and RAC set-up as well.
---------------------------------------------------------------------------------------

col blk_sess format a11
col wtr_sess format a11
col blocker format a10
col waiter format a10

select /*+ rule */
a.inst_id ||',' || a.sid || ',' || a.serial# blk_sess,
a.username blocker,
h.type,
b.inst_id||','||b.sid || ',' || b.serial# wtr_sess,
b.username waiter,
o.owner || '.' || o.object_name ||
nvl2 (subobject_name, '.' || subobject_name, null) blocked_object,
lpad (to_char (trunc (w.ctime / 3600)), 3, '0') || ':' ||
lpad (to_char (mod (trunc (w.ctime / 60), 60)), 2, '0') || ':' ||
lpad (to_char (mod (w.ctime, 60)), 2, '0') duration
from gv$lock h, gv$lock w, gv$session a, gv$session b, dba_objects o
where h.block != 0
and h.lmode != 0
and h.lmode != 1
and w.request != 0
and w.id1 = h.id1
and w.id2 = h.id2
and h.sid = a.sid
and w.sid = b.sid and h.inst_id = a.inst_id
and decode (w.type, 'TX', b.row_wait_obj#, 'TM', w.id1)= o.object_id
order by w.ctime desc;



----------------------------------------------
-- query to find out blocking in the database
----------------------------------------------
SELECT l1.sid
  || ' is blocking '
  || l2.sid blocking_sessions
FROM v$lock l1,
  v$lock l2
WHERE l1.block = 1
AND l2.request > 0
AND l1.id1     = l2.id1
AND l1.id2     = l2.id2;





---------------------------------------------------------------
-- To get limited information on blocking sessions you can use:
---------------------------------------------------------------

SELECT s1.username
  || '@'
  || s1.machine
  || ' ( SID='
  || s1.sid
  || ' ) is blocking '
  || s2.username
  || '@'
  || s2.machine
  || ' ( SID='
  || s2.sid
  || ' ) ' AS blocking_status
FROM v$lock l1,
  v$session s1,
  v$lock l2,
  v$session s2
WHERE s1.sid   =l1.sid
AND s2.sid     =l2.sid
AND l1.BLOCK   =1
AND l2.request > 0
AND l1.id1     = l2.id1
AND l1.id2     = l2.id2 ;

