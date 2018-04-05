drop procedure p3.cust_crt@
drop procedure p3.cust_login@
drop procedure p3.acct_opn@
drop procedure p3.acct_cls@
drop procedure p3.acct_dep@
drop procedure p3.acct_wth@
drop procedure p3.acct_trx@
drop procedure p3.add_interest@

CREATE PROCEDURE P3.CUST_CRT(IN cus_name VARCHAR(15), IN CusGender CHAR(1), IN CusAge INTEGER, IN CusPIN INTEGER, OUT CustID INTEGER, OUT Sql_Code INTEGER, OUT Err_Msg VARCHAR(50))
LANGUAGE SQL
BEGIN
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE SQLCODE INTEGER DEFAULT 0;          

  DECLARE EXIT HANDLER FOR SQLSTATE '50000'
     BEGIN
        SET Sql_Code = -50000;
        SET Err_Msg = 'Error, age cannot be negative'; 
     END;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
     SET Sql_Code = SQLCODE;
 
  IF(CusAge < 0) THEN SIGNAL SQLSTATE '50000';
  END IF;

  SELECT ID INTO CustID
  FROM NEW TABLE
  (INSERT INTO P3.Customer(NAME, GENDER, AGE, PIN)
	VALUES(cus_name, CusGender, CusAge, CusPIN));
END @


CREATE PROCEDURE P3.CUST_LOGIN(IN CustID INTEGER, IN CusPIN INTEGER, OUT valid INTEGER, OUT Sql_Code INTEGER, OUT Err_Msg VARCHAR(50))
LANGUAGE SQL
BEGIN
   DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
   DECLARE SQLCODE INTEGER DEFAULT 0;
   DECLARE DUMMY INTEGER DEFAULT 0;

   DECLARE EXIT HANDLER FOR NOT FOUND
      BEGIN
         SET Sql_Code = -50001;
         SET Err_Msg = 'Incorrect ID/PIN combination';
         SET valid = 0;
      END;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
     SET Sql_Code = SQLCODE;

  SELECT ID INTO DUMMY
  FROM P3.Customer
  WHERE ID = CustID AND Pin = CusPIN;

   SET valid = 1;
END @

CREATE PROCEDURE P3.ACCT_OPN(IN CustID INTEGER, IN AcctBal INTEGER, IN AcctType CHAR(1), OUT AcctNum INTEGER, OUT Sql_Code INTEGER, OUT Err_Msg VARCHAR(50))
LANGUAGE SQL
BEGIN
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE DUMMY INTEGER DEFAULT 0;
  
  DECLARE EXIT HANDLER FOR NOT FOUND
    BEGIN
       SET Sql_Code = -50001;
       SET Err_Msg = 'Error, invalid Customer ID';
    END;

  DECLARE EXIT HANDLER FOR SQLSTATE '50002'
    BEGIN
           SET Sql_Code = -50002;
           SET Err_Msg = 'Error, starting balance cannot be < 0';
    END; 

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
     BEGIN
            SET Sql_Code = SQLCODE; 
     END;
     
  IF(AcctBal < 0) THEN SIGNAL SQLSTATE '50002';
  END IF;

  IF(AcctType != 'C' AND AcctType != 'S') THEN SIGNAL SQLSTATE '45007';
  END IF;
 
  SELECT ID INTO DUMMY
  FROM P3.Customer
  WHERE ID = CustID;

  SELECT Number INTO AcctNum
  FROM NEW TABLE
  (INSERT INTO P3.Account(ID, Balance, Type, Status)
  VALUES(CustID, AcctBal, AcctType, 'A'));  
END @

CREATE PROCEDURE P3.ACCT_CLS(IN AcctNum INTEGER, OUT Sql_Code INTEGER, OUT Err_Msg VARCHAR(50))
LANGUAGE SQL
BEGIN
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE DUMMY INTEGER DEFAULT 0;     	
 
  DECLARE EXIT HANDLER FOR NOT FOUND
     BEGIN
        SET Sql_Code = -50001;
        SET Err_Msg = 'Error, no open accounts exist with that number';  
     END;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
     SET Sql_Code = SQLCODE;
  
  SELECT NUMBER INTO DUMMY
  FROM P3.Account
  WHERE NUMBER = AcctNum AND STATUS = 'A';

  UPDATE P3.Account
  SET BALANCE = 0, STATUS = 'I'
  WHERE NUMBER = AcctNum;
END @

CREATE PROCEDURE P3.ACCT_DEP(IN AcctNum INTEGER, IN amount INTEGER, OUT Sql_Code INTEGER, OUT Err_Msg VARCHAR(50))
LANGUAGE SQL
BEGIN
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE DUMMY INTEGER DEFAULT 0;

  DECLARE EXIT HANDLER FOR NOT FOUND
     BEGIN
        SET Sql_Code = -50000;
        SET Err_Msg = 'Error, no open accounts exist with that number';
     END;

     DECLARE EXIT HANDLER FOR SQLSTATE '50003'
        BEGIN
           SET Sql_Code = -50003;
           SET Err_Msg = 'Error, deposit amount cannot be negative';
        END; 
     
     DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
           SET Sql_Code = SQLCODE;
        END;

     IF(amount < 0) THEN SIGNAL SQLSTATE '50003';
     END IF;
     
     SELECT NUMBER INTO DUMMY
     FROM P3.Account
     WHERE NUMBER = AcctNum AND STATUS = 'A';

     UPDATE P3.Account
     SET BALANCE = BALANCE + amount
     WHERE NUMBER = AcctNum;
