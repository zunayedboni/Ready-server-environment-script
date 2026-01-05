#!/bin/bash

#############################################################
#        SCHERTECH SERVER AUTOMATED SETUP SCRIPT            #
#        Author : Zunayed Islam Rabbi                       # 
#        Position : System Engineer                         #
#############################################################

# NOTE : onlyoffice's password must be "onlyoffice"

echo -e "${CYAN}"
cat << "EOF"
   _____  _____  _    _  ______  _____  _______  ______  _____  _    _ 
  / ____|/ ____|| |  | ||  ____||  __ \|__   __||  ____|/ ____|| |  | |
 | (___ | |     | |__| || |__   | |__) |  | |   | |__  | |     | |__| |
  \___ \| |     |  __  ||  __|  |  _  /   | |   |  __| | |     |  __  |
  ____) | |____ | |  | || |____ | | \ \   | |   | |____| |____ | |  | |
 |_____/ \_____||_|  |_||______||_|  \_\  |_|   |______|\_____||_|  |_|
                                                                       
EOF
echo -e "${BLUE}        :: SCHERTECH DEPLOYMENT SCRIPT ::        ${NC}"
echo ""

# Your script logic starts here...
echo "Starting build process..."

# Colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
CYAN='\e[36m'
NC='\e[0m'

pause() {
    echo -e "${CYAN}Sleeping for 3 seconds...${NC}"
    sleep 3
}

banner() {
    echo -e "${GREEN}=====================================================${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${GREEN}=====================================================${NC}"
}

clear
banner "🔥 SCHERTECH INTERACTIVE SERVER SETUP SCRIPT 🔥"

echo -e "${CYAN}Checking for root privileges...${NC}"
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Please run as root!${NC}"
    exit 1
fi
pause

##############################
# ASK PHP VERSION
##############################
echo -e "${BLUE}Enter PHP version you want to install (example: 8.3):${NC}"
read -p "> " PHP_VERSION

##############################
# ASK NODE.JS VERSION
##############################
echo -e "${BLUE}Enter NodeJS major version you want to install (example: 18):${NC}"
read -p "> " NODE_VERSION
pause

###############################################
# UPDATE & BASIC TOOLS
###############################################
banner "📦 Updating & Installing Basic Tools"
apt-get update && apt-get upgrade -y
apt install -y net-tools btop htop wget git curl ca-certificates apt-transport-https software-properties-common lsb-release gnupg2 ubuntu-keyring
pause

###############################################
# INSTALL NGINX (OFFICIAL REPO)
###############################################
banner "🌐 Installing Nginx from Official Sources"

# 1. Download signing key
curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

# 2. Add repository
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" \
    | tee /etc/apt/sources.list.d/nginx.list

# 3. Install
apt update
apt install -y nginx

# 4. Start & Enable
systemctl enable nginx
systemctl start nginx
pause

###############################################
# TIMEZONE
###############################################
banner "🌍 Setting Timezone to Europe/Berlin"
timedatectl set-timezone Europe/Berlin
pause

###############################################
# INSTALL NTP
###############################################
banner "⏱ Installing & Configuring NTP"
apt install -y ntp
pause

###############################################
# INSTALL PHP
###############################################
banner "🐘 Installing PHP $PHP_VERSION"
add-apt-repository ppa:ondrej/php -y
apt-get update
apt install -y php$PHP_VERSION-fpm php$PHP_VERSION-curl php$PHP_VERSION-mbstring php$PHP_VERSION-xml php$PHP_VERSION-dom php$PHP_VERSION-mysql php$PHP_VERSION-zip php$PHP_VERSION-gd

# Change PHP settings
sed -i "s/post_max_size = .*/post_max_size = 50M/g" /etc/php/$PHP_VERSION/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 50M/g" /etc/php/$PHP_VERSION/fpm/php.ini

# FPM Pool tweaks
sed -i "s/^pm = .*/pm = static/" /etc/php/$PHP_VERSION/fpm/pool.d/www.conf
sed -i "s/^pm.max_children = .*/pm.max_children = 32/" /etc/php/$PHP_VERSION/fpm/pool.d/www.conf

systemctl restart php$PHP_VERSION-fpm.service
pause

###############################################
# INSTALL MARIADB
###############################################
banner "🛢 Installing MariaDB 11.4"
mkdir -p /etc/apt/keyrings
curl -o /etc/apt/keyrings/mariadb-keyring.pgp "https://mariadb.org/mariadb_release_signing_key.pgp"

cat <<EOF > /etc/apt/sources.list.d/mariadb.sources
# MariaDB 11.4 repository list
X-Repolib-Name: MariaDB
Types: deb
URIs: https://mirror.djvg.sg/mariadb/repo/11.4/ubuntu
Suites: jammy
Components: main main/debug
Signed-By: /etc/apt/keyrings/mariadb-keyring.pgp
EOF

apt-get update
apt-get install -y mariadb-server

# Configure MariaDB
echo -e "${CYAN}Run MariaDB secure installation after script completes.${NC}"

sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
sed -i "s/^#max_connections.*/max_connections = 5000/" /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb
pause

###############################################
# INSTALL POSTGRES
###############################################
banner "🐘 Installing PostgreSQL for ONLYOFFICE"
apt install -y postgresql postgresql-contrib
systemctl start postgresql.service
systemctl status postgresql --no-pager
sleep 3
systemctl enable --now postgresql

sudo -u postgres psql -c "CREATE USER onlyoffice WITH PASSWORD 'onlyoffice';"
sudo -u postgres psql -c "CREATE DATABASE onlyoffice OWNER onlyoffice;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE onlyoffice TO onlyoffice;"
pause

###############################################
# INSTALL RABBITMQ
###############################################
banner "🐇 Installing RabbitMQ"
apt install -y rabbitmq-server
systemctl restart rabbitmq-server.service
pause

###############################################
# INSTALL NODEJS & PM2
###############################################
banner "🟩 Installing NodeJS $NODE_VERSION & PM2"
curl -fsSL https://deb.nodesource.com/setup_$NODE_VERSION.x -o nodesource_setup.sh
bash nodesource_setup.sh
apt-get install -y nodejs
npm install -g pm2
pause

###############################################
# INSTALL ONLYOFFICE DOCS
###############################################
banner "📄 Installing ONLYOFFICE Document Server"
mkdir -p -m 700 ~/.gnupg
curl -fsSL https://download.onlyoffice.com/GPG-KEY-ONLYOFFICE | gpg --no-default-keyring --keyring gnupg-ring:/tmp/onlyoffice.gpg --import
chmod 644 /tmp/onlyoffice.gpg
mv /tmp/onlyoffice.gpg /usr/share/keyrings/onlyoffice.gpg

echo "deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main" | tee /etc/apt/sources.list.d/onlyoffice.list

apt-get update
apt-get install -y ttf-mscorefonts-installer
apt-get install -y onlyoffice-documentserver

# Adjust config
cd /etc/onlyoffice/documentserver
cp local.json local.json.bak
cp default.json default.json.bak

sed -i 's/"inbox": true/"inbox": false/' local.json
sed -i 's/"outbox": true/"outbox": false/' local.json
sed -i 's/"browser": true/"browser": false/' local.json

sed -i 's/"blockPrivateIPAddress": true/"blockPrivateIPAddress": false/' default.json

pause

banner "🎉 INSTALLATION COMPLETE — SCHERTECH SERVER READY! 🎉"
echo -e "${GREEN}You may now continue with your custom configurations.${NC}"
echo -e "${GREEN}Please run this command: " sudo mysql_secure_installation ".${NC}"
