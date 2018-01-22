CREATE OR REPLACE FUNCTION SOLAR_OWN.getRandomDate(pStartDate IN DATE, pEndDate IN DATE) RETURN DATE
    IS
    	dRandomDate		DATE;
        piStartNumber	PLS_INTEGER;
        piEndNumber		PLS_INTEGER;
    BEGIN
    	-- 1. Convert the start date to Julian date numbers
        piStartNumber := TO_NUMBER(TO_CHAR(pStartDate, 'J'));
        piEndNumber := TO_NUMBER(TO_CHAR(pEndDate, 'J'));

        -- 2. Using the DBMS_RANDOM function to get the random date
		dRandomDate := TO_DATE(TRUNC(DBMS_RANDOM.VALUE(piStartNumber, piEndNumber)), 'J');

		-- Test output
        dbms_output.put_line(	'Random date between '
        						|| TO_CHAR(pStartDate, 'MM/DD/YYYY')
                                || ' and '
                                || TO_CHAR(pEndDate, 'MM/DD/YYYY')
                                || ' is: '
                                || TO_CHAR(dRandomDate, 'MM/DD/YYYY') );

    	RETURN dRandomDate;
    END;
/
SHOW ERRORS;
