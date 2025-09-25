#!/bin/bash
set -euo pipefail

VERSION=1.0

#NOTES:
#Verification du stockage : OK
#creation des dossiers : OK
#creation de la config : OK
#creation du compte : OK mais A VOIR
#sys de deplacement des files : OK
#sys de lancement: OK
#telechargement du launcher : OK

#On verifie qu'il y a assez de place pour installer minecraft en plus de garder un peu de place pour le reste
max_storage=2147483648 #2Go, le stockage max de l'afs, je deconseille fortement d'augmenter cette valeur !
used_storage=$(du -sb "$HOME/afs" | awk '{print $1}') #La taille actuelle de votre afs
minecraft_storage=943718400 #900Mo, j'utilise cette valeur si vous voulez jouer avec un modpack qui est lourd
margin_storage=419430400 #400Mo, marge de securité pour que vous puissiez utiliser l'afs aprés l'installation du jeu, je deconseille de modifier cette valeur
afs="$HOME/afs"
launcher_name="PrismLauncher"
minecraft_path="$afs/minecraft" #dossier qui contient minecraft la conf du launcher etc
launcher_config_path="$minecraft_path/config" #dossier qui contient les configurations du launcher
instances_path="$minecraft_path/Instances" #dossier qui contient les instances minecraft
mods_path="$minecraft_path/mods" #Dossier qui contient les mods minecraft
java_path="$minecraft_path/java" #Dossier qui contient java(installe auto)
downloads_path="$HOME/Downloads"
prismlocal_path="$HOME/.local/share/PrismLauncher"
appimage="$minecraft_path/PrismLauncher-Linux-x86_64.AppImage" #Dossier sense contenir le .appimage du launcher
url="https://github.com/PrismLauncher/PrismLauncher/releases/download/9.4/PrismLauncher-Linux-x86_64.AppImage" #URL du github pour telecharger le launcher

total=$(($used_storage+$minecraft_storage+$margin_storage))
check_storage(){ #VALIDE
if [  $total-gt$max_storage ]; then
    	   printf "Impossible d'installer minecraft, il n'y a pas assez de place."
    	   printf "\n\tEssayez de supprimer quelques fichiers, regardez dans les configuration (du -h --max-depth=1 ~/.confs) pour connaitre la taille des differentes configuration"
    	   printf "\n\tNote: Chez moi la configuration de Discord faisait plus de 700Mo et celle de Firefox plus de 600Mo"
	   return 1
	else
	   return 0
	fi
}

check_path(){ #VALIDE
	#Verfication de l'arbo du dossier minecraft
	if [ ! -f "$minecraft_path"  ]; then
	   mkdir $minecraft_path $launcher_config_path $instances_path $mods_path $java_path

	else
	   if [ ! -f "$instances_path" ]; then
	      mkdir $instances_path
	   fi

           if [ ! -f "$mods_path" ]; then
	      mkdir $mods_path
	   fi

	   if [ ! -f "$java_path" ]; then
	      mkdir $java_path
	   fi

	   if [ ! -f "$launcher_config_path" ]; then
	      mkdir $launcher_config_path
	   fi

	   if [ ! -f "$downloads_path" ]; then
	      mkdir $downloads_path
	   fi
	fi
}

check_config(){ #VALIDE
	if [ ! -f "launcher_config_path/prismlauncher.cfg" ]; then
	   wget -P "$launcher_config_path/" "https://raw.githubusercontent.com/PixPix20/Minecraft-Installer/refs/heads/main/prismlauncher.cfg"
	   sed -i "s|DownloadsDir=|DownloadsDir=$downloads_path|" $launcher_config_path/prismlauncher.cfg
	   sed -i "s|InstanceDir=|InstanceDir=$instances_path|" $launcher_config_path/prismlauncher.cfg
	   sed -i "s|CentralModsDir=|CentralModsDir=$mods_path|" $launcher_config_path/prismlauncher.cfg
	   sed -i "s|JavaDir=|JavaDir=$java_path|" $launcher_config_path/prismlauncher.cfg
fi
}

check_account(){
	#TODO: A voir
	while [ ! -f "$launcher_config_path/accounts.sh" ]; do
	      sleep 2
	done
	cp $HOME/.local/share/PrismLauncher/accounts.json $launcher_config_path
}

check_launcher(){ #VALIDE
	if [ ! -f "$appimage" ]; then
    	   echo "Téléchargement de PrismLauncher..."
    	   mkdir -p "$(dirname "$appimage")"
    	   #curl -L -o "$appimage" "$url"
    	   wget -P "$appimage" "$url"
chmod +x "$appimage"
	fi
}
cop_files(){ #VALIDE
	if [ ! -f "$prismlocal_path" ]; then
	   mkdir -p $prismlocal_path
	fi
	cp $launcher_config_path/* $prismlocal_path
}

start_launcher(){
	nix-shell -p appimage-run --run "appimage-run $appimage"
}

#installation
#check_storage
check_path
check_config
cop_files
check_launcher
echo fin
start_launcher && check_account # doit se faire en para
