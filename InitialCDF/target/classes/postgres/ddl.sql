-- Table: livy.livy_pool

-- DROP TABLE livy.livy_pool;

CREATE TABLE livy.livy_pool
(
    flowname character varying(100) COLLATE pg_catalog."default",
    pool_size integer,
    allocated integer,
    post_request character varying(10000000) COLLATE pg_catalog."default",
    enable character varying(10) COLLATE pg_catalog."default",
    pool_description character varying(4000) COLLATE pg_catalog."default"
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE livy.livy_pool
    OWNER to postgres;

-- Table: livy.livy_sessions

-- DROP TABLE livy.livy_sessions;

CREATE TABLE livy.livy_sessions
(
    flowname character varying(100) COLLATE pg_catalog."default",
    sessionid character varying(20) COLLATE pg_catalog."default",
    applicationid character varying(1000) COLLATE pg_catalog."default",
    last_updated timestamp without time zone,
    app_status character varying(50) COLLATE pg_catalog."default",
    create_ts timestamp without time zone,
    description character varying(10000) COLLATE pg_catalog."default",
    status character varying(100) COLLATE pg_catalog."default"
)
WITH (
    OIDS = FALSE
)
TABLESPACE pg_default;

ALTER TABLE livy.livy_sessions
    OWNER to postgres;

-- FUNCTION: livy.get_session(text, text)

-- DROP FUNCTION livy.get_session(text, text);

CREATE OR REPLACE FUNCTION livy.get_session(
	vaskedby text,
	vflowname text)
    RETURNS text
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE
AS $BODY$

DECLARE
vsessionid text;
BEGIN
vsessionid := (select sessionid from  livy.livy_sessions where flowname=vflowname and status = 'idle' limit 1);
update livy.livy_sessions set status='LOCKED',last_updated=current_timestamp,description=vaskedby where sessionid=vsessionid;
RETURN vsessionid;
END;

$BODY$;

ALTER FUNCTION livy.get_session(text, text)
    OWNER TO cchennur;