END @

CREATE PROCEDURE P3.ACCT_WTH(IN AcctNum INTEGER, IN amount INTEGER, OUT Sql_Code INTEGER, OUT Err_Msg VARCHAR(50))
LANGUAGE SQL
BEGIN
   DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
   DECLARE SQLCODE INTEGER DEFAULT 0;
   DECLARE DUMMY INTEGER DEFAULT 0;

   DECLARE EXIT HANDLER FOR NOT FOUND
      BEGIN
         SET Sql_Code = -50000;
         SET Err_Msg = 'Error, invalid account';
      END;

   DECLARE EXIT HANDLER FOR SQLEXCEPTION
     SET Sql_Code = SQLCODE;

   DECLARE EXIT HANDLER FOR SQLSTATE '50004'
     BEGIN
        SET Sql_Code = -50004;
	      SET Err_Msg = 'Error, you may not withdraw a negative amount';
     END;

   DECLARE EXIT HANDLER FOR SQLSTATE '50005'
      BEGIN
         SET Sql_Code = -50005;
      END;

    IF(amount < 0) THEN SIGNAL SQLSTATE '50004';
    END IF;

    SELECT BALANCE INTO DUMMY
    FROM P3.Account
    WHERE NUMBER = AcctNum AND STATUS = 'A';

    IF(DUMMY < amount) THEN SIGNAL SQLSTATE '50005';
    END IF;

    UPDATE P3.Account
    SET BALANCE = BALANCE - amount
    WHERE NUMBER = AcctNum;
END @

CREATE PROCEDURE P3.ACCT_TRX(IN SrcAcct INTEGER, IN DestAcct INTEGER, IN amount INTEGER, OUT Sql_Code INTEGER, OUT Err_Msg VARCHAR(50))
LANGUAGE SQL
BEGIN
   DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
   DECLARE SQLCODE INTEGER DEFAULT 0;
   DECLARE DUMMY INTEGER DEFAULT 0;
    
   DECLARE EXIT HANDLER FOR NOT FOUND
      BEGIN
         SET Sql_Code = -50000;
         SET Err_Msg = 'Error, invalid account';
       END;

    DECLARE EXIT HANDLER FOR SQLSTATE '50006'
       BEGIN
          SET Sql_Code = -50006;
          SET Err_Msg = 'Error, you must transfer amount >= 0';
       END;

    DECLARE EXIT HANDLER FOR SQLSTATE '50007'
       BEGIN
           SET Sql_Code = -50007;
           SET Err_Msg = 'Error, you may not overdraw your account';
       END;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        SET Sql_Code = SQLCODE;


    IF(amount < 0) THEN SIGNAL SQLSTATE '50006';
    END IF;

    SELECT BALANCE INTO DUMMY 
    FROM P3.Account
    WHERE NUMBER = DestAcct AND STATUS = 'A';
    
    SELECT BALANCE INTO DUMMY
    FROM P3.Account
    WHERE NUMBER = SrcAcct AND STATUS = 'A';

    IF(DUMMY < amount) THEN SIGNAL SQLSTATE '50007';
    END IF;

    CALL P3.ACCT_WTH(DestAcct, amount, Sql_Code, Err_Msg);
    CALL P3.ACCT_DEP(SrcAcct, amount, Sql_Code, Err_Msg);
END @

CREATE PROCEDURE P3.ADD_INTEREST(IN SavingsRate DOUBLE, IN CheckingRate DOUBLE, OUT Sql_Code INTEGER, OUT Err_Msg VARCHAR(50))
LANGUAGE SQL
BEGIN
   DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
   DECLARE SQLCODE INTEGER DEFAULT 0;
   DECLARE DUMMY INTEGER DEFAULT 0;     

   DECLARE EXIT HANDLER FOR SQLSTATE '50009'
      BEGIN
          SET Sql_Code = -50009;
          SET Err_Msg = 'Error, interest rate must be >= 0';
      END;

     DECLARE EXIT HANDLER FOR SQLSTATE '50009'
        BEGIN
           SET Sql_Code = -50009;
           SET Err_Msg = 'Error, interest must be <= 1';
        END;

     DECLARE EXIT HANDLER FOR SQLEXCEPTION
        SET Sql_Code = SQLCODE;

     IF(SavingsRate < 0 OR CheckingRate < 0) THEN SIGNAL SQLSTATE '50009';
     END IF;

     IF(SavingsRate > 1 OR CheckingRate > 1) THEN SIGNAL SQLSTATE '50009';
     END IF;

     UPDATE P3.Account
     SET BALANCE = BALANCE + BALANCE * SavingsRate
     WHERE STATUS = 'A' AND TYPE = 'S';

     UPDATE P3.Account
     SET BALANCE = BALANCE + BALANCE * CheckingRate
     WHERE STATUS = 'A' AND TYPE = 'C';
END @
