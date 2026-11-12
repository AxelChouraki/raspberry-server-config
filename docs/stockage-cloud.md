# Stockage de fichiers : auto-hébergé ou cloud commercial ?

Synthèse de la réflexion menée dans [archive/nextcloud-setup.txt](archive/nextcloud-setup.txt) (Nextcloud, Seafile, GlusterFS, puis abandon), avec une conclusion.

## « Mon cloud ne sera jamais aussi sûr qu'un cloud commercial » : vrai ou faux ?

Ça dépend de ce qu'on met derrière « sûr ». Il y a trois propriétés distinctes, et la réponse n'est pas la même pour chacune.

| | Cloud commercial | Auto-hébergé **exposé sur Internet** | Auto-hébergé **derrière VPN** |
|---|---|---|---|
| **Résistance aux attaques depuis Internet** | Excellente : équipes dédiées, correctifs en heures, détection | Faible : une grosse application web, un seul administrateur, des correctifs quand on y pense | Excellente : rien à attaquer sans la clé WireGuard |
| **Confidentialité** | Le fournisseur peut lire les fichiers (analyse automatique, réquisitions, fuite chez lui) | Personne d'autre que soi | Personne d'autre que soi |
| **Durabilité** (ne pas perdre les données) | Excellente : réplication multi-sites | Un SSD, une maison | Un SSD, une maison |
| **Disponibilité** | ~100 % | Dépend du courant et de la fibre | Idem |
| **Risque propre** | Compte verrouillé ou piraté, changement de tarif | Erreur de configuration | Erreur de configuration |

Donc :

- **Vrai** si l'instance est publique. Un Nextcloud joignable par tout Internet, maintenu par une personne sur son temps libre, est une cible plus facile que Google Drive. C'était la situation de départ, et l'intuition était juste.
- **Faux** si l'instance n'est joignable que par VPN. Un service que personne ne peut atteindre ne se pirate pas à distance, et côté confidentialité c'est *mieux* qu'un cloud commercial : aucun tiers ne détient les fichiers.
- Le vrai point faible de l'auto-hébergement n'est pas le piratage, c'est **la perte de données** : panne du SSD, vol, incendie, fausse manipulation. Ça se corrige avec une sauvegarde chiffrée hors site, pas avec plus de sécurité réseau.

Il existe une troisième voie pour qui veut la durabilité du commercial sans lui confier ses fichiers en clair : chiffrer côté client (Cryptomator, rclone crypt) avant d'envoyer, ou prendre un fournisseur chiffré de bout en bout.

## Quel logiciel ?

Le besoin, tel que reformulé dans les notes : *un système de fichiers accessible de partout, avec redondance, sans fonctions collaboratives inutiles, simple et peu coûteux à maintenir*.

### Recommandation : Syncthing + partage réseau + restic

- **Syncthing** synchronise des dossiers entre le PC, le téléphone et rpi2. Pas de serveur web, pas de base de données, pas de compte : rien à exposer et presque rien à maintenir. Chaque appareil garde une copie complète, ce qui donne la redondance recherchée avec GlusterFS, sans cluster ni quorum.
- **Un partage Samba (ou SFTP) sur rpi2**, accessible par le VPN, pour ce qu'on veut parcourir comme un lecteur réseau sans le synchroniser partout.
- **restic** pour la sauvegarde versionnée et chiffrée hors site. La synchronisation n'est pas une sauvegarde : un fichier supprimé est supprimé partout.

Ça répond point par point au besoin reformulé, avec trois outils simples au lieu d'une grosse application. **Mais l'expérience sur téléphone est nettement moins bonne qu'avec Nextcloud** : voir ci-dessous avant de choisir.

### Sur téléphone

| Besoin | Nextcloud (appli officielle) | Syncthing + Samba |
|--------|------------------------------|-------------------|
| Appli Android | Oui | Syncthing : l'appli officielle a été abandonnée fin 2024, un fork communautaire (« Syncthing-Fork ») prend le relais. Samba : n'importe quel gestionnaire de fichiers (Material Files…) |
| Appli iOS | Oui | Pas d'appli Syncthing officielle : Möbius Sync (payante) ou Synctrain (libre, plus récente). Samba : intégré à l'appli Fichiers |
| Parcourir tout le stockage sans tout télécharger | Oui, une seule appli | Oui via Samba, mais dans une autre appli que la synchro |
| Fichiers hors ligne à la demande | Oui (fichier par fichier) | Non : Syncthing synchronise des dossiers entiers |
| Sauvegarde automatique des photos | Oui | Oui (dossier appareil photo en « envoi seul ») |
| Lien de partage pour quelqu'un d'extérieur | Oui | Non |
| Fonctionne sans le VPN | Non (derrière le VPN) | Syncthing oui : chiffré et authentifié de bout en bout, il passe par des relais sans port ouvert. Samba non |
| Agenda, contacts | Oui | Non |

En résumé : Syncthing est imbattable pour garder quelques dossiers identiques partout avec zéro maintenance, mais ce n'est pas un « Drive ». Si l'usage principal est d'ouvrir ses fichiers depuis le téléphone comme sur Google Drive, **Nextcloud derrière le VPN** (ou OpenCloud, plus léger) est le meilleur choix : son seul vrai défaut, la surface d'attaque, disparaît une fois qu'il n'est plus exposé. WireGuard se configure pour rester connecté en permanence (« on-demand » sur iOS, VPN permanent sur Android), y compris à la maison puisque le LAN de la Freebox n'a pas accès au labo, ce qui rend le VPN transparent.

