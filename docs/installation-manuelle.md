# Installation manuelle

Ce qui se fait à la main, avant ou à côté d'Ansible. Tout le reste (SSH, pare-feu, utilisateurs, monitoring, logs) est automatisé par les rôles : voir [ansible.md](ansible.md). Les notes d'origine, plus détaillées, sont dans [archive/manual_config.txt](archive/manual_config.txt).

## Préparer une Raspberry Pi

1. Flasher **Raspberry Pi OS Lite (64-bit)** avec Raspberry Pi Imager.
2. Dans les options de l'Imager : nom d'hôte, utilisateur, SSH activé, Wi-Fi si besoin.
   - Le Wi-Fi 5 GHz n'a jamais fonctionné chez moi (cause inconnue) : utiliser le 2,4 GHz ou, mieux, l'Ethernet.
3. Démarrer la Pi, puis la retrouver sur le réseau :
   ```bash
   sudo nmap -p 22 192.168.1.0/24
   ```
4. Sur la Freebox, lui attribuer un bail DHCP fixe (voir le plan d'adressage dans [materiel.md](materiel.md)), puis redémarrer la Pi.
5. Mettre à jour une première fois :
   ```bash
   sudo apt update && sudo apt full-upgrade -y
   ```
6. Ajouter la machine à `inventory/hosts.yml` et lancer le premier déploiement ([ansible.md](ansible.md#premier-déploiement-sur-une-machine-vierge)).

## Démarrer sur un SSD NVMe

1. Brancher le NVMe.
2. Démarrer sur une clé USB ou une carte SD contenant Raspberry Pi OS (version bureau, plus simple).
3. Vérifier que le disque est vu : `lsblk`.
4. Lancer Raspberry Pi Imager depuis ce système et flasher l'OS sur le NVMe.
5. Éteindre, retirer la clé ou la carte, redémarrer.

## Partition `/home` séparée

**Ne pas réduire la partition racine à chaud** : on ne peut pas rétrécir un ext4 monté, et la Pi ne redémarre plus. Si une partition `/home` ou de données est souhaitée, la créer **au moment du flash**, ou redimensionner depuis un autre système avec le disque démonté.

Disposition envisagée pour le NVMe de 1 To :

| Point de montage | Taille | Usage |
|------------------|--------|-------|
| `/` | 20 Go | Système |
| `/srv` | ~200 Go | Services (Prometheus, Grafana, Minecraft) |
| `/data` | le reste | Fichiers |

Monter par `PARTUUID` dans `/etc/fstab` avec `defaults,noatime`.

## Quotas disque (non terminé)

L'idée était de limiter l'espace par utilisateur. Les quotas se posent proprement sur une partition dédiée (`/home`), pas sur la racine. Démarche : paquet `quota`, options `usrquota,grpquota` dans `/etc/fstab`, puis `quotacheck -vagum` et `quotaon -avug`. Jamais mené au bout ; les limites de RAM et de processus sont, elles, gérées par le rôle `hardening`.

## Double authentification SSH (non appliqué)

Possible avec `libpam-google-authenticator` (TOTP). Peu d'intérêt une fois SSH retiré d'Internet et placé derrière le VPN, voir [architecture.md](architecture.md#ssh-ou-vpn-).

## Vérifier le durcissement SSH

```bash
ssh-audit -p 2002 192.168.1.46
```

À lancer dans un terminal Linux pour avoir les couleurs du rapport. Les algorithmes déployés par le rôle `ssh` suivent ses recommandations.

## Serveur Minecraft

Non automatisé.

```bash
sudo mkdir /opt/minecraft-server && cd /opt/minecraft-server
sudo wget <URL du server.jar de la version voulue>
sudo java -Xms2G -Xmx4G -jar server.jar nogui   # premier lancement : génère eula.txt
sudo nano eula.txt                               # eula=true
sudo nano server.properties                      # view-distance=4, max-players=5
sudo screen java -Xms2G -Xmx4G -jar server.jar nogui
```

Détacher le `screen` avec `Ctrl+A` puis `D` ; y revenir avec `screen -r`. Le port 25565 est ouvert par `firewall_public_tcp_ports`.

Pistes d'amélioration : une unité systemd plutôt que `screen`, un utilisateur dédié plutôt que `root`, et le placer en DMZ dans l'architecture cible.

## Interfaces web

| Service | Adresse | Identifiants |
|---------|---------|--------------|
| Grafana | `http://<serveur>:3000` | `admin` + mot de passe du vault |
| Prometheus | `http://<serveur>:9090` | aucun |
| Alertmanager | `http://<serveur>:9093` | aucun |

Accessibles uniquement depuis les réseaux listés dans `firewall_trusted_sources`.
