# 🧠 Objectif réseau initial

Créer un **réseau séparé** pour mes serveurs et tests,  
isolé du réseau domestique, avec **priorité réseau plus faible**,  
tout en gardant **l’accès à Internet** pour les serveurs (ex. : mises à jour, monitoring, etc.).

---

# 🧱 Matériel à disposition

| Matériel        | Rôle                                               | Limitation principale                         |
|-----------------|----------------------------------------------------|------------------------------------------------|
| **Freebox**     | Routeur principal, DHCP/DNS, accès Internet        | ❌ Ne supporte **pas les VLANs 802.1Q**        |
| **Switch manageable** | Permet VLANs, QoS, isolation des ports       | ✅ Très utile pour la segmentation réseau      |
| **2 Raspberry Pi** | Serveurs/clients dans le réseau test            | ⚠️ Peuvent faire routage mais **je veux éviter ça** |

---

# ✅ Ce que je voulais faire

- Séparer les **machines de test** dans un **réseau isolé**
- Leur donner une **priorité réseau plus basse**
- Leur laisser **accès Internet sans perturber le réseau domestique**
- Avoir une **topologie claire**, maintenable et automatisée via Ansible

---

# 🚧 Limitations rencontrées

| Fonction                             | Limitation liée au matériel actuel |
|--------------------------------------|-------------------------------------|
| Routage inter-VLAN (ou filtrage)     | ❌ Freebox ne comprend pas les VLANs → pas d’isolement logique au niveau IP |
| DHCP pour réseau VLAN secondaire     | ❌ Freebox ne gère qu’un seul réseau IP/DHCP |
| Pare-feu entre les réseaux           | ❌ Impossible sans routeur intermédiaire (RPi ou autre) |
| VLAN avec isolation complète         | ⚠️ Possible via le switch **si aucun port ne connecte les VLANs entre eux** |
| Basse priorité réseau pour les serveurs | ✅ Possible via **QoS** sur le switch (si supporté) |

---

# ✅ Ce que je peux faire dès maintenant

- Créer un **VLAN secondaire** (ex. VLAN 10 → `192.168.10.0/24` ou `10.10.10.0/24`)
- Mettre les **serveurs sur VLAN 10** avec **IP statiques**
- Ne pas définir de passerelle → pas d’accès au réseau domestique
- Configurer la **QoS sur le switch** pour limiter la priorité de VLAN 10
- (Optionnel) connecter **1 port VLAN 10** vers Freebox pour accès Internet (non isolé)

---

# 🛠️ Évolutions possibles plus tard

- Ajouter un **routeur dédié** ou un **RPi** pour :
  - Routage inter-VLAN
  - Pare-feu (iptables/nftables)
  - DHCP/DNS par sous-réseau
- Remplacer la Freebox par un **routeur pro VLAN-aware**
  - (ex. : MikroTik, pfSense, EdgeRouter, etc.)
