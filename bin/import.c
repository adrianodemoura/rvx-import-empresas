/**
 * Para compilar:
 * $ gcc import.c -o importa -I /usr/include/postgresql -l jansson -lpq
 */

#include <stdio.h>
#include <libpq-fe.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>   // gettimeofday
#include <jansson.h>
#include <locale.h>
#include <ctype.h>

// Remove espaços em branco no início e fim
char* trim(char* str) {
    char* end;
    while(isspace((unsigned char)*str)) str++;
    if(*str == 0) return str;
    end = str + strlen(str) - 1;
    while(end > str && isspace((unsigned char)*end)) end--;
    end[1] = '\0';
    return str;
}

void carregar_env(const char* filename) {
    FILE* file = fopen(filename, "r");
    if (!file) {
        perror("Erro ao abrir .env");
        exit(1);
    }

    char line[256];
    while (fgets(line, sizeof(line), file)) {
        if (line[0] == '#' || strlen(line) < 3) continue; // ignora comentários e linhas curtas

        char* equal = strchr(line, '=');
        if (!equal) continue;

        *equal = '\0';
        char* key = trim(line);
        char* value = trim(equal + 1);

        // remove \n do final
        value[strcspn(value, "\r\n")] = 0;

        setenv(key, value, 1); // coloca no ambiente
    }
    fclose(file);
}

void carregar_env_duplo(const char* base_env, const char* local_env) {
    // Carrega o .env principal
    carregar_env(base_env);

    // Carrega o .env.local por cima, sobrescrevendo variáveis duplicadas
    carregar_env(local_env);
}

char* str_replace(char* str, char* old, char* new) {
    int len_old = strlen(old);
    int len_new = strlen(new);
    int count = 0;
    char* p = str;
    while ((p = strstr(p, old)) != NULL) {
        count++;
        p += len_old;
    }
 
    char* ret = (char*)malloc(strlen(str) + count * (len_new - len_old) + 1);
    char* q = ret;
    p = str;
    while ((p = strstr(p, old)) != NULL) {
        memcpy(q, str, p - str);
        q += p - str;
        memcpy(q, new, len_new);
        q += len_new;
        p += len_old;
        str = p;
    }
    strcpy(q, str);
    return ret;
}
 
char* substituir_variaveis(char* sql, char* db_schema_tmp, char* db_schema, char* data_origem, char* offset, char* limit) {
    char* new_sql = (char*)malloc(strlen(sql) + strlen(db_schema_tmp) + strlen(db_schema) + strlen(data_origem) + strlen(offset) + strlen(limit) +1 );
    strcpy(new_sql, sql);
    new_sql = str_replace(new_sql, "$DB_SCHEMA_TMP", db_schema_tmp);
    new_sql = str_replace(new_sql, "$DB_SCHEMA", db_schema);
    new_sql = str_replace(new_sql, "$DATA_ORIGEM", data_origem);
    new_sql = str_replace(new_sql, "$OFFSET", offset);
    new_sql = str_replace(new_sql, "$LIMIT", limit);
    return new_sql;
}
 
void ler_config(char* arquivo, char** data_origem, char** limit, char** max_registros) {
    json_t* json;
    json_error_t error;
 
    json = json_load_file(arquivo, 0, &error);
    if (!json) {
        printf("Erro ao ler o arquivo de configuração: %s\n", error.text);
        exit(1);
    }

    *data_origem = strdup(json_string_value(json_object_get(json, "data_origem")));
    *limit = strdup(json_string_value(json_object_get(json, "limit")));
    *max_registros = strdup(json_string_value(json_object_get(json, "max_registros")));
 
    json_decref(json);
}
 
void imprimir_tempo_execucao(time_t inicio, time_t fim) {
    double tempo_execucao = difftime(fim, inicio);
 
    int horas = (int)tempo_execucao / 3600;
    int minutos = ((int)tempo_execucao % 3600) / 60;
    int segundos = (int)tempo_execucao % 60;
 
    printf("Tempo estimado: %02d:%02d:%02d\n", horas, minutos, segundos);
}
 
void imprimir_hora( char* str) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
 
    struct tm *tm_info = localtime(&tv.tv_sec);
 
    printf("%s: %02d:%02d:%02d.%03ld\n",
        str,
        tm_info->tm_hour,
        tm_info->tm_min,
        tm_info->tm_sec,
        tv.tv_usec / 1000
    );
}

void hora_atual_str(char* buffer, size_t size) {
    struct timeval tv;
    gettimeofday(&tv, NULL);

    struct tm *tm_info = localtime(&tv.tv_sec);

    snprintf(buffer, size, "%02d:%02d:%02d.%03ld",
             tm_info->tm_hour,
             tm_info->tm_min,
             tm_info->tm_sec,
             tv.tv_usec / 1000);
}

