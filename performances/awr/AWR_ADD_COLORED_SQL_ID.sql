
ADD_COLORED_SQL Procedure
--------------------------
This procedure adds a colored SQL ID. 
If an SQL ID is colored, it will be captured in every snapshot, independent of its level of activities (so that it does not have to be a TOP SQL). 
Capture occurs if the SQL is found in the cursor cache at snapshot time.To uncolor the SQL, invoke the REMOVE_COLORED_SQL Procedure.

Syntax
------
DBMS_WORKLOAD_REPOSITORY.ASH_REPORT_HTML(
   sql_id         IN VARCHAR2,
   dbid           IN NUMBER DEFAULT NULL);


desc wrm$_colored_sql;

 Name                                      Null?    Type
 ----------------------------------------- -------- ----------------------------
 DBID                                      NOT NULL NUMBER
 SQL_ID                                    NOT NULL VARCHAR2(13)
 OWNER                                     NOT NULL NUMBER
 CREATE_TIME                               NOT NULL DATE

 
 
 
SELECT * FROM wrm$_colored_sql;

SELECT dbid
FROM v$database;

SELECT sql_id
FROM gv$sql
WHERE rownum < 101;


exec dbms_workload_repository.add_colored_sql('a2wuq2td4dd3g',2517960719);


SELECT * FROM wrm$_colored_sql;