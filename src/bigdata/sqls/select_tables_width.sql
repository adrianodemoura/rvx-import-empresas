-- tamanho de cada tabela
SELECT 
  relname AS tabela, 
  pg_size_pretty(pg_total_relation_size(relid)) AS tamanho
FROM 
  pg_catalog.pg_stat_user_tables 
WHERE 
  schemaname = 'bigdata_final'
ORDER BY 
  pg_total_relation_size(relid) DESC;