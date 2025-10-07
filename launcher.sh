#!/usr/bin/env bash
set -euo pipefail

VERSION=1.1

#On verifie qu'il y a assez de place pour installer minecraft en plus de garder un peu de place pour le reste
#STOCKAGE
max_storage=2147483648 #2Go, le stockage max de l'afs, je deconseille fortement d'augmenter cette valeur !
minecraft_storage=943718400 #900Mo, j'utilise cette valeur si vous voulez jouer avec un modpack qui est lourd
margin_storage=419430400 #400Mo, marge de securité pour que vous puissiez utiliser l'afs aprés l'installation du jeu, je deconseille de modifier cette valeur

#AFS
afs="$HOME/afs"

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

check_storage(){
	#verification si l'AFS peut installer minecraft en plus de garder un marge pour les autre fichiers
	local used_storage total_storage
	used_storage=$(de -sb "$afs"|awk '{print $1}')
        total_storage=$((used_storage + minecraft_storage + margin_storage)) #On additionne le stockage déja utilisé, la taille (~) de MC puis on ajoute une marge de secu.
	
}

check_patr(){
	#Verfication de l'arbo du dossier minecraft
	 mkdir -p $minecraft_path $launcher_config_path $instances_path $mods_path $java_path $bin_path
}

check_config(){
	#telechargement et modification de la config
	local config="$launcher_config_path/primslauncher.cfg"
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

check_account(){
	#enregistrement du compte une fois connecte
	while [ ! -f "$prismlocal_path/accounts.json" ]; do
	      sleep 2
	done
	printf "Compte détécté, sauvegarde"
	cp $prismlocal_path/accounts.json $launcher_config_path
}

check_launcher(){
	#telechargement du launcher si inexistant
	if [ ! -f "$launcher_appimage" ]; then
    	   echo "Téléchargement de $name..."
    	   mkdir -p "$(dirname "$launcher_appimage")"
    	   #curl -L -o "$launcher_appimage" "$launcher_url" #si wget ne marche pas, décommentez cette ligne et commentez l'autre
    	   wget -q -O "$launcher_appimage" "$launcher_url"
	   chmod +x "$launcher_appimage"
	fi
}
cop_files(){
	#deplacement des fichers de config et du compte dans le .local du launcher
	mkdir -p $prism_local_files_path
	cp $launcher_config_path/* $prism_local_files_path
}

start_launcher(){
	nix-shell -p appimage-run --run "appimage-run $launcher_appimage"
}

setup(){ #Configure i3 pour l'ajouter le launcher dans dmenu_run
#archi
#$HOME/afs/.confs/config/i3/config
#apres bindsym $mod+d exec --no-startup-id PATH=$HOME/afs/minecraft/bin:$PATH  dmenu_run
#avant bindsym $mod+d exec --no-startup-id dmenu_run
	sed -i "s|bindsym $mod+d exec --no-startup-id|bindsym $mod+d exec --no-startup-id PATH=$HOME/afs/minecraft:$PATH|" "$HOME/afs/.confs/config/i3/config"
#revoir la modif de ligne, trouver un truc plus opti (sed)

	echo "export PATH=$HOME/afs/minecraft/bin:$PATH" >> $HOME/.bashrc
	source .bashrc
	mv $(pwd)/launcher.sh $bin_path
}


start() {
	check_path
	check_config
	check_launcher
	start_launcher & check_account

}
if [ $# -eq 0 ]; then 
   start

elif [ $1 = -i ]; then 
     if [ check_storage = false ]; then 
	exit 0
     else start
     fi
fi
