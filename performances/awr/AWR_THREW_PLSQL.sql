--How to create an Oracle AWR report with SQL and PL/SQL
------------------------------------------------------

/*--AWR is a great tool (but needs diagnostics pack). It can create very useful reports for performace analysis over a given ----period. Most people will pull the AWR Report  from the OS level, with ‘@?/rdbms/admin/awrrpt.sql” (or one of the other scripts --there). But sometime it’s not possible to access a database server’s OS level, or gain permission to do so. So we also can create the whole bunch of possible AWR and ASH reports from SQL level, too. We can have it in text or HTML, it’s just a matter of personal taste. I always preferred the text version, but there are many facts pro HTML. Anyway, here is my cheat sheet how to do it, and the difference in RAC.*/

--What we have to know

--Our database ID (DBID):

select dbid 
  from v$database;
The period we are interested in, spoken in snapshot IDs:

select /*+ FIRST_ROWS */ * 
  from DBA_HIST_SNAPSHOT
  order by snap_id desc, instance_number desc;
Retrieving the report

SELECT output
FROM TABLE (dbms_workload_repository.awr_report_text(
 l_dbid=>123456789,
 l_inst_num=>1,
 l_bid=>24142,
 l_eid=>24143
 )
);

--The return value comes in one column named “output”.

/*Global report for RAC

In Real Application Clusters, we need a special report, to get an overview over how the full system performed. For this purpose, Oracle supplied an own subprogram, delivering a different report style. I’m usually executing it like this:

*/

SELECT output
FROM TABLE (dbms_workload_repository.awr_global_report_text(
 l_dbid=>123456789,
 l_inst_num=>'',
 l_bid=>24142,
 l_eid=>24143,
 l_options=>0
 )
);

