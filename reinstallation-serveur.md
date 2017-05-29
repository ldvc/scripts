# Procédure d'installation d'un serveur dédié

## Pré-requis
### Réinstallation via manager OVH
On commence par lancer la réinstallation depuis le manager OVH. On choisira le partitionnement classique :

- une partition `/` de `20Go`
- une partition `/home` avec le reste de l'espace disponible.

### Mise en place LVM
Une fois le serveur prêt, on va se baser sur ce [tutoriel](https://mondedie.fr/viewtopic.php?id=7147) pour utiliser [LVM](https://debian-administration.org/article/410/A_simple_introduction_to_working_with_LVM).

### Installation paquets
Quelques paquets pratiques : `apt install sudo htop git dnsutils molly-guard tmux zsh fail2ban`

### Oh-my-ZSH
On utilise le script d'auto-install (pas joli de faire du `curl | bash`) mais ça marche bien !

#### Alias
On ajoute quelques alias :

```bash
echo "alias bigf='du -hsx * | sort -rh | head -10'" >> ~/.zshrc
echo "alias ltmux='if tmux has; then tmux attach; else tmux new; fi'" >> ~/.zshrc
alias nocom="egrep -v '^[[:space:]]*(#|$)'"
```
#### Changement du prompt
```bash
cd ~/.oh-my-zsh/themes
#cp robbyrussell.zsh-theme $USER.zsh-theme
==> utilisation du thème **pure**
```

#### Customisation de fail2ban
`sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local`
`sudo vim /etc/fail2ban/jail.local`

Avec comme configuration par défaut :
```
[DEFAULT]
ignoreip = 127.0.0.1
bantime  = 3600 
findtime = 600
maxretry = 3
```

#### Installation pip (en tant que root)
```bash
apt install python-dev build-essential libyaml-dev \
libpython2.7-dev libffi-dev python-pip python-dev virtualenv gcc
pip install --upgrade pip
```

## Installation mailcow
Ici on devrait retrouver les mêmes étapes que définies dans la [doc en ligne de Mailcow](https://github.com/andryyy/mailcow/blob/master/README.md). On réécrit au cas où la doc viendrait à changer.

1. On supprime tous les paquets en rapport avec Exim : `apt-get purge exim4*`
2. On met à jour les dépôts et les paquets installés : `apt update && apt upgrade`
3. Problème de locales : [doc](https://gist.github.com/5car1z/7254095c24299bef28e8)
4. Création de mon utilisateur : `adduser $MYUSER` et `adduser $MYUSER sudo`
5. On se connecte (`$MYUSER`) et on génère nos clés SSH : `ssh-keygen -o -a 100 -t ed25519`
6. On revient en **root** et `mkdir ~/build ; cd ~/build`
7. On récupère le script d'installation et on personnalise le fichier mailcow.config :
`wget -O - https://github.com/andryyy/mailcow/archive/v0.14.tar.gz | tar xfz - && cd mailcow-*`
`cd build && vim mailcow.config`
8. On peut installer : `./install.sh`

```
[...]
    -----------------------------------------------
    mailcow version:      0.14_roundcube

Finished installation
Logged credentials and further information to file installer.log.

Next steps:
 * Backup installer.log to a safe place and delete it from your server
[...]
```
### Vérifications (à compléter)
L'installeur de Mailcow devrait avoir installé Nginx. Il ne reste plus qu'à se connecter à l'espace d'administration et de préparer le reste du serveur.

1. En cas de soucis, on force le vidage du cache local (MacOS) : `sudo killall -HUP mDNSResponder`

### Envoi vers gmail.com
A cette date (oct. 2016) il n'est pas possible de configurer une entrée PTR pour une IPv6 pour un serveur kimsufi... Il est donc impossible d'envoyer un mail via IPv6 à Gmail. Créons une règle spécifique pour envoyer en v4 :

```bash
echo "gmail.com smtp-ipv4:" > /etc/postfix/transport && postmap /etc/postfix/transport
echo -e "## fix for gmail\ntransport_maps = hash:/etc/postfix/transport" >> /etc/postfix/main.cf
echo -e "# fix for sending mail in ipv4 only to gmail\nsmtp-ipv4    unix  -       -       -       -       -       smtp\n  -o inet_protocols=ipv4" >> /etc/postfix/master.cf
````

## Mise en place du firewall
Dans un soucis de simplicité, on va utiliser **ufw** qui est une couche d'abstraction à iptables.

1. `apt install ufw`

2. Configuration des services à autoriser.

```
apt install ufw
ufw status
[[ `grep -ci "ipv6=YES" /etc/default/ufw` -eq '1' ]] \ 
&& echo "IPv6 OK" || echo "Gestion d'IPv6 non activée"
ufw default deny incoming
ufw default deny outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 1194/udp # OpenVPN
ufw allow 5000:5010/tcp # Flask dev webserver
ufw allow 25/tcp
ufw allow 143	
ufw allow 993
ufw allow 465/tcp
ufw allow out 465/tcp
ufw allow out 25/tcp
ufw allow out 80/tcp
ufw allow out 443/tcp
ufw allow out 22/tcp
ufw allow out 53/udp
ufw allow out 20/tcp
ufw allow out 21/tcp
ufw allow out 43/tcp # whois
# Backup tasks to NAS
ufw allow out 4222/tcp
# RealTimeMonitoring (OVH)
ufw allow out from any to `dig rtm-collector.ovh.net A +short` port 6100:6200/udp
ufw allow out proto udp from any to `dig rtm-collector.ovh.net A +short` port 6100:6200
ufw enable
ufw status
```

3. Autoriser l'ICMP en sortie

Par défaut, l'ICMP en sortie est bloqué. On peut l'autoriser en ajoutant dans le fichier `/etc/ufw/before.rules` :
```
# allow outgoint ICMP - ludo - http://www.kelvinism.com/2010/09/enable-icmp-through-ufw_461.html
-A ufw-before-output -p icmp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
-A ufw-before-output -p icmp -m state --state ESTABLISHED,RELATED -j ACCEPT
```
Puis on recharge la configuration avec `ufw reload`

## Nextcloud
Dans le cas d'une installation, suivre la [doc en ligne (v10)](https://docs.nextcloud.com/server/10/admin_manual/installation/index.html). Dans le cas d'une migration, voici les étapes :

##### Paquets nécessaires
`apt install php5-apcu redis-server php5-redis`

#### Restauration du dossier data (à préciser)
Si le dossier `data` n'est pas au même endroit que la partie web :
`tar xvfz nextcloud-data.tgz`

#### Préparation de la base de données :

On se connecte :
`mysql -h localhost -u root -p` et on prépare la base pour charger la sauvegarde :

```sql
CREATE DATABASE nextcloud;
GRANT ALL PRIVILEGES ON nextcloud.* To 'nextclouduser'@'localhost' IDENTIFIED BY 'pa$$word';
```
On injecte la sauvegarde :
`mysql -h localhost -u root -p nextcloud < nextcloud-sqlbkp_20161022.bak`

#### Nginx pour Nextcloud
L'installeur de mailcow a déjà fait quelques modifications. On va créer un :
`openssl dhparam -out dh-4096.pem 4096`


## Mise en place lecm (Let's Encrypt)

Paquets nécessaires :
`apt install build-essential libssl-dev libffi-dev python-dev libyaml-dev libpython2.7-dev`

Ensuite on peut installer le client lecm : `pip install lecm`.
On crée le fichier de configuration :

```yaml
---
path: /etc/letsencrypt
service_name: nginx

certificates:
  ${SERVER}.${DOMAIN}:
```

## Installation + configuration mosquitto (MQTT)
On suit la doc sur [digitalocean.com](https://www.digitalocean.com/community/tutorials/how-to-install-and-secure-the-mosquitto-mqtt-messaging-broker-on-debian-8). Voici les étapes synthétisées :

```
wget http://repo.mosquitto.org/debian/mosquitto-repo.gpg.key
apt-key add mosquitto-repo.gpg.key
echo "deb http://repo.mosquitto.org/debian jessie main" > /etc/apt/sources.list.d/mosquitto.list
apt update && apt install mosquitto mosquitto-clients
```

Création d'un utilisateur :

```
mosquitto_passwd -c /etc/mosquitto/passwd $USER
```

La configuration du serveur :

```
root@atlas:~# cat /etc/mosquitto/conf.d/default.conf
allow_anonymous false
password_file /etc/mosquitto/passwd
 
listener 1883 localhost
 
listener 8883
#certfile /etc/letsencrypt/live/mqtt.example.com/cert.pem
#cafile /etc/letsencrypt/live/mqtt.example.com/chain.pem
#keyfile /etc/letsencrypt/live/mqtt.example.com/privkey.pem
 
certfile /etc/letsencrypt/pem/nuage.terrier.im.pem
cafile /etc/letsencrypt/pem/lets-encrypt-x3-cross-signed.pem
keyfile /etc/letsencrypt/private/nuage.terrier.im.key
```

On redémarre le service et on autorise le flux :

```
systemctl restart mosquitto
ufw allow 8883
```
