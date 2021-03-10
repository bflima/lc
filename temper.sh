#!/usr/bin/env bash

# Variaveis acesso banco
USER_BANCO="root"
USER_SENHA="admin@123"

# Variaveis
BANCO="termometro"
USER="temper2"
PASS="admin@123"

# Variáveis
LSUSB=$(which lsusb)
MYSQL=$(which mysql)
ERROR_MSG_LOG="Termomêtro USB não foi detectado"
MSG_MAIL="Envio de mensagem de alerta por e-mail"
COUNT=0

clear 

# Testando se tem rede ativa
if [[ $(ip link show | grep -ic "state up") -eq 0 ]]
  then
    echo -e "$(tput bold)$(tput setaf 1)$(tput setab 7)Rede não disponível $(tput sgr0) \n"
  sleep 5
fi

# Veririfando se email esta cadastrado
EMAIL=$(echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "select email from email limit 1" | tail -n 1)
if [[ ${#EMAIL} -eq 0 ]]
  then
    echo -e "$(tput bold)$(tput setaf 1)Email para envio de alerta não cadastrado $(tput sgr0) \n"
    echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "insert into envio (tdate, evento, status) values ($(date +%s), '$MSG_MAIL não cadastrado', 'ENVIO DE EMAIL NAO CONFIGURADO');"
    sleep 5
fi

# Inicio do monitoramento
while true
  do
  # Reset cor
  NORNAL=$(tput sgr0) ;

  $LSUSB | grep -oq "TEMPer" || \
    { echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "insert into log (tdate, evento, status) values ($(date +%s), '$ERROR_MSG_LOG', 'ERRO');" ; exit 5 ; }

  #Data e hora
  TEMP=$(echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "select round(temp, 1), date_format(from_unixtime(tdate), '%d/%m/%Y %T') from temper order by tdate DESC limit 1" | tail -n 1 | tr '\t' ' ')
  TMIN=$(echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "select round(min(temp),1), date_format(from_unixtime(tdate), '%d/%m/%Y %T') from temper where temp in (select min(temp) from temper where date_format(from_unixtime(tdate), '%Y') = DATE_FORMAT(now(),'%Y')) order by tdate DESC limit 1" | tail -n 1 | tr '\t' ' ')
  TMAX=$(echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "select round(max(temp),1), date_format(from_unixtime(tdate), '%d/%m/%Y %T') from temper where temp in (select max(temp) from temper where date_format(from_unixtime(tdate), '%Y') = DATE_FORMAT(now(),'%Y')) order by tdate DESC limit 1" | tail -n 1 | tr '\t' ' ')

  # Valores maximo e minimo
  MIN=$(echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "select min_temp from cadastro" | tail -n 1)
  MAX=$(echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "select max_temp from cadastro" | tail -n 1)
  LOCAL=$(echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "select local_temp from cadastro" | tail -n 1)

  # Função para enviar email
  function _EMAIL(){
    TEXTO="A temperatura monitorada atingiu o valor ${TEMP//\ *}  grau(s), no setor $LOCAL na data $(date '+%d/%m/%Y %T')"
    curl -s --url 'smtps://smtp.gmail.com:465' --ssl-reqd \
    --mail-from 'envio.temper@gmail.com' \
    --mail-rcpt 'informatica@santacasadevalinhos.com.br' \
    --user 'envio.temper@gmail.com:envio_Temper.01' \
    -T <(echo -e "From: from-envio.temper@gmail.com\nTo: informatica@santacasadevalinhos.com.br\nSubject: Alerta Monitoramento\n\n$TEXTO")
  }

  # Listando informações
  clear
  
  # Realizando os testes
  if (( $(echo "${TEMP//\ *} > $MAX" | bc -l) ))
    then echo -e "$(tput bold)$(tput setaf 1)$(tput setab 7)Temperatura Atual.: ${TEMP//\ *}\n$(cut -d " " -f 2- <<< "$TEMP") $NORNAL \n"
  elif (( $(echo "${TEMP//\ *} < $MIN" | bc -l) ))
    then echo -e "$(tput bold)$(tput setab 4)Temperatura Atual.: ${TEMP//\ *}\n$(cut -d " " -f 2- <<< "$TEMP") $NORNAL \n"
  else
    echo -e "$(tput bold)$(tput setaf 2)Temperatura Atual.: ${TEMP//\ *}\n$(cut -d " " -f 2- <<< "$TEMP") $NORNAL \n"
  fi
  echo -e "$(tput bold)$(tput setaf 6)Temperatura Mínima: ${TMIN//\ *} \n$(cut -d " " -f 2- <<< "$TMIN") $NORNAL \n $NORNAL \n"
  echo -e "$(tput bold)$(tput setaf 1)Temperatura Máxima: ${TMAX//\ *} \n$(cut -d " " -f 2- <<< "$TMAX") $NORNAL \n" 

#TEMP="1.1"

  # Enviar email
  EMAIL=$(echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "select email from email limit 1" | tail -n 1)
  if [[ ${#EMAIL} -ne 0 ]] && [[ $(ip link show | grep -ic "state up") -ne 0 ]] 
    then
      if (( $(echo "${TEMP//\ *} < $MIN" | bc -l) )) || (( $(echo "${TEMP//\ *} > $MAX" | bc -l) ))
        then
          if [[ $COUNT -eq 0 ]]; then
          echo "$PASS" | sudo -S "$MYSQL" -u"$USER_BANCO" -p"$USER_SENHA" "$BANCO" -e "insert into envio (tdate, evento, status) values ($(date +%s), '$MSG_MAIL', 'EMAIL ENVIADO');"
          _EMAIL
          fi
        (( "COUNT= ++COUNT" ))
        if [[ $COUNT -eq 60 ]] ; then (( "COUNT=0" )) ; fi
      fi
  fi
  # Tempo de atualização
  sleep 45
  done
