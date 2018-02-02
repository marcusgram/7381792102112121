
https://blog.dbi-services.com/oracle-system-statistics-display-auxstats-with-calculated-values-and-formulas/

REM -------------------------------------------------------------------------------------------------------------------
REM -- System statistics can be gathered in NOWORKLOAD or WORKLOAD mode. 
REM -- Different values will be set depending on that and the others will be calculated – derived from them. 
REM -- We can see defined values from SYS.AUX_STATS$ but here is a script that shows the calculated ones as well.
REM -- With no system statistics or NOWORKLOAD the values of IOSEEKTIM (latency in ms) 
REM -- and IOTFRSPEED (transfer in bytes/ms) are set and the SREADTIM (time to read 1 block in ms) 
REM -- and MREADTIM (for multiblock read) are calculated from them.
REM -- MBRC depends on the defaults or the db_file_multiblock_read_count settings.
REM -- With WORKLOAD statistics, the SREADTIM and MREADTIM as well as MBRC are measured and those are the ones that are used by the optimizer
REM --------------------------------------------------------------------------------------------------------------------

set echo off
set linesize 200 pagesize 1000
column pname format a30
column sname format a20
column pval2 format a20
select pname,pval2 from sys.aux_stats$ where sname='SYSSTATS_INFO';
select pname,pval1,calculated,formula from sys.aux_stats$ where sname='SYSSTATS_MAIN'
model
  reference sga on (
    select name,value from v$sga
        ) dimension by (name) measures(value)
  reference parameter on (
    select name,decode(type,3,to_number(value)) value from v$parameter where name='db_file_multiblock_read_count' and ismodified!='FALSE'
    union all
    select name,decode(type,3,to_number(value)) value from v$parameter where name='sessions'
    union all
    select name,decode(type,3,to_number(value)) value from v$parameter where name='db_block_size'
        ) dimension by (name) measures(value)
partition by (sname) dimension by (pname) measures (pval1,pval2,cast(null as number) as calculated,cast(null as varchar2(60)) as formula) rules(
  calculated['MBRC']=coalesce(pval1['MBRC'],parameter.value['db_file_multiblock_read_count'],parameter.value['_db_file_optimizer_read_count'],8),
  calculated['MREADTIM']=coalesce(pval1['MREADTIM'],pval1['IOSEEKTIM'] + (parameter.value['db_block_size'] * calculated['MBRC'] ) / pval1['IOTFRSPEED']),
  calculated['SREADTIM']=coalesce(pval1['SREADTIM'],pval1['IOSEEKTIM'] + parameter.value['db_block_size'] / pval1['IOTFRSPEED']),
  calculated['   multi block Cost per block']=round(1/calculated['MBRC']*calculated['MREADTIM']/calculated['SREADTIM'],4),
  calculated['   single block Cost per block']=1,
  formula['MBRC']=case when pval1['MBRC'] is not null then 'MBRC' when parameter.value['db_file_multiblock_read_count'] is not null then 'db_file_multiblock_read_count' when parameter.value['_db_file_optimizer_read_count'] is not null then '_db_file_optimizer_read_count' else '= _db_file_optimizer_read_count' end,
  formula['MREADTIM']=case when pval1['MREADTIM'] is null then '= IOSEEKTIM + db_block_size * MBRC / IOTFRSPEED' end,
  formula['SREADTIM']=case when pval1['SREADTIM'] is null then '= IOSEEKTIM + db_block_size        / IOTFRSPEED' end,
  formula['   multi block Cost per block']='= 1/MBRC * MREADTIM/SREADTIM',
  formula['   single block Cost per block']='by definition',
  calculated['   maximum mbrc']=sga.value['Database Buffers']/(parameter.value['db_block_size']*parameter.value['sessions']),
  formula['   maximum mbrc']='= buffer cache size in blocks / sessions'
);
set echo on





