###
# Parse les paramètres de la commandes en fonction des options
# ==============================================================================
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
##



###
# Parsing des paramètres
##
function olixmodule_debian_params_parse()
{
    debug "olixmodule_debian_params_parse ($@)"
    local ACTION=$1
    local PARAM

    shift
    while [[ $# -ge 1 ]]; do
        case $1 in
            --all)
                OLIX_MODULE_DEBIAN_PACKAGES_COMPLETE=true
                ;;
            --port=*)
                OLIX_MODULE_DEBIAN_SYNC_PORT=$(String.explode.value $1)
                ;;
            pull|push)
                ;;
            *)
                olixmodule_debian_params_get $1
                ;;
        esac
        shift
    done

    # Chemin de destination de la configuration
    [[ -z $OLIX_MODULE_DEBIAN_SYNC_PATH ]] && OLIX_MODULE_DEBIAN_SYNC_PATH=$(dirname $OLIX_MODULE_DEBIAN_CONFIG 2> /dev/null)
    [[ "$OLIX_MODULE_DEBIAN_SYNC_PATH" == "." ]] && OLIX_MODULE_DEBIAN_SYNC_PATH=""

    olixmodule_debian_params_debug $ACTION
}


###
# Fonction de récupération des paramètres
# @param $1 : Nom du paramètre
##
function olixmodule_debian_params_get()
{
    OLIX_MODULE_DEBIAN_PACKAGES="$OLIX_MODULE_DEBIAN_PACKAGES $1"
    [[ -z $OLIX_MODULE_DEBIAN_SYNC_SERVER ]] && OLIX_MODULE_DEBIAN_SYNC_SERVER=$1 && return
    [[ -z $OLIX_MODULE_DEBIAN_SYNC_PATH ]] && OLIX_MODULE_DEBIAN_SYNC_PATH=$1 && return
}


###
# Mode DEBUG
# @param $1 : Action du module
##
function olixmodule_debian_params_debug ()
{
    case $1 in
        install|config|savecfg)
            debug "OLIX_MODULE_DEBIAN_PACKAGES_COMPLETE=$OLIX_MODULE_DEBIAN_PACKAGES_COMPLETE"
            debug "OLIX_MODULE_DEBIAN_PACKAGES=$OLIX_MODULE_DEBIAN_PACKAGES"
            ;;
        synccfg|init)
            debug "OLIX_MODULE_DEBIAN_SYNC_PORT=$OLIX_MODULE_DEBIAN_SYNC_PORT"
            debug "OLIX_MODULE_DEBIAN_SYNC_SERVER=$OLIX_MODULE_DEBIAN_SYNC_SERVER"
            debug "OLIX_MODULE_DEBIAN_SYNC_PATH=$OLIX_MODULE_DEBIAN_SYNC_PATH"
            ;;
    esac
}
