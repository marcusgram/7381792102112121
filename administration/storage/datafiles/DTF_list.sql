
rem ------------------------------------------------
select bytes "MB", status, file#, block_size, name, creation_time from
( select '1' as sira, status, file#, trunc(bytes/(1024*1024)) as bytes, block_size, name, creation_time
    from v$datafile
  union
  select '2' as sira, '---------' as status, null as file#, null as bytes, null as block_size, '-------------------------------------------' as name, null as creation_time
    from dual
  union
  select '3' as sira, status, file#, trunc(bytes/(1024*1024)) as bytes, block_size, name, creation_time
    from v$tempfile )
order by sira, name, file#
/
rem ------------------------------------------------

rem ------------------------------------------------
select tablespace_name,
       (bytes/1048576) as filesize,
       (maxbytes/1048576) as maxsize,
       DECODE(autoextensible,'YES','+',' ') as auto,
       file_name
from dba_data_files
order by tablespace_name, file_name
/
rem -------------------------------------------------

rem -------------------------------------------------
select tablespace_name,
       (bytes/1048576) as filesize,
       (maxbytes/1048576) as maxsize,
       DECODE(autoextensible,'YES','+',' ') as auto,
       file_name
from dba_data_files
where Upper(file_name) like Upper('%&filename%')
order by tablespace_name, file_name
/
rem ------------------------------------------------

rem -------------------------------------------------
select tablespace_name,
       (bytes/1048576) as filesize,
       DECODE(autoextensible,'YES','+',' ') as auto,
       file_name
from dba_data_files
where tablespace_name like Upper('&tablespacename'||'%')
order by tablespace_name, file_name
/
rem -------------------------------------------------

rem -------------------------------------------------