Si le besoin téléphone est surtout la sauvegarde des photos, **Immich** fait mieux que les deux.

### Et les autres

| Solution | Verdict |
|----------|---------|
| **Nextcloud** | À garder seulement si l'on veut ce qu'il apporte en plus des fichiers : agenda, contacts, partage par lien, édition en ligne. Lourd (PHP + base de données + cron + mises à jour fréquentes) pour un simple besoin de fichiers. Derrière le VPN, sa surface d'attaque n'est plus un problème |
| **OpenCloud / oCIS** | Un « Drive » moderne, un seul binaire, fichiers stockés tels quels sur le disque. Le bon choix si une interface web et des liens de partage deviennent nécessaires |
| **Seafile** | Écarté : format de stockage propriétaire, fonctions de réplication réservées à la version Pro |
| **GlusterFS** | Écarté : à deux nœuds, il faut choisir entre risque de split-brain et perte de la haute disponibilité. Complexité de datacenter pour un besoin domestique |
| **Immich** | Hors sujet pour les fichiers, mais la référence si le besoin réel est de remplacer Google Photos |

## Décision : un cloud personnel multi-utilisateurs

Choix retenu : un « Drive » auto-hébergé sur rpi2 (zone SERVICES), ouvert à d'autres personnes, avec une sauvegarde chiffrée hors site (voir [architecture.md](architecture.md#sauvegardes)).

### Nextcloud ou OpenCloud ?

Les deux gèrent plusieurs utilisateurs, des groupes, des dossiers partagés et des liens de partage, avec des applis bureau, Android et iOS.

| | Nextcloud | OpenCloud |
|---|---|---|
| Comptes, groupes, partage entre utilisateurs | Oui | Oui |
| Espaces partagés (dossier d'équipe avec quota propre) | Via l'appli « Group folders » | Natif (« Spaces ») |
| Agenda, contacts, notes, suite bureautique | Oui, très complet | Limité : centré sur les fichiers |
| Architecture | PHP + base de données + Redis + cron | Un seul binaire Go, pas de base de données, fichiers stockés tels quels sur le disque |
| Charge sur une Pi 5 | Correcte avec le NVMe, interface parfois lente | Légère |
| Sauvegarde | Fichiers + dump de la base, à faire de façon cohérente | Copier le dossier de données suffit |
| Maturité | Plus de dix ans, énorme écosystème | Jeune (fork d'oCIS, 2025) |

En résumé : **OpenCloud** si le besoin est « des fichiers, pour moi et quelques proches » ; **Nextcloud** si l'on veut aussi agenda, contacts ou édition de documents en ligne.

Choix retenu : **OpenCloud**. Appli Android officielle sur Google Play et F-Droid (paquet `eu.opencloud.android`, Android 8 minimum), appli iOS et client de synchronisation pour ordinateur.

### Coût comparé à Google One

Référence : Google One 100 Go à 1,99 €/mois.

| Poste | Coût mensuel indicatif |
|-------|------------------------|
| Électricité des deux Pi (~10-12 W en continu) | ~2 € |
| Électricité du mini-PC OPNsense (~8 W) | ~1,5 € |
| Sauvegarde hors site | 0 à 6 € selon l'option (voir [architecture.md](architecture.md#mettre-en-place-la-sauvegarde-hors-site)) |
| Matériel | Déjà acheté, sauf le mini-PC (150-200 € une fois) |

À capacité égale (100 Go), l'auto-hébergement **n'est pas moins cher** : l'électricité seule dépasse 2 €. Il le devient en coût marginal, puisque les Pi tournent de toute façon pour le site et le monitoring, et surtout en capacité : 1 To chez soi contre 100 Go, avec plusieurs utilisateurs sans payer par compte. On ne le fait pas pour l'argent, mais pour la confidentialité, l'espace et l'apprentissage.

**Garder l'abonnement Google comme destination de sauvegarde.** restic sait écrire dans Google Drive via rclone, et chiffre tout avant l'envoi : Google ne stocke que des blocs illisibles. Les 100 Go suffisent pour les données importantes (documents, photos), sans coût supplémentaire. Limites : 100 Go au total, aucune protection contre l'effacement au-delà de la corbeille de 30 jours, et dépendance au compte Google (un compte bloqué = sauvegarde inaccessible). Pour plus de volume ou une vraie protection contre l'effacement, passer à une Storage Box ou à B2.

### Comment les autres personnes y accèdent

Le cloud est derrière le VPN, donc chaque personne doit pouvoir s'y connecter :

- **Recommandé : un pair WireGuard par personne.** Une configuration générée sur OPNsense, transmise par QR code, l'appli WireGuard en connexion permanente : c'est transparent à l'usage. Sur OPNsense, limiter ces pairs au seul port HTTPS du cloud sur rpi2 (pas de SSH, pas de Grafana). Révoquer quelqu'un = supprimer son pair.
- **Si quelqu'un ne peut pas installer de VPN** : publier le cloud via le Tunnel Cloudflare, protégé par Cloudflare Access (authentification avant d'atteindre le serveur). Le cloud passe alors en DMZ, Cloudflare voit les fichiers en clair, et le plan gratuit limite chaque requête à 100 Mo (les deux logiciels découpent les envois, ça reste utilisable). À réserver au cas où le VPN est vraiment impossible.

### Partager un fichier avec quelqu'un d'extérieur

C'est le seul cas que la solution recommandée ne couvre pas. Deux options : un lien depuis un cloud commercial pour ces fichiers-là, ou une petite application de partage en DMZ derrière Cloudflare, sans accès au reste des données.
