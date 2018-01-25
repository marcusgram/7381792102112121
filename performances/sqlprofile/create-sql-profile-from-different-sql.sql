accept sqlid_sp prompt 'Enter the SQL_ID for the plan you want to use (located in the shared pool): '
accept childno_sp default 0 prompt 'Enter the associated child_number (default 0): '
accept sqlid_bad prompt 'Enter the SQL_ID for the plan you want to replace (located in the shared pool): '
accept childno_bad default 0 prompt 'Enter the associated child_number (default 0): '


declare
	ar_profile_hints sys.sqlprof_attr;
	cl_sql_text clob;
	l_profile_name varchar2(30);
begin
	select
	extractvalue(value(d), '/hint') as outline_hints
	bulk collect
	into
	ar_profile_hints
	from
	xmltable('/*/outline_data/hint'
	passing (
	select
	xmltype(other_xml) as xmlval
	from
	v$sql_plan
	where
	sql_id = '&&sqlid_sp'
	and child_number = &childno_sp
	and other_xml is not null
	)
	) d;

	select
	sql_fulltext, 
	'PROF_'||'&sqlid_sp'
	into
	cl_sql_text, l_profile_name
	from
	v$sql
	where
	sql_id = '&sqlid_bad'
	and child_number = &childno_bad;

	dbms_sqltune.import_sql_profile(
	sql_text => cl_sql_text,
	profile => ar_profile_hints,
	category => 'DEFAULT',
	name => l_profile_name,
	force_match => false
	-- replace => true
	);

	dbms_output.put_line(' ');
	dbms_output.put_line('SQL Profile '||l_profile_name||' created.');
	dbms_output.put_line(' ');

	exception
	when NO_DATA_FOUND then
	  dbms_output.put_line(' ERROR ');
	  -- dbms_output.put_line('ERROR: sql_id: '||'&&sql_id'||' Child: '||'&&child_no'||' not found in v$sql.');
	  dbms_output.put_line(' ');

end;
/

undef sqlid_sp
undef childno_sp
undef sqlid_bad
undef childno_bad