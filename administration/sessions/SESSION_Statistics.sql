
--------------------------
--Session Stats By Session
--for all sessions
--------------------------

-SESSION STAT NOTES:
-Username - Name of the user
-SID - Session ID
-Statistic - Name of the statistic
-Usage - Usage according to Oracle

select  nvl(ss.USERNAME,'ORACLE PROC') username,
	se.SID,
	sn.NAME stastic,
	VALUE usage
from 	v$session ss, 
	v$sesstat se, 
	v$statname sn
where  	se.STATISTIC# = sn.STATISTIC#
and  	se.SID = ss.SID
and	se.VALUE > 0
order  	by sn.NAME, se.SID, se.VALUE desc
;



-----------------------------------------------------------------------------------
-- Description  : Displays current session-specific statistics
-- Requirements : Access to the V$ views.
-- --------------------------------------------------------------------------------
SET VERIFY OFF

SELECT sn.name, 
       ss.value
FROM   v$sesstat ss,
       v$statname sn,
       v$session s
WHERE  ss.statistic# = sn.statistic#
AND    s.sid = ss.sid
AND    s.audsid = SYS_CONTEXT('USERENV','SESSIONID')
AND    sn.name LIKE '%' || DECODE(LOWER('&1'), 'all', '', LOWER('&1')) || '%';



