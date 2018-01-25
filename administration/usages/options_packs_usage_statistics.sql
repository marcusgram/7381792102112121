---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
------- Name        :  options_packs_usage_statistics.sql
-------                MOS Note 1317265.1
-------
------- Applies to:    Oracle Database - Version 11.2 and later
-------
------- Usage       :  Use SQL*Plus to connect to the database (locally or remotely)
-------                with any user having SELECT ANY DICTIONARY privilege:
-------                    sqlplus <UserName>/<Password> @options_packs_usage_statistics.sql
-------
-------                Collect output file spooled in the current directory:
-------                    options_packs_usage_statistics.txt
-------
-------                For Container Databases (CDB):
-------                    - when connected to CDB$ROOT container, the script lists
-------                      data for all the open PDBs, properly detecting if
-------                      Multitenant Option licensing is needed.
-------                    - when connected to a PDB, the script lists only local data,
-------                      as there is no visibility to other PDBs, due to the isolation
-------                      provided by the Multitenant Architecture. For the same reason,
-------                      Multitenant Option usage (more than one PDB) cannot be detected.
-------
------- Description :  This script provides usage statistics for features corresponding
-------                to Database Options and Management Packs.
-------                The report is based on DBA_FEATURE_USAGE_STATISTICS view.
-------                Note that the feature usage data in the view is updated once
-------                a week, so it may take up to 7 days for the report to show
-------                recent usage of options and/or packs.
-------                The CURRENTLY_USED column of DBA_FEATURE_USAGE_STATISTICS view
-------                indicates if the feature in question was used during the last
-------                sampling interval by VERSION and DBID.
-------
------- Disclaimer  :  The following report provides usage statistics for
-------                licensable Database Options and Enterprise Management Packs.
-------                This information is to be used for informational purposes only and
-------                this does not represent your license entitlement or requirement.
-------                The usage data may indicate, in some cases, false positives.
-------                Please see MOS DOC ID 1309070.1 for more information.
-------                This may be due to inclusion of usage by sample schemas (such as HR,
-------                PM, SH...) or system/internal usage.
-------
------- Support     :  For any report issue or discrepancy in the DBA_FEATURE_USAGE_STATISTICS
-------                data please, create a service request.
-------                For any licensing related question please contact License Management
-------                Services (LMS) representative at:
-------                http://www.oracle.com/us/corporate/license-management-services/index.html
-------
-------  Revision   :  Jun-2015
-------  Author     :  Sorin Serban - LMS - Business Services
-------
----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

set ECHO OFF
set TERMOUT ON
set TAB OFF
set TRIMOUT ON
set TRIMSPOOL ON
set PAGESIZE 50000
set LINESIZE 500
set FEEDBACK OFF
set VERIFY OFF
set COLSEP '|'

break on CON_NAME skip page duplicates

CLEAR COLUMNS
col HOST_NAME              format a40 wrap
col INSTANCE_NAME          format a16 wrap
col DATABASE_NAME          format a14 wrap
col OPEN_MODE              format a16 wrap
col RESTRICTED             format a10 wrap
col DATABASE_ROLE          format a16 wrap
col VERSION                format a11 wrap
col BANNER                 format a80 wrap
col CONNECTED_TO           format a12 wrap
col CON_ID                 format 99999 wrap
col LAST_DBA_FUS_VERSION   format a17 wrap
col PRODUCT                format a50 wrap
col FEATURE_BEING_USED     format a56 wrap
col USAGE                  format a24 wrap
col EXTRA_FEATURE_INFO     format a80 wrap
col CURRENTLY_USED         format a14 wrap
col CURRENT_CONTAINER_NAME format a30 wrap
col CURRENT_CONTAINER_ID   format a20 wrap
col PARAMETER              format a30 wrap
col VALUE                  format a20 wrap

alter session set nls_date_format='YYYY.MM.DD_HH24.MI.SS';

spool options_packs_usage_statistics.txt

prompt OVERALL INFORMATION

select i.HOST_NAME,
       i.INSTANCE_NAME,
       d.NAME as database_name,
       d.OPEN_MODE,
       d.DATABASE_ROLE,
       d.CREATED,
       d.DBID,
       i.VERSION,
       v.BANNER
  from  V$INSTANCE i, V$DATABASE d, V$VERSION v
  where v.BANNER LIKE 'Oracle%' or v.BANNER like 'Personal Oracle%'
;

select distinct NAME as PARAMETER, VALUE from GV$PARAMETER where lower(NAME) in ('control_management_pack_access', 'enable_ddl_logging') order by 1;

prompt

prompt
prompt ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
prompt MULTITENANT INFORMATION (Please ignore errors in pre 12.1 databases)
prompt ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

select c.CON_ID, c.NAME, c.OPEN_MODE, c.RESTRICTED,
    case when c.OPEN_MODE not like 'READ%' and c.CON_ID = sys_context('USERENV', 'CON_ID') and c.CON_ID != 0 then
              'NOT OPEN! DBA_FEATURE_USAGE_STATISTICS is not accessible. *CURRENT CONTAINER'
         when c.OPEN_MODE not like 'READ%' then
              'NOT OPEN! DBA_FEATURE_USAGE_STATISTICS is not accessible.'
         when c.CON_ID = sys_context('USERENV', 'CON_ID') and d.CDB='YES' and c.CON_ID not in (0, 1) then
              '*CURRENT CONTAINER. Only data for this PDB will be listed.'
         when c.CON_ID = sys_context('USERENV', 'CON_ID') and d.CDB='YES' and c.CON_ID = 1 then
              '*CURRENT CONTAINER is CDB$ROOT. Information for all open PDBs will be listed.'
         else ''
    end as REMARKS
    from V$CONTAINERS c, V$DATABASE d
    order by CON_ID;
