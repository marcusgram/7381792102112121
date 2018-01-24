spool chain.lst;
set pages 9999;

column c1 heading "Owner"   format a9;
column c2 heading "Table"   format a12;
column c3 heading "PCTFREE" format 99;
column c4 heading "PCTUSED" format 99;
column c5 heading "avg row" format 99,999;
column c6 heading "Rows"    format 999,999,999;
column c7 heading "Chains"  format 999,999,999;
column c8 heading "Pct"     format .99;

set heading off;
select 'Tables with chained rows and no RAW columns.' from dual;
set heading on;

select
   owner              c1,
   table_name         c2,
   pct_free           c3,
   pct_used           c4,
   avg_row_len        c5,
   num_rows           c6,
   chain_cnt          c7,
   chain_cnt/num_rows c8
from dba_tables
where
owner not in ('SYS','SYSTEM')
and
table_name not in
 (select table_name from dba_tab_columns
   where
 data_type in ('RAW','LONG RAW')
 )
and
chain_cnt > 0
order by chain_cnt desc
;
