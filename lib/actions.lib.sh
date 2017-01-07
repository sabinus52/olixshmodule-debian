###
# Librairies des actions du module DEBIAN
# ==============================================================================
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
##



###
# Synchronisation de la configuration des packages par l'action PULL
##
function olixmodule_debian_actions_synccfg_pull()
{
    debug "olixmodule_debian_actions_synccfg_pull ()"

    echo -e "${CBLANC}Récupérer la configuration${CVOID} depuis le serveur ${CCYAN}$OLIX_MODULE_DEBIAN_SYNC_SERVER${CVOID} vers ${CCYAN}${OLIX_MODULE_DEBIAN_SYNC_PATH}${CVOID}"
    Read.confirm "Continuer la récupération de la config" false
    [[ $OLIX_FUNCTION_RETURN == false ]] && return 52

    Filesystem.synchronize $OLIX_MODULE_DEBIAN_SYNC_PORT $OLIX_MODULE_DEBIAN_SYNC_SERVER $OLIX_MODULE_DEBIAN_SYNC_PATH
    return $?
}


###
# Synchronisation de la configuration des packages par l'action PUSH
##
function olixmodule_debian_actions_synccfg_push()
{
    debug "olixmodule_debian_actions_synccfg_push ()"
    local PACKAGE J FILE_INCLUDE FILES RET PARAM

    echo -e "${CBLANC}Pousser la configuration${CVOID} de ${CCYAN}${OLIX_MODULE_DEBIAN_SYNC_PATH}${CVOID} vers le serveur ${CCYAN}${OLIX_MODULE_DEBIAN_SYNC_SERVER}${CVOID}"
    Read.confirm "Continuer le traitement (savecfg + push)" false
    [[ $OLIX_FUNCTION_RETURN == false ]] && return 52

    # Charge le fichier de configuration contenant les paramètes necessaires à l'installation
    Debian.config.load

    # Création du fichier include contenant les fichiers à synchroniser
    FILE_INCLUDE=$(System.file.temp)
    echo "+ $(basename $OLIX_MODULE_DEBIAN_CONFIG)" > $FILE_INCLUDE

    # Pour chaque package
    for PACKAGE in $OLIX_MODULE_DEBIAN_PACKAGES_SAVECFG; do
        info "Sauvegarde de la configuration de '${PACKAGE}'"
        Debian.service.execute $PACKAGE "savecfg"

        FILES=$(Debian.service.execute $PACKAGE synccfg)
        for J in $FILES; do
            echo "+ $J" >> $FILE_INCLUDE
        done
        
    done
    echo "- *" >> $FILE_INCLUDE

    echo -e "${CBLANC} Synchronisation des fichiers de configuration vers le serveur ${CCYAN}${OLIX_MODULE_DEBIAN_SYNC_SERVER}${CVOID}"

    [[ $OLIX_OPTION_VERBOSE == true ]] && PARAM="--progress --stats"
    rsync $PARAM --rsh="ssh -p $OLIX_MODULE_DEBIAN_SYNC_PORT" --archive --compress --include-from=$FILE_INCLUDE $OLIX_MODULE_DEBIAN_SYNC_PATH/ $OLIX_MODULE_DEBIAN_SYNC_SERVER/ 2> ${OLIX_LOGGER_FILE_ERR}
    RET=$?

    rm -f $FILE_INCLUDE
    return $RET
}
