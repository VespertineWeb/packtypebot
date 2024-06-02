#########################################################
  #
  # OPÇÃO DE INSTALAÇÃO DO TYPEBOT
  #
  #########################################################

  read -p "Deseja instalar o Typebot? (y/n): " instala_typebot
  if [ "$instala_typebot" == "y" ]; then
    # prompting additional details for Typebot
    echo -e "\e[32mConfiguração do Typebot: \e[0m"
    echo ""
    echo -e "\e[32mPasso \e[33m1/7\e[0m"
    read -p "Dominio do Builder (ex: app.seudominio.com): " typebot_builder_domain
    echo ""
    echo -e "\e[32mPasso \e[33m2/7\e[0m"
    read -p "Dominio do Viewer (ex: typebot.seudominio.com): " typebot_viewer_domain
    echo ""
    echo -e "\e[32mPasso \e[33m3/7\e[0m"
    read -p "Dominio do Storage (ex: storage.seudominio.com): " typebot_storage_domain
    echo ""
    echo -e "\e[32mPasso \e[33m4/7\e[0m"
    read -p "SMTP Host (ex: smtp.gmail.com): " smtp_host
    echo ""
    echo -e "\e[32mPasso \e[33m5/7\e[0m"
    read -p "SMTP Porta (ex: 25, 587, 465, 2525): " smtp_port
    echo ""
    echo -e "\e[32mPasso \e[33m6/7\e[0m"
    read -p "SMTP E-mail (ex: seuemail@gmail.com): " smtp_email
    echo ""
    echo -e "\e[32mPasso \e[33m7/7\e[0m"
    read -p "SMTP Senha: " smtp_password
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
      - "traefik.http.routers.typebot-builder.entrypoints=websecure"
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

  typebot-viewer:
    image: baptistearno/typebot-viewer:latest
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.typebot-viewer.rule=Host(\`$typebot_viewer_domain\`)"
      - "traefik.http.routers.typebot-viewer.entrypoints=websecure"
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

  mail:
    image: bytemark/smtp
    restart: always

  minio:
    image: minio/minio
    restart: always
    command: server /data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.minio.rule=Host(\`$typebot_storage_domain\`)"
      - "traefik.http.routers.minio.entrypoints=websecure"
      - "traefik.http.routers.minio.tls.certresolver=leresolver"
    environment:
      MINIO_ROOT_USER: minio
      MINIO_ROOT_PASSWORD: minio123
    volumes:
      - typebot_s3_data:/data

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

volumes:
  typebot_db_data:
  typebot_s3_data:
EOL

    # Submitting the stack to Portainer
    read -p "Informe o usuário admin do Portainer: " portainer_user
    read -sp "Informe a senha admin do Portainer: " portainer_pass
    echo ""

    PORTAINER_URL="http://localhost:9000/api"

    STACK_NAME="Typebot"
    ENDPOINT_ID=1

    STACK_FILE_CONTENT=$(cat docker-compose-typebot.yml | sed ':a;N;$!ba;s/\n/\\n/g')

    AUTH_TOKEN=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"username\":\"$portainer_user\",\"password\":\"$portainer_pass\"}" $PORTAINER_URL/auth | jq -r .jwt)

    if [ "$AUTH_TOKEN" == "null" ]; then
      echo "Autenticação falhou. Verifique o usuário e a senha do Portainer."
      exit 1
    fi

    curl -s -X POST -H "Authorization: Bearer $AUTH_TOKEN" -H "Content-Type: application/json" \
    -d "{\"Name\":\"$STACK_NAME\",\"StackFileContent\":\"$STACK_FILE_CONTENT\",\"SwarmID\":\"\",\"EndpointID\":$ENDPOINT_ID, \"Env\":[]}" \
    $PORTAINER_URL/stacks

    sudo docker compose -f docker-compose-typebot.yml up -d

    echo -e "\e[32m\e[0m"
    echo -e "\e[32mTypebot instalado com sucesso!\e[0m"
    echo -e "\e[32m\e[0m"
    echo -e "\e[32mAcesse seu Typebot através do link: https://$typebot_builder_domain\e[0m"
  else
    echo "Instalação do Typebot foi pulada."
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
