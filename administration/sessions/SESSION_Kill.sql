



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



