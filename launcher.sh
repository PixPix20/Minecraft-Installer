#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# AVERTISSEMENT LÉGAL ET TECHNIQUE
# Date    : 2025-10-08
# Auteur  : Lucas Morel <lucas.morel@epita.fr>
# Version : v1.2  (https://github.com/PixPix20/Minecraft-Installer)
#
# 1) Objet : Ce script vise à automatiser le lancement et l'installation de PrismLauncher.
#
# 2) Garantie : Fourni "tel quel", sans garantie expresse ou implicite.
#
# 3) Responsabilité : L'utilisateur est responsable de l'exécution sur son AFS.
#    Je décline toute responsabilité pour toute perte, corruption ou modification
#    de données, que le script ait été modifié ou non.
#
# 4) Modifications : Toute modification du script implique que le modificateur
#    assume l'entière responsabilité des conséquences.
#
# Contact : https://github.com/PixPix20
# -----------------------------------------------------------------------------

set -euo pipefail

VERSION="1.2"

# Variables globales
env="prod"
afs="$HOME/afs"
i3="$afs/.confs/config/i3"
i3_config="$i3/config"

max_storage=2147483648 #2Go max sur l'afs
minecraft_storage=943718400 #900Mo pour Minecraft
margin_storage=419430400 #400Mo de marge

minecraft_path="$afs/minecraft"
launcher_name="PrismLauncher"
launcher_config_path="$minecraft_path/config"
launcher_appimage="$minecraft_path/PrismLauncher-Linux-x86_64.AppImage"
instances_path="$minecraft_path/Instances"
mods_path="$minecraft_path/mods"
java_path="$minecraft_path/java"
downloads_path="$HOME/Downloads"
launcher_local_files_path="$HOME/.local/share/PrismLauncher"
bin_path="$minecraft_path/bin"

launcher_url="https://github.com/PrismLauncher/PrismLauncher/releases/download/9.4/PrismLauncher-Linux-x86_64.AppImage"
config_url="https://raw.githubusercontent.com/PixPix20/Minecraft-Installer/refs/heads/main/prismlauncher.cfg"

# Fonctions

set_env() {
    if [ "${env:-prod}" = "dev" ]; then
        afs="$HOME/test"
        printf "ATTENTION: Vous êtes en mode 'dev'. Les chemins ont changé !\n"
    else
        afs="$HOME/afs"
    fi
    i3="$afs/.confs/config/i3"
    i3_config="$i3/config"
    mkdir -p "$afs" "$i3"
}

show_version() {
    printf "Version %s\n" "$VERSION"
}

show_env() {
    printf "Environnement : %s\n--PATHS :\n" "$env"
    printf "AFS : %s\n" "$afs"
    printf "i3 : %s\n" "$i3_config"
    printf "Config launcher : %s\n" "$launcher_config_path"
    printf "AppImage : %s\n" "$launcher_appimage"
    printf "Instances : %s\n" "$instances_path"
    printf "Mods : %s\n" "$mods_path"
    printf "Java : %s\n" "$java_path"
    printf "Téléchargements : %s\n" "$downloads_path"
    printf "Fichiers locaux launcher : %s\n" "$launcher_local_files_path"
    printf "Script : %s\n" "$bin_path"
}

help_msg() {
cat <<EOF
Minecraft Installer v$VERSION
Usage: $0 [option]

Options:
 -v, --version        Affiche la version du script
 -e, --env [dev|prod] Définit l'environnement (dev/prod)
 -se, --show-env      Affiche l'environnement et les paths
 -i, --install        Installe PrismLauncher
 -u, --update         Met à jour le script
 -r, --remove         Désinstalle le launcher et ses fichiers
 -l, --launch         Lance PrismLauncher
 -ad, --add-dmenu     Ajoute le script à dmenu
 -h, --help           Affiche ce texte
EOF
}

check_commands() {
    local err=0
    for cmd in wget curl sed grep nix-shell bc; do
        if ! command -v "$cmd" &>/dev/null; then
            printf "%s n'est pas installé !\n" "$cmd"
            err=1
        fi
    done
    return $err
}

check_storage() {
    local used_storage total_storage
    used_storage=$(du -sb "$afs" 2>/dev/null | awk '{print $1}')
    total_storage=$((used_storage + minecraft_storage + margin_storage))
    if ((max_storage < total_storage)); then
        printf "Erreur, pas assez de place pour l'installation ! %d octets requis.\n" "$total_storage"
        return 1
    fi
    return 0
}

check_path() {
    mkdir -p "$minecraft_path" "$launcher_config_path" "$instances_path" "$mods_path" "$java_path" "$bin_path"
}

