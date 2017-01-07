###
# Synchronisation des fichiers de configuration des packages
#  - PULL : Récupération depuis un serveur distant
#  - PUSH : Transfert vers un serveur de dépôt distant
# ==============================================================================
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
##



###
# Librairies
##
load 'utils/filesystem.sh'

ACTION=$1


###
# Affichage de l'aide
##
if [[ $# -lt 1 ]]; then
    Module.execute.usage "synccfg"
    die 1
fi


###
# Test des paramètres saisies
##
if [[ -z $OLIX_MODULE_DEBIAN_SYNC_SERVER ]]; then
    critical "Le paramètre de l'adresse du serveur est manquant"
fi
[[ -z $OLIX_MODULE_DEBIAN_SYNC_PORT ]] && OLIX_MODULE_DEBIAN_SYNC_PORT=22

if [[ "$ACTION" == "pull" ]]; then
    if [[ -z $OLIX_MODULE_DEBIAN_SYNC_PATH ]]; then
        critical "Le paramètre du dossier contenant la configuration du serveur est manquant"
    fi
fi


###
# Traitement
##
case $ACTION in
    push)
        olixmodule_debian_actions_synccfg_push
        ;;
    pull)
        olixmodule_debian_actions_synccfg_pull
        ;;
    *)  
        critical "Action \"${ACTION}\" inconnu"
        ;;
esac

case $? in
    0)  echo -e "${CVERT}Action terminée avec succès${CVOID}";;
    52) echo -e "${CJAUNE}Action abordée${CVOID}";;
    *)  echo -e "${CROUGE}Action terminée avec des erreurs${CVOID}"
        critical;;
esac
