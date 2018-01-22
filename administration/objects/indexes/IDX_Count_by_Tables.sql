
		

    SET echo off
    SET feedback off
    SET linesize 512
     
    prompt -----------------------------------
    prompt - Liste des TABLES trops INDEXES --
    prompt -----------------------------------
     
    SELECT
    OWNER,
    TABLE_NAME,
    COUNT (*) "Nbre"
    FROM
    ALL_INDEXES
    WHERE
    OWNER NOT IN ('SYS','SYSTEM','OUTLN','DBSNMP')
    GROUP BY
    OWNER,
    TABLE_NAME
    HAVING
    COUNT (*) > ('6');
