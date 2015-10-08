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


debian_include_title()
{
    echo
    echo -e "${CBLANC} Mise à jour du système ${CVOID}"
    echo -e "-------------------------------------------------------------------------------"
}


###
# Mise à jour
##
debian_include_main()
{
    logger_debug "debian_include_main (update)"

    logger_info "Mise à jour des dépôts"
    apt-get update
    [[ $? -ne 0 ]] && logger_critical "Update des dépôts"

    logger_info "Mise à jour des packages"
    apt-get --yes upgrade
    [[ $? -ne 0 ]] && logger_critical "Update des packages"
}
