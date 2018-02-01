


conn / as sysdba

 grant create any directory to mpf;
 grant create     table     to mpf;

=========================================================

conn mpf
define alert_length="2000"
drop table alert_log;

prompt ============ PREPARE ALERTS OBJECTS ==============

create table alert_log (
  alert_date date,
  alert_text varchar2(&&alert_length)
)
storage (initial 512k next 512K pctincrease 0)
/

create index alert_log_idx on alert_log(alert_date)
storage (initial 512k next 512K pctincrease 0)
/


column db    new_value _DB    noprint;
column bdump new_value _bdump noprint;

select instance_name db from v$instance;

select value BDUMP
from v$parameter 
where name ='background_dump_dest';

drop directory BDUMP;

create directory BDUMP as '&&_bdump';

drop table alert_log_disk;

create table alert_log_disk ( text varchar2(&&alert_length) )
organization external (
  type oracle_loader
  default directory BDUMP
      access parameters (
          records delimited by newline nologfile nobadfile
          fields terminated by "&" ltrim
      )
  location('alert_&&_DB..log')
)
reject limit unlimited
/




============= LOAD DATAS FROM ALERTS.LOG : update_alert_log =============

set serveroutput on 

declare
  
  isdate         number := 0;
  start_updating number := 0;
  rows_inserted  number := 0;
  
  alert_date     date;
  max_date       date;
  
  alert_text     alert_log_disk.text%type;

begin
  
  /* find a starting date */
  select max(alert_date) into max_date from alert_log;
  
  if (max_date is null) then
    max_date := to_date('01-jan-1980', 'dd-mon-yyyy');
  end if;
  
  for r in (
    select substr(text,1,180) text from alert_log_disk
     where text not like '%offlining%' 
       and text not like 'ARC_:%' 
       and text not like '%LOG_ARCHIVE_DEST_1%'
       and text not like '%Thread 1 advanced to log sequence%'
       and text not like '%Current log#%seq#%mem#%'
       and text not like '%Undo Segment%lined%'
       and text not like '%alter tablespace%back%'
       and text not like '%Log actively being archived by another process%'
       and text not like '%alter database backup controlfile to trace%'
       and text not like '%Created Undo Segment%'
       and text not like '%started with pid%'
       and text not like '%ORA-12012%'
       and text not like '%ORA-06512%'
       and text not like '%ORA-000060:%'
       and text not like '%coalesce%'
       and text not like '%Beginning log switch checkpoint up to RBA%'
       and text not like '%Completed checkpoint up to RBA%'
       and text not like '%specifies an obsolete parameter%'
       and text not like '%BEGIN BACKUP%'
       and text not like '%END BACKUP%'
  )
  loop
  
    isdate     := 0;
    alert_text := null;
  
    select count(*) into isdate 
      from dual 
     where substr(r.text, 21) in ('2014')
       and r.text not like '%cycle_run_year%';
  
    if (isdate = 1) then  
      select to_date(substr(r.text, 5),'Mon dd hh24:mi:ss rrrr') 
        into alert_date 
        from dual;
  
      if (alert_date > max_date) then
        start_updating := 1;
      end if;  
    else
      alert_text := r.text;
    end if;
  
    if (alert_text is not null) and (start_updating = 1) then
      insert into alert_log values (alert_date, substr(alert_text, 1, 180));
      rows_inserted := rows_inserted + 1;
      commit;
    end if;
  
  end loop;
  
  sys.dbms_output.put_line('Inserting after date '||to_char(max_date, 'MM/DD/RR HH24:MI:SS'));
  sys.dbms_output.put_line('Rows Inserted: '||rows_inserted);
  
  commit;

end;
/



@update_alert_log

======================= READ ALERTS FROM TABLE =======================
col MESSAGE for a100
select alert_date, substr(alert_text,1, 100) MESSAGE from alert_log;

12-JUL-14 Error stack returned to user:
12-JUL-14 ORA-02049: timeout: distributed transaction waiting for lock
16-JUL-14 Errors in file /usr/local/opt/oracle/admin/P2BL36A/udump/p2bl36a_ora_
18-JUL-14 ORACLE Instance P2BL36A - Can not allocate log, archival required

