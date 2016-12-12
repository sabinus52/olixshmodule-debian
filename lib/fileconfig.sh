###
# Utilitaires pour la gestion des fichiers ce configuration des paquets
# ==============================================================================
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
##



###
# Sauvegarde le fichier de configuration original et restaure l'ancien pour modification
# @param $1 : Fichier à conserver
##
function Debian.fileconfig.keep()
{
    Debian.fileconfig.backup $1
    Debian.fileconfig.restore $1
}


###
# Sauvegarde le fichier de configuration original
# @param $1 : Fichier à conserver
##
function Debian.fileconfig.backup()
{
    debug "Debian.fileconfig.backup ($1)"
    local ORIGINAL="$1.original"

    if [[ ! -f $ORIGINAL ]]; then
        info "Sauvegarde de l'original '$1'"
        cp $1 $ORIGINAL > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical "Impossible de sauvegarder '$1'"
    fi
}


###
# Restaure le fichier de configuration original
# @param $1 : Fichier à restaurer
##
function Debian.fileconfig.restore()
{
    debug "Debian.fileconfig.restore ($1)"
    local ORIGINAL="$1.original"

    if [[ ! -f $ORIGINAL ]]; then
        warning "Le fichier original de '$1' est absent"
        return
    fi

    info "Effacement de l'ancien fichier '$1'"
    rm -f $1 > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical "Impossible d'effacer '$1'"

    info "Remise de l'original du fichier '$1'"
    cp $ORIGINAL $1 > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical "Impossible de remettre l'original '$1'"
}



###
# Installe un fichier de configuration dans son emplacement
# @param $1 : Fichier de configuration à lier
# @param $2 : Lien de destination
# @param $3 : Message
##
function Debian.fileconfig.install()
{
    debug "Debian.fileconfig.install ($1, $2, $3)"
    local MODE_CONFIG=$(Yaml.get "parameters.mode_config")

    [[ ! -f $1 ]] && critical "Le fichier '$1' n'existe pas"

    # Si on ne choisit pas le mode par lien symbolique
    if [[ "$MODE_CONFIG" == "symlink" ]]; then
        File.link "$1" "$2"
    else
        File.copy "$1" "$2"
    fi
    [[ $? -ne 0 ]] && critical "Impossible de copier le fichier de configuration '$1' dans '$2'"
    [[ ! -z $3 ]] && echo -e "$3 : ${CVERT}OK ...${CVOID}"
    return 0
}


###
# Sauvegarde d'un fichier de configuration dans son emplacement d'origine
# @param $1 : Fichier de configuration à sauvegarder
# @param $2 : Fichier ou dossier d'origine
##
function Debian.fileconfig.save()
{
    debug "Debian.fileconfig.save ($1, $2)"
    [[ ! -f $1 ]] && critical "Le fichier '$1' n'existe pas"
    if [[ -L $1 ]]; then
        warning "Sauvegarde inutile $1 : lien symbolique"
        return 0
    fi
    debug "cp $1 $2"
    cp $1 $2 > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    local OWNER=$(File.owner $OLIX_MODULE_DEBIAN_CONFIG)
    local GROUP=$(File.group $OLIX_MODULE_DEBIAN_CONFIG)
    debug "chown -R ${OWNER}.${GROUP} $2"
    chown -R $OWNER.$GROUP $2 > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    echo -e "Sauvegarde de $1 : ${CVERT}OK ...${CVOID}"
    return 0
}
