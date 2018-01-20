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
      
      
      
      
      