prompt
prompt The multitenant architecture with one user-created pluggable database (single tenant) is available in all editions without the Multitenant Option.
prompt If more than one PDB containers are created, then Multitenant Option licensing is needed

-- Prepare settings for pre 12c databases
define DFUS=DBA_
col DFUS_ new_val DFUS noprint

define DCOL1=CON_ID
col DCOL1_ new_val DCOL1 noprint
define DCID=-1
col DCID_ new_val DCID noprint

define DCOL2=CON_NAME
col DCOL2_ new_val DCOL2 noprint
define DCNA=to_char(NULL)
col DCNA_ new_val DCNA noprint

select 'CDB_' as DFUS_, 'CON_ID' as DCID_, '(select NAME from V$CONTAINERS xz where xz.CON_ID=xy.CON_ID)' as DCNA_, 'XXXXXX' as DCOL1_, 'XXXXXX' as DCOL2_
  from CDB_FEATURE_USAGE_STATISTICS
  where exists (select 1 from V$DATABASE where CDB='YES')
    and rownum=1;

col CON_ID  NOPRINT
col GID     NOPRINT
-- Hide CON_NAME column for non-Container Databases:
col &&DCOL2 NOPRINT

prompt ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
prompt >>> Selecting from &&DFUS.FEATURE_USAGE_STATISTICS


prompt
prompt
prompt DBA_FEATURE_USAGE_STATISTICS (DBA_FUS) INFORMATION - MOST RECENT SAMPLE BASED ON LAST_SAMPLE_DATE

select distinct
       &&DCID as CON_ID,
       first_value (DBID            ) over (partition by &&DCID order by last_sample_date desc nulls last) as last_dba_fus_dbid,
       first_value (VERSION         ) over (partition by &&DCID order by last_sample_date desc nulls last) as last_dba_fus_version,
       first_value (LAST_SAMPLE_DATE) over (partition by &&DCID order by last_sample_date desc nulls last) as last_dba_fus_sample_date,
       sysdate,
       case when (select trim(max(LAST_SAMPLE_DATE) || max(TOTAL_SAMPLES)) from &&DFUS.FEATURE_USAGE_STATISTICS) = '0'
            then 'NEVER SAMPLED !!!'
            else ''
       end as REMARKS
from &&DFUS.FEATURE_USAGE_STATISTICS
order by CON_ID
;

prompt
prompt
prompt ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
prompt PRODUCT USAGE
prompt ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

