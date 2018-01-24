

--alter session set current_schema=icu;
--alter session set statistics_level=all;

-- set your favourite editor, must be in your path
--define _editor="notepad++"
define _editor="nano"

-- raise arraysize to higher value
set arraysize 100

-- useful and clearer prompt
set sqlprompt "_USER'@'_CONNECT_IDENTIFIER> "

-- make default date format nicer, reset termout back to normal
set termout off
alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
set termout on

-- better output
set linesize 300
set pagesize 1000

-- fetch 10000000 bytes of long datatypes. good for
-- querying DBA_VIEWS and DBA_TRIGGERS
set long 10000000
set longchunksize 10000000

-- to have less garbage on screen
set verify off

-- to trim trailing spaces from spool files
set trimspool on

-- to trim trailing spaces from screen output
set trimout on

-- don't use tabs instead of spaces for "wide blanks"
-- this can mess up the vertical column locations in output
set tab off

-- this makes describe command better to read and more
-- informative in case of complex datatypes in columns
set describe depth 1 linenum on indent on
