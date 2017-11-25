###
# Initialisation du module
#  - Récupération des fichiers de configuration des packages
#  - Création du fichier de configuration
# ==============================================================================
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
##


###
# Librairies
##
load "utils/fileconfig.sh"
load "utils/filesystem.sh"


###
# Vérifie si l'initialisation a été effectuée
##
if [[ -n $OLIX_MODULE_DEBIAN_CONFIG ]]; then
    echo -e "${CJAUNE}La configuration du module a été déjà effectuée !!!${CVOID}"
    Read.confirm "Relancer à nouveau la réinitialisation de la configuration du module" false
    [[ $OLIX_FUNCTION_RETURN == false ]] && return 0
fi


###
# Demande pour la récupération de la configuration distante
##
OLIX_MODULE_DEBIAN_CONFIG=
OLIX_MODULE_DEBIAN_SYNC_PORT=
OLIX_MODULE_DEBIAN_SYNC_SERVER=
OLIX_MODULE_DEBIAN_SYNC_PATH=
olixmodule_debian_params_parse "init" $@
Fileconfig.param.set debian syncserver $OLIX_MODULE_DEBIAN_SYNC_SERVER || critical "Impossible d'écrire 'syncserver=$OLIX_MODULE_DEBIAN_SYNC_SERVER' dans le fichier debian.conf"
Fileconfig.param.set debian syncport $OLIX_MODULE_DEBIAN_SYNC_PORT || critical "Impossible d'écrire 'syncport=$OLIX_MODULE_DEBIAN_SYNC_PORT' dans le fichier debian.conf"

# Dossier de destination
if [[ -z $OLIX_MODULE_DEBIAN_SYNC_PATH ]]; then
    Read.directory "Dossier de destination où seront placés les fichiers de configuration des packages" "/root"
    OLIX_MODULE_DEBIAN_SYNC_PATH=$OLIX_FUNCTION_RETURN
fi
OLIX_MODULE_DEBIAN_SYNC_PATH=$OLIX_MODULE_DEBIAN_SYNC_PATH/debiancfg
[[ ! -d $OLIX_MODULE_DEBIAN_SYNC_PATH ]] && mkdir $OLIX_MODULE_DEBIAN_SYNC_PATH


###
# Chargement de la configuration du module suite au saisies précédentes
##
Config.load debian


###
# Synchronisation des fichiers de configuration
##
olixmodule_debian_actions_synccfg_pull


###
# Choix du fichier YML contenant la configuration complète des différents packages
##
Fileconfig.param.set debian configpath


echo -e "${CVERT}Action terminée avec succès${CVOID}"
