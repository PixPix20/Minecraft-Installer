#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# AVERTISSEMENT LÉGAL ET TECHNIQUE
# Date    : 2025-10-08
# Auteur  : Lucas Morel <lucas.morel@epita.fr>
# Version : v1.1  (https://github.com/PixPix20/Minecraft-Installer)
#
# 1) Objet : Ce script vise à automatiser le lancement de PrismLauncher.
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

VERSION="1.1"

#On verifie qu'il y a assez de place pour installer minecraft en plus de garder un peu de place pour le reste
#STOCKAGE
max_storage=2147483648 #2Go, le stockage max de l'afs, je deconseille fortement d'augmenter cette valeur !
minecraft_storage=943718400 #900Mo, j'utilise cette valeur si vous voulez jouer avec un modpack qui est lourd
margin_storage=419430400 #400Mo, marge de securité pour que vous puissiez utiliser l'afs aprés l'installation du jeu, je deconseille de modifier cette valeur
env="prod"
#AFS
if [ "$env" = "dev" ]; then
	afs="$HOME/test"
else
	afs="$HOME/afs"
	i3="$afs/.confs/config/i3/config"

fi
i3=$afs/.confs/config/i3/
i3_config=$i3/config
mkdir -p $afs $i3


#LAUNCHER

minecraft_path="$afs/minecraft" #dossier qui contient minecraft la conf du launcher etc

launcher_name="PrismLauncher"
launcher_config_path="$minecraft_path/config" #dossier qui contient les configurations du launcher
launcher_appimage="$minecraft_path/PrismLauncher-Linux-x86_64.AppImage" #Dossier sense contenir le .appimage du launcher

instances_path="$minecraft_path/Instances" #dossier qui contient les instances minecraft
mods_path="$minecraft_path/mods" #Dossier qui contient les mods minecraft
java_path="$minecraft_path/java" #Dossier qui contient java(prism l'installe)
downloads_path="$HOME/Downloads"
launcher_local_files_path="$HOME/.local/share/PrismLauncher"
bin_path="$minecraft_path/bin" #dossier où se trouve l'executable du launcher

#URL
launcher_url="https://github.com/PrismLauncher/PrismLauncher/releases/download/9.4/PrismLauncher-Linux-x86_64.AppImage" #URL du github pour telecharger le launcher
config_url="https://raw.githubusercontent.com/PixPix20/Minecraft-Installer/refs/heads/main/prismlauncher.cfg" #URL pour télécharger la config du launcher

help_msg(){
	cat <<EOF
	Minecraft Installer v$VERSION
Usage: $0 [option]

Options:
 -i, --install		Installer le PrismLauncher
 -u, --update		Mettre à jour le script
 -r, --remove		Désinstaller le launcher et ses fichiers
 -l, --launch		Lancer PrismLauncher
 --add-dmenu		Ajouter Le script à dmenu
 -h, --help		Afficher ce texte
EOF
}


check_storage(){
	#verification si l'AFS peut installer minecraft en plus de garder un marge pour les autre fichiers
	local used_storage total_storage
	used_storage=$(du -sb "$afs"|awk '{print $1}')
        total_storage=$((used_storage + minecraft_storage + margin_storage)) #On additionne le stockage déja utilisé, la taille (~) de MC puis on ajoute une marge de secu.
	
}

check_path(){
	#Verfication de l'arbo du dossier minecraft
	 mkdir -p $minecraft_path $launcher_config_path $instances_path $mods_path $java_path $bin_path
}

check_config(){
	#telechargement et modification de la config
	local config="$launcher_config_path/prismlauncher.cfg"
	if [ ! -f "$config" ]; then
	   wget -q -P "$launcher_config_path/" $config_url
	   sed -i \
		   -e "s|DownloadsDir=|DownloadsDir=$downloads_path|" \
		   -e "s|InstanceDir=|InstanceDir=$instances_path|" \
		   -e "s|CentralModsDir=|CentralModsDir=$mods_path|" \
		   -e "s|JavaDir=|JavaDir=$java_path|" \
		   "$config"
	fi
}

