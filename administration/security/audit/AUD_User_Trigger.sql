

CREATE TRIGGER emp_audit AFTER
  INSERT OR
  DELETE OR
  UPDATE ON emp FOR EACH row BEGIN
  INSERT
  INTO emp_audit
    (
      empno,
      ename,
      job,
      mgr,
      hiredate,
      sal,
      comm,
      deptno,
      last_modified_user,
      last_modified_date
    )
    VALUES
    (
      :new.empno,
      :new.ename,
      :new.job,
      :new.mgr,
      :new.hiredate,
      :new.sal,
      :new.comm,
      :new.deptno,
      USER,
      sysdate
    );
END;
