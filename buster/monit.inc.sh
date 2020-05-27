###
# Installation et configuration de MONIT
# ==============================================================================
# - Installatio des paquets MONIT
# - Installation des fichiers de configuration
# ------------------------------------------------------------------------------
# monit:
#    enabled:
#    confd:   Liste des fichiers de conf des check
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
            echo -e "${CBLANC} Installation de MONIT ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        config)
            echo
            echo -e "${CBLANC} Configuration de MONIT ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        savecfg)
            echo -e "${CBLANC} Sauvegarde de la configuration de MONIT ${CVOID}"
            ;;
    esac
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_service_main()
{
    debug "debian_service_main (monit, $1)"

    if [[ "$(Yaml.get "monit.enabled")" != true ]]; then
        warning "Service 'monit' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname $OLIX_MODULE_DEBIAN_CONFIG)/monit"

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
    debug "debian_service_install (monit)"

    info "Installation des packages MONIT"
    apt-get --yes install monit
    [[ $? -ne 0 ]] && critical "Impossible d'installer les packages MONIT"
}


###
# Configuration du service
##
debian_service_config()
{
    debug "debian_service_config (monit)"
    local CONFD=$(Yaml.get "monit.confd")

    info "Effacement des fichiers déjà présents dans /etc/monit/conf.d"
    rm -f /etc/monit/conf.d/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    info "Mise en place des fichiers de conf dans /etc/monit/conf.d"
    for I in $CONFD; do
        Debian.fileconfig.install "${__PATH_CONFIG}/$I" "/etc/monit/conf.d/" \
            "Mise en place de ${CCYAN}$I${CVOID} vers /etc/monit/conf.d"
    done
}


###
# Redemarrage du service
##
debian_service_restart()
{
    debug "debian_service_restart (monit)"

    info "Redémarrage du service MONIT"
    systemctl restart monit
    [[ $? -ne 0 ]] && critical "Service MONIT NOT running"
}


###
# Sauvegarde de la configuration
##
debian_service_savecfg()
{
    debug "debian_service_savecfg (monit)"
    local CONFD=$(Yaml.get "monit.confd")

    for I in $CONFD; do
        Debian.fileconfig.save "/etc/monit/conf.d/$I" "${__PATH_CONFIG}/$I"
    done
}


###
# Synchronisation de la configuration
##
debian_service_synccfg()
{
    debug "debian_service_synccfg (monit)"
    local CONFD=$(Yaml.get "monit.confd")

    echo "monit"
    for I in $CONFD; do
       echo "monit/$I.conf"
    done
}
