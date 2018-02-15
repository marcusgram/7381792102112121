

select group#,members,status,bytes/1024/1024 as mb from v$log;


    GROUP#    MEMBERS STATUS                   MB
---------- ---------- ---------------- ----------
         1          2 INACTIVE               1024
         2          2 INACTIVE               1024
         3          2 CURRENT                1024
         



-- size of the redo log members --
set linesize 300
column REDOLOG_FILE_NAME format a50
SELECT
    a.GROUP#,
    a.THREAD#,
    a.SEQUENCE#,
    a.ARCHIVED,
    a.STATUS,
    b.MEMBER    AS REDOLOG_FILE_NAME,
    (a.BYTES/1024/1024) AS SIZE_MB
FROM v$log a
JOIN v$logfile b ON a.Group#=b.Group# 
ORDER BY a.GROUP# ASC;

    GROUP#    THREAD#  SEQUENCE# ARC STATUS           REDOLOG_FILE_NAME                                     SIZE_MB
---------- ---------- ---------- --- ---------------- -------------------------------------------------- ----------
         1          1      32129 YES INACTIVE         /apps/oradata01/X11121AP1/datafile/red11.rdo             1024
         1          1      32129 YES INACTIVE         /apps/orafra/X11121AP1/red12.rdo                         1024
         2          1      32130 YES INACTIVE         /apps/oradata01/X11121AP1/datafile/red21.rdo             1024
         2          1      32130 YES INACTIVE         /apps/orafra/X11121AP1/red22.rdo                         1024
         3          1      32131 NO  CURRENT          /apps/oradata01/X11121AP1/datafile/red31.rdo             1024
         3          1      32131 NO  CURRENT          /apps/orafra/X11121AP1/red32.rdo                         1024




-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/logfiles.sql
-- Author       : Tim Hall
-- Description  : Displays information about redo log files.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @logfiles
-- Last Modified: 21/12/2004
-- -----------------------------------------------------------------------------------

SELECT l.thread#,
       lf.group#,
       lf.member,
       TRUNC(l.bytes/1024/1024) AS size_mb,
       l.status,
       l.archived,
       lf.type,
       lf.is_recovery_dest_file AS rdf,
       l.sequence#,
       l.first_change#,
       l.next_change#   
FROM   v$logfile lf
       JOIN v$log l ON l.group# = lf.group#
ORDER BY l.thread#,lf.group#, lf.member;

SET LINESIZE 80

   THREAD#     GROUP# MEMBER                                                SIZE_MB STATUS           ARC TYPE    RDF  SEQUENCE#         FIRST_CHANGE#          NEXT_CHANGE#
---------- ---------- -------------------------------------------------- ---------- ---------------- --- ------- --- ---------- --------------------- ---------------------
         1          1 /apps/oradata01/X11121AP1/datafile/red11.rdo             1024 INACTIVE         YES ONLINE  NO       32129             299396926             299403634
         1          1 /apps/orafra/X11121AP1/red12.rdo                         1024 INACTIVE         YES ONLINE  NO       32129             299396926             299403634
         1          2 /apps/oradata01/X11121AP1/datafile/red21.rdo             1024 INACTIVE         YES ONLINE  NO       32130             299403634             299408205
         1          2 /apps/orafra/X11121AP1/red22.rdo                         1024 INACTIVE         YES ONLINE  NO       32130             299403634             299408205
         1          3 /apps/oradata01/X11121AP1/datafile/red31.rdo             1024 CURRENT          NO  ONLINE  NO       32131             299408205       281474976710655
         1          3 /apps/orafra/X11121AP1/red32.rdo                         1024 CURRENT          NO  ONLINE  NO       32131             299408205       281474976710655

 6 lignes sélectionnées 

set linesize 200
select group#,member from v$logfile;
