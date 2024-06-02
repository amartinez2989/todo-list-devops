#!/bin/bash
USER="ubuntu"

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
usermod -aG docker ${USER}
chmod 777 /var/run/docker.sock

# Crear el archivo docker-compose.yml para Jenkins
cat <<EOF > /home/${USER}/docker-compose.yml
version: '3'

services:
  jenkins:
    image : amartinez8929/jenkins:v1
    container_name: jenkins
    environment:
      - TZ=America/Argentina/Buenos_Aires    
    ports:
      - 8787:8080
    volumes:
      - jenkins_tutorial:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock # Importante esta linea, caso contrario no podremos usar docker dentro de docker
    networks:
      - ci-network

  sonarqube:
    image: sonarqube:10.5.1-community
    container_name: sonarqube 
    environment:
      - sonar.jdbc.username=sonar
      - sonar.jdbc.password=sonar
      - TZ=America/Argentina/Buenos_Aires
    volumes:
      - sonarqube_conf:/opt/sonarqube/conf
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_bundled-plugins:/opt/sonarqube/lib/bundled-plugins
    networks:
      - ci-network
    ports:
      - 9000:9000
networks:
  ci-network:
    external: true
volumes:
  jenkins_tutorial:
  sonarqube_bundled-plugins:
  sonarqube_extensions:
  sonarqube_data:
  sonarqube_conf:
EOF

# Cambiar permisos y ejecutar Docker Compose
echo "--------------------Cambiar permisos y ejecutar Docker Compose--------------------"
chown ${USER}:${USER} /home/${USER}/docker-compose.yml
chown ${USER}:${USER} /home/${USER}/Dockerfile
docker network create ci-network

# establecer los valores recomendados para la sesión actual
echo "--------------------establecer los valores recomendados para la sesión actual--------------------"
sysctl -w vm.max_map_count=524288
sysctl -w fs.file-max=131072
ulimit -n 131072
ulimit -u 8192
cd /home/${USER}/
docker-compose up -d

docker-compose ps -a
echo "--------------------Descarga imagen de Sonar Scanner-------------------"

docker pull sonarsource/sonar-scanner-cli
# Esperar hasta que Jenkins genere la clave inicial
echo "Esperando a que Jenkins genere la clave inicial..."
until docker exec jenkins test -f /var/jenkins_home/secrets/initialAdminPassword; do
    sleep 5
done

# Mostrar la clave inicial de Jenkins
echo "--------------------Jenkins Password--------------------"
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
