

COLUMN parameter  HEADING "Parameter" FORMAT a25 ON
COLUMN Database  HEADING "Database" FORMAT a30 ON
COLUMN Instance  HEADING "Instance" FORMAT a30 ON
COLUMN Sesssion  HEADING "Sesssion" FORMAT a30 ON

SELECT ndp.parameter
     , max(ndp.value) Database
     , max(nip.value) Instance
     , max(nsp.value) Sesssion
FROM nls_session_parameters nsp
FULL OUTER JOIN nls_instance_parameters nip ON nip.parameter = nsp.parameter
FULL OUTER JOIN nls_database_parameters ndp ON ndp.parameter = nsp.parameter
group by ndp.parameter  
ORDER BY parameter
;


Parameter                 Database                       Instance                       Sesssion
------------------------- ------------------------------ ------------------------------ ------------------------------
NLS_CALENDAR              GREGORIAN                                                     GREGORIAN
NLS_CHARACTERSET          WE8ISO8859P15
NLS_COMP                  BINARY                         BINARY                         BINARY
NLS_CURRENCY              $                                                             $
NLS_DATE_FORMAT           DD-MON-RR                                                     DD/MM/YYYY HH24:MI:SS
NLS_DATE_LANGUAGE         AMERICAN                                                      AMERICAN
NLS_DUAL_CURRENCY         $                                                             $
NLS_ISO_CURRENCY          AMERICA                                                       AMERICA
NLS_LANGUAGE              AMERICAN                       AMERICAN                       AMERICAN
NLS_LENGTH_SEMANTICS      BYTE                           BYTE                           BYTE
NLS_NCHAR_CHARACTERSET    AL16UTF16
NLS_NCHAR_CONV_EXCP       FALSE                          FALSE                          FALSE
NLS_NUMERIC_CHARACTERS    .,                                                            .,
NLS_RDBMS_VERSION         11.2.0.2.0
NLS_SORT                  BINARY                                                        BINARY
NLS_TERRITORY             AMERICA                        AMERICA                        AMERICA
NLS_TIMESTAMP_FORMAT      DD-MON-RR HH.MI.SSXFF AM                                      DD-MON-RR HH.MI.SSXFF AM
NLS_TIMESTAMP_TZ_FORMAT   DD-MON-RR HH.MI.SSXFF AM TZR                                  DD-MON-RR HH.MI.SSXFF AM TZR
NLS_TIME_FORMAT           HH.MI.SSXFF AM                                                HH.MI.SSXFF AM
NLS_TIME_TZ_FORMAT        HH.MI.SSXFF AM TZR                                            HH.MI.SSXFF AM TZR

20 rows selected.




--NLS
set linesize 1000
col parameter for a30
col database_value for a30
col session_value for a30
col instance_value for a30

SELECT
   db.parameter as parameter,
   db.value as database_value,
   s.value as session_value,
   i.value as instance_value
FROM
   nls_database_parameters db
LEFT JOIN 
   nls_session_parameters s
ON s.parameter = db.parameter
LEFT JOIN 
   nls_instance_parameters i
ON i.parameter = db.parameter
ORDER BY parameter;


PARAMETER                      DATABASE_VALUE                 SESSION_VALUE                  INSTANCE_VALUE
------------------------------ ------------------------------ ------------------------------ ------------------------------
NLS_CALENDAR                   GREGORIAN                      GREGORIAN
NLS_CHARACTERSET               AL32UTF8
NLS_COMP                       BINARY                         BINARY                         BINARY
NLS_CURRENCY                   $                              $
NLS_DATE_FORMAT                DD-MON-RR                      DD-MON-RR
NLS_DATE_LANGUAGE              AMERICAN                       AMERICAN
NLS_DUAL_CURRENCY              $                              $
NLS_ISO_CURRENCY               AMERICA                        AMERICA
NLS_LANGUAGE                   AMERICAN                       AMERICAN                       AMERICAN
NLS_LENGTH_SEMANTICS           BYTE                           CHAR                           CHAR
NLS_NCHAR_CHARACTERSET         AL16UTF16
NLS_NCHAR_CONV_EXCP            FALSE                          FALSE                          FALSE
NLS_NUMERIC_CHARACTERS         .,                             .,
NLS_RDBMS_VERSION              11.2.0.2.0
NLS_SORT                       BINARY                         BINARY
NLS_TERRITORY                  AMERICA                        AMERICA                        AMERICA
NLS_TIMESTAMP_FORMAT           DD-MON-RR HH.MI.SSXFF AM       DD-MON-RR HH.MI.SSXFF AM
NLS_TIMESTAMP_TZ_FORMAT        DD-MON-RR HH.MI.SSXFF AM TZR   DD-MON-RR HH.MI.SSXFF AM TZR
NLS_TIME_FORMAT                HH.MI.SSXFF AM                 HH.MI.SSXFF AM
NLS_TIME_TZ_FORMAT             HH.MI.SSXFF AM TZR             HH.MI.SSXFF AM TZR

NLS_LANG='english_united kingdom.we8iso8859p1'; export NLS_LANG
NLS_CHARACTERSET='AL32UTF8'; export NLS_CHARACTERSET
NLS_LANG='AMERICAN_AMERICA.AL32UTF8'; export NLS_LANG


alter session set NLS_LANGUAGE = '


NLS_DATABASE_PARAMETERS
When you create your database, you tell it how you are going to handle or not handle globalization of the database. 
The NLS_DATABASE_PARAMETERS view will display what these settings were at database creation time. 
These are fixed at the database level and cannot be changed. The good thing is that while they do set up some of your 
options down the road with regard to having your database talk globally, they are only used when check constraints are enforced 
in the database. Therefore, you will not really need to worry about what these settings are after database creation time.

NLS_INSTANCE_PARAMETERS
As you know, you can change a variety of parameters for your instance through either the INIT.ORA file or the SPFILE. 
The NLS_INSTANCE_PARAMETERS view will display those settings that are set at the instance level.

NLS_SESSION_PARAMETERS
In addition, you have the ability to set each individual session's globalization parameters and the NLS_SESSION_PARAMETERS view 
will show you what the current settings are. This view is specific to the session querying from it.
