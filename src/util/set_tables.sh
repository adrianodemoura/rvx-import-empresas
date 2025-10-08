#!/bin/bash
#
source "./config/config.sh"

for entry in "${TABLES[@]}"; do
    table_name=${entry%%.*}
    table_nick=$(getTableAttr $table_name nick)

    if ! [[ "$table_name" =~ ^(pf_emails|pf_pessoas|pf_enderecos)$ ]]; then
        continue
    fi

    echo "Tabela: '$table_name', Alias da Tabela: '$table_nick'"

    FIELDS=$("${PROD_PSQL_CMD[@]}" -t -A -F "" -c \
        "SELECT column_name||'-'
        FROM information_schema.columns 
        WHERE table_schema='$PROD_POSTGRES_DB_SCHEMA' 
        AND table_name='$table_name'
        ORDER BY ordinal_position")
    FIELDS=$(echo ${FIELDS%-} | tr -d ' ')
    echo "Fields: $FIELDS"

    INDEXES=$("${PROD_PSQL_CMD[@]}" -t -A -F "" -c \
        "SELECT idx.indexrelid::regclass AS index_name, string_agg(att.attname, ',') AS columns
            FROM pg_index idx
            JOIN pg_class t ON t.oid = idx.indrelid
            JOIN pg_attribute att 
            ON att.attrelid = t.oid AND att.attnum = ANY(idx.indkey)
            JOIN pg_namespace n ON t.relnamespace = n.oid
            WHERE t.relname = '$table_name'
            AND n.nspname = '$PROD_POSTGRES_DB_SCHEMA'
            GROUP BY idx.indexrelid::regclass")
    echo "Indexes: $INDEXES"

    # echo "Nome da Tabela: '$table_name', Alias da Tabela: '${table_nick:-fudeu}'"
    # echo "Campos: $(getTableAttr $table_name fields)"
    # echo "Índexes: $(getTableAttr $table_name indexes)"
    # echo "Constraints: $(getTableAttr $table_name constraints)"
    echo
done

