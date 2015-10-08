###
# Librairies de la gestion des serveurs DEBIAN
# ==============================================================================
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
##


###
# Vérifie et charge le fichier de conf de la configuration du serveur
##
function module_debian_loadConfiguration()
{
    logger_debug "module_debian_loadConfiguration ()"
    local FILECFG="${OLIX_MODULE_DEBIAN_CONFIG}"

    if [[ ! -r ${FILECFG} ]]; then
        logger_warning "${FILECFG} absent"
        logger_critical "Impossible de charger le fichier de configuration du serveur"
    fi

    logger_info "Chargement du fichier '${FILECFG}'"
    yaml_parseFile "${FILECFG}" "OLIX_MODULE_DEBIAN_"
}


###
# Excute une action sur le service
# @param $1 : action (install|config|save)
# @param $2 : nom du package
##
function module_debian_executeService()
{
    logger_debug "module_debian_executeService ($1, $2)"
    local FILEEXEC=${OLIX_MODULE_DIR}/${OLIX_MODULE_NAME}/${OLIX_MODULE_DEBIAN_VERSION_RELEASE}/$2.inc.sh

    logger_info "Chargement du fichier '$2.inc.sh' pour l'exécution de la tâche"
    if [[ ! -r ${FILEEXEC} ]]; then
        logger_critical "Fichier introuvable : ${FILEEXEC}"
    fi
    source ${FILEEXEC}
    
    if ! type "debian_include_$1" >/dev/null 2>&1; then
        logger_warning "Pas de tâche '$1' pour le service '$2'"
        return 1
    else
        debian_include_title $1
        debian_include_main $1
        return $?
    fi
}


###
# Sauvegarde le fichier de configuration original
# @param $1 : Fichier à conserver
##
function module_debian_backupFileOriginal()
{
    logger_debug "module_debian_backupFileOriginal ($1)"
    local ORIGINAL="$1.original"

    if [[ ! -f ${ORIGINAL} ]]; then
        logger_info "Sauvegarde de l'original '$1'"
        cp $1 ${ORIGINAL} > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical "Impossible de sauvegarder '$1'"
    fi

    logger_info "Effacement de l'ancien fichier '$1'"
    rm -f $1 > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical "Impossible d'effacer '$1'"

    logger_info "Remise de l'original du fichier '$1'"
    cp ${ORIGINAL} $1 > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical "Impossible de remettre l'original '$1'"
}


###
# Installe un fichier de configuration dans son emplacement
# @param $1 : Fichier de configuration à lier
# @param $2 : Lien de destination
# @param $3 : Message
##
function module_debian_installFileConfiguration()
{
    logger_debug "module_debian_installFileConfiguration ($1, $2, $3)"
    local MODE_CONFIG=$(yaml_getConfig "parameters.mode_config")

    # Si on ne choisit pas le mode par lien symbolique
    if [[ "${MODE_CONFIG}" == "symlink" ]]; then
        filesystem_linkNodeConfiguration "$1" "$2"
    else
        filesystem_copyFileConfiguration "$1" "$2"
    fi
    [[ ! -z $3 ]] && echo -e "$3 : ${CVERT}OK ...${CVOID}"
    return 0
}