check_config() {
    local config="$launcher_config_path/prismlauncher.cfg"
    if [ ! -f "$config" ]; then
        wget -q -P "$launcher_config_path/" "$config_url"
        sed -i \
            -e "s|DownloadsDir=.*|DownloadsDir=$downloads_path|" \
            -e "s|InstanceDir=.*|InstanceDir=$instances_path|" \
            -e "s|CentralModsDir=.*|CentralModsDir=$mods_path|" \
            -e "s|JavaDir=.*|JavaDir=$java_path|" \
            "$config"
    fi
}

add_to_dmenu() {
    sed -i "s|bindsym \$mod+d exec --no-startup-id dmenu_run|bindsym \$mod+d exec --no-startup-id PATH=$bin_path:\$PATH dmenu_run|" "$i3_config"
    if ! grep -q "PATH=$bin_path" "$HOME/.bashrc"; then
        echo "export PATH=$bin_path:\$PATH" >> "$HOME/.bashrc"
    fi
    if ! grep -q "minecraft-launcher" "$i3_config"; then
        echo "bindsym \$mod+m exec --no-startup-id minecraft-launcher -l" >> "$i3_config"
    fi
    cp "$0" "$bin_path/minecraft-launcher"
    chmod +x "$bin_path/minecraft-launcher"
}

remove_all() {
    rm -rf "$minecraft_path"
    sed -i "s|PATH=$bin_path:\$PATH||g" "$HOME/.bashrc"
}

update_script() {
    local script_url="https://raw.githubusercontent.com/PixPix20/Minecraft-Installer/main/launcher.sh"
    wget -q -O "$0.tmp" "$script_url"
    if [ -s "$0.tmp" ]; then
        mv "$0.tmp" "$0"
        chmod +x "$0"
        echo "Script mis à jour !"
    else
        echo "Erreur lors du téléchargement de la mise à jour."
        rm -f "$0.tmp"
    fi
}

get_remote_version() {
    local remote_url="https://api.github.com/repos/PixPix20/Minecraft-Installer/releases/latest"
    curl -s "$remote_url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

check_script_update() {
    local local_version="$VERSION"
    local remote_version
    remote_version=$(get_remote_version)
    if [ -z "$remote_version" ]; then
        echo "Impossible de récupérer la version distante."
        return 1
    fi
    echo "Version locale : $local_version"
    echo "Version distante : $remote_version"
    if [ "$(printf '%s\n' "$remote_version" "$local_version" | sort -V | head -n1)" != "$remote_version" ]; then
        echo "Une nouvelle version du script est disponible."
        read -r -p "Voulez-vous la mettre à jour ? [o/N] " answer
        if [[ "$answer" =~ ^[Oo]$ ]]; then
            update_script
        else
            echo "Mise à jour annulée."
        fi
    else
        echo "Le script est à jour."
    fi
}

check_account() {
    while [ ! -f "$launcher_local_files_path/accounts.json" ]; do
        sleep 2
    done
    printf "Compte détecté, sauvegarde\n"
    cp "$launcher_local_files_path/accounts.json" "$launcher_config_path"
}

check_launcher() {
    if [ ! -f "$launcher_appimage" ]; then
        mkdir -p "$(dirname "$launcher_appimage")"
        wget -q -O "$launcher_appimage" "$launcher_url"
        chmod +x "$launcher_appimage"
    fi
}

cop_files() {
    mkdir -p "$launcher_local_files_path"
    cp "$launcher_config_path"/* "$launcher_local_files_path"
}

start_launcher() {
    nix-shell -p appimage-run --run "appimage-run $launcher_appimage"
}

main() {
    set_env
    if [ $# -eq 0 ]; then
        check_commands || exit 1
        check_path
        check_config
        check_launcher
        cop_files
        check_account & start_launcher
        exit 0
    fi

    case "${1:-}" in
        -e|--env)
            if [[ -n "${2:-}" ]]; then
                env="$2"
            else
                echo "Usage: $0 --env [dev|prod]"
                exit 1
            fi
            set_env
            ;;
        -se|--show-env)
            show_env
            ;;
        -i|--install)
            check_commands || exit 1
            check_storage || exit 1
            check_path
            check_config
            check_launcher
            add_to_dmenu
            echo "Installation terminée."
            ;;
        -u|--update)
            check_commands || exit 1
            check_script_update
            ;;
        -r|--remove)
            remove_all
            ;;
        -l|--launch)
            check_commands || exit 1
            check_path
            check_config
            check_launcher
            cop_files
            check_account & start_launcher
            ;;
        -ad|--add-dmenu)
            add_to_dmenu
            ;;
        -v|--version)
            show_version
            ;;
        -h|--help)
            help_msg
            ;;
        *)
            echo "Option inconnue: $1"
            help_msg
            exit 1
            ;;
    esac
}

main "$@"

