------------------------------------------------------------------------------------
-- Max sessions connected since the database startup
-- You can find the maximum number of sessions connected since the database startup
-- V$LICENSE B, 
-- V$DATABASE C;
------------------------------------------------------------------------------------


SELECT RPAD(C.NAME||':',11)||RPAD(' current logons='||
   (TO_NUMBER(B.SESSIONS_CURRENT)),20)||'  maximum connected='||
   B.SESSIONS_HIGHWATER INFORMATION 
   FROM V$LICENSE B, V$DATABASE C;



--Tip: If you want to keep the complete history of max sessions connected to your database you can create a BEFORE SHUTDOWN ON DATABASE trigger and store the value SELECT B.SESSIONS_HIGHWATER FROM V$LICENSE B; to a table. 
--But on shutdown abort the trigger it won't work!
