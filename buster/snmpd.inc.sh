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


debian_service_title()
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
debian_service_main()
{
    debug "debian_service_main (snmpd, $1)"

    if [[ "$(Yaml.get "snmpd.enabled")" != true ]]; then
        warning "Service 'snmpd' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname $OLIX_MODULE_DEBIAN_CONFIG)/snmpd"

    case $1 in
        install)
            debian_service_install
            debian_service_config
            debian_service_restart
            ;;
        config)
            debian_service_config
            debian_service_restart
            ;;
        restart)
            debian_service_restart
            ;;
        savecfg)
            debian_service_savecfg
            ;;
        synccfg)
            debian_service_synccfg
            ;;
    esac
}


###
# Installation du service
##
debian_service_install()
{
    debug "debian_service_install (snmpd)"

    info "Installation des packages SNMPD"
    apt-get --yes install snmp snmpd
    [[ $? -ne 0 ]] && critical "Impossible d'installer les packages SNMPD"
}


###
# Configuration du service
##
debian_service_config()
{
    debug "debian_service_config (snmpd)"
    local FILECFG=$(Yaml.get "snmpd.filecfg")

    Debian.fileconfig.keep "/etc/snmp/snmpd.conf"
    Debian.fileconfig.install "${__PATH_CONFIG}/$FILECFG" "/etc/snmp/snmpd.conf" \
        "Mise en place de ${CCYAN}${FILECFG}${CVOID} vers /etc/snmp/snmpd.conf"
}


###
# Redemarrage du service
##
debian_service_restart()
{
    debug "debian_service_restart (snmpd)"

    info "Redémarrage du service SNMPD"
    systemctl restart snmpd
    [[ $? -ne 0 ]] && critical "Service SNMPD NOT running"
}


###
# Sauvegarde de la configuration
##
debian_service_savecfg()
{
    debug "debian_service_savecfg (snmpd)"
    local FILECFG=$(Yaml.get "snmpd.filecfg")

    Debian.fileconfig.save "/etc/snmp/snmpd.conf" "${__PATH_CONFIG}/$FILECFG"
}


###
# Synchronisation de la configuration
##
debian_service_synccfg()
{
    debug "debian_service_synccfg (snmpd)"
    local FILECFG=$(Yaml.get "snmpd.filecfg")

    echo "snmpd"
    echo "snmpd/$FILECFG"
}
