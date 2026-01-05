# SCHERTECH Server Automated Setup Script

This repository contains an interactive Bash script to provision and configure a **Schertech Shopfloor server** with all required core services (**Nginx**, **PHP-FPM**, **MariaDB**, **PostgreSQL**, **RabbitMQ**, **NodeJS**, **PM2**, **ONLYOFFICE**). The script is designed for **Ubuntu-based systems** and assumes **root access**.

---

## Features

- Interactive prompts for:
  - PHP version (e.g. `8.3`)
  - Node.js major version (e.g. `18`)
- Installs and configures:
  - Nginx from the official Nginx repository
  - PHP-FPM and common PHP extensions for Laravel-style apps
  - MariaDB 11.4 with tuned `bind-address` and `max_connections`
  - PostgreSQL for ONLYOFFICE (user/database `onlyoffice`)
  - RabbitMQ server
  - Node.js (via NodeSource) and PM2
  - ONLYOFFICE Document Server with basic hardening
- Applies basic system settings:
  - Timezone to `Europe/Berlin`
  - NTP for time synchronization
- Idempotent and interactive:
  - Checks for root privileges
  - Uses banner and pause helpers for readable output

---

## Prerequisites

- Ubuntu (Jammy / 22.04 or compatible)
- Root access (run via `sudo` or as root)
- Working internet connection (for APT repositories and GPG keys)

---

## What the Script Installs

### 1. Basic Tools

Installs common utilities:

- `net-tools`
- `btop`
- `htop`
- `wget`
- `git`
- `curl`
- `ca-certificates`
- `apt-transport-https`
- `software-properties-common`
- `lsb-release`
- `gnupg2`
- `ubuntu-keyring`

### 2. Nginx (Official Repository)

- Adds the official Nginx signing key  
- Adds the `nginx.org` APT repository  
- Installs Nginx and enables it as a systemd service

### 3. PHP-FPM + Extensions

- Prompts for PHP version (e.g. `8.3`)
- Adds `ppa:ondrej/php`
- Installs:

  - `php<version>-fpm`
  - `php<version>-curl`
  - `php<version>-mbstring`
  - `php<version>-xml`
  - `php<version>-dom`
  - `php<version>-mysql`
  - `php<version>-zip`
  - `php<version>-gd`

- Tweaks PHP-FPM configuration:

  ```ini
  post_max_size = 50M
  upload_max_filesize = 50M
  pm = static
  pm.max_children = 32
4. MariaDB 11.4
Adds MariaDB 11.4 APT source

Installs mariadb-server

Configures:

text

   ``bind-address = 0.0.0.0``
   ``max_connections = 5000``

Prints a reminder to run mysql_secure_installation manually

5. PostgreSQL for ONLYOFFICE
Installs:

postgresql

postgresql-contrib

Enables and starts PostgreSQL

Creates:

User: onlyoffice with password onlyoffice

Database: onlyoffice owned by onlyoffice

6. RabbitMQ
Installs rabbitmq-server

Restarts the service

7. NodeJS & PM2
Prompts for NodeJS major version (e.g. 18)

Uses NodeSource setup script

Installs:

nodejs

`Global pm2 (via npm install -g pm2)`

8. ONLYOFFICE Document Server
Adds ONLYOFFICE GPG key and repository

Installs:

ttf-mscorefonts-installer

onlyoffice-documentserver

Backs up:

local.json → local.json.bak

default.json → default.json.bak

Adjusts ONLYOFFICE config:

Disables inbox, outbox, browser in local.json

Sets "blockPrivateIPAddress": false in default.json

Usage
1. Clone This Repository
bash
git clone <your_repo_url>
cd <your_repo_folder>
2. Make the Script Executable
bash
chmod +x schertech-server-setup.sh
Replace schertech-server-setup.sh with the actual filename if it differs.

3. Run the Script as Root
bash
sudo ./schertech-server-setup.sh
4. Follow Interactive Prompts
The script will ask you for:

PHP version you want to install (e.g. 8.3)

NodeJS major version (e.g. 18)

It will then automatically:

Update and install base tools

Install and enable Nginx

Install and configure PHP-FPM

Install MariaDB, PostgreSQL, RabbitMQ, NodeJS, PM2, ONLYOFFICE

At the end, it will remind you to run:

bash
sudo mysql_secure_installation
to harden your MariaDB instance.

Important Notes
The ONLYOFFICE PostgreSQL user and database must use the password onlyoffice as required by this environment.

Timezone is set globally to Europe/Berlin. Adjust that section if your deployment requires a different timezone.

Nginx is installed from the official Nginx repository, not Ubuntu’s default repo, to ensure more up-to-date packages.

This script does not deploy your application code (Laravel/Angular); it prepares the system services needed for Shopfloor-Suite and Schertech modules.

Customization
You can safely customize:

Timezone:

bash
timedatectl set-timezone <Your/Timezone>
PHP-FPM pool tuning (under):

text
```/etc/php/<version>/fpm/pool.d/www.conf```
(e.g. pm, pm.max_children)

MariaDB settings:

text
```/etc/mysql/mariadb.conf.d/50-server.cnf```
ONLYOFFICE behavior via:

text
```/etc/onlyoffice/documentserver/local.json```
```/etc/onlyoffice/documentserver/default.json```
After configuration changes, restart the relevant services:

bash
`systemctl restart nginx`
`systemctl restart php<version>-fpm`
`systemctl restart mariadb`
`systemctl restart postgresql`
`systemctl restart rabbitmq-server`
