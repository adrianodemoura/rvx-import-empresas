#!/bin/bash
#

sed -n '1,1000p' "/media/dados/adrianod/rvx/SIAPE_SETEMBRO/1 - Siape Setembro 2025 - PENSIONISTAS.csv" > storage/cache/import_csv/1_siape_setembro_2025_pensionistas.csv
sed -n '1,1000p' "/media/dados/adrianod/rvx/SIAPE SETEMBRO/2 - Siape Setembro 2025 - SERVIDOR 1.csv" > storage/cache/import_csv/2_siape_setembro_2025_servidor_1.csv
sed -n '1,1000p' "/media/dados/adrianod/rvx/SIAPE SETEMBRO/3 - Siape Setembro 2025 - SERVIDOR 2.csv" > storage/cache/import_csv/3_siape_setembro_2025_servidor_2.csv
sed -n '1,1000p' "/media/dados/adrianod/rvx/SIAPE SETEMBRO/4 - Siape Setembro 2025 - SERVIDOR 3.csv" > storage/cache/import_csv/4_siape_setembro_2025_servidor_3.csv
sed -n '1,1000p' "/media/dados/adrianod/rvx/SIAPE SETEMBRO/5 - Siape Setembro 2025 - SERVIDOR EXCLUIDOS.csv" > storage/cache/import_csv/5_siape_setembro_2025_servidor_excluidos.csv
sed -n '1,1000p' "/media/dados/adrianod/rvx/SIAPE SETEMBRO/6 - Siape Setembro 2025 - PENSIONISTAS EXCLUIDOS.csv" > storage/cache/import_csv/6_siape_setembro_2025_pensionistas_excluidos.csv