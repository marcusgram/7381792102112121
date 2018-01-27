
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




/* It also possible to explicit define the BYTE or CHAR semantics when creating a column:

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

Many of DBA's know that database migration 
from single-byte character set (like CL8MSWIN1251, WE8MSWIN1252 etc) 
to multi-byte character set (AL32UTF8) is a comprehensive task.

*/


