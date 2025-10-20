SELECT * 
	FROM bigdata_final.pf_telefones 
	WHERE updated_at>'2025-10-20'
	ORDER BY id DESC 
	LIMIT 100;
	
SELECT * 
	FROM bigdata_final.pf_telefones 
	WHERE cpf='49092910244'
	ORDER BY id DESC 
	LIMIT 100;

SELECT id 
	FROM bigdata_final.pf_telefones 
	ORDER BY id DESC 
	LIMIT 3;

SELECT COUNT(1) FROM bigdata_final.pf_telefones;
SELECT COUNT(1) FROM bigdata_final.pf_telefones WHERE updated_at>'2025-10-20';

SELECT * FROM bigdata_final.pf_telefones WHERE id>276260285;

CREATE SEQUENCE bigdata_final.pf_telefones_id_seq
START WITH 276260286
INCREMENT BY 1
MINVALUE 276260286
MAXVALUE 9223372036854775807
CACHE 1;

ALTER TABLE bigdata_final.pf_telefones ALTER COLUMN id SET DEFAULT nextval('bigdata_final.pf_telefones_id_seq'::regclass);

BEGIN;
ALTER TABLE bigdata_final.pf_telefones
ADD COLUMN ranking integer DEFAULT 0;

CREATE INDEX idx_pf_telefones_ranking ON bigdata_final.pf_telefones (ranking);
COMMIT;

CREATE OR REPLACE FUNCTION bigdata_final.set_updated_at()
    RETURNS trigger
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE NOT LEAKPROOF
AS $BODY$

BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$BODY$;

ALTER FUNCTION bigdata_final.set_updated_at() OWNER TO postgres;

CREATE OR REPLACE TRIGGER trg_set_updated_at_pf_telefones
    BEFORE UPDATE 
    ON bigdata_final.pf_telefones
    FOR EACH ROW
    WHEN (old.* IS DISTINCT FROM new.*)
    EXECUTE FUNCTION bigdata_final.set_updated_at();

ALTER TABLE bigdata_final.pf_telefones
ADD COLUMN temp_min character varying(255),
ADD COLUMN temp_max character varying(255),
ADD COLUMN ok_calls_total character varying(255),
ADD COLUMN whatsapp_checked_at timestamp without time zone,
ADD COLUMN err_404_notfound integer DEFAULT 0,
ADD COLUMN err_503_blacklist_stage integer DEFAULT 0,
ADD COLUMN penal_487_cancel integer DEFAULT 0,
ADD COLUMN penal_480_noanswer integer DEFAULT 0,
ADD COLUMN last_ok_date date,
ADD COLUMN last_error_date date;