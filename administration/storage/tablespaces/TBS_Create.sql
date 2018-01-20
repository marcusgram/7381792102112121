

SELECT value from v$parameter where name = 'db_create_file_dest';

CREATE tablespace ABIDI datafile size 1M;

CREATE tablespace LASER datafile SIZE 5M AUTOEXTEND OFF EXTENT MANAGEMENT LOCAL AUTOALLOCATE;