add_to_dmenu() {
    # Ajoute le bin dans le PATH via dmenu_run
    sed -i "s|bindsym \$mod+d exec --no-startup-id dmenu_run|bindsym \$mod+d exec --no-startup-id PATH=$bin_path:\$PATH dmenu_run|" "$i3_config"
    echo "export PATH=$bin_path:\$PATH" >> "$HOME/.bashrc"
    source "$HOME/.bashrc"
    cp "$0" "$bin_path/minecraft-launcher"
    chmod +x "$bin_path/minecraft-launcher"
    #echo "Ajouté à dmenu !"
}

remove_all() {
    #echo "Suppression de Minecraft et du launcher..."
    rm -rf "$minecraft_path"
    sed -i "s|PATH=$bin_path:\$PATH||g" "$HOME/.bashrc"
    #echo "Suppression terminée."
}

update_script() {
    #echo "Mise à jour du script launcher.sh..."
    script_url="https://raw.githubusercontent.com/PixPix20/Minecraft-Installer/main/launcher.sh"
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
    # Récupère la version sur GitHub avec l'API
    remote_url="https://api.github.com/repos/PixPix20/Minecraft-Installer/releases/latest"
    version=$(curl -s $remote_url | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    echo "$version"
}

check_script_update() {
    local_version="$VERSION"
    remote_version=$(get_remote_version)

    if [ -z "$remote_version" ]; then
        echo "Impossible de récupérer la version distante."
        return 1
    fi

    echo "Version locale : $local_version"
    echo "Version distante : $remote_version"

    if [ 1 -eq "$(echo "${remote_version} > ${local_version}" | bc)" ]; then
        echo "Une nouvelle version du script est disponible."
        echo "Voulez-vous la mettre à jour ? [o/N]"
        read -r answer
        if [[ "$answer" =~ ^[Oo]$ ]]; then
            update_script
        else
            echo "Mise à jour annulée."
        fi
    else
        echo "Le script est à jour."
    fi
}

check_account(){
	#enregistrement du compte une fois connecte
	while [ ! -f "$launcher_local_files_path/accounts.json" ]; do
	      sleep 2
	done
	printf "Compte détécté, sauvegarde"
	cp $launcher_local_files_path/accounts.json $launcher_config_path
}

check_launcher(){
	#telechargement du launcher si inexistant
	if [ ! -f "$launcher_appimage" ]; then
    	   #echo "Téléchargement de $name..."
    	   mkdir -p "$(dirname "$launcher_appimage")"
    	   #curl -L -o "$launcher_appimage" "$launcher_url" #si wget ne marche pas, décommentez cette ligne et commentez l'autre
    	   wget -q -O "$launcher_appimage" "$launcher_url"
	   chmod +x "$launcher_appimage"
	fi
}
cop_files(){
	#deplacement des fichers de config et du compte dans le .local du launcher
	mkdir -p $launcher_local_files_path
	cp $launcher_config_path/* $launcher_local_files_path
}

start_launcher(){
	nix-shell -p appimage-run --run "appimage-run $launcher_appimage"
}

main() {
    if [ $# -eq 0 ]; then
        check_path
	    check_config
	    check_launcher
	    cop_files
	    check_account & start_launcher
		exit 0
    fi

    case "$1" in
        -i|--install)
            check_storage || exit 1
            check_path
            check_config
            check_launcher
            add_to_dmenu
            echo "Installation terminée."
            ;;
        -u|--update)
            check_script_update
            ;;
        -r|--remove)
            remove_all
            ;;
		-l|--launch)
			check_path
		    check_config
		    check_launcher
		    cop_files
		    check_account & start_launcher
			;;
        -ad|--add-dmenu)
            add_to_dmenu
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
