WITH inseridos AS (
  INSERT INTO $DB_SCHEMA.pj_empresas_socios( 
    data_origem
  , origem
  , cpf
  , cnpj
  , qualificacao
  , nome_representante
  , qualificacao_representante
  , faixa_etaria
  , pais
  , identificador
  , data_entrada
  )
  SELECT 
      '$DATA_ORIGEM' as data_origem
    , 'socios' as origem
    , pp.cpf
    , s.cnpj_basico||s.cnpj_ordem||s.cnpj_dv as cnpj
    , q.descricao
    , o.nome_representante
    , q2.descricao as qualificacao_representante
    , o.faixa_etaria
    , p.descricao as pais
    , CASE o.identificador_de_socio WHEN '1' THEN 'PESSOA JURÍDICA' WHEN '2' THEN 'PESSOA FÍSICA' WHEN '3' THEN 'ESTRANGEIRO' ELSE 'DESCONHECIDO' END as identificador_de_socio
    , CASE o.data_entrada_sociedade WHEN '***000000**' THEN NULL ELSE TO_DATE(o.data_entrada_sociedade, 'YYYYMMDD') END as data_entrada_sociedade
    FROM $DB_SCHEMA_TMP.socios o
    LEFT JOIN $DB_SCHEMA_TMP.estabelecimentos s ON s.cnpj_basico = o.cnpj_basico
    LEFT JOIN $DB_SCHEMA_TMP.paises p ON p.codigo = o.pais
    LEFT JOIN $DB_SCHEMA_TMP.qualificacoes q ON q.codigo = o.qualificacao_socio
    LEFT JOIN $DB_SCHEMA_TMP.qualificacoes q2 ON q2.codigo = o.qualificacao_representante_legal
    LEFT JOIN $DB_SCHEMA_FINAL.pf_pessoas pp 
      ON  pp.cpf_basico = o.cnpj_cpf_socio
      AND pp.nome = o.nome_socio
    WHERE o.id > $LAST_ID
    ORDER BY o.id 
    LIMIT $LIMIT
    RETURNING id
)
SELECT MAX(id) AS last_id FROM inseridos;