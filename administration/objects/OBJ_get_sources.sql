SET HEAD OFF VERIFY OFF
SELECT DECODE(ROWNUM, 1, 'CREATE OR REPLACE '||RTRIM(RTRIM(ds.text, CHR(10))),
       RTRIM(RTRIM(ds.text, CHR(10) ))) text
FROM  dba_source ds
WHERE ds.owner = UPPER('&1')
  AND ds.name = UPPER('&3')
  AND ds.type = UPPER('&2')
ORDER BY ds.line
/
prompt /
SET HEAD ON VERIFY ON
