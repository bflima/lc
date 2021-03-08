#!/usr/bin/env bash

# Variaveis acesso banco
USER_BANCO="root"
USER_SENHA="admin@123"

# Variaveis
BANCO="termometro"
USER="temper2"
PASS="admin@123"

# Verificar pacotes
which mariadb || apt-get install mariadb-server

# Configurar banco de dados
# mysql_secure_installation

mysql -u"$USER_BANCO" -p"$USER_SENHA" -e "create database if not exists $BANCO;"
mysql -u"$USER_BANCO" -p"$USER_SENHA" -e "CREATE USER '$USER'@localhost IDENTIFIED BY '$PASS';"
mysql -u"$USER_BANCO" -p"$USER_SENHA" -e "GRANT ALL PRIVILEGES ON $BANCO.* TO '$USER'@'localhost' IDENTIFIED BY '$PASS';"
mysql -u"$USER_BANCO" -p"$USER_SENHA" -e "FLUSH PRIVILEGES;"

# Criar tabela Telegrgam
mysql -u"$USER_BANCO" -p"$USER_SENHA" $BANCO -e "
                                    CREATE TABLE if not exists log(
                                    id_log INT NOT NULL AUTO_INCREMENT,
                                    tdate int(11) NOT NULL,
                                    evento VARCHAR(255) NOT NULL,
                                    status VARCHAR(45) NOT NULL,
                                    PRIMARY KEY (id_log)); "

# Criar tabela Telegrgam
mysql -u"$USER_BANCO" -p"$USER_SENHA" $BANCO -e "
                                    CREATE TABLE if not exists envio(
                                    id_envio INT NOT NULL AUTO_INCREMENT,
                                    tdate int(11) NOT NULL,
                                    evento VARCHAR(255) NOT NULL,
                                    status VARCHAR(45) NOT NULL,
                                    PRIMARY KEY (id_envio)); "

# Criar tabela Telegrgam
mysql -u"$USER_BANCO" -p"$USER_SENHA" $BANCO -e "
                                    CREATE TABLE if not exists token(
                                    id_token INT NOT NULL AUTO_INCREMENT,
                                    nome_token VARCHAR(45) NOT NULL,
                                    chave_token VARCHAR(45) NOT NULL,
                                    PRIMARY KEY (id_token)); "

mysql -u"$USER_BANCO" -p"$USER_SENHA" $BANCO -e "
                                    CREATE TABLE if not exists email(
                                    id_email INT NOT NULL AUTO_INCREMENT,
                                    nome_email VARCHAR(45) NOT NULL,
                                    email VARCHAR(45) NOT NULL,
                                    PRIMARY KEY (id_email)); "


# Criar tabela Cadastro
mysql -u"$USER_BANCO" -p"$USER_SENHA" $BANCO -e "
                                    CREATE TABLE if not exists cadastro(
                                    id_cadastro INT NOT NULL,
                                    max_temp float(2) NOT NULL,
                                    min_temp float(2) NOT NULL,
                                    local_temp varchar(255) NOT NULL,
                                    PRIMARY KEY (id_cadastro)); "

# Cadastrando tabela com inforações padrão
mysql -u"$USER_BANCO" -p"$USER_SENHA" $BANCO -e " INSERT INTO cadastro(max_temp, min_temp, local_temp) values (8, 2, 'NAO INFORMADO');"

# Criar tabela temperatura
mysql -u"$USER_BANCO" -p"$USER_SENHA" $BANCO -e "
                                  CREATE TABLE if not exists temper(
                                  id     int           NOT NULL AUTO_INCREMENT PRIMARY KEY,
                                  tdate  int(11)       NOT NULL,
                                  tlocal varchar(255)  NOT NULL,
                                  temp   float(3)      NOT NULL
                                  ); "

# Criar indice para tabela temperatura (tdate)
mysql -u"$USER_BANCO" -p"$USER_SENHA" $BANCO -e "CREATE INDEX if not exists index_tdate ON temper (tdate);"

# Mostrar índices
mysql -u"$USER_BANCO" -p"$USER_SENHA" $BANCO -e "SHOW INDEXES FROM temper IN $BANCO";






csHJlweZhtg
curl -s -H "Content-Type: application/json" -X POST -d '{"text":" Alerta de temperatura, Valor = '' "}' https://integram.org/csHJlweZhtg


# Insert
INSERT INTO termometro.token(nome_token) VALUES ('TESTE');

CREATE TABLE apagar(data int(11) NOT NULL DEFAULT CURRENT_TIMESTAMP);