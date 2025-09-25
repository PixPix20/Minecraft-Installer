#!/bin/bash
set -euo pipefail

VERSION=1.0

#NOTES:
#Verification du stockage : OK
#creation des dossiers : OK
#creation de la config : OK
#creation du compte : NOK
#sys de deplacement des files : NOK
#sys de lancement/ telechargement du launcher : NOK

#On verifie qu'il y a assez de place pour installer minecraft en plus de garder un peu de place pour le reste
max_storage=2147483648 #2Go, le stockage max de l'afs, je deconseille fortement d'augmenter cette valeur !
used_storage=$(du -sb "$HOME/afs" | awk '{print $1}') #La taille actuelle de votre afs
minecraft_storage=943718400 #900Mo, j'utilise cette valeur si vous voulez jouer avec un modpack qui est lourd
margin_storage=419430400 #400Mo, marge de securité pour que vous puissiez utiliser l'afs aprés l'installation du jeu, je deconseille de modifier cette valeur

afs="$HOME/afs"

launcher_name="PrismLauncher"
minecraft_path="$afs/minecraft"
launcher_config_path="$minecraft_path/config"
instances_path="$minecraft_path/Instances"
mods_path="$minecraft_path/mods"
java_path="$minecraft_path/java"
downloads_path="$HOME/Downloads"
prismlocal_path="$HOME/.local/share/PrismLauncher"
appimage="$minecraft_path/PrismLauncher-Linux-x86_64.AppImage"
url="https://github.com/PrismLauncher/PrismLauncher/releases/download/9.4/PrismLauncher-Linux-x86_64.AppImage"

check_storage(){
	if [ $used_storage+$minecraftstorage+$margin_storage -gt "$max_storage" ]; then
    	   printf "Impossible d'installer minecraft, il n'y a pas assez de place."
    	   printf "\tEssayez de supprimer quelques fichiers, regardez dans les configuration (du -h --max-depth=1 ~/.confs) pour connaitre la taille des differentes configuration"
    	   printf "\tNote: Chez moi la configuration de Discord faisait plus de 700Mo et celle de Firefox plus de 600Mo"
	   return 1
	else
	   return 0
	fi
}

check_path(){
	#Verfication de l'arbo du dossier minecraft
	if [ -f "$minecraft_path"  ]; then
	   mkdir -p $minecraft_path $launcher_config_path $instances_path $mods_path $java_path
	else
	   if [ ! -f "$instances_path" ]; then
	      mkdir -p $instances_path
	   fi

           if [ ! -f "$mods_path" ]; then
	      mkdir -p $mods_path
	   fi

	   if [ ! -f "$java_path" ]; then
	      mkdir -p $java_path
	   fi

	   if [ ! -f "$launcher_config_path" ]; then
	      mkdir -p $launcher_config_path
	   fi

	   if [ ! -f "$downloads_path" ]; then
	      mkdir -p $downloads_path
	   fi
	fi
}

check_config(){
	if [ ! -f "launcher_config_path/prismlauncher.cfg" ]; then
	   curl -L -o "$launcher_config_path/" "https://github.com/PixPix20/Minecraft-Installer/blob/main/prismlauncher.cfg"
	   awk -F '=' -v varname=="DownloadsDir" -v varvalue="$downloads_path" '$1 == varname { $2 = "\""varvalue"\"" } { print }' "$launcher_config_path/prismlaucnher.cfg"
           awk -F '=' -v varname=="InstanceDir" -v varvalue="$instances_path" '$1 == varname { $2 = "\""varvalue"\"" } { print }' "$launcher_config_path/prismlaucnher.cfg"
           awk -F '=' -v varname=="CentralModsDir" -v varvalue="$mods_path" '$1 == varname { $2 = "\""varvalue"\"" } { print }' "$launcher_config_path/prismlaucnher.cfg"
           awk -F '=' -v varname=="JavaDir" -v varvalue="$java_path" '$1 == varname { $2 = "\""varvalue"\"" } { print }' "$launcher_config_path/prismlaucnher.cfg"
	fi
}

check_account(){
	#TODO: A voir
	while [ ! -f "$launcher_conig_path/accounts.sh" ]; do
	      sleep 2
	done
	cp $HOME/.local/share/PrismLauncher/accounts.json $launcher_config_path
}

check_launcher(){
	if [ ! -f "$appimage" ]; then
    	   echo "Téléchargement de PrismLauncher..."
    	   mkdir -p "$(dirname "$appimage")"
    	   curl -L -o "$appimage" "$url"
    	   chmod +x "$appimage"
	fi
}
cop_files(){
	if [ ! -f "$prismlocal_path" ]; then
	   mkdir -p $prismlocal_path
	fi
	cp $launcher_config_file/* $prismlocal_path
}
