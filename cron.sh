#!/usr/bin/env bash

# Agendar no cron do usuario não root

# Variaveis acesso banco
USER_BANCO="root"
USER_SENHA="admin@123"
BANCO="termometro"
USER="temper2"
PASS="admin@123"

# Variáveis
LSUSB=$(which lsusb)
TEMPER=$(which temper-poll)
MYSQL=$(which mysql)
ERROR_MSG="Termomêtro USB não foi detectado"
MSG_TELEGRAM="Mensagem de alerta via TELGRAM"

# Verificando se o dispositivo USB está conectado
$LSUSB | grep -oq "TEMPer" || \
  { echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "insert into log (tdate, evento, status) values ($(date +%s), '$ERROR_MSG', 'ERRO');" ; exit 5 ; }

# Lendo local cadastrado
MIN=$(echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "select min_temp from cadastro" | tail -n 1)
MAX=$(echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "select max_temp from cadastro" | tail -n 1)
LOCAL=$(echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "select local_temp from cadastro" | tail -n 1)

# Lendo temperatura
TEMPERATURA=$(echo "$PASS" | sudo -S "$TEMPER" -c) || \
  { echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "insert into log (tdate, evento, status) values ($(date +%s), '$ERROR_MSG', 'ERRO');" ; exit 5 ; }

# Verificando se a temperatura foi lida
if [[ $(wc -l <<< "$TEMPERATURA") -eq 0 ]] || [[ "${#TEMPERATURA}" -eq 0 ]]
  then { echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "insert into log (tdate, evento, status) values ($(date +%s), '$ERROR_MSG', 'ERRO');" ; exit 5 ; }
fi

# Inserindo temperatura no banco
echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "INSERT INTO temper (tdate, tlocal, temp) VALUES ($(date +%s),'$LOCAL', $TEMPERATURA);"

# Testar se chave telegram está configurada
CHAVE=$(echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" $BANCO -e "select chave_token from token" | tail -n 1)
if [[ ${#CHAVE} -eq 0 ]]
  then 
    echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "insert into envio (tdate, evento, status) values ($(date +%s), '$MSG_TELEGRAM', 'ERRO DE ENVIO NAO CONFIGURADO');"
    exit 5 
fi

# Verificando se a temperatuta está dentro do padrão
if (( $(echo "$TEMPERATURA < $MIN" | bc -l) ))
  then 
      CHAVE=$(echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" $BANCO -e "select chave_token from token")
      for ITEM_CHAVE in $(echo "${CHAVE}" | tr ' ' '\n' | tail -n +2)
        do 
          DATA_MSG=$(date '+%d/%m/%Y %T')
          curl -H "Content-Type: application/json" -X POST -d '{"text":"'"Alerta Temperatura monitorada no local: \
            $LOCAL atingiu o valor mínimo: $TEMPERATURA graus na data $DATA_MSG, valor de referência é $MIN graus"'"}' "https://integram.org/$ITEM_CHAVE"
          echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "insert into envio (tdate, evento, status) values ($(date +%s), '$MSG_TELEGRAM chave $ITEM_CHAVE', 'ENVIADO');"  
          sleep 1
      done

elif (( $(echo "$TEMPERATURA > $MAX" | bc -l) ))
  then 
      CHAVE=$(echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" $BANCO -e "select chave_token from token")
      for ITEM_CHAVE in $(echo "${CHAVE}" | tr ' ' '\n' | tail -n +2)
        do 
          DATA_MSG=$(date '+%d/%m/%Y %T')
          curl -H "Content-Type: application/json" -X POST -d '{"text":"'"Alerta Temperatura monitorada no local: \
            $LOCAL atingiu o valor máximo: $TEMPERATURA graus na data $DATA_MSG, valor de referência é $MAX graus"'"}' "https://integram.org/$ITEM_CHAVE"
          echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "insert into envio (tdate, evento, status) values ($(date +%s), '$MSG_TELEGRAM chave $ITEM_CHAVE', 'ENVIADO');"
          sleep 1
      done
fi
