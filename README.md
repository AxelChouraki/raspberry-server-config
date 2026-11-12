# raspberry-server-config

Configuration Ansible de mes serveurs domestiques (2 Raspberry Pi 5) et documentation du réseau qui les héberge.

Objectif : héberger des services à la maison (site perso, stockage de fichiers, monitoring) derrière une architecture réseau segmentée, sans exposer ni ralentir le réseau domestique.

## Ce que fait ce dépôt

Un seul point d'entrée, `site.yml`, applique des **rôles** aux machines de l'inventaire :

| Rôle | Ce qu'il fait |
|------|---------------|
| `common` | Paquets de base, mises à jour de sécurité automatiques |
| `users` | Comptes, groupes, clés SSH, groupe d'administration `wheel` |
| `hardening` | Limites de ressources (anti fork-bomb), `su` réservé à `wheel`, droits sur `/opt` |
| `ssh` | Durcissement de sshd (clés uniquement, algorithmes modernes), Fail2ban |
| `firewall` | Pare-feu nftables, tout fermé par défaut |
| `node_exporter` | Métriques système |
| `prometheus` | Collecte + règles d'alerte ; chaque serveur surveille aussi les autres |
| `alertmanager` | Alertes vers Discord, en cluster pour ne pas notifier en double |
| `grafana` | Tableaux de bord, source de données et dashboard provisionnés |
| `logwatch` | Rapport mensuel des logs sur Discord |
| `backup` | Rappel mensuel de sauvegarde sur Discord (pas encore de vraie sauvegarde) |

## Démarrage rapide

Depuis WSL (voir [docs/ansible.md](docs/ansible.md) pour l'installation et le premier déploiement) :

```bash
ansible-galaxy collection install -r requirements.yml
cp vault.example.yml group_vars/all/vault.yml   # puis renseigner et chiffrer
ansible-vault encrypt group_vars/all/vault.yml
ansible-playbook site.yml --ask-vault-pass
```

## Organisation

```
site.yml                 point d'entrée : quels rôles sur quels groupes
inventory/hosts.yml      les machines et leurs groupes
group_vars/all/          variables du parc (main.yml, users.yml, vault.yml chiffré)
roles/<rôle>/            tasks, templates, handlers, defaults (variables documentées)
docs/                    documentation
```

## Documentation

- [docs/architecture.md](docs/architecture.md) : architecture réseau cible, analyse de sécurité, feuille de route
- [docs/ansible.md](docs/ansible.md) : utiliser Ansible depuis Windows/WSL, secrets, rôles et variables
- [docs/stockage-cloud.md](docs/stockage-cloud.md) : auto-hébergement ou cloud commercial, quel logiciel choisir
- [docs/materiel.md](docs/materiel.md) : matériel et plan d'adressage actuel
- [docs/installation-manuelle.md](docs/installation-manuelle.md) : ce qui n'est pas automatisé (flash, NVMe, quotas, Minecraft)
- [docs/archive/](docs/archive/) : notes d'origine, conservées telles quelles
