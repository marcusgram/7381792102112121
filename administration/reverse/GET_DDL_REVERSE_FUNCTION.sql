REM
REM ******************** Knowledge Xpert for Oracle Administration ********************
REM
REM LOCATION:   Object Management\Functions,Procedures, and Packages
REM FUNCTION:   Script to re-generate Stored Procedure DLL
REM TESTED ON:  10.2.0.3, 11.1.0.6 (not tested but should work on previous versions)
REM PLATFORM:   non-specific
REM REQUIRES:   dba_objects, proc_count
REM NOTES:      Some particularly large schemas may cause this code to break because
REM             of the large amounts of code in that schema.
REM             In some versions of Oracle, dbms_metadata has been known to throw an
REM             error trying to produce certain types of code. This is rare, but it
REM             happens. If this is the case, this code will return the following:
REM
REM             Unable to print code for object
REM             owner.object_name type: object_type
REM
REM ******************** Knowledge Xpert for Oracle Administration ********************
REM



UNDEF enter_owner_name
UNDEF enter_object_name
SET long 1000000
SET verify off lines 132
SET serveroutput on

SPOOL Func_Proc_Packg.sql

DECLARE
   v_output        CLOB          := NULL;
   v_owner         VARCHAR2 (30) := '&&ENTER_OWNER_NAME';
   v_object_name   VARCHAR2 (30) := '&&ENTER_OBJECT_NAME';
BEGIN
   -- Note, we don't search for package bodies. We will extract the body
   -- along with the package spec.
   DBMS_OUTPUT.put_line ('Database DDL For Selected Objects Report');

   FOR dd IN (SELECT owner, object_name, object_type
                FROM dba_objects
               WHERE owner LIKE v_owner
                 AND object_name LIKE v_object_name
                 AND object_type IN
                              ('PROCEDURE', 'PACKAGE', 'TRIGGER', 'FUNCTION'))
   LOOP
      SELECT DBMS_METADATA.get_ddl (dd.object_type, dd.object_name, dd.owner)
        INTO v_output
        FROM DUAL;

      BEGIN
         DBMS_OUTPUT.put_line (v_output);
      EXCEPTION
         WHEN OTHERS
         THEN
            DBMS_OUTPUT.put_line ('Unable to print code for object');
            DBMS_OUTPUT.put_line (   dd.owner
                                  || '.'
                                  || dd.object_name
                                  || ' type: '
                                  || dd.object_type
                                 );
      END;
   END LOOP;
END;
/

SPOOL OFF;

