
--------------------------------------------------------------------------------------------------------
--Resizing a Smallfile Tablespace Using ALTER DATABASE

--In the following examples, we attempt to resize the USERS tablespace, which contains one
--datafile, starting out at 5MB. First, we make it 15MB, then realize it’s too big, and shrink it down
--to 10MB. Then, we attempt to shrink it too much. Finally, we try to increase its size too much.
---------------------------------------------------------------------------------------------------------

alter database datafile '/u01/app/oracle/oradata/rmanrep/users01.dbf' resize 15m;

alter database datafile '/u01/app/oracle/oradata/rmanrep/users01.dbf' resize 10m;

alter database datafile '/u01/app/oracle/oradata/rmanrep/users01.dbf' autoextend on next 20m maxsize 1g;

---------------
--Add datafiles
---------------
alter tablespace users
 add datafile '/u03/oradata/users02.dbf'
 size 50m
 autoextend on
 next 10m
 maxsize 200m;
 
 
 
