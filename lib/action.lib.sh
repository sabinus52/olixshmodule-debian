###
# Librairies des actions du module DEBIAN
# ==============================================================================
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
##



###
# Initialisation du module en créant le fichier de configuration
##
function module_debian_action_init()
{
    logger_debug "module_debian_action_init ($@)"
    local FILECONF=$(config_getFilenameModule ${OLIX_MODULE_NAME})

    if [[ ! -f ${FILECONF} ]]; then
        echo -e "${CJAUNE}Avant l'initialisation, il faut que la configuration du serveur soit présente${CVOID}"
        echo -e " 1. Installer les fichiers de configuration"
        echo -e "        via la commande ${Ccyan}olixsh debian synccfg pull <user>@<host>:/<path> <destination>${CVOID}"
        echo -e " 2. Initialiser le module"
        echo -e "        avec la commande ${Ccyan}olixsh debian init${CVOID}"
        stdin_readYesOrNo "Continuer l'initialisation du module" false
        [[ ${OLIX_STDIN_RETURN} == false ]] && return 0
    fi

    # Demande du fichier de paramètre
    stdin_readFile "Chemin complet du fichier contenant la configuration de l'installation du serveur" "${OLIX_MODULE_DEBIAN_CONFIG}"
    logger_debug "OLIX_MODULE_DEBIAN_CONFIG=${OLIX_STDIN_RETURN}"
    OLIX_MODULE_DEBIAN_CONFIG=${OLIX_STDIN_RETURN}
    stdin_read "Adresse du serveur source de la configuration [user]@[host]:/[path]" "${OLIX_MODULE_DEBIAN_SYNC_SERVER}"
    logger_debug "OLIX_MODULE_DEBIAN_SYNC_SERVER=${OLIX_STDIN_RETURN}"
    OLIX_MODULE_DEBIAN_SYNC_SERVER=${OLIX_STDIN_RETURN}
    stdin_read "Port du serveur source de la configuration" "${OLIX_MODULE_DEBIAN_SYNC_PORT}"
    logger_debug "OLIX_MODULE_DEBIAN_SYNC_PORT=${OLIX_STDIN_RETURN}"
    OLIX_MODULE_DEBIAN_SYNC_PORT=${OLIX_STDIN_RETURN}
   
    # Ecriture du fichier de configuration
    logger_info "Création du fichier de configuration ${FILECONF}"
    echo "# Fichier de configuration pour l'install de DEBIAN" > ${FILECONF}
    [[ $? -ne 0 ]] && logger_critical
    echo "OLIX_MODULE_DEBIAN_CONFIG=${OLIX_MODULE_DEBIAN_CONFIG}" >> ${FILECONF}
    echo "OLIX_MODULE_DEBIAN_SYNC_SERVER=${OLIX_MODULE_DEBIAN_SYNC_SERVER}" >> ${FILECONF}
    echo "OLIX_MODULE_DEBIAN_SYNC_PORT=${OLIX_MODULE_DEBIAN_SYNC_PORT}" >> ${FILECONF}

    echo -e "${Cvert}Action terminée avec succès${CVOID}"
    return 0
}
