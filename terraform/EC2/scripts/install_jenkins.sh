#!/bin/bash
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Este script debe ejecutarse como root o con sudo."
        exit 1
    fi
}

install_packages() {
    local packages=("docker.io" "docker-compose")

    for package in "${packages[@]}"; do
        if ! dpkg -l "$package" > /dev/null 2>&1; then
            echo "El paquete $package no está instalado. Instalándolo ahora..."
            apt-get update -y
            apt-get install -y "$package"
        else
            echo "El paquete $package ya está instalado."
        fi
    done
}


# Ejecutar la función para instalar los paquetes necesarios
check_root
install_packages

# Iniciar el servicio Docker y agregar el usuario ubuntu al grupo docker
systemctl start docker
usermod -aG docker ubuntu
chmod 666 /var/run/docker.sock
# Crear el archivo docker-compose.yml para Jenkins
cat <<EOF > /home/ubuntu/docker-compose.yml
version: '3'

services:
  jenkins:
    build: .
    container_name: jenkins
    ports:
      - 8080:8080
    volumes:
      - jenkins_tutorial:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock # Importante esta linea, caso contrario no podremos usar docker dentro de docker
    networks:
      - ci-network

  sonarqube:
    image: sonarqube
    container_name: sonarqube
    networks:
      - ci-network
    ports:
      - 9000:9000

volumes:
  jenkins_tutorial:

networks:
  ci-network:
    external: true
EOF

cat <<EOF > /home/ubuntu/Dockerfile
# Usamos la imagen lts de Jenkins como base
FROM jenkins/jenkins:lts

# Instalamos Git
USER root
RUN apt-get update && \
    apt-get install -y git && \
    rm -rf /var/lib/apt/lists/*

# Usamos la imagen docker:dind y copias el binario a /usr/local/bin
COPY --from=docker:dind /usr/local/bin/docker /usr/local/bin


# Añadimos el usuario jenkins al grupo docker
RUN usermod -aG root jenkins

# Cambiamos el directorio de inicio
WORKDIR /var/jenkins_home
RUN jenkins-plugin-cli --plugins \
    kubernetes \
    git \
    github \
    prometheus \
    docker-plugin

# Cambiamos el usuario para jenkins
USER jenkins
EOF

# Cambiar permisos y ejecutar Docker Compose
chown ubuntu:ubuntu /home/ubuntu/docker-compose.yml
docker network create ci-network
cd /home/ubuntu
docker-compose up -d
sleep 30
echo "--------------------Jenkins Password--------------------"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

