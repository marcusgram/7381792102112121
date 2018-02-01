

-- ********************************************************************
-- * Copyright Notice   : (c)1999 OraPub, Inc.
-- * Filename		: rlog.sql - Redo logging activity
-- * Author		: Craig A. Shallahamer
-- * Original		: 09-dec-99
-- * Last Update	: 09-dec-99
-- * Description	: Redo logging activity
-- * Usage		: start rlog.sql
-- ********************************************************************

def osm_prog	= 'rlog.sql'
def osm_title	= 'Redo Log Activity'
--start osmtitle

col seq  format 999999 heading 'Log|Seq #'
col grp  format    999 heading 'Group #'
col arch format a10    heading 'Archived?'
col stat format a10    heading 'Status'
col ti   format a8    heading 'Wr Start'
col dur  format 990.00 heading 'Lst Log|Swtch Dur'

select  a.sequence# seq,
        a.group# grp,
        a.archived arch,
        a.status stat,
        to_char(a.first_time,'HH24:MI:SS') ti,
        (a.first_time-b.first_time)*(24*60) dur
from    v$log a,
        v$log b
where   a.sequence# = b.sequence# + 1
order by 1;

--start osmclear
