REPHEADER PAGE CENTER 'LISTE DES CONTRAINTES D''UNE TABLE OU VIEW'

SET LINESIZE 100
SET PAGESIZE 900
COL CONSTRAINT_NAME FORMAT A20
COL INDEX_NAME FORMAT A20
COL COLUMN_NAME FORMAT A15
SELECT   a.constraint_name,
         DECODE(a.constraint_type,'C', 'Check constraint',
                                  'P', 'Primary Key',
                                  'U', 'Unique Key',
                                  'R', 'Referential Integrity',
                                  'V', 'With Check Option on a View',
                                  'O', 'With Read Only on a View',
                                  'Autre à définir') CONSTRAINT_TYPE,
         a.index_name,
         b.column_name,
         b.position
  FROM   all_constraints a INNER JOIN all_cons_columns b
                           ON (a.constraint_name = b.constraint_name
                               AND a.owner = b.owner)
 WHERE   a.table_name = '&table'
   AND   a.owner = '&user'
 ORDER BY 3,2;
