#!/bin/bash

# Demander le mot de passe une seule fois
read -s -p "Entrez votre ansible_ssh_pass : " password
echo

playbook_directory="./playbooks"  # Chemin vers le dossier contenant les playbooks
log_file="ansible.log" 

# Liste des noms de fichiers de playbook à exécuter dans l'ordre souhaité
playbooks=(
    "configure_miscellaneous_install.yml"
    "configure_users.yml"
    "configure_node_exporter.yml"
    "configure_grafana.yml"
    "configure_alertmanager.yml"
    "configure_prometheus.yml"
    "configure_logwatch.yml"
    "configure_back_up.yml"
    "configure_permissions.yml"
    "configure_ssh.yml"
    "configure_firewall.yml"
)

# Boucle à travers la liste des playbooks et les exécute un par un
for playbook in "${playbooks[@]}"; do
    echo "Exécution de $playbook..."
    ansible-playbook "$playbook_directory/$playbook" --extra-vars "ansible_ssh_pass=$password" | tee -a "$log_file"
    echo "Terminé."
done