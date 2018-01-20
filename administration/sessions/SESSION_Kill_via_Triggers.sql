----------------------------------------------------------------------------
-- Script to create the trigger under SYS user to forbid access by SQL*Plus:
----------------------------------------------------------------------------
  
   CREATE OR REPLACE TRIGGER on_logon
   AFTER LOGON
   ON DATABASE
   DECLARE
    --Declare a cursor to find out the program
    --the user is connecting with.
    CURSOR user_prog IS
          SELECT  program FROM v$session  
          WHERE   audsid=sys_context('USERENV','SESSIONID');
    
    --Assign the cursor to a PL/SQL record.
    user_rec user_prog%ROWTYPE;
    BEGIN
        OPEN user_prog;
        FETCH user_prog INTO user_rec;
        IF user_rec.program IN ('sqlplusw.exe')
        THEN
            RAISE_APPLICATION_ERROR(-20001, 'You are not allowed to login');
        END IF;
        CLOSE user_prog;
    END;
   /
   
    Example
   -------
      SQL> connect test/test
      ERROR:
      ORA-00604: error occurred at recursive SQL level 1
      ORA-20001: You are not allowed to login
      ORA-06512: at line 16
    
      Warning: You are no longer connected to ORACLE.
      
      
      
      
 -----------------------------------------------------------------------     
 --Script to create the trigger under SYS user to forbid access by TOAD:
 -----------------------------------------------------------------------

   create or replace trigger ban_toad after logon on database
    declare
     v_sid number;
     v_isdba varchar2(10);
     v_program varchar2(48);
    begin
     execute immediate
       'select distinct sid from sys.v_$mystat' into v_sid;
     execute immediate
       'select program from sys.v_$session where sid = :b1'
        into v_program using v_sid;
     select sys_context('userenv','ISDBA') into v_isdba from dual;
     if upper(v_program) = 'TOAD.EXE' and v_isdba = 'FALSE' then
          raise_application_error
            (-20001,'TOAD Access for non DBA users restricted',true);
     end  if;
    end;
   /        
   
   
   
    Example
   -------

      SQL> conn scott/tiger
      ERROR:
      ORA-00604: error occurred at recursive SQL level 1
      ORA-20001: TOAD Access for non DBA users restricted
      ORA-06512: at line 13

      Warning: You are no longer connected to ORACLE.

   Note that TOAD populates the MODULE column of V$SESSION :
      
      
    
      
 -----------------------------------------------------------------------
 --TRIGGER AFTER LOGON TO EXECUTE TRACE ON SESSION
 -----------------------------------------------------------------------

CREATE OR REPLACE TRIGGER USER_TRACE_TRG
AFTER LOGON ON DATABASE
BEGIN
    IF USER = '&USER_ID'
  THEN
    execute immediate 'alter session set events ''10046 trace name context forever, level 12''';
  END IF;
EXCEPTION
WHEN OTHERS THEN
NULL;
END;
/

------------
CREATE OR REPLACE TRIGGER TRG_USER_BUG
AFTER LOGON ON DATABASE
BEGIN
 IF UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER')) = 'TIBCOBWPM'
     THEN
   execute immediate 'alter session set events= ''31156 trace name context forever, level 0x400''';
 END IF;
 EXCEPTION
 WHEN OTHERS THEN
 RETURN;
 END;
 /
 
 
 
------------------------------------------------------------------------------------------------------------- 
-- This trigger records the Oracle username, clients computer name, clients OS username, 
-- and the name of program (module) used to connect to the database as determined by the SYS_CONTEXT function
 ------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER myAuditor.logon_trigger AFTER LOGON ON DATABASE
BEGIN
 IF UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER')) 
    NOT IN ('SYS','SYSTEM','SYSMAN','DBSNMP') -- list of users to ignore
 THEN
 IF (TRIM(UPPER(SYS_CONTEXT('USERENV', 'HOST'))) 
    IN ('WEB01','WEB02','WEB03') -- list of hosts to ignore
 AND TRIM(UPPER(SYS_CONTEXT('USERENV', 'MODULE'))) != 'W3WP.EXE') -- list of apps to ignore on hosts
 THEN
 INSERT
 INTO myauditor.logon_audit VALUES
 (
 UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER')) ,
 UPPER(SYS_CONTEXT('USERENV', 'HOST')) ,
 UPPER(SYS_CONTEXT('USERENV', 'OS_USER')) ,
 UPPER(SYS_CONTEXT('USERENV', 'MODULE')) ,
 sysdate
 );
 ELSIF TRIM(UPPER(SYS_CONTEXT('USERENV', 'HOST'))) 
   NOT IN ('WEB01','WEB02','WEB03') -- list of hosts to ignore
 THEN
 INSERT
 INTO myauditor.logon_audit VALUES
 (
 UPPER(SYS_CONTEXT('USERENV', 'SESSION_USER')) ,
 UPPER(SYS_CONTEXT('USERENV', 'HOST')) ,
 UPPER(SYS_CONTEXT('USERENV', 'OS_USER')) ,
 UPPER(SYS_CONTEXT('USERENV', 'MODULE')) ,
 sysdate
 );
 END IF;
 END IF;
 EXCEPTION
 WHEN OTHERS THEN
 RETURN;
 END;
