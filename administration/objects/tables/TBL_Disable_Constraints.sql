

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





------------------------------------------------------
-- here another sql to disable all enable constraints
-- from current schema
------------------------------------------------------
SET Serveroutput ON
BEGIN
    FOR c IN
    (SELECT c.owner,c.table_name,c.constraint_name
    FROM user_constraints c,user_tables t
    WHERE c.table_name=t.table_name
    AND c.status='ENABLED'
    ORDER BY c.constraint_type DESC,c.last_change DESC
    )
    LOOP
        FOR D IN
        (SELECT P.Table_Name Parent_Table,C1.Table_Name Child_Table,C1.Owner,P.Constraint_Name Parent_Constraint,
            c1.constraint_name Child_Constraint
        FROM user_constraints p
        JOIN user_constraints c1 ON(p.constraint_name=c1.r_constraint_name)
        WHERE(p.constraint_type='P' OR p.constraint_type='U' OR p.constraint_type='C' OR p.constraint_type='O')
        AND c1.constraint_type='R'
        AND p.table_name=UPPER(c.table_name)
        )
        LOOP
            dbms_output.put_line('. Disable the constraint ' || d.Child_Constraint ||' (on table '||d.owner || '.' || d.Child_Table || ')') ;
			      dbms_output.put_line('alter table ' || d.owner || '.' ||d.Child_Table || ' disable constraint ' || d.Child_Constraint || ' CASCADE') ;
            dbms_utility.exec_ddl_statement('alter table ' || d.owner || '.' ||d.Child_Table || ' disable constraint ' || d.Child_Constraint || ' CASCADE') ;
        END LOOP;
    END LOOP;
END;
/



-------------------------------------
-- A procedure to manage constraints
-------------------------------------
CREATE OR REPLACE PROCEDURE LASERMIGR.DISABLE_CONSTRAINTS (in_enable in boolean) is
begin

  if in_enable = false then
   -- PRIMARY KEY
    for i in 
    (
      select constraint_name, table_name 
      from user_constraints 
      where constraint_type ='P'
      and status = 'ENABLED'
	  and owner = 'LASERMIGR'
    ) LOOP
      execute immediate 'ALTER TABLE '||i.table_name||' DISABLE PRIMARY KEY CASCADE ';
    end loop;
	
	-- UNIQUE
    for i in 
    (
      select constraint_name, table_name 
      from user_constraints 
      where constraint_type ='U'
      and status = 'ENABLED'
    ) LOOP
      execute immediate 'alter table '||i.table_name||' disable constraint '||i.constraint_name||' CASCADE';
    end loop;
	
    -- FOREIGN
    for i in 
    (
      select constraint_name, table_name 
      from user_constraints 
      where constraint_type ='R'
      and status = 'ENABLED'
    ) LOOP
      execute immediate 'alter table '||i.table_name||' disable constraint '||i.constraint_name||' CASCADE';
    end loop;
	
	-- CHECK
	for i in 
    (
      select constraint_name, table_name 
      from user_constraints 
      where constraint_type ='C'
      and status = 'ENABLED'
    ) LOOP
      execute immediate 'alter table '||i.table_name||' disable constraint '||i.constraint_name||'';
    end loop;
	
  else
   
    -- PRIMARY KEY
    for i in 
    (
      select constraint_name, table_name 
      from user_constraints 
      where constraint_type ='P'
      and status <> 'ENABLED'
    ) LOOP
      execute immediate 'ALTER TABLE '||i.table_name||' ENABLE PRIMARY KEY CASCADE ';
    end loop;
   
    -- FK 
    for i in 
    (
      select constraint_name, table_name 
      from user_constraints 
      where constraint_type ='R'
      and status <> 'ENABLED'
    ) LOOP
      execute immediate 'alter table '||i.table_name||' enable constraint '||i.constraint_name||'';
    end loop;
	
	-- CHECK
	for i in 
    (
      select constraint_name, table_name 
      from user_constraints 
      where constraint_type ='C'
      and status <> 'ENABLED'
    ) LOOP
      execute immediate 'alter table '||i.table_name||' enable constraint '||i.constraint_name||'';
    end loop;
	
	-- UNIQUE
    for i in 
    (
      select constraint_name, table_name 
      from user_constraints 
      where constraint_type ='U'
      and status <> 'ENABLED'
    ) LOOP
      execute immediate 'alter table '||i.table_name||' enable constraint '||i.constraint_name||'';
    end loop;
  end if;
--This procedure could be made more elegant, that will be left as an exercise for the reader ;)
end;
/
show errors;

EXECUTE LASERMIGR.DISABLE_CONSTRAINTS (false);
EXECUTE LASERMIGR.DISABLE_CONSTRAINTS (true);



