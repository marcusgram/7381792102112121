http://satya-dba.blogspot.co.uk/2010/08/setting-sql-prompt-in-oracle.html

$ORACLE_HOME/sqlplus/admin/glogin.sql
set sqlprompt "&_user> "
set sqlprompt "_user'@'_connect_identifier>"

_connect_identifier will display connection identifier.
_date               will display date.
_editor             will display editor name used by the EDIT command.
_o_version          will display Oracle version.
_o_release          will display Oracle release.
_privilege          will display privilege such as SYSDBA, SYSOPER, SYSASM
_sqlplus_release    will display SQL*PLUS release.
_user               will display current user name.

set sqlprompt "&_connect_identifier> "
set sqlprompt "&_date> "
set sqlprompt "&_editor> "
set sqlprompt "&_o_version> "
set sqlprompt "&_o_release> "
set sqlprompt "&_privilege> "
set sqlprompt "&_sqlplus_release> "
set sqlprompt "&_user> 



set appinfo OFF
set appinfo "SQL*Plus"
set arraysize 15
set autocommit OFF
set autoprint OFF
set autorecovery OFF
set autotrace OFF
set blockterminator "."
set cmdsep OFF
set colsep " "
set compatibility NATIVE
set concat "."
set copycommit 0
set copytypecheck ON
set define "&"
set describe DEPTH 1 LINENUM OFF INDENT ON
set echo OFF
set editfile "afiedt.buf"
set embedded OFF
set escape OFF
set escchar OFF
set exitcommit ON
set feedback 6
set flagger OFF
set flush ON
set heading ON
set headsep "|"
set linesize 9999
set logsource ""
set long 5000
set longchunksize 80
set markup HTML OFF HEAD "<style type='text/css'> body {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} p {font:10pt Arial,Helvetica,sans-serif; color:black; background:White;} table,tr,td {font:10pt Arial,Helvetica,sans-serif; color:Black; background:#f7f7e7; padding:0px 0px 0px 0px; margin:0px 0px 0px 0px;} th {font:bold 10pt Arial,Helvetica,sans-serif; color:#336699; background:#cccc99; padding:0px 0px 0px 0px;} h1 {font:16pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; border-bottom:1px solid #cccc99; margin-top:0pt; margin-bottom:0pt; padding:0px 0px 0px 0px; } h2 {font:bold 10pt Arial,Helvetica,Geneva,sans-serif; color:#336699; background-color:White; margin-top:4pt; margin-bottom:0pt;} a {font:9pt Arial,Helvetica,sans-serif; color:#663300; background:#ffffff; margin-top:0pt; margin-bottom:0pt; vertical-align:top;}</style><title>SQL*Plus Report</title>" BODY "" TABLE "border='1' width='90%' align='center' summary='Script output'" SPOOL OFF ENTMAP ON PRE OFF
set newpage 1
set null ""
set numformat ""
set numwidth 10
set pagesize 999
set pause OFF
set recsep WRAP
set recsepchar " "
set securedcol OFF
set serveroutput OFF
set shiftinout invisible
set showmode OFF
set sqlblanklines OFF
set sqlcase MIXED
set sqlcontinue "> "
set sqlnumber ON
set sqlpluscompatibility 11.2.0
set sqlprefix "#"
set sqlprompt "nkarag@DWHPRD> "
set sqlterminator ";"
set suffix "sql"
set tab ON
set termout ON
set time OFF
set timing ON
set trimout ON
set trimspool ON
set underline "-"
set verify ON
set wrap OFF
