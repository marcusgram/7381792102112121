
Oracle Tuning Pack
-------------------
The Oracle Tuning Pack provides database administrators with expert performance management for the Oracle environment, including SQL tuning and storage optimizations. 
The Oracle Diagnostic Pack is a prerequisite product to the Oracle Tuning Pack. 
Therefore, to use the Tuning Pack, you must also have a Diagnostic Pack.

The Tuning Pack includes the following features:

SQL Access Advisor
SQL Tuning Advisor
Automatic SQL Tuning
SQL Tuning Sets
SQL Monitoring
Reorganize objects

In order to use the features listed above, you must purchase licenses for the Tuning Pack, 
with one exception: SQL Tuning Sets can be used if you have licensed either the Tuning Pack or Oracle Real Application Testing. A new initialization parameter, CONTROL_MANAGEMENT_PACK_ACCESS, is introduced to control access to the Diagnostic Pack and Tuning Pack in the database server. This parameter can be set to one of three values:

DIAGNOSTIC+TUNING: Diagnostic Pack and Tuning Pack functionally is enabled in the database server.

DIAGNOSTIC: Only Diagnostic Pack functionality is enabled in the server.

NONE: Diagnostic Pack and Tuning pack functionally is disabled in the database server.

The Tuning Pack functionality can be accessed by the Enterprise Manager links as well as through the database server command-line APIs. 
The use of either interface requires licensing of the Tuning Pack