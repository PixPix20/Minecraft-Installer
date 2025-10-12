# Minecraft Installer Script

Ce script automatise l'installation et le lancement de PrismLauncher pour Minecraft sur le système AFS de l'école.

## Fonctionnalités
- Installation automatique de PrismLauncher dans `$HOME/afs/minecraft`
- Vérification de l'espace disque restant avant installation
- Configuration automatique des dossiers (instances, mods, java, etc.)
- Ajout du launcher au dmenu et au PATH
- Mise à jour du script possible
- Désinstallation complète
- Sauvegarde des comptes Minecraft

## Usage

```bash
./launcher.sh [option]
```

### Options principales

- `-i, --install` : Installe PrismLauncher
- `-l, --launch` : Lance PrismLauncher
- `-r, --remove` : Désinstalle PrismLauncher et ses fichiers
- `-u, --update` : Met à jour le script
- `-se, --show-env` : Affiche les chemins utilisés
- `-v, --version` : Affiche la version du script
- `-h, --help` : Affiche l’aide
- `--verbose` : Mode verbeux (affiche les étapes détaillées)

## Prérequis

- Système Linux compatible avec AppImage
- Commandes nécessaires : `wget`, `curl`, `sed`, `grep`, `nix-shell`, `bc`

## Sécurité/limitations

- **Le script vérifie que l’installation ne dépasse pas 2 Go d’espace sur l’AFS.**
- **Vérifie la présence des commandes nécessaires avant installation.**
- **Le script prend le moins de place possible.**

## Mise à jour

La mise à jour du script et de PrismLauncher se fait via les options `--update` et `--install`.

## Désinstallation

Supprime tous les fichiers liés à PrismLauncher sur ton espace AFS.

---

**Contact** : [GitHub PixPix20](https://github.com/PixPix20)  
**Auteur** : Lucas Morel