with
MAP as (
-- mapping between features tracked by DBA_FUS and their corresponding database products (options or packs)
select '' PRODUCT, '' feature, '' MVERSION, '' CONDITION from dual union all
SELECT 'Active Data Guard'                                   , 'Active Data Guard - Real-Time Query on Physical Standby' , '11.2'       , ' '       from dual union all
SELECT 'Active Data Guard'                                   , 'Active Data Guard - Real-Time Query on Physical Standby' , '12.1'       , ' '       from dual union all
SELECT 'Active Data Guard'                                   , 'Global Data Services'                                    , '12.1'       , ' '       from dual union all
SELECT 'Advanced Analytics'                                  , 'Data Mining'                                             , '11.2'       , ' '       from dual union all
SELECT 'Advanced Analytics'                                  , 'Data Mining'                                             , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'ADVANCED Index Compression'                              , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Advanced Index Compression'                              , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup HIGH Compression'                                 , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup HIGH Compression'                                 , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup LOW Compression'                                  , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup LOW Compression'                                  , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup MEDIUM Compression'                               , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup MEDIUM Compression'                               , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup ZLIB Compression'                                 , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup ZLIB Compression'                                 , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Data Guard'                                              , '11.2'       , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'Data Guard'                                              , '12.1'       , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'Flashback Data Archive'                                  , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Flashback Data Archive'                                  , '11.2.0.4'   , 'INVALID' from dual union all -- licensing required by Optimization for Flashback Data Archive
SELECT 'Advanced Compression'                                , 'Flashback Data Archive'                                  , '12.1'       , 'INVALID' from dual union all -- licensing required by Optimization for Flashback Data Archive
SELECT 'Advanced Compression'                                , 'HeapCompression'                                         , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'HeapCompression'                                         , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Heat Map'                                                , '12.1'       , ' '       from dual union all --
SELECT 'Advanced Compression'                                , 'Hybrid Columnar Compression Row Level Locking'           , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Information Lifecycle Management'                        , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Advanced Network Compression Service'             , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Utility Datapump (Export)'                        , '11.2'       , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Utility Datapump (Export)'                        , '12.1'       , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Utility Datapump (Import)'                        , '11.2'       , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Utility Datapump (Import)'                        , '12.1'       , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'SecureFile Compression (user)'                           , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'SecureFile Compression (user)'                           , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'SecureFile Deduplication (user)'                         , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'SecureFile Deduplication (user)'                         , '12.1'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Backup Encryption'                                       , '11.2'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Backup Encryption'                                       , '12.1'       , 'INVALID' from dual union all -- licensing required only by encryption to disk
SELECT 'Advanced Security'                                   , 'Data Redaction'                                          , '12.1'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Encrypted Tablespaces'                                   , '11.2'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Encrypted Tablespaces'                                   , '12.1'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Oracle Utility Datapump (Export)'                        , '11.2'       , 'C002'    from dual union all
SELECT 'Advanced Security'                                   , 'Oracle Utility Datapump (Export)'                        , '12.1'       , 'C002'    from dual union all
SELECT 'Advanced Security'                                   , 'Oracle Utility Datapump (Import)'                        , '11.2'       , 'C002'    from dual union all
SELECT 'Advanced Security'                                   , 'Oracle Utility Datapump (Import)'                        , '12.1'       , 'C002'    from dual union all
SELECT 'Advanced Security'                                   , 'SecureFile Encryption (user)'                            , '11.2'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'SecureFile Encryption (user)'                            , '12.1'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Transparent Data Encryption'                             , '11.2'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Transparent Data Encryption'                             , '12.1'       , ' '       from dual union all
SELECT 'Change Management Pack'                              , 'Change Management Pack'                                  , '11.2'       , ' '       from dual union all
SELECT 'Configuration Management Pack for Oracle Database'   , 'EM Config Management Pack'                               , '11.2'       , ' '       from dual union all
SELECT 'Data Masking Pack'                                   , 'Data Masking Pack'                                       , '11.2'       , ' '       from dual union all
SELECT '.Database Gateway'                                   , 'Gateways'                                                , '12.1'       , ' '       from dual union all
SELECT '.Database Gateway'                                   , 'Transparent Gateway'                                     , '12.1'       , ' '       from dual union all
SELECT 'Database In-Memory'                                  , 'In-Memory Aggregation'                                   , '12.1'       , ' '       from dual union all
SELECT 'Database In-Memory'                                  , 'In-Memory Column Store'                                  , '12.1.0.2'   , 'BUG'     from dual union all
SELECT 'Database Vault'                                      , 'Oracle Database Vault'                                   , '11.2'       , ' '       from dual union all
SELECT 'Database Vault'                                      , 'Oracle Database Vault'                                   , '12.1'       , ' '       from dual union all
SELECT 'Database Vault'                                      , 'Privilege Capture'                                       , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'ADDM'                                                    , '11.2'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'ADDM'                                                    , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Baseline'                                            , '11.2'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Baseline'                                            , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Baseline Template'                                   , '11.2'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Baseline Template'                                   , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Report'                                              , '11.2'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Report'                                              , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Automatic Workload Repository'                           , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Baseline Adaptive Thresholds'                            , '11.2'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Baseline Adaptive Thresholds'                            , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Baseline Static Computations'                            , '11.2'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Baseline Static Computations'                            , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Diagnostic Pack'                                         , '11.2'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'EM Performance Page'                                     , '12.1'       , ' '       from dual union all
SELECT '.Exadata'                                            , 'Exadata'                                                 , '11.2'       , ' '       from dual union all
SELECT '.Exadata'                                            , 'Exadata'                                                 , '12.1'       , ' '       from dual union all
SELECT '.GoldenGate'                                         , 'GoldenGate'                                              , '12.1'       , ' '       from dual union all
SELECT '.HW'                                                 , 'Hybrid Columnar Compression'                             , '12.1'       , 'BUG'     from dual union all
SELECT '.HW'                                                 , 'Hybrid Columnar Compression Row Level Locking'           , '12.1'       , ' '       from dual union all
SELECT '.HW'                                                 , 'Sun ZFS with EHCC'                                       , '12.1'       , ' '       from dual union all
SELECT '.HW'                                                 , 'ZFS Storage'                                             , '12.1'       , ' '       from dual union all
SELECT '.HW'                                                 , 'Zone maps'                                               , '12.1'       , ' '       from dual union all
SELECT 'Label Security'                                      , 'Label Security'                                          , '11.2'       , ' '       from dual union all
SELECT 'Label Security'                                      , 'Label Security'                                          , '12.1'       , ' '       from dual union all
SELECT 'Multitenant'                                         , 'Oracle Multitenant'                                      , '12.1'       , 'C003'    from dual union all -- licensing required only when more than one PDB containers are created
SELECT 'Multitenant'                                         , 'Oracle Pluggable Databases'                              , '12.1'       , 'C003'    from dual union all -- licensing required only when more than one PDB containers are created
SELECT 'OLAP'                                                , 'OLAP - Analytic Workspaces'                              , '11.2'       , ' '       from dual union all
SELECT 'OLAP'                                                , 'OLAP - Analytic Workspaces'                              , '12.1'       , ' '       from dual union all
SELECT 'OLAP'                                                , 'OLAP - Cubes'                                            , '12.1'       , ' '       from dual union all
SELECT 'Partitioning'                                        , 'Partitioning (user)'                                     , '11.2'       , ' '       from dual union all
SELECT 'Partitioning'                                        , 'Partitioning (user)'                                     , '12.1'       , ' '       from dual union all
SELECT 'Partitioning'                                        , 'Zone maps'                                               , '12.1'       , ' '       from dual union all
SELECT '.Pillar Storage'                                     , 'Pillar Storage'                                          , '12.1'       , ' '       from dual union all
SELECT '.Pillar Storage'                                     , 'Pillar Storage with EHCC'                                , '12.1'       , ' '       from dual union all
SELECT '.Provisioning and Patch Automation Pack'             , 'EM Standalone Provisioning and Patch Automation Pack'    , '11.2'       , ' '       from dual union all
SELECT 'Provisioning and Patch Automation Pack for Database' , 'EM Database Provisioning and Patch Automation Pack'      , '11.2'       , ' '       from dual union all
SELECT 'RAC or RAC One Node'                                 , 'Quality of Service Management'                           , '12.1'       , ' '       from dual union all
SELECT 'Real Application Clusters'                           , 'Real Application Clusters (RAC)'                         , '11.2'       , ' '       from dual union all
SELECT 'Real Application Clusters'                           , 'Real Application Clusters (RAC)'                         , '12.1'       , ' '       from dual union all
SELECT 'Real Application Clusters One Node'                  , 'Real Application Cluster One Node'                       , '12.1'       , ' '       from dual union all
SELECT 'Real Application Testing'                            , 'Database Replay: Workload Capture'                       , '11.2'       , ' '       from dual union all
SELECT 'Real Application Testing'                            , 'Database Replay: Workload Capture'                       , '12.1'       , ' '       from dual union all
SELECT 'Real Application Testing'                            , 'Database Replay: Workload Replay'                        , '11.2'       , ' '       from dual union all
SELECT 'Real Application Testing'                            , 'Database Replay: Workload Replay'                        , '12.1'       , ' '       from dual union all
SELECT 'Real Application Testing'                            , 'SQL Performance Analyzer'                                , '11.2'       , ' '       from dual union all
SELECT 'Real Application Testing'                            , 'SQL Performance Analyzer'                                , '12.1'       , ' '       from dual union all
SELECT '.Secure Backup'                                      , 'Oracle Secure Backup'                                    , '12.1'       , 'INVALID' from dual union all  -- does not differentiate usage of Oracle Secure Backup Express, which is free
SELECT 'Spatial and Graph'                                   , 'Spatial'                                                 , '11.2'       , 'INVALID' from dual union all  -- does not differentiate usage of Locator, which is free
SELECT 'Spatial and Graph'                                   , 'Spatial'                                                 , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Automatic Maintenance - SQL Tuning Advisor'              , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Automatic SQL Tuning Advisor'                            , '11.2'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Automatic SQL Tuning Advisor'                            , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Real-Time SQL Monitoring'                                , '11.2'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Real-Time SQL Monitoring'                                , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Access Advisor'                                      , '11.2'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Access Advisor'                                      , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Monitoring and Tuning pages'                         , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Profile'                                             , '11.2'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Profile'                                             , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Tuning Advisor'                                      , '11.2'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Tuning Advisor'                                      , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Tuning Set (user)'                                   , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Tuning Pack'                                             , '11.2'       , ' '       from dual union all
SELECT '.WebLogic Server Management Pack Enterprise Edition' , 'EM AS Provisioning and Patch Automation Pack'            , '11.2'       , ' '       from dual union all
select '' PRODUCT, '' FEATURE, '' MVERSION, '' CONDITION from dual
),
FUS as (
-- the current data set to be used: DBA_FEATURE_USAGE_STATISTICS or CDB_FEATURE_USAGE_STATISTICS for Container Databases(CDBs)
select
    &&DCID as CON_ID,
    &&DCNA as CON_NAME,
    -- Detect and mark with Y the current DBA_FUS data set = Most Recent Sample based on LAST_SAMPLE_DATE
      case when DBID || '#' || VERSION || '#' || to_char(LAST_SAMPLE_DATE, 'YYYYMMDDHH24MISS') =
                first_value (DBID    )         over (partition by &&DCID order by LAST_SAMPLE_DATE desc nulls last, DBID desc) || '#' ||
                first_value (VERSION )         over (partition by &&DCID order by LAST_SAMPLE_DATE desc nulls last, DBID desc) || '#' ||
                first_value (to_char(LAST_SAMPLE_DATE, 'YYYYMMDDHH24MISS'))
                                               over (partition by &&DCID order by LAST_SAMPLE_DATE desc nulls last, DBID desc)
           then 'Y'
           else 'N'
    end as CURRENT_ENTRY,
    NAME            ,
    LAST_SAMPLE_DATE,
    DBID            ,
    VERSION         ,
    DETECTED_USAGES ,
    TOTAL_SAMPLES   ,
    CURRENTLY_USED  ,
    FIRST_USAGE_DATE,
    LAST_USAGE_DATE ,
    AUX_COUNT       ,
    FEATURE_INFO
from &&DFUS.FEATURE_USAGE_STATISTICS xy
),
PFUS as (
-- Product-Feature Usage Statitsics = DBA_FUS entries mapped to their corresponding database products
select
    CON_ID,
    CON_NAME,
    PRODUCT,
    NAME as FEATURE_BEING_USED,
    case  when CONDITION = 'BUG'
               --suppressed due to exceptions/defects
            then '3.SUPPRESSED_DUE_TO_BUG'
          when detected_usages > 0               -- some usage detection - current or past
           and(trim(CONDITION) is null
               -- if special conditions (coded on the MAP.CONDITION column) are required, check if entries satisfy the condition
               -- C001 = compression has been used
               or CONDITION = 'C001' and regexp_like(to_char(FEATURE_INFO), 'compression used: *TRUE', 'i')
               -- C002 = encryption has been used
               or CONDITION = 'C002' and regexp_like(to_char(FEATURE_INFO), 'encryption used: *TRUE', 'i')
               -- C003 = more than one PDB are created
               or CONDITION = 'C003' and CON_ID=1 and AUX_COUNT > 1
              )
            then decode(CURRENT_ENTRY || '#' || CURRENTLY_USED, 'Y#TRUE', '6.CURRENT_USAGE', '4.PAST_USAGE')
          when detected_usages > 0               -- some usage detection - current or past
           and(
               -- if special counter conditions (coded on the MAP.CONDITION column) are required, check if the counter value is not 0
               -- C001 = compression has been used at least once
                  CONDITION = 'C001' and regexp_like(to_char(FEATURE_INFO), 'compression used:[ 0-9]*[1-9][ 0-9]*time', 'i')
               -- C002 = encryption has been used at least once
               or CONDITION = 'C002' and regexp_like(to_char(FEATURE_INFO), 'encryption used:[ 0-9]*[1-9][ 0-9]*time', 'i')
              )
            then decode(CURRENT_ENTRY || '#' || CURRENTLY_USED, 'Y#TRUE', '5.PAST_OR_CURRENT_USAGE', '4.PAST_USAGE') -- FEATURE_INFO counters indicate current or past usage
          when CURRENT_ENTRY = 'Y' then '2.NO_CURRENT_USAGE'   -- detectable feature shows no current usage
          else '1.NO_PAST_USAGE'
    end as USAGE,
    LAST_SAMPLE_DATE,
    DBID            ,
    VERSION         ,
    DETECTED_USAGES ,
    TOTAL_SAMPLES   ,
    CURRENTLY_USED  ,
    FIRST_USAGE_DATE,
    LAST_USAGE_DATE
from (
select m.PRODUCT, m.CONDITION, m.MVERSION,
       first_value (m.MVERSION) over (partition by f.CON_ID, f.NAME, f.VERSION order by m.MVERSION desc nulls last) as MMVERSION,
       f.*
  from MAP m
  join FUS f on m.FEATURE = f.NAME and m.MVERSION = substr(f.VERSION, 1, length(m.MVERSION))
  where nvl(f.TOTAL_SAMPLES, 0) > 0            -- ignore features that have never been sampled
)
  where MVERSION = MMVERSION              -- retain only the MAP entry that mathces the most to the DBA_FUS version = the "most matching version"
    and nvl(CONDITION, '-') != 'INVALID'  -- ignore entries that are invalidated by bugs or known issues or correspond to features which became free of charge
    and not (CONDITION = 'C003' and CON_ID not in (0, 1)) -- multiple PDBs are visible only in CDB$ROOT
)
select
    grouping_id(CON_ID) as gid,
    CON_ID   ,
    decode(grouping_id(CON_ID), 1, '--ALL--', max(CON_NAME)) as CON_NAME,
    PRODUCT  ,
    max(USAGE)            as USAGE,
    max(LAST_SAMPLE_DATE) as LAST_SAMPLE_DATE,
    min(FIRST_USAGE_DATE) as FIRST_USAGE_DATE,
    max(LAST_USAGE_DATE)  as LAST_USAGE_DATE
  from PFUS
  where USAGE in ('2.NO_CURRENT_USAGE', '4.PAST_USAGE', '5.PAST_OR_CURRENT_USAGE', '6.CURRENT_USAGE')   -- ignore '1.NO_PAST_USAGE', '3.SUPPRESSED_DUE_TO_BUG'
  group by rollup(CON_ID), PRODUCT
  having not (max(CON_ID) in (-1, 0) and grouping_id(CON_ID) = 1)            -- aggregation not needed for non-container databases
