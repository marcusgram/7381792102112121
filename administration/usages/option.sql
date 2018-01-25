-- This one should be copy and pastable, however for formatting 
-- you can always go to the Metalink note 1317265.1 

SET LINESIZE 180;
SET PAGESIZE 1000;
SET FEEDBACK OFF;
SET COLSEP '|';
WHENEVER SQLERROR EXIT SQL.SQLCODE;

COL "Host Name" FORMAT A30;
COL "Option/Management Pack" FORMAT A60;
COL "Used" FORMAT A5;
with features as(
select a OPTIONS, b NAME  from
(
select 'Active Data Guard' a,  'Active Data Guard - Real-Time Query on Physical 
Standby' b from dual
union all
select 'Advanced Compression', 'HeapCompression' from dual
union all
select 'Advanced Compression', 'Backup BZIP2 Compression' from dual
union all
select 'Advanced Compression', 'Backup DEFAULT Compression' from dual
union all
select 'Advanced Compression', 'Backup HIGH Compression' from dual
union all
select 'Advanced Compression', 'Backup LOW Compression' from dual
union all
select 'Advanced Compression', 'Backup MEDIUM Compression' from dual
union all
select 'Advanced Compression', 'Backup ZLIB, Compression' from dual
union all
select 'Advanced Compression', 'SecureFile Compression (user)' from dual
union all
select 'Advanced Compression', 'SecureFile Deduplication (user)' from dual
union all
select 'Advanced Compression',        'Data Guard' from dual
union all
select 'Advanced Compression', 'Oracle Utility Datapump (Export)' from dual
union all
select 'Advanced Compression', 'Oracle Utility Datapump (Import)' from dual
union all
select 'Advanced Security',     'ASO native encryption and checksumming' from 
dual
union all
select 'Advanced Security', 'Transparent Data Encryption' from dual
union all
select 'Advanced Security', 'Encrypted Tablespaces' from dual
union all
select 'Advanced Security', 'Backup Encryption' from dual
union all
select 'Advanced Security', 'SecureFile Encryption (user)' from dual
union all
select 'Change Management Pack',        'Change Management Pack (GC)' from dual
union all
select 'Data Masking Pack',     'Data Masking Pack (GC)' from dual
union all
select 'Data Mining',   'Data Mining' from dual
union all
select 'Diagnostic Pack',       'Diagnostic Pack' from dual
union all
select 'Diagnostic Pack',       'ADDM' from dual
union all
select 'Diagnostic Pack',       'AWR Baseline' from dual
union all
select 'Diagnostic Pack',       'AWR Baseline Template' from dual
union all
select 'Diagnostic Pack',       'AWR Report' from dual
union all
select 'Diagnostic Pack',       'Baseline Adaptive Thresholds' from dual
union all
select 'Diagnostic Pack',       'Baseline Static Computations' from dual
union all
select 'Tuning  Pack',          'Tuning Pack' from dual
union all
select 'Tuning  Pack',          'Real-Time SQL Monitoring' from dual
union all
select 'Tuning  Pack',          'SQL Tuning Advisor' from dual
union all
select 'Tuning  Pack',          'SQL Access Advisor' from dual
union all
select 'Tuning  Pack',          'SQL Profile' from dual
union all
select 'Tuning  Pack',          'Automatic SQL Tuning Advisor' from dual
union all
select 'Database Vault',        'Oracle Database Vault' from dual
union all
select 'WebLogic Server Management Pack Enterprise Edition',    'EM AS 
Provisioning and Patch Automation (GC)' from dual
union all
select 'Configuration Management Pack for Oracle Database',     'EM Config 
Management Pack (GC)' from dual
union all
select 'Provisioning and Patch Automation Pack for Database',   'EM Database 
Provisioning and Patch Automation (GC)' from dual
union all
select 'Provisioning and Patch Automation Pack',        'EM Standalone 
Provisioning and Patch Automation Pack (GC)' from dual
union all
select 'Exadata',       'Exadata' from dual
union all
select 'Label Security',        'Label Security' from dual
union all
select 'OLAP',          'OLAP - Analytic Workspaces' from dual
union all
select 'Partitioning',          'Partitioning (user)' from dual
union all
select 'Real Application Clusters',     'Real Application Clusters (RAC)' from 
dual
union all
select 'Real Application Testing',      'Database Replay: Workload Capture' 
from dual
union all
select 'Real Application Testing',      'Database Replay: Workload Replay' from 
dual
union all
select 'Real Application Testing',      'SQL Performance Analyzer' from dual
union all
select 'Spatial'        ,'Spatial (Not used because this does not differential 
usage of spatial over locator, which is free)' from dual
union all
select 'Total Recall',  'Flashback Data Archive' from dual
)
)
select t.o "Option/Management Pack",
       t.u "Used",
       d.DBID "DBID",
       d.name "DB Name",
       i.version "DB Version",
       i.host_name "Host Name",
       to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') "ReportGen Time"
