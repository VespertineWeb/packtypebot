echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m  _____        _____ _  __  _________     _______  ______ ____   ____ _______ \e[0m"
echo -e "\e[32m |  __ \ /\   / ____| |/ / |__   __\ \   / /  __ \|  ____|  _ \ / __ \__   __|\e[0m"
echo -e "\e[32m | |__) /  \ | |    | ' /     | |   \ \_/ /| |__) | |__  | |_) | |  | | | |   \e[0m"
echo -e "\e[32m |  ___/ /\ \| |    |  <      | |    \   / |  ___/|  __| |  _ <| |  | | | |   \e[0m"
echo -e "\e[32m | |  / ____ \ |____| . \     | |     | |  | |    | |____| |_) | |__| | | |   \e[0m"
echo -e "\e[32m |_| /_/    \_\_____|_|\_\    |_|     |_|  |_|    |______|____/ \____/  |_|   \e[0m"
echo -e "\e[32m\e[0m"
echo -e "\e[32m\e[0m"

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

  echo -e "\e[32mINICIANDO A INSTALAÇÃO DO TYPEBOT \e[0m"
  echo ""

  read -p "Deseja instalar o Typebot? (y/n): " instala_typebot
  if [ "$instala_typebot" == "y" ]; then
    # prompting additional details for Typebot
    echo -e "\e[32mConfiguração do Typebot: \e[0m"
    echo ""
    echo -e "\e[32mPasso \e[33m1/5\e[0m"
    read -p "Digite o Dominio para o Builder do Typebot (ex: app.seudominio.com): " typebot_builder_domain
    echo ""
    echo -e "\e[32mPasso \e[33m2/5\e[0m"
    read -p "Digite o Dominio para o Viewer do Typebot (ex: typebot.seudominio.com): " typebot_viewer_domain
    echo ""
    echo -e "\e[32mPasso \e[33m3/5\e[0m"
    read -p "Digite o Dominio para o Storage do Typebot (ex: storage.seudominio.com): " typebot_storage_domain
    echo ""
    echo -e "\e[32mPasso \e[33m4/5\e[0m"
    read -p "Digite o SMTP Host (ex: smtp.gmail.com): " smtp_host
    echo ""
    echo -e "\e[32mPasso \e[33m5/5\e[0m"
    read -p "Digite a porta SMTP do Email (ex: 587): " smtp_port
    echo ""
    echo -e "\e[32mPasso \e[33m6/5\e[0m"
    read -p "Digite o Email para SMTP (ex: seuemail@gmail.com): " smtp_email
    echo ""
    echo -e "\e[32mPasso \e[33m7/5\e[0m"
    read -p "Digite a Senha SMTP do Email (ex: minhasenha123@ ): " smtp_password
    echo ""

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
      - "traefik.http.services.typebot-builder.loadbalancer.server.port=3000"
      - "traefik.http.services.typebot-builder.loadbalancer.passHostHeader=true"
      - "traefik.http.routers.typebot-builder.service=typebot_builder"
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
      - "traefik.http.services.typebot-viewer.loadbalancer.server.port=3000"
      - "traefik.http.services.typebot-viewer.loadbalancer.passHostHeader=true"
      - "traefik.http.routers.typebot-viewer.service=typebot_viewer"
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
      - "traefik.http.services.minio.loadbalancer.passHostHeader=true"
      - "traefik.http.routers.minio.service=minio"
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
    echo -e "\e[32m\e[0m"
    echo -e "\e[32mAcesse seu Typebot através do link: https://$typebot_builder_domain\e[0m"
  else
    echo "Instalação do Typebot foi pularida."
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
