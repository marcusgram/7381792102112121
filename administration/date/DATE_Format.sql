--- You can create separate columns for date and time like this:

alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';

--------------------------
1 - Change nls_date_format
--------------------------
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY HH24:MI:SS';

ALTER SESSION SET NLS_DATE_FORMAT = 'YYYY MM DD';
select sysdate from dual;

ALTER SESSION SET NLS_DATE_FORMAT = 'HH24:MI:SS';
select sysdate from dual;

or
-----------------------
2 - use the format mask
-----------------------

select to_char(sysdate,'HH24:MI:SS') from dual;
select to_char(sysdate,'YYY MM DD') from dual;

select to_char(sysdate,'DDMMYYYY_HH24MISS') from dual;
select to_char(sysdate,'YYY MM DD') from dual;


------------------------------------
-- Afficher une durée en HH:MM:SS --
------------------------------------
SELECT 
   TO_CHAR(TO_DATE(MOD(999999, 86400),'SSSSS'), 'HH24:MI:SS') AS elapsed
FROM dual;

SELECT trunc(100/60)  minutes,  mod(100,60) secondes FROM dual ;



--------------------------
-- Date to char conversion
--------------------------
DECLARE
  v_string VARCHAR2(30) := '10/30/1998 12:34:03 PM';
  v_date DATE;
BEGIN
  v_date := to_date(v_string, 'MM/DD/YYYY HH:MI:SS AM');
  dbms_output.put_line(  to_char(v_date, 'FMDD Month, YYYY') );
END;
/



