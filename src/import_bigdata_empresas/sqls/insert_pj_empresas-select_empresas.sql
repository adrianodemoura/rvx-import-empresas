WITH inseridos AS (
    INSERT INTO $DB_SCHEMA.pj_empresas( 
        data_origem,
        origem,
        cnpj,
        cnpj_basico, 
        razao_social, 
        nome_fantasia,
        cod_natureza, 
        natureza_juridica_descricao,
        qualificacao_responsavel, 
        capital,
        porte,
        porte_descricao,
        situacao,
        situacao_descricao,
        situacao_data,
        situacao_motivo,
        situacao_motivo_descricao,
        abertura,
        tipo,
        tipo_descricao,
        optante_simples,
        data_opcao_simples,
        data_exclusao_simples,
        data_opcao_mei,
        data_exclusao_mei
    )
    SELECT 
        '$DATA_ORIGEM' as data_origem,
        '$ORIGEM' as origem,
        s.cnpj_basico||s.cnpj_ordem||s.cnpj_dv as cnpj,
        e.cnpj_basico, 
        e.razao_social, 
        s.nome_fantasia,
        e.natureza_juridica, 
        n.descricao,
        e.qualificacao_responsavel, 
        e.capital_social_str,
        e.porte_empresa,
        CASE e.porte_empresa 
            WHEN '1'  THEN 'NÃO INFORMADO' 
            WHEN '01' THEN 'NÃO INFORMADO' 
            WHEN '2'  THEN 'MICRO EMPRESA' 
            WHEN '02' THEN 'MICRO EMPRESA' 
            WHEN '03' THEN 'EMPRESA DE PEQUENO PORTE' 
            WHEN '05' THEN 'DEMAIS' 
        END as porte_descricao,
        s.situacao_cadastral,
        CASE s.situacao_cadastral 
            WHEN '01' THEN 'NULA' 
            WHEN '02' THEN 'ATIVA' 
            WHEN '03' THEN 'SUSPENSA' 
            WHEN '04' THEN 'INAPTA' 
            WHEN '08' THEN 'BAIXADA' 
            ELSE 'DESCONHECIDA' 
        END AS situacao_descricao, 
        s.data_situacao_cadastral,
        s.motivo_situacao_cadastral,
        m.descricao,
        s.data_inicio_atividades,
        s.matriz_filial,
        CASE s.matriz_filial WHEN '1' THEN 'MATRIZ' WHEN '2' THEN 'FILIAL' END as matriz_filial,
        CASE i.opcao_simples WHEN 'S' THEN true WHEN 'N' THEN false END as opcao_simples,
        CASE i.data_opcao_simples    WHEN '00000000' THEN NULL ELSE TO_DATE(i.data_opcao_simples,    'YYYYMMDD') END as data_opcao_simples,
        CASE i.data_exclusao_simples WHEN '00000000' THEN NULL ELSE TO_DATE(i.data_exclusao_simples, 'YYYYMMDD') END as data_exclusao_simples,
        CASE i.data_opcao_mei        WHEN '00000000' THEN NULL ELSE TO_DATE(i.data_opcao_mei,        'YYYYMMDD') END as data_opcao_mei,
        CASE i.data_exclusao_mei     WHEN '00000000' THEN NULL ELSE TO_DATE(i.data_exclusao_mei,     'YYYYMMDD') END as data_exclusao_mei
    FROM $DB_SCHEMA_TMP.estabelecimentos s
    LEFT JOIN $DB_SCHEMA_TMP.empresas e   ON e.cnpj_basico = s.cnpj_basico
    LEFT JOIN $DB_SCHEMA_TMP.motivos m    ON m.codigo = s.motivo_situacao_cadastral
    LEFT JOIN $DB_SCHEMA_TMP.naturezas n  ON n.codigo = e.natureza_juridica
    LEFT JOIN $DB_SCHEMA_TMP.simples i    ON i.cnpj_basico = e.cnpj_basico
    WHERE s.id > $LAST_ID
    ORDER BY s.id 
    LIMIT $LIMIT
    RETURNING id
)
SELECT MAX(id) AS last_id FROM inseridos;
