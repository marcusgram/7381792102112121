

#Add the following parameter to the init.ora file:
---------------------------------------------------

audit_trail=DB

#The database needs to be shutdown and started up again for the parameter to be read.
#Enable Connection Auditing

#The next step is to enable the auditing of the connections.  

#Using sqlplus connect as sysdba and issue the following command.
#---------------------------------------------------------------
audit connect;


The audit trail should now log every logon and logoff to the database 
#Querying the Audit Trail
-------------------------
The connection audit trial can be queried via the dba_audit_sessions view, 
which also contains session auditing if audit session is enabled. Below are a couple of basic query examples. 
The return code column has a value of 0 for successful connects, otherwise the logon attempt was unsuccessful.

#Count of Connects by User in the Last Week
#-------------------------------------------
SELECT das.username,
       COUNT(*) logonCount
  FROM sys.dba_audit_session das
 WHERE das.timeStamp > SYSDATE-7
   AND das.returnCode = 0
 GROUP BY das.username;
 
 
#Number of Minutes Connected By User in the Last Week
#----------------------------------------------------
SELECT das.username,
       ROUND(SUM((NVL(das.logoff_time,SYSDATE)-das.timestamp)*1440)) connectMins
  FROM sys.dba_audit_session das
 WHERE das.timeStamp > SYSDATE-7
   AND das.returnCode = 0
 GROUP BY das.username;
 
#Unsuccessful Logon Attempts in the Last Week
#--------------------------------------------
SELECT das.username,
       das.os_username,
       das.terminal,
       TO_CHAR(das.timeStamp,'DD Mon YYYY HH24:MI') timestamp,
       das.returnCode
  FROM sys.dba_audit_session das
 WHERE das.timeStamp > SYSDATE-7
   AND das.returnCode != 0;
   
   
#Connections Made Out Of Working Hours in the Last Week
#------------------------------------------------------
SELECT das.username,
       TO_CHAR(das.timestamp,'DD Mon YYYY HH24:MI:SS')   logontime,
       TO_CHAR(das.logoff_time,'DD Mon YYYY HH24:MI:SS') logofftime
  FROM sys.dba_audit_session das
 WHERE das.timeStamp > SYSDATE-7
   AND das.returnCode = 0
   AND NOT (    TO_NUMBER(TO_CHAR(das.timestamp,'D')) < 6 
            AND TO_NUMBER(TO_CHAR(das.timestamp,'HH24MI')) BETWEEN 800 AND 1800 )
 ORDER BY das.username;
