

----------------------------------------------------------------------------------------------
--Script permettant de lister les Contraintes d'intégrités à désactiver
--ici sur la table ANALYSE et pour le user Scott
---------------------------------------------------------------------------------------------- 

SELECT   TABLE_NAME,
             CONSTRAINT_NAME,
             STATUS,
             CONSTRAINT_TYPE
      FROM   ALL_CONSTRAINTS
     WHERE       CONSTRAINT_TYPE = 'C'
             AND OWNER = UPPER ('SCOTT')
             AND TABLE_NAME = UPPER ('ANALYSE')
             AND STATUS = 'ENABLED';

TABLE_NAME                     CONSTRAINT_NAME                STATUS   C
------------------------------ ------------------------------ -------- -
ANALYSE                        SYS_C0013527                   ENABLED  C
ANALYSE                        CHECK_A_PRE                    ENABLED  C
ANALYSE                        CHECK_VER_PRE                  ENABLED  C
ANALYSE                        CHECK_ANA_E_PR                 ENABLED  C
ANALYSE                        CHECK_ANA_VAL_REC              ENABLED  C






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
