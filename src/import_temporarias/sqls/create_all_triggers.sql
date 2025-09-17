-- Função genérica (criada apenas uma vez)
CREATE OR REPLACE FUNCTION {schema}.updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Agora uma trigger para cada tabela
CREATE TRIGGER cnaes_update_timestamp
BEFORE UPDATE ON {schema}.cnaes
FOR EACH ROW
EXECUTE FUNCTION {schema}.updated_at_column();

CREATE TRIGGER simples_update_timestamp
BEFORE UPDATE ON {schema}.simples
FOR EACH ROW
EXECUTE FUNCTION {schema}.updated_at_column();

CREATE TRIGGER naturezas_update_timestamp
BEFORE UPDATE ON {schema}.naturezas
FOR EACH ROW
EXECUTE FUNCTION {schema}.updated_at_column();

CREATE TRIGGER motivos_update_timestamp
BEFORE UPDATE ON {schema}.motivos
FOR EACH ROW
EXECUTE FUNCTION {schema}.updated_at_column();

CREATE TRIGGER municipios_update_timestamp
BEFORE UPDATE ON {schema}.municipios
FOR EACH ROW
EXECUTE FUNCTION {schema}.updated_at_column();

CREATE TRIGGER paises_update_timestamp
BEFORE UPDATE ON {schema}.paises
FOR EACH ROW
EXECUTE FUNCTION {schema}.updated_at_column();
