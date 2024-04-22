#!/bin/bash
set -e

set -o errexit
set -o nounset
IFS=$(printf '\n\t')

username="dued"



# instala comandos basicos
which aptitude || apt-get -qqy install aptitude
aptitude -y update
# aptitude -y install make git gcc libncurses5-dev


# Verificar si el usuario existe
if id "$username" &>/dev/null; then
    # El usuario existe, mostrar su directorio de inicio
    echo "El usuario $username ya existe."
else
    # El usuario no existe, crearlo
    echo "El usuario $username no existe, creándolo..."
    adduser --disabled-password --gecos "" "$username"
    echo "Usuario $username creado con éxito."
fi
user_home=$(getent passwd "$username" | cut -d: -f6)
echo "El directorio de inicio de $username es: $user_home"

# Verificar si el usuario ya es sudoer
if sudo grep -q "^$username" /etc/sudoers; then
    echo "El usuario $username ya es sudoer."
else
    # Agregar al usuario como sudoer
    echo "Agregando al usuario $username como sudoer..."
    echo "$username ALL=(ALL:ALL) ALL" | sudo EDITOR='tee -a' visudo
    echo "Usuario $username agregado como sudoer."
fi

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    # Docker no está instalado, lo instala
    echo "Docker no está instalado, instalando..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    printf '\nDocker instalado con éxito\n\n'
else
    # Docker está instalado, imprimir mensaje
    echo "Docker ya está instalado en el sistema."
fi

# Verificar si Docker-compose está instalado esta vez con which (alternativo a command -v)
if ! which docker-compose &> /dev/null; then
    # Si no esta instalado Docker-compose lo instala
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    curl -L https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    curl -L https://raw.githubusercontent.com/docker/compose/${COMPOSE_VERSION}/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose
    printf '\nDocker Compose instalado con éxito\n\n'
    docker-compose -v
else
    # Docker está instalado, imprimir mensaje
    echo "Docker Compose ya está instalado en el sistema."
fi

# Verificar si el usuario ya es miembro del grupo docker
if groups "$username" | grep -q '\bdocker\b'; then
    echo "El usuario $username ya es miembro del grupo docker."
else
    # Agregar al usuario como miembro del grupo docker
    echo "Agregando al usuario $username como miembro del grupo docker..."
    usermod -aG docker "$username"
    echo "Usuario $username agregado como miembro del grupo docker."
fi

# crear una clave ssh
sudo -u $username ssh-keygen -t rsa -b 4096 -N '' -f $user_home/.ssh/id_rsa

# Instalar Dotfiles para configurar VPS en producción con el ususario dued
# cd $user_home && git clone https://github.com/dued/dotfiles.git
# cd $user_home/.dotfiles && /bin/bash -c "source bootstrap.sh"

# Instalar Autodued en el home del usuario
cd $user_home && git clone https://github.com/dued/autodued.git


cp -r . /home/dued/autodued
chown -R dued.dued /home/dued/autodued
cp ./bin/autodued.service /etc/systemd/system


# Instalar Monitor en /usr/bin 
./monitor.sh -i

