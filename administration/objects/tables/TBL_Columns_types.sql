
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

