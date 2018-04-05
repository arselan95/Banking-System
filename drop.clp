-- Project 3 DDLs: drop.clp
--
connect to sample;
--
-- drop previous definition first
drop specific function p3.encrypt;
drop specific function p3.decrypt;
drop table p2.account;
drop table p2.customer;
--
-- 
commit;
terminate;