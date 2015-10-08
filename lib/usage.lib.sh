###
# Usage du module DEBIAN
# ==============================================================================
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
##


###
# Usage principale du module
##
function module_debian_usage_main()
{
    logger_debug "module_debian_usage_main ()"
    stdout_printVersion
    echo
    echo -e "Installation, configuration et gestion d'un serveur DEBIAN ${CBLANC}$(lsb_release -sr) (${OLIX_MODULE_DEBIAN_VERSION_RELEASE})${CVOID}"
    echo
    echo -e "${CBLANC} Usage : ${CVIOLET}$(basename ${OLIX_ROOT_SCRIPT}) ${CVERT}debian ${CJAUNE}<action>${CVOID}"
    echo
    echo -e "${CJAUNE}Liste des ACTIONS disponibles${CVOID} :"
    echo -e "${Cjaune} init    ${CVOID}  : Initialisation du module"
    echo -e "${Cjaune} synccfg ${CVOID}  : Synchronisation de la configuration actuelle vers un autre serveur"
    echo -e "${Cjaune} help    ${CVOID}  : Affiche cet écran"
}


###
# Usage de l'action SYNCCFG
##
function module_debian_usage_synccfg()
{
    logger_debug "module_debian_usage_synccfg ()"
    stdout_printVersion
    echo
    echo -e "Synchronisation de la configuration des services avec un autre serveur${CVOID}"
    echo
    echo -e "Récupère la configuration depuis un autre serveur"
    echo -e "${CBLANC} Usage : ${CVIOLET}$(basename ${OLIX_ROOT_SCRIPT}) ${CVERT}debian ${CJAUNE}synccfg${CVOID} ${CBLANC}pull [<user>@<host>:/<path>] [PATH CONFIG] [OPTIONS]${CVOID}"
    echo
    echo -e "Pousse la configuration vers un autre serveur"
    echo -e "${CBLANC} Usage : ${CVIOLET}$(basename ${OLIX_ROOT_SCRIPT}) ${CVERT}debian ${CJAUNE}synccfg${CVOID} ${CBLANC}push [<user>@<host>:/<path>] [OPTIONS]${CVOID}"
    echo
    echo -e "${CJAUNE}Liste des OPTIONS disponibles${CVOID} :"
    echo -e "${Cjaune} --port=22  ${CVOID} : Port du serveur"
    echo -e "${Cjaune} help       ${CVOID} : Affiche cet écran"
}


###
# Retourne les paramètres de la commandes en fonction des options
# @param $@ : Liste des paramètres
##
function module_debian_usage_getParams()
{
    logger_debug "module_debian_usage_getParams ($@)"
    local PARAM

    while [[ $# -ge 1 ]]; do
        case $1 in
            --all)
                OLIX_MODULE_DEBIAN_PACKAGES_COMPLETE=true
                ;;
            --port=*)
                IFS='=' read -ra PARAM <<< "$1"
                OLIX_MODULE_DEBIAN_SYNC_PORT=${PARAM[1]}
                ;;
            *)
                OLIX_MODULE_DEBIAN_PACKAGES="${OLIX_MODULE_DEBIAN_PACKAGES} $1"
                ;;
        esac
        shift
    done
    logger_debug "OLIX_MODULE_DEBIAN_PACKAGES_COMPLETE=${OLIX_MODULE_DEBIAN_PACKAGES_COMPLETE}"
    logger_debug "OLIX_MODULE_DEBIAN_PACKAGES=${OLIX_MODULE_DEBIAN_PACKAGES}"
}
