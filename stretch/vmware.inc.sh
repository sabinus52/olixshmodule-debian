###
# Installation des Tools pour VMware
# ==============================================================================
# - Installation du noyau
# - Installation des tools
# ------------------------------------------------------------------------------
# vmware:
#    enabled:
# ------------------------------------------------------------------------------
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
# @version 8 (jessie)
##


debian_service_title()
{
    echo
    echo -e "${CBLANC} Installation des Tools pour VMware ${CVOID}"
    echo -e "-------------------------------------------------------------------------------"
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_service_main()
{
    debug "debian_service_install (vmware, $1)"
    local ACTION=$1

    if [[ "$(Yaml.get "vmware.enabled")" != true ]]; then
        warning "Service 'vmware' non activé"
        return 1
    fi

    # Vérifie si les tools ont été déjà installé
    if [[ -f /usr/bin/vmware-config-tools.pl ]]; then
        warning "VMware Tools déjà installés"
    fi

    debian_service_install
}


###
# Installation du service
##
debian_service_install()
{
    debug "debian_service_install (vmware)"

    info "Installation des packages necessaires à VMware"
    #apt-get --yes install dkms build-essential linux-headers-$(uname -r)
    apt-get --yes install open-vm-tools
    [[ $? -ne 0 ]] && critical "Impossible d'installer tous les packages"
}