from
(select OPTIONS o, DECODE(sum(num),0,'NO','YES') u
from
(
select f.OPTIONS OPTIONS, case
                   when f_stat.name is null then 0
                   when ( ( f_stat.currently_used = 'TRUE' and
                            f_stat.detected_usages > 0 and
                            (sysdate - f_stat.last_usage_date) < 366 and
                            f_stat.total_samples > 0
                          )
                          or
                          (f_stat.detected_usages > 0 and
                          (sysdate - f_stat.last_usage_date) < 366 and
                          f_stat.total_samples > 0)
                        ) and
                        ( f_stat.name not in('Data Guard', 'Oracle Utility 
Datapump (Export)', 'Oracle Utility Datapump (Import)')
                          or
                          (f_stat.name in('Data Guard', 'Oracle Utility 
Datapump (Export)', 'Oracle Utility Datapump (Import)') and
                           f_stat.feature_info is not null and 
trim(substr(to_char(feature_info), instr(to_char(feature_info), 'compression 
used: ',1,1) + 18, 2)) != '0')
                        )
                        then 1
                   else 0
                  end num
  from features f,
       sys.dba_feature_usage_statistics f_stat
where f.name = f_stat.name(+)
) group by options) t,
  v$instance i,
  v$database d
order by 2 desc,1
;


-- Joel Patterson Database Administrator 904 727-2546
-- Works on 10g too.
-- A mere 150 lines give or take don't cha know.


SET LINESIZE 180;
SET PAGESIZE 1000;
SET FEEDBACK OFF;
SET COLSEP '|';
WHENEVER SQLERROR EXIT SQL.SQLCODE;

COL "Host Name" FORMAT A30;
COL "Option/Management Pack" FORMAT A60;
COL "Used" FORMAT A5;

with features as(
select a OPTIONS, b NAME  from
(
select 'Active Data Guard' a,  'Active Data Guard - Real-Time Query on Physical 
Standby' b from dual
union all
select 'Advanced Compression', 'HeapCompression' from dual
union all
select 'Advanced Compression', 'Backup BZIP2 Compression' from dual
union all
select 'Advanced Compression', 'Backup DEFAULT Compression' from dual
union all
select 'Advanced Compression', 'Backup HIGH Compression' from dual
union all
select 'Advanced Compression', 'Backup LOW Compression' from dual
union all
select 'Advanced Compression', 'Backup MEDIUM Compression' from dual
union all
select 'Advanced Compression', 'Backup ZLIB, Compression' from dual
union all
select 'Advanced Compression', 'SecureFile Compression (user)' from dual
union all
select 'Advanced Compression', 'SecureFile Deduplication (user)' from dual
union all
select 'Advanced Compression',        'Data Guard' from dual
union all
select 'Advanced Compression', 'Oracle Utility Datapump (Export)' from dual
union all
select 'Advanced Compression', 'Oracle Utility Datapump (Import)' from dual
union all
select 'Advanced Security',     'ASO native encryption and checksumming' from dual
union all
select 'Advanced Security', 'Transparent Data Encryption' from dual
union all
select 'Advanced Security', 'Encrypted Tablespaces' from dual
union all
select 'Advanced Security', 'Backup Encryption' from dual
union all
select 'Advanced Security', 'SecureFile Encryption (user)' from dual
union all
select 'Change Management Pack',        'Change Management Pack (GC)' from dual
union all
select 'Data Masking Pack',     'Data Masking Pack (GC)' from dual
union all
select 'Data Mining',   'Data Mining' from dual
union all
select 'Diagnostic Pack',       'Diagnostic Pack' from dual
union all
select 'Diagnostic Pack',       'ADDM' from dual
union all
select 'Diagnostic Pack',       'AWR Baseline' from dual
union all
select 'Diagnostic Pack',       'AWR Baseline Template' from dual
union all
select 'Diagnostic Pack',       'AWR Report' from dual
union all
select 'Diagnostic Pack',       'Baseline Adaptive Thresholds' from dual
union all
select 'Diagnostic Pack',       'Baseline Static Computations' from dual
union all
select 'Tuning  Pack',          'Tuning Pack' from dual
union all
select 'Tuning  Pack',          'Real-Time SQL Monitoring' from dual
union all
select 'Tuning  Pack',          'SQL Tuning Advisor' from dual
union all
select 'Tuning  Pack',          'SQL Access Advisor' from dual
union all
select 'Tuning  Pack',          'SQL Profile' from dual
union all
select 'Tuning  Pack',          'Automatic SQL Tuning Advisor' from dual
union all
select 'Database Vault',        'Oracle Database Vault' from dual
union all
select 'WebLogic Server Management Pack Enterprise Edition',    'EM AS 
Provisioning and Patch Automation (GC)' from dual
union all
select 'Configuration Management Pack for Oracle Database',     'EM Config 
Management Pack (GC)' from dual
union all
select 'Provisioning and Patch Automation Pack for Database',   'EM Database 
Provisioning and Patch Automation (GC)' from dual
union all
select 'Provisioning and Patch Automation Pack',        'EM Standalone 
Provisioning and Patch Automation Pack (GC)' from dual
union all
select 'Exadata',       'Exadata' from dual
union all
select 'Label Security',        'Label Security' from dual
union all
select 'OLAP',          'OLAP - Analytic Workspaces' from dual
union all
select 'Partitioning',          'Partitioning (user)' from dual
union all
select 'Real Application Clusters',     'Real Application Clusters (RAC)' from 
dual
union all
select 'Real Application Testing',      'Database Replay: Workload Capture' 
from dual
union all
select 'Real Application Testing',      'Database Replay: Workload Replay' from 
dual
union all
select 'Real Application Testing',      'SQL Performance Analyzer' from dual
union all
select 'Spatial'        ,'Spatial (Not used because this does not differential 
usage of spatial over locator, which is free)' from dual
union all
select 'Total Recall',  'Flashback Data Archive' from dual
)
)
select t.o "Option/Management Pack",
       t.u "Used",
       d.DBID "DBID",
       d.name "DB Name",
       i.version "DB Version",
       i.host_name "Host Name",
       to_char(sysdate, 'YYYY-MM-DD HH24:MI:SS') "ReportGen Time"
from
(select OPTIONS o, DECODE(sum(num),0,'NO','YES') u
from
(
select f.OPTIONS OPTIONS, case
                   when f_stat.name is null then 0
                   when ( ( f_stat.currently_used = 'TRUE' and
                            f_stat.detected_usages > 0 and
                            (sysdate - f_stat.last_usage_date) < 366 and
                            f_stat.total_samples > 0
                          )
                          or
                          (f_stat.detected_usages > 0 and
                          (sysdate - f_stat.last_usage_date) < 366 and
                          f_stat.total_samples > 0)
                        ) and
                        ( f_stat.name not in('Data Guard', 'Oracle Utility 
Datapump (Export)', 'Oracle Utility Datapump (Import)')
                          or
                          (f_stat.name in('Data Guard', 'Oracle Utility 
Datapump (Export)', 'Oracle Utility Datapump (Import)') and
                           f_stat.feature_info is not null and 
trim(substr(to_char(feature_info), instr(to_char(feature_info), 'compression 
used: ',1,1) + 18, 2)) != '0')
                        )
                        then 1
                   else 0
                  end num
  from features f,
       sys.dba_feature_usage_statistics f_stat
where f.name = f_stat.name(+)
) group by options) t,
  v$instance i,
  v$database d
order by 2 desc,1
;



-- Joel Patterson Database Administrator 904 727-2546
-- This could possibly help... It's as close as I have come.   You can put 
-- whatever NAME you wish from the dba_feature_usage_statistics view.  I just 
-- added 'Diagnostic Pack' for you.

-- Let me know if you get something better.   I'm still looking for Gartners 
-- warning about 'Total Recall','Advanced Compression','Active Data Guard' and 
-- 'Real Application Testing' being separately chargeable which I do not see 
-- listed in this view.   (Gartner Publication Date: 6 February 2009, ID Number: 
-- G00164790).  (btw someone just handed me the article... so I guess they are 
-- about three years late... anyway, I'm looking for a definitive way :).

-- So if anyone has info on these other four...

  SELECT  a.*
  FROM    (
          SELECT  dfs.*,
                  ROW_NUMBER() OVER (PARTITION BY name ORDER BY version
  DESC) rno
          FROM    DBA_FEATURE_USAGE_STATISTICS dfs
          WHERE   detected_usages > 0
          AND     name IN
                  (
                  'Advanced Security',
                  'Automatic Database Diagnostic Monitor',
                  'Data Mining',
                  'Diagnostic Pack',
                  'Label Security',
                  'Partitioning (user)',
                  'RMAN - Tape Backup',
                  'Real Application Clusters (RAC)',
                  'SQL Access Advisor',
                  'SQL Tuning Advisor',
                  'SQL Tuning Set',
                  'Spatial',
                  'Transparent Gateway'
                  )
          ) a
  WHERE   a.rno = 1
;

REM Joel Patterson Database Administrator 904 727-2546

