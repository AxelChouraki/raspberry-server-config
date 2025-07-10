Réseau local

Mise en place d'un VLAN difficle avec le matériel actuel (voir notes/)
    --> à cause de cette contrainte, je ne vais pas faire de serveur DNS mais je vais rester en nDNS

routeur: Freebox Server (r2)
    Max débit descendant: 1Gb/s
    Max débit ascendant: 900Mb/s
    --> pas besoin de scale le réseau au delà de 1Gbps pour le moment

TP-Link TL-SG108E Switch Manageable Ethernet
    --> isole mon réseau et le reste de la maison
    8 ports Ethernet Gigabit 10/100/1000 Mbps à auto-négociation, fonction Auto MDI/MDX
    interface utilisateur Web ou les outils téléchargeables
    plug and play possible
    Supports QoS (IEEE 802.1p), Rate Limit, Storm Control et IGMP snooping
    sans ventilo / boitier en métal / techno d'économie d'énergie
    Config:
        Ip fixe: 192.168.1.41
        Par défaut, on laisse: débit auto, flow control OFF, IGMP Snooping ON, 
        Pas d'utilisation de LAG group. pas de besoin + 1 prise RJ45 par serveur
        Pas de VLAN sans routeur qui gère les VLAN (sinon 1 seul VLAN aura accès à internet entre autres)
        QoS port based, priority on port 1 and 2

Cables
    Ethernet CAT 6
    le bottleneck se trouve sur le routeur normalement (l'abonnement internet plus précisément)

Onduleur
    Eaton Onduleur Ellipse ECO 800 USB FR - Off-line UPS - EL800USBFR - Puissance 800VA (4 prises FR, Parasurtenseur, Batterie) - UPS avec Interface USB (câble inclus) - Noir

Prise connectée
    Tapo Prise Connectée WiFi, Suivi de consommation, 16A Type E, compatible avec Alexa et Google Home, Contrôler le radiateur, le chauffage, Économie d'énergie, Commande vocale, Tapo P110(FR)
    Branchée sur l'onduleur
    Tous les serveurs sont branchés dessus pour suivre leur consommation électrique

Serveurs
    rpi1: Raspberry pi 5 8Go, SD Card 256Go
    rpi2: Raspberry pi 5 8Go, NVMe 1To
    PC non utilisée pour le moment

    IPs
Freebow: 192.168.1.254
Switch: 192.168.1.41
PC: 192.168.1.42
rpi1: 192.168.1.43 (wifi), 192.168.1.44 (eth)
rpi2: 192.168.1.45 (wifi), 192.168.1.46 (eth)

    LÉGALITÉ

?