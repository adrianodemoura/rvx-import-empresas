-- pf_pessoas
SELECT COUNT(1) FROM tmp_bigdata.pf_pessoas;
SELECT * FROM tmp_bigdata.pf_pessoas ORDER BY id ASC LIMIT 10;

-- pj_qualificacoes_socios
SELECT * FROM tmp_bigdata.pj_qualificacoes_socios q LIMIT 101;
SELECT COUNT(1) FROM tmp_bigdata.pj_qualificacoes_socios q;
SELECT * FROM tmp_empresas.qualificacoes q LIMIT 101;
SELECT COUNT(1) FROM tmp_empresas.qualificacoes q;

-- naturezas_juridicas
SELECT * FROM tmp_bigdata.pj_naturezas_juridicas n LIMIT 11;
SELECT COUNT(1) FROM tmp_bigdata.pj_naturezas_juridicas n;
SELECT * FROM tmp_empresas.naturezas n LIMIT 11;
SELECT COUNT(1) FROM tmp_empresas.naturezas n;

-- pj_empresas_telefones
SELECT * 
	FROM tmp_bigdata.pj_empresas_telefones et 
	WHERE et.cnpj='18107794000152'
	ORDER BY et.cnpj 
	LIMIT 11;
SELECT COUNT(1) FROM tmp_bigdata.pj_empresas_telefones et;
SELECT * 
	FROM tmp_empresas.estabelecimentos s 
	WHERE s.cnpj_basico='18107613' 
		AND s.cnpj_ordem='0001' 
		AND s.cnpj_dv='98' 
		LIMIT 11;
SELECT COUNT(1) FROM tmp_empresas.estabelecimentos s;
SELECT COUNT(1) AS total, et.cnpj, et.telefone 
	FROM tmp_bigdata.pj_empresas_telefones et
	GROUP BY 2,3
	HAVING COUNT(1)>1;

-- pj_empresas_socios
SELECT * FROM tmp_bigdata.pj_empresas_socios es LIMIT 11;
SELECT COUNT(1) FROM tmp_bigdata.pj_empresas_socios es;
SELECT COUNT(1), es.cpf
	FROM tmp_bigdata.pj_empresas_socios es
	GROUP BY es.cpf
	HAVING COUNT(1) > 1;
SELECT * FROM tmp_empresas.socios es WHERE es.cpf IS NOT NULL LIMIT 11;
SELECT COUNT(1) FROM tmp_empresas.socios es;
SELECT COUNT(1), o.cnpj_basico, o.cnpj_cpf_socio
	FROM tmp_empresas.socios o
	GROUP BY o.cnpj_basico, o.cnpj_cpf_socio
	HAVING COUNT(1) > 1;
CREATE INDEX IF NOT EXISTS socios_cnpj_basico_idx ON tmp_empresas.socios USING btree (cnpj_basico);

-- pj_empresas_emails
SELECT COUNT(1) FROM tmp_bigdata.pj_empresas_emails;
SELECT * FROM tmp_empresas.estabelecimentos s LIMIT 110;
SELECT * FROM tmp_bigdata.pj_empresas e WHERE e.cnpj='09017632000132' LIMIT 11;
SELECT * FROM tmp_bigdata.pj_empresas_emails em WHERE em.cnpj='09017632000132' LIMIT 11;
SELECT * FROM tmp_bigdata.pj_empresas_emails em WHERE em.cnpj='00019357000545' LIMIT 11;
SELECT count(1) as total, em.cnpj FROM tmp_bigdata.pj_empresas_emails em GROUP BY em.cnpj HAVING count(1)>1;

-- pj_empresas_enderecos
SELECT * FROM tmp_bigdata.pj_empresas_enderecos ee ORDER BY ee.cnpj LIMIT 11;
SELECT COUNT(1) FROM tmp_bigdata.pj_empresas_enderecos ee;
SELECT * FROM tmp_empresas.estabelecimentos s LIMIT 11;
SELECT COUNT(1) FROM tmp_empresas.estabelecimentos s;