int main() {
    time_t inicio, fim;
    time(&inicio);
 
    // Printar hora inicial
    imprimir_hora( "Início" );
    puts("");

    // pega locale do sistema (ex: pt_BR)
    setlocale(LC_NUMERIC, "");

    // Carrega .env e .env.local
    carregar_env_duplo("../.env", "../.env.local");

    // Pega variáveis do ambiente
    char *host          = getenv("DB_HOST");
    char *dbname        = getenv("DB_DATABASE");
    char *user          = getenv("DB_USER");
    char *password      = getenv("DB_PASSWORD");
    char *dbport        = getenv("DB_PORT");
    char *dbschema      = getenv("DB_SCHEMA");
    char *dbschema_tmp  = getenv("DB_SCHEMA_TMP");

    if (!host || !dbname || !user || !password) {
        fprintf(stderr, "Erro: variáveis de ambiente do banco não definidas.\n");
        exit(1);
    }
 
    PGconn *conn;
    PGresult *res;
    char *data_origem;
    char *limit;
    char *max_registros;
    char conn_string[256];
 
    ler_config("config.json", &data_origem, &limit, &max_registros);
 
    sprintf(conn_string, "host=%s dbname=%s user=%s password=%s", host, dbname, user, password);
 
    // Conectar ao banco de dados
    conn = PQconnectdb(conn_string);
 
    if (PQstatus(conn) == CONNECTION_BAD) {
        printf("Erro ao conectar ao banco de dados: %s\n", PQerrorMessage(conn));
        exit(1);
    }
 
    // Carregar o arquivo SQL
    FILE *arquivo = fopen("../src/import_bigdata/sqls/insert_pj_empresas_select_empresas.sql", "r");
    if (!arquivo) {
        printf("Erro ao abrir o arquivo SQL\n");
        return 1;
    }
    fseek(arquivo, 0, SEEK_END);
    long tamanho = ftell(arquivo);
    rewind(arquivo);
    char* sql = (char *) malloc(tamanho + 1);
    fread(sql, 1, tamanho, arquivo);
    sql[tamanho] = '\0';
    fclose(arquivo);
 
     // Conversão de valores numéricos
    long off = 0;
    long lim = atol(limit);
    long max_records = atol(max_registros);
    long total_importados = 0;
    int lote = 1;

    while (total_importados < max_records) {
        // Ajusta limite se faltar menos registros para atingir o máximo
        long lim_atual = lim;
        if (total_importados + lim > max_records) {
            lim_atual = max_records - total_importados;
        }

        char str_off[50], str_lim[50];
        sprintf(str_off, "%ld", off);
        sprintf(str_lim, "%ld", lim_atual);

        char* new_sql = substituir_variaveis(sql, dbschema_tmp, dbschema, data_origem, str_off, str_lim);

        printf("➡️  Executando lote %d (OFFSET=%ld, LIMIT=%ld)\n", lote, off, lim_atual);

        res = PQexec(conn, new_sql);

        if (PQresultStatus(res) != PGRES_COMMAND_OK && PQresultStatus(res) != PGRES_TUPLES_OK) {
            printf("Erro na execução da query: %s\n", PQerrorMessage(conn));
            PQclear(res);
            free(new_sql);
            break;
        }

        int registros = 0;

        if (PQresultStatus(res) == PGRES_COMMAND_OK) {
            registros = atoi(PQcmdTuples(res));  // número de linhas afetadas em INSERT/UPDATE/DELETE
        } else if (PQresultStatus(res) == PGRES_TUPLES_OK) {
            registros = PQntuples(res);          // número de linhas retornadas em SELECT
        }

        PQclear(res);
        free(new_sql);

        if (registros == 0) {
            printf("✅ Nenhum registro retornado, fim do processamento.\n");
            break;
        }


        total_importados += registros;
        // printf("📦 Total importado até agora: %'ld\n", total_importados);
        char hora[16];
        hora_atual_str(hora, sizeof(hora));
        printf("%s 📦 Total importado até agora: %'ld\n", hora, total_importados);


        off += lim;
        lote++;

        if (total_importados >= max_records) {
            puts("");
            printf("🛑 Limite de %'ld registros atingido. 👍\n", max_records);
            break;
        }
    }

    free(sql);
    PQfinish(conn);

    // 
    puts("");
    imprimir_hora( "FIM" );
    puts("");

    // fim
    time(&fim);
    imprimir_tempo_execucao(inicio, fim);

    return 0;
 }
 