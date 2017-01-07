###
# Mise à jour du système
# ==============================================================================
# - Update des sources
# - Upgrade des packages
# ------------------------------------------------------------------------------
# @package olixsh
# @module debian
# @action install update
# @author Olivier <sabinus52@gmail.com>
##


debian_service_title()
{
    echo
    echo -e "${CBLANC} Mise à jour du système ${CVOID}"
    echo -e "-------------------------------------------------------------------------------"
}


###
# Mise à jour
##
debian_service_main()
{
    debug "debian_service_main (update)"

    info "Mise à jour des dépôts"
    apt-get update
    [[ $? -ne 0 ]] && critical "Update des dépôts"

    info "Mise à jour des packages"
    apt-get --yes upgrade
    [[ $? -ne 0 ]] && critical "Update des packages"
}
