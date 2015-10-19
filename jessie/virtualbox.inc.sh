###
# Installation des Tools pour VirtualBox
# ==============================================================================
# - Installation du noyau
# - Installation des tools
# ------------------------------------------------------------------------------
# virtualbox:
#    enabled: true|false
# ------------------------------------------------------------------------------
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
# @version 8 (jessie)
##


debian_include_title()
{
    echo
    echo -e "${CBLANC} Installation des Tools pour VirtualBox ${CVOID}"
    echo -e "-------------------------------------------------------------------------------"
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_include_main()
{
    logger_debug "debian_include_install (virtualbox, $1)"
    local ACTION=$1
    local SERVICE_ENABLED=$(yaml_getConfig "virtualbox.enabled")

    if [[ "${SERVICE_ENABLED}" != true ]]; then
        logger_warning "Service 'virtualbox' non activé"
        return 1
    fi

    case ${ACTION} in
        install)
            debian_include_install
            ;;
    esac
}


###
# Installation du service
##
debian_include_install()
{
    logger_debug "debian_include_install (virtualbox)"

    logger_info "Installation des packages necessaires à VirtualBox"
    #apt-get --yes install dkms build-essential linux-headers-$(uname -r)
    apt-get --yes install virtualbox-guest-utils
    [[ $? -ne 0 ]] && logger_critical "Impossible d'installer tous les packages"

    echo -en "Activer le partage automatique ${CJAUNE}[ENTER pour continuer] ?${CVOID} "; read REP
}