-- pj_empresas_cnaes
SELECT COUNT(1) FROM tmp_bigdata.pj_empresas_cnaes ec;
SELECT * FROM tmp_bigdata.pj_empresas_cnaes ec ORDER BY ec.ID DESCLIMIT 11;
SELECT COUNT(1) as total, ec.cnpj, ec.cnae
	FROM tmp_bigdata.pj_empresas_cnaes ec
	GROUP BY ec.cnpj, ec.cnae
	HAVING COUNT(1) > 1;
SELECT *
	FROM tmp_empresas.estabelecimentos ec
	WHERE ec.cnpj_basico='09497274'
	LIMIT 11;

SELECT SUM(
    CASE 
        WHEN cnae_fiscal_secundaria IS NULL OR cnae_fiscal_secundaria = '' THEN 0
        ELSE array_length(string_to_array(cnae_fiscal_secundaria, ','), 1)
    END
) AS total_cnaes_secundarios
FROM tmp_empresas.estabelecimentos;

SELECT 
	s.cnpj_basico||s.cnpj_ordem||s.cnpj_dv AS cnpj,
	trim(cnae_valor) AS cnae,
	CASE WHEN cnae_valor = s.cnae_fiscal THEN 'principal' ELSE 'secundário' END AS tipo
FROM 
	tmp_empresas.estabelecimentos s,
	unnest(string_to_array(s.cnae_fiscal_secundaria, ',') || ARRAY[s.cnae_fiscal]) AS cnae_valor
WHERE s.id > 30 ORDER BY s.id LIMIT 10;

-- pj_cnaes_list
SELECT COUNT(1) FROM tmp_bigdata.pj_cnaes_list c;
SELECT * FROM tmp_bigdata.pj_cnaes_list c LIMIT 11;
SELECT count(1) FROM tmp_empresas.cnaes c;
SELECT * FROM tmp_empresas.cnaes c LIMIT 11;

-- pj_empresas
SELECT COUNT(1) FROM tmp_bigdata.pj_empresas e;
SELECT * FROM tmp_bigdata.pj_empresas e LIMIT 11;
SELECT count(1) FROM tmp_empresas.empresas e;
SELECT * FROM tmp_empresas.empresas e LIMIT 11;

-- pj_paises
SELECT COUNT(1) AS total, p.codigo
	FROM tmp_empresas.paises p
	GROUP BY p.codigo
	HAVING count(1) > 1;

SELECT o.id, o.cnpj_cpf_socio, o.cnpj_basico 
	FROM tmp_empresas.socios o 
	ORDER BY o.id 
	LIMIT 11;

SELECT 
	  o.cnpj_basico
	, o.cnpj_cpf_socio
	, s.cnpj_basico||s.cnpj_ordem||s.cnpj_dv as cnpj
	, CASE o.identificador_de_socio
		WHEN '1' THEN 'PESSOA JURÍDICA'
		WHEN '2' THEN 'PESSOA FÍSICA'
		WHEN '3' THEN 'ESTRANGEIRO'
		ELSE 'DESCONHECIDO'
	  END
	, q.descricao as qualificacao
	, o.nome_representante
	, q2.descricao as qualificacao_representante
	, o.faixa_etaria
	, p.descricao as pais
	, CASE o.data_entrada_sociedade WHEN '***000000**' THEN NULL ELSE TO_DATE(o.data_entrada_sociedade, 'YYYYMMDD') END as data_entrada_sociedade
	FROM tmp_empresas.socios o
	LEFT JOIN tmp_empresas.estabelecimentos s ON s.cnpj_basico = o.cnpj_basico
	LEFT JOIN tmp_empresas.paises p ON p.codigo = o.pais
	LEFT JOIN tmp_empresas.qualificacoes q ON q.codigo = o.qualificacao_socio
	LEFT JOIN tmp_empresas.qualificacoes q2 ON q2.codigo = o.qualificacao_representante_legal
	ORDER BY o.id 
	LIMIT 11;

-- Removendo os * do socios.
UPDATE tmp_bigdata.socios
	SET cnpj_cpf_socio = REPLACE(cnpj_cpf_socio, '*', '')
	WHERE ID < 100;
