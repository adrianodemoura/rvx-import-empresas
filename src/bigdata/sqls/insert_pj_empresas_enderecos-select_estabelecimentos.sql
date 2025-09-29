WITH inseridos AS (
    INSERT INTO $DB_SCHEMA.pj_empresas_enderecos( 
        data_origem,
        origem,
        cnpj,
        tipo,
        logradouro,
        numero,
        complemento,
        bairro,
        cidade,
        cep,
        uf
    )
    SELECT 
        '$DATA_ORIGEM' as data_origem,
        '$ORIGEM' as origem,
        s.cnpj_basico||s.cnpj_ordem||s.cnpj_dv as cnpj,
        s.tipo_logradouro,
        s.logradouro,
        s.numero,
        s.complemento,
        s.bairro,
        m.descricao AS municipio,
        s.cep,
        s.uf
    FROM $DB_SCHEMA_TMP.estabelecimentos s
    LEFT JOIN tmp_empresas.municipios m ON m.codigo = s.municipio
    WHERE s.id > $LAST_ID
    ORDER BY s.id 
    LIMIT $LIMIT
    RETURNING id
)
SELECT MAX(id) AS last_id FROM inseridos;
