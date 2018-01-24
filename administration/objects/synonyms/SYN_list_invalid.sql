SELECT Substr(RPAD(owner||'.'||synonym_name,40,' ')||' --> '||
       table_owner||'.'||table_name||decode(db_link,NULL,' ','@'||db_link),1,100) as syn
FROM dba_synonyms
WHERE synonym_name in ( select object_name 
                          from all_objects 
                          where status != 'VALID' 
                          and object_type = 'SYNONYM' )
/
