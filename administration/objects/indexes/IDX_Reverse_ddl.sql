


SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON
BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/
SELECT DBMS_METADATA.get_ddl ('INDEX', index_name, table_owner)
FROM   user_indexes
WHERE  table_owner = UPPER('&owner_name');



SET LONG 90000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON
BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/
SELECT DBMS_METADATA.GET_DDL('INDEX',object_name,'&owner') 
FROM DBA_OBJECTS 
WHERE OWNER=UPPER('&owner') 
AND OBJECT_TYPE='INDEX';




SET LONG 90000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON
BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/
SELECT DBMS_METADATA.GET_DDL('INDEX',object_name,'&owner') 
FROM dba_objects 
WHERE owner=upper('&owner') 
AND object_type ='INDEX' 
AND object_name='&index';





SET LONG 90000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON
SPOOL CREATE_SIEBEL_EIM_INDEXES.sql

select DBMS_METADATA.GET_DDL('INDEX',object_name,'&owner') || CHR(10) || ' /' from dba_objects 
where owner=upper('&owner') 
and object_type ='INDEX' 
and object_name like 'EIM%';

SPOOL OFF
