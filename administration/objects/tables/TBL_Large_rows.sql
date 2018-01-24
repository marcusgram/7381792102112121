column db_block_size new_value blksz noprint

select value db_block_size from v$parameter where name = 'db_block_size';

select
   table_name,
   tablespace_name,
   avg_row_len
from
   dba_tables
where
avg_row_len > &blksz/4
order by
   avg_row_len desc
;
