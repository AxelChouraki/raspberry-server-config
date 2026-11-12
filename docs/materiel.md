# Matériel et réseau actuel

État des lieux **aujourd'hui** (réseau à plat, tout sur le LAN de la Freebox). L'architecture visée est décrite dans [architecture.md](architecture.md).

## Matériel

| Élément | Modèle | Notes |
|---------|--------|-------|
| Routeur | Freebox (routeur opérateur) | DHCP, DNS, accès Internet. Ne gère pas les VLAN 802.1Q : un seul réseau IP |
| Switch | TP-Link TL-SG108E, 8 ports Gigabit | Manageable (VLAN 802.1Q, QoS 802.1p, rate limit, IGMP snooping), sans ventilateur |
| rpi1 | Raspberry Pi 5, 8 Go | Carte SD 256 Go |
| rpi2 | Raspberry Pi 5, 8 Go | SSD NVMe 1 To |
| PC | Non utilisé pour le moment | |
| Onduleur | Eaton Ellipse ECO 800 USB | 800 VA, off-line, interface USB |
| Prise connectée | Tapo P110 | Branchée sur l'onduleur, mesure la consommation des serveurs |
| Câblage | Ethernet Cat 6 | |

> Le TL-SG108E est un switch de niveau 2 : il transporte des VLAN mais ne route pas entre eux. Son interface d'administration répond depuis tous les VLAN et sans HTTPS : ne pas compter sur lui comme barrière de sécurité, seulement comme répartiteur. Dans l'architecture cible, le plus simple est de le laisser côté LAN Freebox, sans VLAN (voir [architecture.md](architecture.md#le-schéma-avec-le-matériel-réel)).

## Configuration du switch

- IP fixe : `192.168.1.41`
- Débit automatique, flow control désactivé, IGMP snooping activé
- Pas d'agrégation de liens (une prise par serveur suffit)
- QoS par port, priorité sur les ports 1 et 2
- Pas de VLAN pour l'instant : sans routeur capable de router entre VLAN, un seul VLAN aurait accès à Internet (détail dans [archive/pourquoi-pas-de-vlan.md](archive/pourquoi-pas-de-vlan.md))

## Plan d'adressage

| Machine | Adresse |
|---------|---------|
| Freebox | `192.168.1.254` |
| Switch | `192.168.1.41` |
| PC | `192.168.1.42` |
| rpi1 | `192.168.1.44` (Ethernet), `192.168.1.43` (Wi-Fi) |
| rpi2 | `192.168.1.46` (Ethernet), `192.168.1.45` (Wi-Fi) |

## Débit

La Freebox plafonne à 1 Gb/s descendant et 900 Mb/s montant : inutile de dimensionner le réseau local au-delà de 1 Gb/s pour l'instant. Le goulot d'étranglement est l'abonnement, pas le câblage.

## Ports utilisés sur les serveurs

| Port | Service | Ouvert à |
|------|---------|----------|
| 2002/tcp | SSH | tous (à restreindre, voir `firewall_ssh_sources`) |
| 3000/tcp | Grafana | réseaux de confiance |
| 9090/tcp | Prometheus | réseaux de confiance + autres serveurs |
| 9093/tcp | Alertmanager | réseaux de confiance + autres serveurs |
| 9094/tcp+udp | Alertmanager (cluster) | autres serveurs |
| 9100/tcp | node_exporter | autres serveurs |
| 25565/tcp | Minecraft | tous |
| 8000/tcp | Service web | Cloudflare + réseaux de confiance |
