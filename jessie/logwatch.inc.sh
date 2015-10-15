###
# Installation et configuration de LOGWATCH
# ==============================================================================
# - Installation des paquets LOGWATCH
# - Installation des fichiers de configuration
# ------------------------------------------------------------------------------
# logwatch:
#   enabled:
#   filecfg:  Fichier logwatch.conf à utiliser
#   logfiles: Liste des fichiers de configuration pour surcharger la conf initiale
#   services: Liste des fichiers de services pour surcharger la conf initiale
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
            echo -e "${CBLANC} Installation de LOGWATCH ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        config)
            echo
            echo -e "${CBLANC} Configuration de LOGWATCH ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        savecfg)
            echo -e "${CBLANC} Sauvegarde de la configuration de LOGWATCH ${CVOID}"
            ;;
    esac
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_include_main()
{
    logger_debug "debian_include_main (logwatch, $1)"

    if [[ "$(yaml_getConfig "logwatch.enabled")" != true ]]; then
        logger_warning "Service 'logwatch' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname ${OLIX_MODULE_DEBIAN_CONFIG})/logwatch"

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
    logger_debug "debian_include_install (logwatch)"

    logger_info "Installation des packages LOGWATCH"
    apt-get --yes install logwatch
    [[ $? -ne 0 ]] && logger_critical "Impossible d'installer les packages LOGWATCH"
}


###
# Configuration du service
##
debian_include_config()
{
    logger_debug "debian_include_config (logwatch)"

    local FILECFG=$(yaml_getConfig "logwatch.filecfg")
    module_debian_installFileConfiguration "${__PATH_CONFIG}/${FILECFG}" "/etc/logwatch/conf/logwatch.conf" \
        "Mise en place de ${CCYAN}${FILECFG}${CVOID} vers /etc/logwatch/conf/logwatch.conf"

    # Mise en place du fichier de configuration de "logfiles"
    local LOGFILES=$(yaml_getConfig "logwatch.logfiles")
    logger_info "Effacement des fichiers déjà présents dans /etc/logwatch/conf/logfiles"
    rm -f /etc/logwatch/conf/logfiles/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    logger_info "Mise en place des fichiers dans /etc/logwatch/conf/logfiles"
    for I in ${LOGFILES}; do
        module_debian_installFileConfiguration "${__PATH_CONFIG}/logfiles/${I}" "/etc/logwatch/conf/logfiles/" \
            "Mise en place de ${CCYAN}logfiles/${I}${CVOID} vers /etc/logwatch/conf/logfiles"
    done

    # Mise en place du fichier de configuration de "services"
    local SERVICES=$(yaml_getConfig "logwatch.services")
    logger_info "Effacement des fichiers déjà présents dans /etc/logwatch/conf/services"
    rm -f /etc/logwatch/conf/services/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    logger_info "Mise en place des fichiers dans /etc/logwatch/conf/logfiles"
    for I in ${SERVICES}; do
        module_debian_installFileConfiguration "${__PATH_CONFIG}/services/${I}" "/etc/logwatch/conf/services/" \
            "Mise en place de ${CCYAN}services/${I}${CVOID} vers /etc/logwatch/conf/services"
    done
}


###
# Redemarrage du service
##
debian_include_restart()
{
    logger_debug "debian_include_restart (logwatch)"
}


###
# Sauvegarde de la configuration
##
debian_include_savecfg()
{
    logger_debug "debian_include_savecfg (logwatch)"
    local FILECFG=$(yaml_getConfig "logwatch.filecfg")
    local LOGFILES=$(yaml_getConfig "logwatch.logfiles")
    local SERVICES=$(yaml_getConfig "logwatch.services")

    module_debian_backupFileConfiguration "/etc/logwatch/conf/logwatch.conf" "${__PATH_CONFIG}/${FILECFG}"
    for I in ${LOGFILES}; do
        module_debian_backupFileConfiguration "/etc/logwatch/conf/logfiles/${I}" "${__PATH_CONFIG}/logfiles/${I}"
    done
    for I in ${SERVICES}; do
        module_debian_backupFileConfiguration "/etc/logwatch/conf/services/${I}" "${__PATH_CONFIG}/services/${I}"
    done
}


###
# Synchronisation de la configuration
##
debian_include_synccfg()
{
    logger_debug "debian_include_synccfg (logwatch)"
    local FILECFG=$(yaml_getConfig "logwatch.filecfg")
    local LOGFILES=$(yaml_getConfig "logwatch.logfiles")
    local SERVICES=$(yaml_getConfig "logwatch.services")

    echo "logwatch logwatch/logfiles logwatch/services"
    echo "logwatch/${FILECFG}"
    for I in ${LOGFILES}; do
        echo "logwatch/logfiles/${I}"
    done
    for I in ${SERVICES}; do
        echo "logwatch/services/${I}"
    done
}
