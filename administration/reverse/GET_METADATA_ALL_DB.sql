
sqlplus<<EOF
set long 100000
set head off
set echo off
set pagesize 0
set verify off
set feedback off
spool schema.out

select dbms_metadata.get_ddl(object_type, object_name, owner)
from
(
    --Convert DBA_OBJECTS.OBJECT_TYPE to DBMS_METADATA object type:
    select
        owner,
        --Java object names may need to be converted with DBMS_JAVA.LONGNAME.
        --That code is not included since many database don't have Java installed.
        object_name,
        decode(object_type,
            'DATABASE LINK',      'DB_LINK',
            'JOB',                'PROCOBJ',
            'RULE SET',           'PROCOBJ',
            'RULE',               'PROCOBJ',
            'EVALUATION CONTEXT', 'PROCOBJ',
            'PACKAGE',            'PACKAGE_SPEC',
            'PACKAGE BODY',       'PACKAGE_BODY',
            'TYPE',               'TYPE_SPEC',
            'TYPE BODY',          'TYPE_BODY',
            'MATERIALIZED VIEW',  'MATERIALIZED_VIEW',
            'QUEUE',              'AQ_QUEUE',
            'JAVA CLASS',         'JAVA_CLASS',
            'JAVA TYPE',          'JAVA_TYPE',
            'JAVA SOURCE',        'JAVA_SOURCE',
            'JAVA RESOURCE',      'JAVA_RESOURCE',
            object_type
        ) object_type
    from dba_objects 
    where owner in ('OWNER1')
        --These objects are included with other object types.
        and object_type not in ('INDEX PARTITION','INDEX SUBPARTITION',
           'LOB','LOB PARTITION','TABLE PARTITION','TABLE SUBPARTITION')
        --Ignore system-generated types that support collection processing.
        and not (object_type = 'TYPE' and object_name like 'SYS_PLSQL_%')
        --Exclude nested tables, their DDL is part of their parent table.
        and (owner, object_name) not in (select owner, table_name from dba_nested_tables)
        --Exlclude overflow segments, their DDL is part of their parent table.
        and (owner, object_name) not in (select owner, table_name from dba_tables where iot_type = 'IOT_OVERFLOW')
)
order by owner, object_type, object_name;

spool off
quit
EOF

cat schema.out|sed 's/OWNER1/MYOWNER/g'>schema.out.change.sql