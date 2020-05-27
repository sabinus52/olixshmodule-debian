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


debian_service_title()
{
    echo
    echo -e "${CBLANC} Installation des Tools pour VirtualBox ${CVOID}"
    echo -e "-------------------------------------------------------------------------------"
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_service_main()
{
    debug "debian_service_install (virtualbox, $1)"
    local ACTION=$1
    local SERVICE_ENABLED=$(Yaml.get "virtualbox.enabled")

    if [[ "$SERVICE_ENABLED" != true ]]; then
        warning "Service 'virtualbox' non activé"
        return 1
    fi

    case $ACTION in
        install)
            debian_service_install
            ;;
    esac
}


###
# Installation du service
##
debian_service_install()
{
    debug "debian_service_install (virtualbox)"

    info "Installation des packages necessaires à VirtualBox"
    apt-get --yes install dkms linux-headers-$(uname -r) build-essential
    [[ $? -ne 0 ]] && critical "Impossible d'installer tous les packages"
    echo -en "Activer l'installation des Additions Invités ${CJAUNE}[ENTER pour continuer] ?${CVOID} "; read REP
    mount /media/cdrom
    [[ $? -ne 0 ]] && critical "Impossible de monter le CD"
    sh /media/cdrom/VBoxLinuxAdditions.run --nox11
    [[ $? -ne 0 ]] && critical "Erreur de sortie du script VBoxLinuxAdditions.run"

    echo -en "Activer le partage automatique ${CJAUNE}[ENTER pour continuer] ?${CVOID} "; read REP
}
