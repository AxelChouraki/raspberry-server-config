# Utiliser Ansible

## Poste de contrôle : travailler directement dans WSL

Ansible ne tourne pas nativement sous Windows, il faut passer par WSL. Plutôt que de garder le dépôt côté Windows et de le recopier dans `/etc/ansible` à chaque fois, **cloner le dépôt dans le système de fichiers de WSL** et travailler dedans :

```bash
git clone https://github.com/AxelChouraki/raspberry-server-config.git ~/raspberry-server-config
```

Pourquoi c'est mieux :

- Plus de copie `rsync` vers `/etc/ansible`, donc plus de risque de déployer une version périmée. Le dépôt contient son propre `ansible.cfg`, son inventaire et ses rôles : tout se lance depuis sa racine.
- Ansible **ignore** un `ansible.cfg` situé dans un dossier accessible en écriture à tous, ce qui est le cas de tout ce qui se trouve sous `/mnt/c`. Lancé depuis le disque Windows, le dépôt perdrait silencieusement sa configuration.
- Les permissions Unix (clés SSH, fichier de mot de passe du vault) sont respectées, et les accès disque sont bien plus rapides que via `/mnt/c`.
- Le dépôt sort de OneDrive, qui synchronise mal un dossier `.git` (fichiers verrouillés, conflits, corruption possible).

Pour éditer : VS Code avec l'extension WSL (`code .` depuis le terminal WSL), ou Claude Code lancé dans WSL. Le dossier reste visible depuis l'explorateur Windows via `\\wsl$\Ubuntu\home\<user>\raspberry-server-config`.

### Installation

```bash
sudo apt update
sudo apt install pipx
pipx install --include-deps ansible
ansible-galaxy collection install -r requirements.yml
```

## Secrets

Les secrets (webhook Discord, mot de passe Grafana, hash des mots de passe) vivent dans `group_vars/all/vault.yml`, chiffré avec `ansible-vault`. Les autres fichiers ne contiennent que des références (`{{ vault_... }}`).

```bash
cp vault.example.yml group_vars/all/vault.yml
nano group_vars/all/vault.yml                    # renseigner les vraies valeurs
ansible-vault encrypt group_vars/all/vault.yml
ansible-vault edit group_vars/all/vault.yml      # pour modifier ensuite
```

`vault.yml` est **ignoré par git** (`.gitignore`), même chiffré : il n'existe que sur le poste de contrôle. En garder une copie ailleurs (gestionnaire de mots de passe, clé USB), sinon il faudra le recréer depuis `vault.example.yml` en cas de perte du poste. Pour éviter de retaper le mot de passe du vault, le stocker dans `.vault_pass` (ignoré aussi, `chmod 600`) et lancer avec `--vault-password-file .vault_pass`.

Générer un hash de mot de passe utilisateur : `mkpasswd --method=sha-512` (paquet `whois`).

> Les hash de mots de passe commités autrefois dans `vars/main.yml` ont été retirés de l'historique git (réécriture en novembre 2026). Les clones faits avant cette date les contiennent encore : les supprimer et recloner.

## Lancer

```bash
ansible all -m ping                                   # test de connexion
ansible-playbook site.yml --ask-vault-pass            # tout, partout
ansible-playbook site.yml --ask-vault-pass --limit rpi2
ansible-playbook site.yml --ask-vault-pass --tags ssh,firewall
ansible-playbook site.yml --ask-vault-pass --check --diff   # simulation
```

Le mot de passe sudo est demandé à chaque lancement (`become_ask_pass` dans `ansible.cfg`).

Tags disponibles : `common`, `users`, `hardening`, `ssh`, `firewall`, `logwatch`, `backup`, `monitoring`, `node_exporter`, `prometheus`, `alertmanager`, `grafana`.

### Premier déploiement sur une machine vierge

Sur une Raspberry Pi tout juste flashée (voir [installation-manuelle.md](installation-manuelle.md)), SSH écoute encore sur le port 22 et accepte les mots de passe :

```bash
ssh sramy@192.168.1.46        # une fois, pour enregistrer l'empreinte de l'hôte
ansible-playbook site.yml --ask-vault-pass --limit rpi2 --tags common,users,hardening,ssh,firewall -e ansible_port=22 --ask-pass
ansible-playbook site.yml --ask-vault-pass --limit rpi2
```

La première commande s'arrête au socle : le rôle `ssh` bascule le port et coupe l'authentification par mot de passe à la fin, donc la suite ne pourrait plus se connecter sur le port 22. La seconde, comme tous les lancements suivants, utilise le port de l'inventaire (2002) et la clé SSH. `--ask-pass` nécessite le paquet `sshpass`.

## Inventaire et groupes

`inventory/hosts.yml` déclare les machines. Les groupes décident des rôles appliqués :

