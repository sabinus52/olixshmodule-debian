###
# Installation et configuration de SNMPD
# ==============================================================================
# - Installation des paquets SNMPD
# - Installation des fichiers de configuration
# ------------------------------------------------------------------------------
# snmpd:
#    enabled:
#    filecfg: Fichier snmpd.conf à utiliser
# ------------------------------------------------------------------------------
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
# @version 8 (jessie)
##


debian_include_title()
{
    case $1 in
        install)
            echo
            echo -e "${CBLANC} Installation de SNMPD ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        config)
            echo
            echo -e "${CBLANC} Configuration de SNMPD ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        savecfg)
            echo -e "${CBLANC} Sauvegarde de la configuration de SNMPD ${CVOID}"
            ;;
    esac
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_include_main()
{
    logger_debug "debian_include_main (snmpd, $1)"

    if [[ "$(yaml_getConfig "snmpd.enabled")" != true ]]; then
        logger_warning "Service 'snmpd' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname ${OLIX_MODULE_DEBIAN_CONFIG})/snmpd"

    case $1 in
        install)
            debian_include_install
            debian_include_config
            debian_include_restart
            ;;
        config)
            debian_include_config
            debian_include_restart
            ;;
        restart)
            debian_include_restart
            ;;
        savecfg)
            debian_include_savecfg
            ;;
        synccfg)
            debian_include_synccfg
            ;;
    esac
}


###
# Installation du service
##
debian_include_install()
{
    logger_debug "debian_include_install (snmpd)"

    logger_info "Installation des packages SNMPD"
    apt-get --yes install snmp snmpd
    [[ $? -ne 0 ]] && logger_critical "Impossible d'installer les packages SNMPD"
}


###
# Configuration du service
##
debian_include_config()
{
    logger_debug "debian_include_config (snmpd)"
    local FILECFG=$(yaml_getConfig "snmpd.filecfg")

    module_debian_backupFileOriginal "/etc/snmp/snmpd.conf"
    module_debian_installFileConfiguration "${__PATH_CONFIG}/${FILECFG}" "/etc/snmp/snmpd.conf" \
        "Mise en place de ${CCYAN}${FILECFG}${CVOID} vers /etc/snmp/snmpd.conf"
}


###
# Redemarrage du service
##
debian_include_restart()
{
    logger_debug "debian_include_restart (snmpd)"

    logger_info "Redémarrage du service SNMPD"
    systemctl restart snmpd
    [[ $? -ne 0 ]] && logger_critical "Service SNMPD NOT running"
}


###
# Sauvegarde de la configuration
##
debian_include_savecfg()
{
    logger_debug "debian_include_savecfg (snmpd)"
    local FILECFG=$(yaml_getConfig "snmpd.filecfg")

    module_debian_backupFileConfiguration "/etc/snmp/snmpd.conf" "${__PATH_CONFIG}/${FILECFG}"
}


###
# Synchronisation de la configuration
##
debian_include_synccfg()
{
    logger_debug "debian_include_synccfg (snmpd)"
    local FILECFG=$(yaml_getConfig "snmpd.filecfg")

    echo "snmpd"
    echo "snmpd/${FILECFG}"
}
