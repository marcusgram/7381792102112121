
-------------------------------------------------
-- Generate script to set autoextend on datafiles
-------------------------------------------------
select a.tablespace_name as tbsname,
       (a.bytes/1048576) as fsize, trunc(((a.bytes-b.bytes)/1048576)+1) as usize,
       'alter database datafile '''||a.file_name||''' autoextend on;' as myscr
from dba_data_files a, dba_free_space b
where a.tablespace_name like Upper('%&tbsname%')
  and a.file_id = b.file_id
order by a.tablespace_name, a.file_name
/
