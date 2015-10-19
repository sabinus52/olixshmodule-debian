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


debian_include_title()
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
debian_include_main()
{
    logger_debug "debian_include_main (monit, $1)"

    if [[ "$(yaml_getConfig "monit.enabled")" != true ]]; then
        logger_warning "Service 'monit' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname ${OLIX_MODULE_DEBIAN_CONFIG})/monit"

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
    logger_debug "debian_include_install (monit)"

    logger_info "Installation des packages MONIT"
    apt-get --yes install monit
    [[ $? -ne 0 ]] && logger_critical "Impossible d'installer les packages MONIT"
}


###
# Configuration du service
##
debian_include_config()
{
    logger_debug "debian_include_config (monit)"
    local CONFD=$(yaml_getConfig "monit.confd")

    logger_info "Effacement des fichiers déjà présents dans /etc/monit/conf.d"
    rm -f /etc/monit/conf.d/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    logger_info "Mise en place des fichiers de conf dans /etc/monit/conf.d"
    for I in ${CONFD}; do
        module_debian_installFileConfiguration "${__PATH_CONFIG}/${I}" "/etc/monit/conf.d/" \
            "Mise en place de ${CCYAN}${I}${CVOID} vers /etc/monit/conf.d"
    done
}


###
# Redemarrage du service
##
debian_include_restart()
{
    logger_debug "debian_include_restart (monit)"

    logger_info "Redémarrage du service MONIT"
    systemctl restart monit
    [[ $? -ne 0 ]] && logger_critical "Service MONIT NOT running"
}


###
# Sauvegarde de la configuration
##
debian_include_savecfg()
{
    logger_debug "debian_include_savecfg (monit)"
    local CONFD=$(yaml_getConfig "monit.confd")

    for I in ${CONFD}; do
        module_debian_backupFileConfiguration "/etc/monit/conf.d/${I}" "${__PATH_CONFIG}/${I}"
    done
}


###
# Synchronisation de la configuration
##
debian_include_synccfg()
{
    logger_debug "debian_include_synccfg (monit)"
    local CONFD=$(yaml_getConfig "monit.confd")

    echo "monit"
    for I in ${CONFD}; do
       echo "monit/$I.conf"
    done
}
