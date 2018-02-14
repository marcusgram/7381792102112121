# Oracle 12c

## SQL commands

1. Data definition language ```DDL```
2. Data manipulation language ```DML```
3. Data control language ```DCL```
4. Transaction control language ```TCL```

### Data definition language ```DDL```

*DDL command is used to define the structure of the object or it can be table. Every DDL statement, there are ```2 commit operations```. One will be executed before DDL statement and another commit will be executed after DDL statement by the server. These two commits are implicitly call, so that there's ```no rollback``` in DDL statements.*

1. CREATE
2. ALTER
3. TRUNCATE
4. RENAME
5. DROP
6. FLASHBACK
7. PURGE
8. COMMENT

#### CREATE

- It is used to create object like database or schema and tables
- To create totally new table.
- To create totally new table with copied data from another table.

```SQL
CREATE SCHEMA XYZ;
---------------------------------------------------
CREATE TABLE `Persons` (
  `name` VARCHAR(20),
  `age` DATE,
  `city` VARCHAR(20)
);
----------------------------------------------------
CREATE TABLE `Person` AS SELECT * FROM `Employees`;
```

#### TRUNCATE

- This command is used to delete / remove all data from particular table.

```SQL
TRUNCATE TABLE `Employees`;
```

#### RENAME

- This command is used to change the table name, column name and constraint name.

```SQL
RENAME `Emp` TO `Employee`;
---------------------------------------------------------
ALTER TABLE `Emp` RENAME COLUMN `Empno` TO `EmpNo`;
---------------------------------------------------------
ALTER TABLE `Emp` RENAME CONSTRAINT `PK_EMP` TO `P_EMP`;
```

#### DROP

- To delete / remove the table, object, columns or constraints from database.
- Once we drop the object the object will be placed into recycle bin.

```SQL
DROP TABLE `Employee`;
DROP TABLE `Employee` PURGE; // (shift + delete)
------------------------------------------
ALTER TABLE `Emp` DROP COLUMN `COL1`;
ALTER TABLE `Emp` DROP(COL1);
ALTER TABLE `Emp` DROP(COL1, COL2, COL3, ...);
-------------------------------------------------
SELECT * FROM RECYCLEBIN;
SHOW RECYCLEBIN;
```

#### FLASHBACK

- To restore the object from recycle bin.

```SQL
FLASHBACK TABLE `Emp` TO BEFORE DROP;
-------------------------------------
FLASHBACK TABLE `Emp` TO BEFORE DROP RENAME TO `Employee`;
```

#### PURGE

- This command is used to empty recycle bin.

```SQL
PURGE TABLE `Employee`;
DROP TABLE `Employee` PURGE; // (shift + delete)
```

#### COMMENT

- This command is used to comment out the table, column and we can uncomment also.
- The old comments will be overridden.

```SQL
COMMENT ON TABLE `Employee` IS 'This is the comment';
----------------------------------------------------
COMMENT ON COLUMN `Employee`.`COL1` IS 'This is the comment';
---------------------------------------------------------
USER_TAB_COMMENTS
USER_COL_COMMENTS
```

#### ALTER

- This command is used to add / drop columns.
- To hiding columns.
- To renaming columns.
- To renaming constraints.
- To modifying datatypes.
- To modifying size of the columns.
  - Increasing / Decreasing
  - With data
  - Without data
- To adding / dropping constraints.
- To enabling / disabling constraints
  - ADD
  - MODIFY
  - DROP
  - RENAME
  - SET UNUSED (hiding the column)
  - ENABLE
  - DISABLE

### Data manipulation language ```DML```

*DML commands deals with the data only. DML commands interact with the buffer first and then database on commit. We can undo (rollback) the changes. DML commands are slower in performance.*

1. SELECT - ```R```
2. INSERT - ```W```
3. UPDATE - ```W```
4. DELETE - ```W```
5. MERGE - ```W```

#### INSERT

- This command is used to insert data into the table.

```SQL
INSERT INTO `Employees` (Col1, Col2) VALUES (1, 'HARSH');
----------------------------------------------------------
INSERT INTO `Employees` VALUES (To_Date('22-mar-05 1:03', 'dd-mm-yy hh24:mi'));
----------------------------------------------------------------------
INSERT INTO `Employees` VALUES (&name, '&name');
------------------------------------------------
INSERT INTO `Employees` SELECT * FROM `EMP`;
```

#### SELECT

- This command is used to retrieve the data from table.

```SQL
SELECT * FROM `Employees`;
SELECT col1, col2 FROM `Employees`;
SELECT col1, col2 FROM `Employees` WHERE col1 = 2;
SELECT col1, col2 FROM `Employees` WHERE col1 = 2 ORDER BY col1 DESC;
```

#### UPDATE

- This command is used to do modify the data.

```SQL
UPDATE `Employees` SET col1 = 'Harsh' WHERE id = 1 AND salary = 2000 OR salary = 3000;
```

#### DELETE

- We can delete the data from table.

```SQL
DELETE FROM `Employees`;
DELETE FROM `Employees` WHERE ID = 1;
```

### Data control language ```DCL```

*DCL commands deals with privileges only. DCL commands enforces an implicit commit before & after the statement. We cannot undo (rollback) the changes.
Data Control Language is used to manage user access to an Oracle database*


1. GRANT
2. REVOKE
3. SET ROLE
4. COMMIT
5. ROLLBACK
6. SAVEPOINT

#### GRANT

- A DBA or user can grant access permission on owned database objects to other user or roles using GRANT command.

```
GRANT [privilege]
ON [object]
TO {user |PUBLIC |role} 
[WITH ADMIN | GRANT OPTION];

SQL> GRANT CREATE SESSION TO U1;
SQL> GRANT CONNECT, RESOURCE TO U1;
```
#### REVOKE

- The DCL command is used to revoke an existing privilege from a user. It can revoke a system privilege, object privilege or a role from a user. Only DBA or a user with ADMIN OPTION can revoke system privilege.

```
REVOKE [privilege]
ON [object]
FROM {USER |PUBLIC | ROLE}

SQL> REVOKE SELECT ON T1 FROM U1;
```

#### Privileges

- The right to execute a particular type of SQL statement.
- The right to connect to the database.
- The right to create the table in your schema.
- The right to select rows from someone else's tables / execute store procedure.

There are two types of privileges.
1. ```System privileges``` - Available only to administrator and application developers.
2. ```Object privileges``` - Allow users to perform a particular action on a specific object. Object privileges are granted to end-user so that they can use a database application to accomplish specific task.

### Transaction control language ```TCL```

*TCL commands deals with transaction only. Transaction is the set of DML operations with commit and rollback. Commit and rollback is the end point of the database server.*

1. COMMIT
2. ROLLBACK
3. SAVEPOINT
4. SET TRANSACTION

#### COMMIT

- This command is used to make changes permanently into database.
- This command is the end point of the transaction.
- By default all transactions is stored in buffer. After committing the data will be permanently stored into database.
- Until we committing the transaction the data won't be seen by other users. Only committed data is visible to other users.

```SQL
COMMIT;
```

#### ROLLBACK

- Rollback is the undo operation. Something like reverting back the transactions.
- If the transaction is not perfect we can rollback.
