

col object_type format a10
col object_name format a20

SELECT dba_objects.owner
,object_name
,object_type
,object_type 
  FROM dba_objects
     ,dba_indexes,dba_tables 
 WHERE dba_objects.object_name = dba_indexes.index_name
   AND dba_objects.object_name = dba_tables.table_name
   AND dba_tables.buffer_pool = 'KEEP' 
   AND dba_indexes.buffer_pool = 'KEEP'
   ;
