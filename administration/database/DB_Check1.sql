
set head on
set pagesize 100
break on today
column today noprint new_value xdate
select substr(to_char(sysdate,'fmMonth DD, YYYY HH:MI:SS P.M.'),1,35) today
from dual;
column name noprint new_value dbname
select name from v$database;

set heading on
set feedback off

spool /home/jsoria/SCRIPTS/SQL/dbcheck.log

prompt **********************************************************
prompt *****            Database Information                *****
prompt **********************************************************
ttitle left "DATABASE:  "dbname"    (AS OF:  "xdate")"
select name, created, log_mode from v$database;
prompt
prompt **********************************************************
ttitle off

rem -------------------------------------------------------------
rem     DB Block Buffer - Hit Ratio
rem -------------------------------------------------------------

clear breaks
clear computes

set heading off
set feedback off
set termout off

create table dbbb (
PR      number,
CG      number,
dbbg    number);

insert into DBBB values (0,0,0);
UPDATE dbbb
        set dbbg =
           (SELECT  VALUE FROM V$SYSSTAT WHERE NAME = 'db block gets');
UPDATE dbbb
        set cg =
                (SELECT  VALUE FROM V$SYSSTAT WHERE NAME = 'consistent gets');
UPDATE dbbb
        set pr =
                (SELECT  VALUE FROM V$SYSSTAT WHERE NAME = 'physical reads');

set heading on
set termout on

column "Physical Reads" format 999,999,999,999,999
column "Consistent Gets" format 999,999,999,999,999
column "DB Block Gets" format 999,999,999,999,999
column "Percent (Above 70% ?)" format 999.99

TTitle left "*****  Database:  "dbname", DB Block Buffers ( As of:  "xdate" )   *****" skip 1 -
       left "Percent = (100*(1-(Physical Reads/(Consistent Gets + DB Block Gets))))" skip 2
SELECT  pr "Physical Reads",
        cg "Consistent Gets",
        dbbg "DB Block Gets",
        (100*(1-(PR/(CG+dbbg)))) "Percent (Above 70% ?)"
from dbbb;

set heading off
set termout off
drop table dbbb;
ttitle off
clear breaks
clear computes
set heading on
set termout on

rem -------------------------------------------------------------
rem     Shared Pool Size - Gets and Misses
rem -------------------------------------------------------------

set line 150

column "Executions" format 999,999,999,999
column "Cache Misses Executing" format 999,999,999,999
column "Data Dictionary Gets" format 999,999,999,999
column "Get Misses" format 999,999,999,999

ttitle left skip 1 - left "**********     Shared Pool Size (Execution Misses)     **********" skip 1

select sum(pins) "Executions",
       sum(reloads) "Cache Misses Executing",
     (sum(reloads)/sum(pins)*100) "% Ratio (STAY UNDER 1%)"
from v$librarycache;

ttitle left "**********     Shared Pool Size (Dictionary Gets)     **********"  skip 1

select sum(gets) "Data Dictionary Gets",
       sum(getmisses) "Get Misses",
       100*(sum(getmisses)/sum(gets)) "% Ratio (STAY UNDER 12%)"
from v$rowcache;

ttitle off


rem -------------------------------------------------------------
rem     Log Buffer
rem -------------------------------------------------------------

ttitle left "**********     Log Buffers     **********" skip 1

select  substr(name,1,25) Name,
        substr(value,1,15) "VALUE (Near 0?)"
from v$sysstat
where name = 'redo log space requests';

ttitle off


rem -------------------------------------------------------------
rem         Latch Contention
rem -------------------------------------------------------------

ttitle left "**********     Latch Information     **********" skip 1

select  substr(l.name,1,25) Name,
        l.gets, l.misses,
        l.immediate_gets, l.immediate_misses
from v$latch l, v$latchname ln
where ln.name in ('redo allocation', 'redo copy')
and ln.latch# = l.latch#;

ttitle off


rem -------------------------------------------------------------
rem     Reinstates the xdbname parameter
rem -------------------------------------------------------------

column name noprint new_value xdbname
select name from v$database;


rem -------------------------------------------------------------
rem     Tablespace Usage
rem -------------------------------------------------------------

set pagesize 66
set line 132