order by GID desc, CON_ID, decode(substr(PRODUCT, 1, 1), '.', 2, 1), PRODUCT
;


prompt
prompt
prompt ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
prompt FEATURE USAGE DETAILS
prompt ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

with
MAP as (
-- mapping between features tracked by DBA_FUS and their corresponding database products (options or packs)
select '' PRODUCT, '' feature, '' MVERSION, '' CONDITION from dual union all
SELECT 'Active Data Guard'                                   , 'Active Data Guard - Real-Time Query on Physical Standby' , '11.2'       , ' '       from dual union all
SELECT 'Active Data Guard'                                   , 'Active Data Guard - Real-Time Query on Physical Standby' , '12.1'       , ' '       from dual union all
SELECT 'Active Data Guard'                                   , 'Global Data Services'                                    , '12.1'       , ' '       from dual union all
SELECT 'Advanced Analytics'                                  , 'Data Mining'                                             , '11.2'       , ' '       from dual union all
SELECT 'Advanced Analytics'                                  , 'Data Mining'                                             , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'ADVANCED Index Compression'                              , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Advanced Index Compression'                              , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup HIGH Compression'                                 , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup HIGH Compression'                                 , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup LOW Compression'                                  , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup LOW Compression'                                  , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup MEDIUM Compression'                               , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup MEDIUM Compression'                               , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup ZLIB Compression'                                 , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Backup ZLIB Compression'                                 , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Data Guard'                                              , '11.2'       , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'Data Guard'                                              , '12.1'       , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'Flashback Data Archive'                                  , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Flashback Data Archive'                                  , '11.2.0.4'   , 'INVALID' from dual union all -- licensing required by Optimization for Flashback Data Archive
SELECT 'Advanced Compression'                                , 'Flashback Data Archive'                                  , '12.1'       , 'INVALID' from dual union all -- licensing required by Optimization for Flashback Data Archive
SELECT 'Advanced Compression'                                , 'HeapCompression'                                         , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'HeapCompression'                                         , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Heat Map'                                                , '12.1'       , ' '       from dual union all --
SELECT 'Advanced Compression'                                , 'Hybrid Columnar Compression Row Level Locking'           , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Information Lifecycle Management'                        , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Advanced Network Compression Service'             , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Utility Datapump (Export)'                        , '11.2'       , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Utility Datapump (Export)'                        , '12.1'       , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Utility Datapump (Import)'                        , '11.2'       , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'Oracle Utility Datapump (Import)'                        , '12.1'       , 'C001'    from dual union all
SELECT 'Advanced Compression'                                , 'SecureFile Compression (user)'                           , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'SecureFile Compression (user)'                           , '12.1'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'SecureFile Deduplication (user)'                         , '11.2'       , ' '       from dual union all
SELECT 'Advanced Compression'                                , 'SecureFile Deduplication (user)'                         , '12.1'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Backup Encryption'                                       , '11.2'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Backup Encryption'                                       , '12.1'       , 'INVALID' from dual union all -- licensing required only by encryption to disk
SELECT 'Advanced Security'                                   , 'Data Redaction'                                          , '12.1'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Encrypted Tablespaces'                                   , '11.2'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Encrypted Tablespaces'                                   , '12.1'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Oracle Utility Datapump (Export)'                        , '11.2'       , 'C002'    from dual union all
SELECT 'Advanced Security'                                   , 'Oracle Utility Datapump (Export)'                        , '12.1'       , 'C002'    from dual union all
SELECT 'Advanced Security'                                   , 'Oracle Utility Datapump (Import)'                        , '11.2'       , 'C002'    from dual union all
SELECT 'Advanced Security'                                   , 'Oracle Utility Datapump (Import)'                        , '12.1'       , 'C002'    from dual union all
SELECT 'Advanced Security'                                   , 'SecureFile Encryption (user)'                            , '11.2'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'SecureFile Encryption (user)'                            , '12.1'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Transparent Data Encryption'                             , '11.2'       , ' '       from dual union all
SELECT 'Advanced Security'                                   , 'Transparent Data Encryption'                             , '12.1'       , ' '       from dual union all
SELECT 'Change Management Pack'                              , 'Change Management Pack'                                  , '11.2'       , ' '       from dual union all
SELECT 'Configuration Management Pack for Oracle Database'   , 'EM Config Management Pack'                               , '11.2'       , ' '       from dual union all
SELECT 'Data Masking Pack'                                   , 'Data Masking Pack'                                       , '11.2'       , ' '       from dual union all
SELECT '.Database Gateway'                                   , 'Gateways'                                                , '12.1'       , ' '       from dual union all
SELECT '.Database Gateway'                                   , 'Transparent Gateway'                                     , '12.1'       , ' '       from dual union all
SELECT 'Database In-Memory'                                  , 'In-Memory Aggregation'                                   , '12.1'       , ' '       from dual union all
SELECT 'Database In-Memory'                                  , 'In-Memory Column Store'                                  , '12.1.0.2'   , 'BUG'     from dual union all
SELECT 'Database Vault'                                      , 'Oracle Database Vault'                                   , '11.2'       , ' '       from dual union all
SELECT 'Database Vault'                                      , 'Oracle Database Vault'                                   , '12.1'       , ' '       from dual union all
SELECT 'Database Vault'                                      , 'Privilege Capture'                                       , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'ADDM'                                                    , '11.2'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'ADDM'                                                    , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Baseline'                                            , '11.2'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Baseline'                                            , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Baseline Template'                                   , '11.2'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Baseline Template'                                   , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Report'                                              , '11.2'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'AWR Report'                                              , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Automatic Workload Repository'                           , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Baseline Adaptive Thresholds'                            , '11.2'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Baseline Adaptive Thresholds'                            , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Baseline Static Computations'                            , '11.2'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Baseline Static Computations'                            , '12.1'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'Diagnostic Pack'                                         , '11.2'       , ' '       from dual union all
SELECT 'Diagnostics Pack'                                    , 'EM Performance Page'                                     , '12.1'       , ' '       from dual union all
SELECT '.Exadata'                                            , 'Exadata'                                                 , '11.2'       , ' '       from dual union all
SELECT '.Exadata'                                            , 'Exadata'                                                 , '12.1'       , ' '       from dual union all
SELECT '.GoldenGate'                                         , 'GoldenGate'                                              , '12.1'       , ' '       from dual union all
SELECT '.HW'                                                 , 'Hybrid Columnar Compression'                             , '12.1'       , 'BUG'     from dual union all
SELECT '.HW'                                                 , 'Hybrid Columnar Compression Row Level Locking'           , '12.1'       , ' '       from dual union all
SELECT '.HW'                                                 , 'Sun ZFS with EHCC'                                       , '12.1'       , ' '       from dual union all
SELECT '.HW'                                                 , 'ZFS Storage'                                             , '12.1'       , ' '       from dual union all
SELECT '.HW'                                                 , 'Zone maps'                                               , '12.1'       , ' '       from dual union all
SELECT 'Label Security'                                      , 'Label Security'                                          , '11.2'       , ' '       from dual union all
SELECT 'Label Security'                                      , 'Label Security'                                          , '12.1'       , ' '       from dual union all
SELECT 'Multitenant'                                         , 'Oracle Multitenant'                                      , '12.1'       , 'C003'    from dual union all -- licensing required only when more than one PDB containers are created
SELECT 'Multitenant'                                         , 'Oracle Pluggable Databases'                              , '12.1'       , 'C003'    from dual union all -- licensing required only when more than one PDB containers are created
SELECT 'OLAP'                                                , 'OLAP - Analytic Workspaces'                              , '11.2'       , ' '       from dual union all
SELECT 'OLAP'                                                , 'OLAP - Analytic Workspaces'                              , '12.1'       , ' '       from dual union all
SELECT 'OLAP'                                                , 'OLAP - Cubes'                                            , '12.1'       , ' '       from dual union all
SELECT 'Partitioning'                                        , 'Partitioning (user)'                                     , '11.2'       , ' '       from dual union all
SELECT 'Partitioning'                                        , 'Partitioning (user)'                                     , '12.1'       , ' '       from dual union all
SELECT 'Partitioning'                                        , 'Zone maps'                                               , '12.1'       , ' '       from dual union all
SELECT '.Pillar Storage'                                     , 'Pillar Storage'                                          , '12.1'       , ' '       from dual union all
SELECT '.Pillar Storage'                                     , 'Pillar Storage with EHCC'                                , '12.1'       , ' '       from dual union all
SELECT '.Provisioning and Patch Automation Pack'             , 'EM Standalone Provisioning and Patch Automation Pack'    , '11.2'       , ' '       from dual union all
SELECT 'Provisioning and Patch Automation Pack for Database' , 'EM Database Provisioning and Patch Automation Pack'      , '11.2'       , ' '       from dual union all
SELECT 'RAC or RAC One Node'                                 , 'Quality of Service Management'                           , '12.1'       , ' '       from dual union all
SELECT 'Real Application Clusters'                           , 'Real Application Clusters (RAC)'                         , '11.2'       , ' '       from dual union all
SELECT 'Real Application Clusters'                           , 'Real Application Clusters (RAC)'                         , '12.1'       , ' '       from dual union all
SELECT 'Real Application Clusters One Node'                  , 'Real Application Cluster One Node'                       , '12.1'       , ' '       from dual union all
SELECT 'Real Application Testing'                            , 'Database Replay: Workload Capture'                       , '11.2'       , ' '       from dual union all
SELECT 'Real Application Testing'                            , 'Database Replay: Workload Capture'                       , '12.1'       , ' '       from dual union all
SELECT 'Real Application Testing'                            , 'Database Replay: Workload Replay'                        , '11.2'       , ' '       from dual union all
SELECT 'Real Application Testing'                            , 'Database Replay: Workload Replay'                        , '12.1'       , ' '       from dual union all
SELECT 'Real Application Testing'                            , 'SQL Performance Analyzer'                                , '11.2'       , ' '       from dual union all
SELECT 'Real Application Testing'                            , 'SQL Performance Analyzer'                                , '12.1'       , ' '       from dual union all
SELECT '.Secure Backup'                                      , 'Oracle Secure Backup'                                    , '12.1'       , 'INVALID' from dual union all  -- does not differentiate usage of Oracle Secure Backup Express, which is free
SELECT 'Spatial and Graph'                                   , 'Spatial'                                                 , '11.2'       , 'INVALID' from dual union all  -- does not differentiate usage of Locator, which is free
SELECT 'Spatial and Graph'                                   , 'Spatial'                                                 , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Automatic Maintenance - SQL Tuning Advisor'              , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Automatic SQL Tuning Advisor'                            , '11.2'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Automatic SQL Tuning Advisor'                            , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Real-Time SQL Monitoring'                                , '11.2'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Real-Time SQL Monitoring'                                , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Access Advisor'                                      , '11.2'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Access Advisor'                                      , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Monitoring and Tuning pages'                         , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Profile'                                             , '11.2'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Profile'                                             , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Tuning Advisor'                                      , '11.2'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Tuning Advisor'                                      , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'SQL Tuning Set (user)'                                   , '12.1'       , ' '       from dual union all
SELECT 'Tuning Pack'                                         , 'Tuning Pack'                                             , '11.2'       , ' '       from dual union all
SELECT '.WebLogic Server Management Pack Enterprise Edition' , 'EM AS Provisioning and Patch Automation Pack'            , '11.2'       , ' '       from dual union all
select '' PRODUCT, '' FEATURE, '' MVERSION, '' CONDITION from dual
),
FUS as (
-- the current data set to be used: DBA_FEATURE_USAGE_STATISTICS or CDB_FEATURE_USAGE_STATISTICS for Container Databases(CDBs)
select
    &&DCID as CON_ID,
    &&DCNA as CON_NAME,
    -- Detect and mark with Y the current DBA_FUS data set = Most Recent Sample based on LAST_SAMPLE_DATE
      case when DBID || '#' || VERSION || '#' || to_char(LAST_SAMPLE_DATE, 'YYYYMMDDHH24MISS') =
                first_value (DBID    )         over (partition by &&DCID order by LAST_SAMPLE_DATE desc nulls last, DBID desc) || '#' ||
                first_value (VERSION )         over (partition by &&DCID order by LAST_SAMPLE_DATE desc nulls last, DBID desc) || '#' ||
                first_value (to_char(LAST_SAMPLE_DATE, 'YYYYMMDDHH24MISS'))
                                               over (partition by &&DCID order by LAST_SAMPLE_DATE desc nulls last, DBID desc)
           then 'Y'
           else 'N'
    end as CURRENT_ENTRY,
    NAME            ,
    LAST_SAMPLE_DATE,
    DBID            ,
    VERSION         ,
    DETECTED_USAGES ,
    TOTAL_SAMPLES   ,
    CURRENTLY_USED  ,
    FIRST_USAGE_DATE,
    LAST_USAGE_DATE ,
    AUX_COUNT       ,
    FEATURE_INFO
from &&DFUS.FEATURE_USAGE_STATISTICS xy
),
PFUS as (
-- Product-Feature Usage Statitsics = DBA_FUS entries mapped to their corresponding database products
select
    CON_ID,
    CON_NAME,
    PRODUCT,
    NAME as FEATURE_BEING_USED,
    case  when CONDITION = 'BUG'
               --suppressed due to exceptions/defects
            then '3.SUPPRESSED_DUE_TO_BUG'
          when detected_usages > 0               -- some usage detection - current or past
           and(trim(CONDITION) is null
               -- if special conditions (coded on the MAP.CONDITION column) are required, check if entries satisfy the condition
               -- C001 = compression has been used
               or CONDITION = 'C001' and regexp_like(to_char(FEATURE_INFO), 'compression used: *TRUE', 'i')
               -- C002 = encryption has been used
               or CONDITION = 'C002' and regexp_like(to_char(FEATURE_INFO), 'encryption used: *TRUE', 'i')
               -- C003 = more than one PDB are created
               or CONDITION = 'C003' and CON_ID=1 and AUX_COUNT > 1
              )
            then decode(CURRENT_ENTRY || '#' || CURRENTLY_USED, 'Y#TRUE', '6.CURRENT_USAGE', '4.PAST_USAGE')
          when detected_usages > 0               -- some usage detection - current or past
           and(
               -- if special counter conditions (coded on the MAP.CONDITION column) are required, check if the counter value is not 0
               -- C001 = compression has been used at least once
                  CONDITION = 'C001' and regexp_like(to_char(FEATURE_INFO), 'compression used:[ 0-9]*[1-9][ 0-9]*time', 'i')
               -- C002 = encryption has been used at least once
               or CONDITION = 'C002' and regexp_like(to_char(FEATURE_INFO), 'encryption used:[ 0-9]*[1-9][ 0-9]*time', 'i')
              )
            then decode(CURRENT_ENTRY || '#' || CURRENTLY_USED, 'Y#TRUE', '5.PAST_OR_CURRENT_USAGE', '4.PAST_USAGE') -- FEATURE_INFO counters indicate current or past usage
          when CURRENT_ENTRY = 'Y' then '2.NO_CURRENT_USAGE'   -- detectable feature shows no current usage
          else '1.NO_PAST_USAGE'
    end as USAGE,
    LAST_SAMPLE_DATE,
    DBID            ,
    VERSION         ,
    DETECTED_USAGES ,
    TOTAL_SAMPLES   ,
    CURRENTLY_USED  ,
    FIRST_USAGE_DATE,
    LAST_USAGE_DATE,
    case when CONDITION = 'C001' then
                     regexp_substr(to_char(FEATURE_INFO), 'compression used:(.*?)(times|TRUE|FALSE)')
         when CONDITION = 'C002' then
                     regexp_substr(to_char(FEATURE_INFO), 'encryption used:(.*?)(times|TRUE|FALSE)')
         when CONDITION = 'C003' then
              'AUX_COUNT=' || AUX_COUNT
         else ''
    end as EXTRA_FEATURE_INFO
from (
select m.PRODUCT, m.CONDITION, m.MVERSION,
       first_value (m.MVERSION) over (partition by f.CON_ID, f.NAME, f.VERSION order by m.MVERSION desc nulls last) as MMVERSION,
       f.*
  from MAP m
  join FUS f on m.FEATURE = f.NAME and m.MVERSION = substr(f.VERSION, 1, length(m.MVERSION))
  where nvl(f.TOTAL_SAMPLES, 0) > 0            -- ignore features that have never been sampled
)
  where MVERSION = MMVERSION              -- retain only the MAP entry that mathces the most to the DBA_FUS version = the "most matching version"
    and nvl(CONDITION, '-') != 'INVALID'  -- ignore entries that are invalidated by bugs or known issues or correspond to features which became free of charge
    and not (CONDITION = 'C003' and CON_ID not in (0, 1)) -- multiple PDBs are visible only in CDB$ROOT
)
select
    CON_ID            ,
    CON_NAME          ,
    PRODUCT           ,
    FEATURE_BEING_USED,
    USAGE             ,
    LAST_SAMPLE_DATE  ,
    DBID              ,
    VERSION           ,
    DETECTED_USAGES   ,
    TOTAL_SAMPLES     ,
    CURRENTLY_USED    ,
    FIRST_USAGE_DATE  ,
    LAST_USAGE_DATE   ,
    EXTRA_FEATURE_INFO
  from PFUS
  where USAGE in ('2.NO_CURRENT_USAGE', '3.SUPPRESSED_DUE_TO_BUG', '4.PAST_USAGE', '5.PAST_OR_CURRENT_USAGE', '6.CURRENT_USAGE')  -- ignore '1.NO_PAST_USAGE'
order by CON_ID, decode(substr(PRODUCT, 1, 1), '.', 2, 1), PRODUCT, FEATURE_BEING_USED, LAST_SAMPLE_DATE desc, USAGE
;

prompt
prompt ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
prompt NOTES:
prompt ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
prompt * The report lists all detectable products, according to the sampled database version(s)
prompt * CURRENT_USAGE represents usage tracked over the last sample period, which defaults to one week.
prompt * PAST_OR_CURRENT_USAGE example: Datapump Export entry indicates CURRENTLY_USED='TRUE' and FEATURE_INFO "compression used" counter
prompt *                                indicates a non zero value that can be originated by past or current usage.
prompt * For historical details check FIRST_USAGE_DATE, LAST_USAGE_DATE, LAST_SAMPLE_DATE, TOTAL_SAMPLES, DETECTED_USAGES columns
prompt * Leading dot (.) denotes a product that is not a Database Option or Database Management Pack

prompt
show USER
prompt End of script

spool off
