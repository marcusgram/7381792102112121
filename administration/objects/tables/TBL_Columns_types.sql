
----------------------------------------------------
--select will give all columns using CHAR semantics:
----------------------------------------------------
SELECT C.owner
||'.'
|| C.table_name
||'.'
|| C.column_name
||' ('
|| C.data_type
||' '
|| C.char_length
||' CHAR)'
FROM all_tab_columns C
WHERE C.char_used = 'C'
AND C.table_name NOT IN
(SELECT table_name FROM all_external_tables
)
AND C.data_type IN ('VARCHAR2', 'CHAR')
ORDER BY 1
/



----------------------------------------------------
--select will give all columns using BYTE semantics:
----------------------------------------------------
SELECT C.owner
||'.'
|| C.table_name
||'.'
|| C.column_name
||' ('
|| C.data_type
||' '
|| C.char_length
||' CHAR)'
FROM all_tab_columns C
WHERE C.char_used = 'C'
AND C.table_name NOT IN
(SELECT table_name FROM all_external_tables
)
AND C.data_type IN ('BYTE')
ORDER BY 1
/




It also possible to explicit define the BYTE or CHAR semantics when creating a column:

CHAR(10 BYTE)  - will always be BYTE regardless of the used NLS_LENGTH_SEMANTICS
CHAR(10 CHAR) - will always be CHAR regardless of the used NLS_LENGTH_SEMANTICS


select * from nls_database_parameters 
where parameter in ('NLS_RDBMS_VERSION','NLS_CHARACTERSET','NLS_NCHAR_CHARACTERSET','NLS_LANGUAGE','NLS_TERRITORY','NLS_LENGTH_SEMANTICS');


PARAMETER                      VALUE
------------------------------ ----------------------------------------
NLS_LANGUAGE                   AMERICAN
NLS_TERRITORY                  AMERICA
NLS_CHARACTERSET               WE8MSWIN1252
NLS_LENGTH_SEMANTICS           BYTE
NLS_NCHAR_CHARACTERSET         AL16UTF16
NLS_RDBMS_VERSION              11.2.0.2.0

/*
Many of DBA's know that database migration 
from single-byte character set (like CL8MSWIN1251, WE8MSWIN1252 etc) 
to multi-byte character set (AL32UTF8) is a comprehensive task.
*/

select parameter, value from nls_database_parameters where parameter like '%CHARACTERSET%';

PARAMETER                      VALUE
------------------------------ ----------------------------------------
NLS_CHARACTERSET               WE8MSWIN1252



select LENGTH('CANDIDE') from dual; => 7
select LENGTHB('CANDIDE') from dual; => 7
 
we are using single-byte database character set.
NLS_CHARACTERSET WE8MSWIN1252 is single byte character set.

alter session set nls_length_semantics='CHAR';

 With data As (
      Select 'Império Bonança Mediadores' As text From dual
    )
    select length(text) Len_Char_Org, length(convert(text,'UTF8')) Len_Char from Data ;


alter session set nls_length_semantics='BYTE';	

	 With data As (
      Select 'Império Bonança Mediadores' As text From dual
    )
  
  select lengthb(text) Len_Char_Org, lengthb(convert(text,'UTF8')) Len_Byte from Data ;

	select length(convert('CANDIDE','WE8MSWIN1252','US7ASCII')) from dual; => 7
	
	select length(convert('CANDIDE','WE8MSWIN1252','UTF8')) from dual; => 7
	
	select length(convert('Império Bonança Mediadores','WE8MSWIN1252','UTF8')) from dual; => 32
	select length(convert('Império Bonança Mediadores','WE8MSWIN1252','AL32UTF8')) from dual; => 32
	
	select length(convert('Império Bonança Mediadores','CL8ISO8859P5','AL32UTF8')) from dual; => 32
	select length(convert('Império Bonança Mediadores','CL8MSWIN1251','AL32UTF8')) from dual; => 32
	
  select lengthb(convert('Império Bonança Mediadores','CL8MSWIN1251','AL32UTF8')) from dual; => 32 (single => multiple)
	select lengthb(convert('Império Bonança Mediadores','AL32UTF8','CL8MSWIN1251')) from dual; => 40 (multiple => single)
	select length(convert('Império Bonança Mediadores','AL32UTF8','CL8MSWIN1251')) from dual; => 40
	
	select (convert('Império Bonança Mediadores','CL8MSWIN1251','AL32UTF8')) from dual;
	select (convert('Império Bonança Mediadores','WE8MSWIN1252','WE8MSWIN1252')) from dual;
	
	
CL8MSWIN125
CL8MSWIN1251
CL8ISO8859P5
	
	select length(convert('CANDIDE','WE8MSWIN1252','US7ASCII')) from dual; => 7
		
	http://www.dbaoracle.info/2012/08/happy-three-friends-varchar2-unicode.html
	
	declare
      a varchar(4000) := '?'; /* ? - russian unique letter */
    begin
      dbms_output.enable(4000);
      while length(a) < 4000 loop
        a := a || '?';
      end loop;
      insert into test (b) values (a);
      commit;
     dbms_output.put_line(length(a) ||'..inserted');
   end;
  /
	



