WITH inseridos AS (
    INSERT INTO $DB_SCHEMA.pj_qualificacoes_socios( codigo, descricao )
    SELECT 
        codigo, 
        descricao 
        FROM $DB_SCHEMA_TMP.qualificacoes q
        WHERE q.id > $LAST_ID
        ORDER BY q.id 
        LIMIT $LIMIT
        RETURNING id
)
SELECT MAX(id) AS last_id FROM inseridos;