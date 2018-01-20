
----------------------------------------------------------------------------------------------------
--Required privileges to allow users to kill a session. 
--Description
--What privileges are required so that a user can view and kill a session in DBA | Kill/Trace Session
----------------------------------------------------------------------------------------------------

-- Required object grants:
 GRANT SELECT ON sys.v_$sess_io TO <username>;
 GRANT SELECT ON sys.v_$session TO <username>;
 GRANT SELECT ON sys.v_$transaction TO <username>;
 GRANT SELECT ON sys.v_$rollname TO <username>;
 GRANT SELECT ON sys.V$open_cursor TO <username>;
 GRANT SELECT ON sys.v_$process TO <username>;
 GRANT SELECT ON sys.v$lock TO <username>;
 GRANT SELECT ON sys.v$Locked_object TO <username>;
 GRANT SELECT ON sys.v$sqltext_with_newlines TO <username>;
 GRANT SELECT ON sys.v_$transaction TO <username>;

-- Required system grants:
 GRANT ALTER SESSION TO <username>;
 GRANT ALTER SYSTEM FROM <username>;




-----------------------------
-- identifier les sessions 
-----------------------------
 COLUMN inst_id FORMAT 9999
 COLUMN sid FORMAT 9999
 COLUMN serial# FORMAT 9999999
 COLUMN spid FORMAT 9999
 COLUMN username FORMAT A10
 COLUMN program FORMAT A30
 SET LINESIZE 150
 SELECT s.inst_id,
             s.sid,
             s.serial#,
             p.spid,
             s.username,
             s.program
      FROM   gv$session s
             JOIN gv$process p ON p.addr = s.paddr 
             AND p.inst_id = s.inst_id
			ORDER BY s.sid
      ;			 
			 
INST_ID   SID  SERIAL# SPID                     USERNAME   PROGRAM
------- ----- -------- ------------------------ ---------- ------------------------------
      1   198    25895 25297654                 OEMPF      OMS
      1   573    53985 10486456                 OEMPF      OMS




-----------------------------------------
-- identifier les sessions 
-- par username
-- Retourne le SID et le SERIAL à utiliser
-----------------------------------------
 COLUMN inst_id FORMAT 9999
 COLUMN sid FORMAT 9999
 COLUMN serial# FORMAT 9999999
 COLUMN spid FORMAT 9999
 COLUMN username FORMAT A10
 COLUMN program FORMAT A30
 SET LINESIZE 150
 SELECT s.inst_id,
             s.sid,
             s.serial#,
             p.spid,
             s.username,
             s.program
      FROM   gv$session s
             JOIN gv$process p ON p.addr = s.paddr 
             AND p.inst_id = s.inst_id
             AND s.username='&1'
             ;





-----------------------------------------
-- identifier les sessions 
-- par username
-- Retourne la requete, le SID et le SERIAL à utiliser,
-- le username
----------------------------------------
 COLUMN KILL FORMAT 40
 COLUMN inst_id FORMAT 9999
 COLUMN sid FORMAT 9999
 COLUMN serial# FORMAT 9999999
 COLUMN username FORMAT A10
 SET LINESIZE 150
 
SELECT 'ALTER SYSTEM KILL SESSION ' ||CHR(39)|| s.sid ||','|| s.serial# ||CHR(39)||' IMMEDIATE;' KILL,
       s.inst_id,
	     s.serial#,
       s.username
      FROM   gv$session s
             JOIN gv$process p ON p.addr = s.paddr 
             AND p.inst_id = s.inst_id
             AND s.sid='&1'
             ;

KILL                                                                                                                     INST_ID  SERIAL# USERNAME
------------------------------------------------------------------------------------------------------------------------ ------- -------- ----------
ALTER SYSTEM KILL SESSION '7,10239' IMMEDIATE;                                                                                 1    10239 GEN$HUIS




-----------------------------------------
-- identifier les sessions 
-- par username
-- Retourne la requete du KILL, le SID et le SERIAL à utiliser,
-- le username
----------------------------------------
 COLUMN inst_id FORMAT 9999
 COLUMN sid FORMAT 9999
 COLUMN serial# FORMAT 9999999
 COLUMN spid FORMAT 9999
 COLUMN username FORMAT A10
 COLUMN program FORMAT A30
 SET LINESIZE 150
 
SELECT 'ALTER SYSTEM KILL SESSION ' ||CHR(39)|| s.sid ||','|| s.serial# ||CHR(39)||' IMMEDIATE;',
       s.inst_id,
	     s.serial#,
       p.spid,
       s.username,
       s.program
      FROM   gv$session s
             JOIN gv$process p ON p.addr = s.paddr 
             AND p.inst_id = s.inst_id
             AND s.sid='&1'
             ;


-----------------------------------------------	  
-- Supprimer ces sessions => Kill -9 du SPID --
-----------------------------------------------

SQL> ALTER SYSTEM KILL SESSION '198,25895' IMMEDIATE;




-----------------------------------------------	  
-- BLOC PL/SQL  --
-- Supprimer en auto toutes les sessions 
-- pour un user en parametre
-----------------------------------------------
BEGIN
    FOR r IN (
        SELECT 'ALTER SYSTEM KILL SESSION ''' || s.sid || ',' || s.serial# || ''' IMMEDIATE;' AS ddl
        FROM   gv$session s
             JOIN gv$process p ON p.addr = s.paddr 
             AND p.inst_id = s.inst_id
             AND s.username='&Username'
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE(r.ddl);
       -- EXECUTE IMMEDIATE r.ddl
    END LOOP;
END;
/




-----------------------------------------------	  
-- PROCEDURE PL/SQL  --
-- Prend en parametre SID et SERIAL
-- prerequis :
-- CREATE PUBLIC SYNONYM KILL_SESSION FOR SYS.KILL_SESSION;
-- GRANT EXECUTE ON KILL_SESSION TO user;
-----------------------------------------------
CREATE OR REPLACE PROCEDURE kill_session (p_sid IN NUMBER, p_serial IN NUMBER)
AS
  my_requestor_username VARCHAR2(30);
  my_kill_username      VARCHAR2(30);
  my_msg                VARCHAR2(200);
BEGIN
  DBMS_OUTPUT.ENABLE(1000000);

  SELECT username
  INTO   my_requestor_username
  FROM   v$session
  WHERE  audsid = USERENV('SESSIONID');

  SELECT username
  INTO   my_kill_username
  FROM   v$session
  WHERE  sid = p_sid
  AND    serial# = p_serial;

  IF my_requestor_username = my_kill_username
  THEN
    EXECUTE IMMEDIATE 'ALTER SYSTEM KILL SESSION '''||p_sid||','||p_serial||''' IMMEDIATE';
  ELSE
    DBMS_OUTPUT.PUT_LINE('YOU ARE NOT ALLOWED TO KILL OTHER USERS');
  END IF;
EXCEPTION WHEN OTHERS
THEN
  my_msg := SQLERRM;
  DBMS_OUTPUT.PUT_LINE(my_msg);
END;
/

CREATE PUBLIC SYNONYM KILL_SESSION FOR SYS.KILL_SESSION;
GRANT EXECUTE ON KILL_SESSION TO GEN$HUIS;


