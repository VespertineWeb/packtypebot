#!/bin/bash
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m                                                                       \e[0m"
echo -e "\e[32m  _____        _____ _  __  _________     _______  ______ ____   ____ _______ \e[0m"
echo -e "\e[32m |  __ \ /\   / ____| |/ / |__   __\ \   / /  __ \|  ____|  _ \ / __ \__   __|\e[0m"
echo -e "\e[32m | |__) /  \ | |    | ' /     | |   \ \_/ /| |__) | |__  | |_) | |  | | | |   \e[0m"
echo -e "\e[32m |  ___/ /\ \| |    |  <      | |    \   / |  ___/|  __| |  _ <| |  | | | |   \e[0m"
echo -e "\e[32m | |  / ____ \ |____| . \     | |     | |  | |    | |____| |_) | |__| | | |   \e[0m"
echo -e "\e[32m |_| /_/    \_\_____|_|\_\    |_|     |_|  |_|    |______|____/ \____/  |_|   \e[0m"
echo -e "\e[32m                                                                              \e[0m"                                                                                                                                            
echo -e "\e[32mAuto Instalador Pack Typebot                                                  \e[0m"                                                           \e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"


echo ""
echo -e "\e[32m==============================================================================\e[0m"
echo -e "\e[32m=                                                                            =\e[0m"
echo -e "\e[32m=                 \e[33mPreencha as informações solicitadas abaixo\e[32m                 =\e[0m"
echo -e "\e[32m=                                                                            =\e[0m"
echo -e "\e[32m==============================================================================\e[0m"
echo ""
echo ""
echo ""

# Prompt for email, traefik, senha, portainer, and edge variables
echo -e "\e[32mPasso \e[33m1/5\e[0m"
read -p "Endereço de e-mail: " email
echo ""
echo -e "\e[32mPasso \e[33m2/5\e[0m"
read -p "Dominio do Traefik (ex: traefik.seudominio.com): " traefik
echo ""
echo -e "\e[32mPasso \e[33m3/5\e[0m"
read -p "Senha do Traefik: " senha
echo ""
echo -e "\e[32mPasso \e[33m4/5\e[0m"
read -p "Dominio do Portainer (ex: portainer.seudominio.com): " portainer
echo ""
echo -e "\e[32mPasso \e[33m5/5\e[0m"
read -p "Dominio do Edge (ex: edge.seudominio.com): " edge
echo ""

#########################################################
#
# VERIFICAÇÃO DE DADOS
#
#########################################################

clear

echo ""
echo "Seu E-mail: $email"
echo "Dominio do Traefik: $traefik"
echo "Senha do Traefik: $senha"
echo "Dominio do Portainer: $portainer"
echo "Dominio do Edge: $edge"
echo ""
echo ""
read -p "As informações estão certas? (y/n): " confirma1
if [ "$confirma1" == "y" ]; then

  clear

  #########################################################
  #
  # INSTALANDO DEPENDENCIAS
  #
  #########################################################

  sudo apt update -y
  sudo apt upgrade -y
  sudo apt install curl

  curl -fsSL https://get.docker.com -o get-docker.sh

  sudo sh get-docker.sh

  sleep 3

  mkdir Portainer
  cd Portainer

  sleep 3

  echo ""
  echo ""
  echo "Atualizado/Instalado com Sucesso"

  sleep 3

  clear

  #########################################################
  #
  # CRIANDO DOCKER-COMPOSE.YML
  #
  #########################################################

  sleep 3

  # Create or modify docker-compose.yml file with subdomains
  cat > docker-compose.yml <<EOL
version: "3.3"
services:
  traefik:
    container_name: traefik
    image: "traefik:latest"
    restart: always
    command:
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --api.insecure=true
      - --api.dashboard=true
      - --providers.docker
      - --log.level=ERROR
      - --certificatesresolvers.leresolver.acme.httpchallenge=true
      - --certificatesresolvers.leresolver.acme.email=$email
      - --certificatesresolvers.leresolver.acme.storage=./acme.json
      - --certificatesresolvers.leresolver.acme.httpchallenge.entrypoint=web
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./acme.json:/acme.json"
    labels:
      - "traefik.http.routers.http-catchall.rule=hostregexp(\`{host:.+}\`)"
      - "traefik.http.routers.http-catchall.entrypoints=web"
      - "traefik.http.routers.http-catchall.middlewares=redirect-to-https"
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
      - "traefik.http.routers.traefik-dashboard.rule=Host(\`$traefik\`)"
      - "traefik.http.routers.traefik-dashboard.entrypoints=websecure"
      - "traefik.http.routers.traefik-dashboard.service=api@internal"
      - "traefik.http.routers.traefik-dashboard.tls.certresolver=leresolver"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=$senha"
      - "traefik.http.routers.traefik-dashboard.middlewares=traefik-auth"

  portainer:
    image: portainer/portainer-ce:latest
    command: -H unix:///var/run/docker.sock
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=Host(\`$portainer\`)"
      - "traefik.http.routers.frontend.entrypoints=websecure"
      - "traefik.http.services.frontend.loadbalancer.server.port=9000"
      - "traefik.http.routers.frontend.service=frontend"
      - "traefik.http.routers.frontend.tls.certresolver=leresolver"
      - "traefik.http.routers.edge.rule=Host(\`$edge\`)"
      - "traefik.http.routers.edge.entrypoints=websecure"
      - "traefik.http.services.edge.loadbalancer.server.port=8000"
      - "traefik.http.routers.edge.service=edge"
      - "traefik.http.routers.edge.tls.certresolver=leresolver"
volumes:
  portainer_data:
EOL

  clear

  ###############################################
  #
  # Certificates letsencrypt
  #
  ###############################################

  echo ""
  echo ""
  echo "Instalando certificado letsencrypt"

  touch acme.json

  sudo chmod 600 acme.json

  ###############################################
  #
  # INICIANDO CONTAINER
  #
  ###############################################

  sudo docker compose up -d


  echo -e "\e[32m\e[0m"
  echo -e "\e[32mAcesse o Portainer através do link: https://$portainer\e[0m"
  echo -e "\e[32m\e[0m"
  echo -e "\e[32mAcesse o Traefik através do link: https://$traefik\e[0m"
  echo -e "\e[32m\e[0m"
  echo -e "\e[32mhttps://packtypebot.com.br\e[0m"
  echo -e "\e[32m\e[0m"

  #########################################################
  #
  # OPÇÃO DE INSTALAÇÃO DO TYPEBOT
  #
  #########################################################

  read -p "Deseja instalar o Typebot? (y/n): " instala_typebot
  if [ "$instala_typebot" == "y" ]; then
    # prompting additional details for Typebot
    echo -e "\e[32mConfiguração do Typebot: \e[0m"
    read -p "URL do Builder (ex: app.seudominio.com): " typebot_builder_domain
    read -p "URL do Viewer (ex: typebot.seudominio.com): " typebot_viewer_domain
    read -p "URL do Storage (ex: storage.seudominio.com): " typebot_storage_domain

    read -p "SMTP Host: " smtp_host
    read -p "SMTP Porta: " smtp_port
    read -p "SMTP E-mail: " smtp_email
    read -p "SMTP Senha: " smtp_password

    # Generate a random ENCRYPTION_SECRET
    encryption_secret=$(openssl rand -hex 16)

    cat > docker-compose-typebot.yml <<EOL
version: '3.7'
services:
  typebot-db:
    image: postgres:13
    restart: always
    volumes:
      - typebot_db_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=typebot
      - POSTGRES_PASSWORD=typebot
    networks:
      - portainer_default

  typebot-builder:
    image: baptistearno/typebot-builder:latest
    restart: always
    depends_on:
      - typebot-db
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.typebot-builder.rule=Host(\`$typebot_builder_domain\`)"
      - "traefik.http.routers.typebot-builder.entrypoints=web,websecure"
      - "traefik.http.routers.typebot-builder.tls.certresolver=leresolver"
    environment:
      - DATABASE_URL=postgresql://postgres:typebot@typebot-db:5432/typebot
      - NEXTAUTH_URL=https://$typebot_builder_domain
      - NEXT_PUBLIC_VIEWER_URL=https://$typebot_viewer_domain
      - ENCRYPTION_SECRET=$encryption_secret
      - ADMIN_EMAIL=$email
      - DISABLE_SIGNUP=true
      - SMTP_AUTH_DISABLED=false
      - SMTP_SECURE=true
      - SMTP_HOST=$smtp_host
      - SMTP_PORT=$smtp_port
      - SMTP_USERNAME=$smtp_email
      - SMTP_PASSWORD=$smtp_password
      - NEXT_PUBLIC_SMTP_FROM=$smtp_email
      - S3_ACCESS_KEY=minio
      - S3_SECRET_KEY=minio123
      - S3_BUCKET=typebot
      - S3_ENDPOINT=$typebot_storage_domain   

    networks:
      - portainer_default

  typebot-viewer:
    image: baptistearno/typebot-viewer:latest
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.typebot-viewer.rule=Host(\`$typebot_viewer_domain\`)"
      - "traefik.http.routers.typebot-viewer.entrypoints=web,websecure"
      - "traefik.http.routers.typebot-viewer.tls.certresolver=leresolver"
    environment:
      - DATABASE_URL=postgresql://postgres:typebot@typebot-db:5432/typebot
      - NEXTAUTH_URL=https://$typebot_builder_domain
      - NEXT_PUBLIC_VIEWER_URL=https://$typebot_viewer_domain
      - ENCRYPTION_SECRET=$encryption_secret
      - SMTP_HOST=$smtp_host
      - NEXT_PUBLIC_SMTP_FROM=$smtp_email
      - S3_ACCESS_KEY=minio
      - S3_SECRET_KEY=minio123
      - S3_BUCKET=typebot
      - S3_ENDPOINT=$typebot_storage_domain
    networks:
      - portainer_default

  mail:
    image: bytemark/smtp
    restart: always
    networks:
      - portainer_default

  minio:
    image: minio/minio
    restart: always
    command: server /data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.minio.rule=Host(\`$typebot_storage_domain\`)"
      - "traefik.http.routers.minio.entrypoints=web,websecure"
      - "traefik.http.routers.minio.tls.certresolver=leresolver"
    environment:
      MINIO_ROOT_USER: minio
      MINIO_ROOT_PASSWORD: minio123
    volumes:
      - typebot_s3_data:/data
    networks:
      - portainer_default

  createbuckets:
    image: minio/mc
    depends_on:
      - minio
    entrypoint: >
      /bin/sh -c "
      sleep 10;
      /usr/bin/mc config host add minio http://minio:9000 minio minio123;
      /usr/bin/mc mb minio/typebot;
      /usr/bin/mc anonymous set public minio/typebot/public;
      exit 0;
      "
    networks:
      - portainer_default

volumes:
  typebot_db_data:
  typebot_s3_data:

networks:
  portainer_default:
    external: true
EOL

    sudo docker compose -f docker-compose-typebot.yml up -d

    echo -e "\e[32m\e[0m"
    echo -e "\e[32mTypebot instalado com sucesso!\e[0m"
    echo -e "\e[32mConstrutor (Builder): https://$typebot_builder_domain\e[0m"
    echo -e "\e[32mVisualizador (Viewer): https://$typebot_viewer_domain\e[0m"
    echo -e "\e[32m\e[0m"
  else
    echo "Instalação do Typebot foi pularida."
  fi

  #########################################################
  #
  # OPÇÃO DE INSTALAÇÃO DO EVOLUTION API
  #
  #########################################################

  read -p "Deseja instalar o Evolution API? (y/n): " instala_evolution
  if [ "$instala_evolution" == "y" ]; then
    # Prompting additional details for Evolution API
    read -p "URL do Server (ex: evolutionapi.seudominio.com): " evolution_api_domain

    # Generate a random AUTHENTICATION_API_KEY
    authentication_api_key=$(openssl rand -hex 16)

    cat > docker-compose-evolution.yml <<EOL
version: '3.8'

services:
  evolution_api:
    image: atendai/evolution-api:latest
    restart: always
    volumes:
      - evolution_instances:/evolution/instances
      - evolution_store:/evolution/store
      - evolution_manager:/evolution/Extras/appsmith
      - evolution_views:/evolution/views
    environment:
      SERVER_URL: 'https://$evolution_api_domain'
      CONFIG_SESSION_PHONE_CLIENT: PackTypebot
      CONFIG_SESSION_PHONE_NAME: Chrome
      AUTHENTICATION_TYPE: apikey
      AUTHENTICATION_API_KEY: $authentication_api_key
      AUTHENTICATION_EXPOSE_IN_FETCH_INSTANCES: true
      AUTHENTICATION_JWT_EXPIRIN_IN: 0
      AUTHENTICATION_JWT_SECRET: 'L=0YWt]b2w[WF>#>:&E`'
      STORE_MESSAGES: true
      STORE_MESSAGE_UP: true
      STORE_CONTACTS: true
      STORE_CHATS: true
      LOG_LEVEL: ERROR
      CLEAN_STORE_CLEANING_INTERVAL: 7200
      CLEAN_STORE_MESSAGES: true
      CLEAN_STORE_MESSAGE_UP: true
      CLEAN_STORE_CONTACTS: true
      CLEAN_STORE_CHATS: true
      WEBHOOK_GLOBAL_URL: ''
      WEBHOOK_GLOBAL_ENABLED: false
      WEBHOOK_GLOBAL_WEBHOOK_BY_EVENTS: false 
      WEBHOOK_EVENTS_APPLICATION_STARTUP: false
      WEBHOOK_EVENTS_QRCODE_UPDATED: true
      WEBHOOK_EVENTS_MESSAGES_SET: true
      WEBHOOK_EVENTS_MESSAGES_UPSERT: true
      WEBHOOK_EVENTS_MESSAGES_UPDATE: true
      WEBHOOK_EVENTS_MESSAGES_DELETE: true
      WEBHOOK_EVENTS_SEND_MESSAGE: true
      WEBHOOK_EVENTS_CONTACTS_SET: true
      WEBHOOK_EVENTS_CONTACTS_UPSERT: true
      WEBHOOK_EVENTS_CONTACTS_UPDATE: true
      WEBHOOK_EVENTS_PRESENCE_UPDATE: true
      WEBHOOK_EVENTS_CHATS_SET: true
      WEBHOOK_EVENTS_CHATS_UPSERT: true
      WEBHOOK_EVENTS_CHATS_UPDATE: true
      WEBHOOK_EVENTS_CHATS_DELETE: true
      WEBHOOK_EVENTS_GROUPS_UPSERT: true
      WEBHOOK_EVENTS_GROUPS_UPDATE: true
      WEBHOOK_EVENTS_GROUP_PARTICIPANTS_UPDATE: true
      WEBHOOK_EVENTS_CONNECTION_UPDATE: true
      WEBHOOK_EVENTS_CALL: true
      WEBHOOK_EVENTS_NEW_JWT_TOKEN: false
      WEBHOOK_EVENTS_TYPEBOT_START: false
      WEBHOOK_EVENTS_TYPEBOT_CHANGE_STATUS: false
      WEBHOOK_EVENTS_CHAMA_AI_ACTION: false
      WEBHOOK_EVENTS_ERRORS: false
      WEBHOOK_EVENTS_ERRORS_WEBHOOK:
      QRCODE_LIMIT: 30
      QRCODE_COLOR: #198754
    labels:
       - "traefik.enable=true"
       - "traefik.http.routers.evolution_api.rule=Host(\`$evolution_api_domain\`)"
       - "traefik.http.services.evolution_api.loadbalancer.server.port=8080"
       - "traefik.http.routers.evolution_api.service=evolution_api"
       - "traefik.http.routers.evolution_api.entrypoints=websecure"
       - "traefik.http.routers.evolution_api.tls.certresolver=leresolver"

    networks:
        - portainer_default

networks:
  portainer_default:
    external: true

volumes:
  evolution_instances:
  evolution_store:
  evolution_manager:
  evolution_views:
EOL

    sudo docker compose -f docker-compose-evolution.yml up -d

    echo -e "\e[32m\e[0m"
    echo -e "\e[32mEvolution API instalado com sucesso!\e[0m"
    echo -e "\e[32mServer URL: https://$evolution_api_domain\e[0m"
    echo -e "\e[32mAUTHENTICATION_API_KEY: $authentication_api_key\e[0m"
    echo -e "\e[32m\e[0m"
  else
    echo "Instalação do Evolution API foi pularida."
  fi

#########################################################
#
# USUARIO PREENCHEU DADOS ERRADOS
#
#########################################################

elif [ "$confirma1" == "n" ]; then
    echo "Encerrando a instalação, por favor, inicie a instalação novamente."
    exit 0
else
    echo "Resposta inválida. Digite 'y' para confirmar ou 'n' para encerrar a instalação."
    exit 1
fi