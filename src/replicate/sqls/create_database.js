-- Database: rvx-bigdata-db

CREATE ROLE "rvx-bigdata-us" WITH PASSWORD '455ttte' LOGIN;

DROP DATABASE IF EXISTS "rvx-bigdata-db";

CREATE DATABASE "rvx-bigdata-db" 
	WITH OWNER = "rvx-bigdata-us" 
	ENCODING = 'UTF8' 
	LC_COLLATE = 'pt_BR.utf8' 
	LC_CTYPE = 'pt_BR.utf8' 
	TEMPLATE template0 
	TABLESPACE = pg_default 
	CONNECTION LIMIT = -1 
	IS_TEMPLATE = False;

COMMENT ON DATABASE "rvx-bigdata-db" IS 'default administrative connection database';