clear breaks
clear computes

column "Total Bytes" format 9,999,999,999,999,999
column "SQL Blocks" format 9,999,999,999,999
column "VMS Blocks" format 9,999,999,999,999
column "Bytes Free" format 9,999,999,999,999,999
column "Bytes Used" format 9,999,999,999,999,999
column "% Free" format 9999.999
column "% Used" format 9999.999
break on report
compute sum of "Total Bytes" on report
compute sum of "SQL Blocks" on report
compute sum of "VMS Blocks" on report
compute sum of "Bytes Free" on report
compute sum of "Bytes Used" on report
compute avg of "% Free" on report
compute avg of "% Used" on report

TTitle left "*******   Database:  "dbname", Current Tablespace Usage ( As of: "xdate" )   *******" skip 1

--select  substr(fs.FILE_ID,1,3) "ID#",
 select      fs.tablespace_name,
        sum(df.bytes) "Total Bytes",
        sum(df.blocks) "SQL Blocks",
        sum(df.bytes)/512 "VMS Blocks",
        sum(fs.bytes) "Bytes Free",
        (100*((sum(fs.bytes))/sum(df.bytes))) "% Free",
        sum(df.bytes)-sum(fs.bytes) "Bytes Used",
    (100*((sum(df.bytes)-sum(fs.bytes))/sum(df.bytes))) "% Used"
from sys.dba_data_files df, sys.dba_free_space fs
where df.tablespace_name = fs.tablespace_name
group by fs.tablespace_name
--group by fs.FILE_ID, fs.tablespace_name, df.bytes, df.blocks
order by fs.tablespace_name;

ttitle off

rem -------------------------------------------------------------
rem     Disk Activity
rem -------------------------------------------------------------

column "File Total" format 9,999,999,999,999

set line 132
set pagesize 33

ttitle  "        *****   Database:  "dbname", DataFile's Disk Activity (As  of:" xdate " )   *****"

