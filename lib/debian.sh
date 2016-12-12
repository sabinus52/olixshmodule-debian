###
# Librairies de la gestion du module DEBIAN
# ==============================================================================
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
##



###
# Vérifie et charge le fichier de conf de la configuration du serveur
##
function Debian.config.load()
{
    debug "Debian.config.load ()"

    if [[ ! -r $OLIX_MODULE_DEBIAN_CONFIG ]]; then
        warning "${OLIX_MODULE_DEBIAN_CONFIG} absent"
        critical "Impossible de charger le fichier de configuration du serveur"
    fi

    info "Chargement du fichier '${OLIX_MODULE_DEBIAN_CONFIG}'"
    Yaml.parse "$OLIX_MODULE_DEBIAN_CONFIG" "OLIX_MODULE_DEBIAN_"
}


###
# Retroune le script du service à executer
# @param $1 : Nom du service
##
function Debian.service.script()
{
    echo -n "$OLIX_MODULE_PATH/debian/$OLIX_MODULE_DEBIAN_VERSION_RELEASE/$1.inc.sh"
}


###
# Excute une action sur le service
# @param $1 : nom du service
# @param $2 : action (install|config|save)
##
function Debian.service.execute()
{
    debug "Debian.service.execute ($1, $2)"
    local FILEEXEC=$(Debian.service.script $1)

    info "Chargement du fichier '$1.inc.sh' pour l'exécution de la tâche"
    if [[ ! -r $FILEEXEC ]]; then
        critical "Fichier introuvable : ${FILEEXEC}"
    fi
    source $FILEEXEC
    
    # Excution de la tâche
    if ! Function.exists "debian_service_$2"; then
        warning "Pas de tâche '$2' pour le service '$1'"
        return 1
    else
        debian_service_title $2
        debian_service_main $2
        return $?
    fi
}
