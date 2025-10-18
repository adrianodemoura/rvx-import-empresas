#!/bin/bash
#
# amarelo: pf_pessoas
# cinza : pf_siape_bancos
# verde: pf_siape_matriculass
# roxo: pf_siape_contratos
# vermelho: pf_enderecos
# laranja: pf_telefones
# bege: pf_emails
# se for pensionista, criar campo "tipo_aposentadoria", arquivo 1 e 6
# levar cpf e matrícula, para novas tabelas
# quando importar novamente, deletar empréstimos, pois virá tudo novamente.
# 6_siape_setembro_2025_pensionistas_excluidos.csv, colocar FLAG `excluído`.
# 

readonly FIELDS=(
    "cpf:pf_pessoas.cpf"
    "nome:pf_pessoas.nome"
    "SEXO:pf_pessoas.sexo"
    "DT_NASCIMENTO:pf_pessoas.nascimento"
    "IDADE":
    "NOME_MAE:pf_pessoas.nome_mae"

    "BCO_PAGTO:pf_siape_bancos.bco_pagto"
    "AG:pf_siape_bancos.ag"
    "CC:pf_siape_bancos.cc"
    "banco:pf_siape_bancos.banco"

    "rub:pf_siape_contratos.rub"
    "parcela:pf_siape_contratos.parcela"
    "prazo:pf_siape_contratos.prazo"
    "codigo_ug-iafi:pf_siape_contratos.codigo_uf_siafi"

    "orgao:pf_siape_matriculas.orgao"
    "instituidor:pf_siape_matriculas.instituidor"
    "matricula:pf_siape_matriculas.matricula"
    "upag:pf_siape_matriculas.upag"
    "uf:pf_siape_matriculas.uf"
    "tipoContrato:pf_siape_matriculas.tipo_contrato"
    "numeroContrato:pf_siape_matriculas.numero_contrato"
    "assunto_calculo:pf_siape_matriculas.assunto_calculo"
    "percentual:pf_siape_matriculas.percentual"
    "Orgao:pf_siape_matriculas.orgao"
    "Instituidor:pf_siape_matriculas.instituidor"
    "Matricula:pf_siape_matriculas.matricula"
    "Base alc:pf_siape_matriculas.base_calc"
    "Bruta %:pf_siape_matriculas.bruta_5"
    "Utilz %:pf_siape_matriculas.utilz_5"
    "Saldo %:pf_siape_matriculas.saldo_5"
    "Beneficio ruta 5%:pf_siape_matriculas.beneficio_bruta_5"
    "Beneficio tilizado 5%:pf_siape_matriculas.beneficio_utilizado_5"
    "Beneficio aldo 5%:pf_siape_matriculas.beneficio_saldo_5"
    "Bruta 5%:pf_siape_matriculas.bruta_35"
    "Utilz 5%:pf_siape_matriculas.utiliz_35"
    "Saldo 5%:pf_siape_matriculas.saldo_35"
    "Bruta 0%:pf_siape_matriculas.bruta_70"
    "Utilz 0%:pf_siape_matriculas.utilz_70"
    "Saldo 0%:pf_siape_matriculas.saldo_70"
    "Creditos:pf_siape_matriculas.creditos"
    "DEbitos:pf_siape_matriculas.debitos"
    "Liquido:pf_siape_matriculas.liquido"
    "ARQ.UPAG:pf_siape_matriculas.arq_upag"
    "EXC TD:pf_siape_matriculas.exc_qtd"
    "EXC oma:pf_siape_matriculas.exc_soma"
    "RJUR:pf_siape_matriculas.rjur"
    "Sit unc:pf_siape_matriculas.sit_func"
    "Margem:pf_siape_matriculas.margem"

    "TIPO_ENDERECO:pf_enderecos.tipo"
    "LOGRADOURO:pf_enderecos.logradouro"
    "NUMERO:pf_enderecos.numero"
    "COMPLEMENTO:pf_enderecos.complemento"
    "BAIRRO:pf_enderecos.bairro"
    "CIDADE:pf_enderecos.cidade"
    "ESTADO":
    "UF.:pf_enderecos.uf"
    "CEP:pf_enderecos.cep"

    "HotFone1:pf_telefones.telefone"
    "HotFone2:pf_telefones.telefone"
    "HotFone3:pf_telefones.telefone"
    "telefone_movel_1:pf_telefones.telefone"
    "telefone_movel_2:pf_telefones.telefone"
    "telefone_movel_3:pf_telefones.telefone"
    "telefone_movel_4:pf_telefones.telefone"
    "telefone_movel_5:pf_telefones.telefone"

    "email_1:pf_emails.email"
    "email_2:pf_emails.email"
    "email_3:pf_emails.email"
)