select substr(df.file#,1,2) "ID",
       rpad(substr(name,1,52),42,'.') "File Name",
       rpad(substr(phyrds,1,10),10,'.') "Phy Reads",
       rpad(substr(phywrts,1,10),10,'.') "Phy Writes",
       rpad(substr(phyblkrd,1,10),10,'.') "Blk Reads",
       rpad(substr(phyblkwrt,1,10),10,'.') "Blk Writes",
       rpad(substr(readtim,1,9),9,'.') "Read Time",
       rpad(substr(writetim,1,10),10,'.') "Write Time",
       (sum(phyrds+phywrts+phyblkrd+phyblkwrt+readtim)) "File Total"
from v$filestat fs, v$datafile df
where fs.file# = df.file#
group by df.file#, df.name, phyrds, phywrts, phyblkrd,
         phyblkwrt, readtim, writetim
order by sum(phyrds+phywrts+phyblkrd+phyblkwrt+readtim) desc, df.name;

ttitle off


rem -------------------------------------------------------------
rem     Fragmentation Need
rem -------------------------------------------------------------

set heading on
set termout on
set pagesize 66
set line 132

ttitle left "     *****    Database:  "dbname", DEFRAGMENTATION NEED, AS OF: " xdate "      *****"

select  substr(de.owner,1,8) "Owner",
        substr(de.segment_type,1,8) "Seg Type",
        substr(de.segment_name,1,35) "Table Name (Segment)",
        substr(de.tablespace_name,1,20) "Tablespace Name",
        count(*) "Frag NEED",
        substr(df.name,1,40) "DataFile Name"
from sys.dba_extents de, v$datafile df
where de.owner <> 'SYS'
and de.file_id = df.file#
and de.segment_type = 'TABLE'
group by de.owner, de.segment_name, de.segment_type, de.tablespace_name,
df.name
having count(*) > 1
order by count(*) desc;

ttitle off


rem -------------------------------------------------------------
rem     Rollback Information
rem -------------------------------------------------------------

set pagesize 66
set line 132

TTitle left "*** Database:  "dbname", Rollback Information ( As of:  " xdate " ) ***" skip 2

select  substr(sys.dba_rollback_segs.SEGMENT_ID,1,5) "ID#",
        substr(sys.dba_segments.OWNER,1,8) "Owner",
        substr(sys.dba_segments.TABLESPACE_NAME,1,10) "Tablespace Name",
        substr(sys.dba_segments.SEGMENT_NAME,1,11) "Rollback Name",
        substr(sys.dba_rollback_segs.INITIAL_EXTENT,1,10) "INI_Extent",
        substr(sys.dba_rollback_segs.NEXT_EXTENT,1,10) "Next Exts",
        substr(sys.dba_segments.MIN_EXTENTS,1,5) "MinEx",
      substr(sys.dba_segments.MAX_EXTENTS,1,5) "MaxEx",
        substr(sys.dba_segments.PCT_INCREASE,1,5) "%Incr",
        substr(sys.dba_segments.BYTES,1,15) "Size (Bytes)",
        substr(sys.dba_segments.EXTENTS,1,6) "Extent#",
        substr(sys.dba_rollback_segs.STATUS,1,10) "Status"
from sys.dba_segments, sys.dba_rollback_segs
where sys.dba_segments.segment_name = sys.dba_rollback_segs.segment_name and
      sys.dba_segments.segment_type = 'ROLLBACK'
order by sys.dba_rollback_segs.segment_id;

ttitle off

TTitle left " " skip 2 - left "*** Database:  "dbname", Rollback Status ( As of:  " xdate " )  ***" skip 2

select substr(V$rollname.NAME,1,20) "Rollback_Name",
        substr(V$rollstat.EXTENTS,1,6) "EXTENT",
        v$rollstat.RSSIZE, v$rollstat.WRITES,
        substr(v$rollstat.XACTS,1,6) "XACTS",
        v$rollstat.GETS,
        substr(v$rollstat.WAITS,1,6) "WAITS",
        v$rollstat.HWMSIZE, v$rollstat.SHRINKS,
        substr(v$rollstat.WRAPS,1,6) "WRAPS",
        substr(v$rollstat.EXTENDS,1,6) "EXTEND",
        v$rollstat.AVESHRINK,
        v$rollstat.AVEACTIVE
from v$rollname, v$rollstat
where v$rollname.USN = v$rollstat.USN
order by v$rollname.USN;

ttitle off

TTitle left " " skip 2 - left "*** Database:  "dbname", Rollback Segment Mapping ( As of:  "  xdate " ) ***" skip 2

select  r.name Rollback_Name,
      p.pid Oracle_PID,
        p.spid VMS_PID,
        nvl(p.username,'NO TRANSACTION') Transaction,
        p.terminal Terminal
from v$lock l, v$process p, v$rollname r
where   l.addr = p.addr(+)
        and trunc(l.id1(+)/65536)=r.usn
      and l.type(+) = 'TX'
        and l.lmode(+) = 6
order by r.name;

ttitle off


rem -------------------------------------------------------------
rem     Current Users
rem -------------------------------------------------------------

set line 132
set pagesize 66

TTitle left "***   Database:  "dbname", Current User Info (As of:  "xdate") ***" skip 1

select  substr(username,1,15) "DB UserName",
        osuser "OS UserName",
        substr(object,1,25) Object,
        a.type, command,
        substr(machine,1,15) Machine,
        substr(terminal,1,15) Terminal, process, status
from v$access a, v$session s
where a.sid = s.sid
and s.status in ('ACTIVE','INACTIVE')
order by username;

TTitle left "***   Database:  "dbname", Current Sessions (As of:  "xdate") ***" skip 1

select  substr(username,1,15) "DB UserName",
  substr(osuser,1,15) "OS UserName",
        substr(command,1,3) CMD,
        substr(machine,1,10) Machine,
        terminal, process, status,
        substr(program,1,50) "OS Program Name"
from v$session
where type = 'USER'
and status in ('ACTIVE','INACTIVE')
order by username;

TTitle left "***   Database:  "dbname", Current Access (As of:  "xdate") ***" skip 1

select  sid,
        substr(owner,1,15) Owner,
        substr(object,1,25) Object,
        type
from v$access
order by owner;
PROMPT
PROMPT
PROMPT *******************  END OF REPORT   *******************

rem -------------------------------------------------------------
rem -------------------------------------------------------------

spool off
set feedback on
exit