| Groupe | Rôles |
|--------|-------|
| `servers` | `common`, `users`, `hardening`, `ssh`, `firewall`, `logwatch`, `backup` |
| `monitoring` | `node_exporter`, `alertmanager`, `prometheus` |
| `grafana` | `grafana` |

Par défaut les deux Pi sont dans les trois groupes. Pour ne garder Grafana que sur un serveur, ne lister que lui dans le groupe `grafana`.

## Variables

Chaque rôle documente ses variables et leurs valeurs par défaut dans `roles/<rôle>/defaults/main.yml`. Ce qui est propre à ce parc est surchargé dans `group_vars/all/main.yml`. Pour un réglage propre à une machine, créer `host_vars/<hôte>.yml`.

Les plus utiles :

| Variable | Rôle | Effet |
|----------|------|-------|
| `ssh_port` | ssh, firewall | Port d'écoute de sshd |
| `firewall_ssh_sources` | firewall | Réseaux autorisés en SSH (vide = tous) |
| `firewall_trusted_sources` | firewall | Réseaux autorisés vers Grafana/Prometheus/Alertmanager |
| `firewall_public_tcp_ports` | firewall | Ports ouverts à tous |
| `firewall_cloudflare_tcp_ports` | firewall | Ports ouverts aux seules IP Cloudflare |
| `prometheus_version`, `alertmanager_version`, `node_exporter_version` | monitoring | `latest` ou version épinglée |
| `prometheus_retention_time`, `prometheus_retention_size` | prometheus | Taille maximale de la base de métriques |
| `users_list` | users | Comptes à créer (dans `group_vars/all/users.yml`) |

## Surveillance mutuelle

Il n'y a pas de machine dédiée au monitoring : chaque serveur du groupe `monitoring` fait tourner Prometheus et Alertmanager, et **scrape tous les serveurs du groupe, lui-même compris**.

- Si rpi1 tombe, le Prometheus de rpi2 voit `up == 0` pour rpi1 et alerte sur Discord, et inversement.
- Les deux Alertmanager forment un cluster (port 9094) et chaque Prometheus envoie ses alertes aux deux : une alerte vue des deux côtés n'est notifiée qu'une fois.
- Limite : si les deux serveurs tombent ensemble (coupure de courant plus longue que l'onduleur, panne Internet), personne ne prévient. Un contrôle externe gratuit de type « dead man's switch » comble ce trou (voir la feuille de route dans [architecture.md](architecture.md)).

## Ce qui a changé par rapport aux anciens playbooks

| Avant | Maintenant |
|-------|-----------|
| 11 playbooks lancés en boucle par `run_playbooks.sh` | `site.yml` + rôles, sélection par `--tags` et `--limit` |
| Dépôt recopié dans `/etc/ansible` | Tout se lance depuis le dépôt |
| Webhook Discord en clair dans 4 fichiers | Variable unique, stockée dans le vault |
| Vérification des clés d'hôte SSH désactivée | Activée |
| Binaires `linux-armv7` (32 bits) | Architecture détectée (`arm64` sur un Pi 5) |
| Prometheus, Alertmanager, node_exporter lancés en `root` | Utilisateurs système dédiés, unités systemd durcies |
| Données Prometheus dans `/opt/prometheus-<version>/data`, donc perdues à chaque montée de version | `/var/lib/prometheus`, rétention bornée en durée et en taille |
| Chaque Prometheus ne surveillait que sa propre machine | Surveillance mutuelle + Alertmanager en cluster |
| Ports 9090/9093/9100/3000 ouverts à tous | Réservés aux réseaux de confiance et aux autres serveurs |
| Ports 53 et 43 ouverts en entrée sans raison, ICMPv6 bloqué (casse IPv6) | Supprimés ; ICMP/ICMPv6 autorisés |
| `sshd_config` modifié ligne par ligne, avec des expressions régulières qui supprimaient trop de lignes | Fichier `sshd_config.d/10-hardening.conf`, validé par `sshd -t` avant application |
| Moduli SSH régénérés à chaque exécution (long, et inutile avec curve25519) | Supprimé |
| Fail2ban pointé sur `/var/log/journal` (ne bannissait rien) | Backend `systemd` |
| Grafana en `admin`/`admin`, dépôt APT ajouté en double à chaque exécution | Mot de passe depuis le vault, source de données et dashboard provisionnés par fichiers |
| Mot de passe de tous les utilisateurs expiré à chaque exécution | Uniquement à la création du compte |
| Script Logwatch dupliqué deux fois dans le même fichier | Nettoyé |

Les rôles sont idempotents : relancer `site.yml` sans rien changer ne doit rien modifier.

**État de validation** : la syntaxe du playbook et le rendu de tous les templates ont été vérifiés en local. Les rôles n'ont pas encore été exécutés sur les Raspberry Pi : faire le premier passage avec `--check --diff`, sur un seul hôte (`--limit`), en gardant une session SSH ouverte à côté.
