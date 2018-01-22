

-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/constraints/disable_chk.sql
-- Description  : Disables all check constraints for a specified table, or all tables.
-- Call Syntax  : @disable_chk (table-name or all) (schema-name)
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER TABLE "' || a.table_name || '" DISABLE CONSTRAINT "' || a.constraint_name || '";'
FROM   all_constraints a
WHERE  a.constraint_type = 'C'
AND    a.owner           = UPPER('&2');
AND    a.table_name      = DECODE(UPPER('&1'),'ALL',a.table_name,UPPER('&1'));

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON




----------------------------------------------------------------------------------------------
--Script permettant de generer la désactivation des Contraintes d'intégrités CHECK
--ici sur la table xx et pour le user yyy
----------------------------------------------------------------------------------------------  	

SELECT      'ALTER TABLE "'
             || table_name
             || '" DISABLE CONSTRAINT "'
             || constraint_name
             || '";' "CHECK CONSTRAINTS A DESACTIVER"
      FROM   all_constraints a
     WHERE       constraint_type = 'C'
             AND owner = UPPER ('&username')
             AND table_name = UPPER ('&tabname')
             AND status = 'ENABLED';

CHECK CONSTRAINTS A DESACTIVER
--------------------------------------------------------------------
ALTER TABLE "ANALYSE" DISABLE CONSTRAINT "SYS_C0013527";
ALTER TABLE "ANALYSE" DISABLE CONSTRAINT "CHECK_A_PRE";
ALTER TABLE "ANALYSE" DISABLE CONSTRAINT "CHECK_VER_PRE";
ALTER TABLE "ANALYSE" DISABLE CONSTRAINT "CHECK_ANA_E_PR";
ALTER TABLE "ANALYSE" DISABLE CONSTRAINT "CHECK_ANA_VAL_REC";

10 rows selected.