/


 
 
----------------------------------------------------------------------------------------------------
 -- Le trigger AFTER LOGON peut etre alors code : si pour le login Oracle SESSION_USER=SOP_DATATEAM, 
 -- il n'existe pas de lignes dans la table SECURITY_OSUSERS 
 -- pour l'OS_USER entrant, une exception est levee et la connexion est refusee.
 ---------------------------------------------------------------------------------------------------
CREATE TABLE SECURITY_OSUSERS
(
  OSUSER VARCHAR2(30) NOT NULL
);

CREATE OR REPLACE TRIGGER systrg_logon
  AFTER LOGON
  ON DATABASE
  DECLARE
    username VARCHAR2(30);
    osuser VARCHAR2(30);
    is_authorized NUMBER;

    BEGIN
      SELECT sys_context ('USERENV', 'SESSION_USER')
      INTO username
      FROM dual;

      IF username='SOP_DATATEAM' then

        SELECT sys_context ('USERENV', 'OS_USER') INTO osuser
          FROM dual;

        SELECT COUNT(*) INTO is_authorized from SECURITY_OSUSERS
          WHERE OSUSER=osuser;

        IF is_authorized=0 then
          raise_application_error( -20001, 'Connection refused, OS User not allowed' );
        END IF;
      END IF;
    END;
/





------------------------------------------------------
--REM # Configure and send an email after deleting a
--REM # row in a table: use an AFTER DELETE trigger
------------------------------------------------------

sqlplus / as sysdba
 
@?/rdbms/admin/utlsmtp.sql
@?/rdbms/admin/prvtsmtp.plb
@?/rdbms/admin/utlmail.sql
@?/rdbms/admin/prvtmail.plb

GRANT EXECUTE ON UTL_MAIL TO PUBLIC;
 
ALTER SESSION SET CURRENT SCHEMA=myschema;
 
CREATE OR REPLACE TRIGGER myschema.mytrigger
AFTER DELETE ON myschema.mytable REFERENCING NEW AS NEW OLD AS OLD FOR EACH ROW
BEGIN
        EXECUTE IMMEDIATE 'ALTER SESSION SET smtp_out_server = ''127.0.0.1''';
          UTL_MAIL.send(sender => 'mysender@company.com',
                 recipients => 'myrecipient1@company.com',
                 cc => 'myrecipient2@company.com',
                        subject => 'Myapplication: A row has been deleted in the table mytable',
                        message => 'A row has been deleted in the table mytable.'       ||  utl_tcp.CRLF ||  utl_tcp.CRLF ||
                '   Customer informations: ' ||  utl_tcp.CRLF ||
                '       Name: ' || :old.Name                                ||  utl_tcp.CRLF ||
                '       Country  : ' || :old.COUNTRY                                ||  utl_tcp.CRLF || utl_tcp.CRLF ||
                '   Technical informations: ' ||  utl_tcp.CRLF ||
                '       DB Name: ' || SYS_CONTEXT('USERENV','DB_NAME')                ||  utl_tcp.CRLF ||
                '       OS USER: ' || SYS_CONTEXT('USERENV','OS_USER')                 ||  utl_tcp.CRLF ||
                '       Session ID: ' || SYS_CONTEXT('USERENV','SESSIONID')                ||  utl_tcp.CRLF ||
                '       Session User: ' || SYS_CONTEXT('USERENV','SESSION_USER')        ||  utl_tcp.CRLF ||
                '       IP Address: ' ||  SYS_CONTEXT('USERENV','IP_ADDRESS')        ||  utl_tcp.CRLF ||
                '       Terminal: ' || SYS_CONTEXT('USERENV','TERMINAL')                 ||  utl_tcp.CRLF ||
                '       Is DBA: ' || SYS_CONTEXT('USERENV','ISDBA') ,
                      mime_type => 'text; charset=us-ascii');
END;
/

