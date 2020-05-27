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


debian_service_title()
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
debian_service_main()
{
    debug "debian_service_main (logwatch, $1)"

    if [[ "$(Yaml.get "logwatch.enabled")" != true ]]; then
        warning "Service 'logwatch' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname $OLIX_MODULE_DEBIAN_CONFIG)/logwatch"

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
    debug "debian_service_install (logwatch)"

    info "Installation des packages LOGWATCH"
    apt-get --yes install logwatch
    [[ $? -ne 0 ]] && critical "Impossible d'installer les packages LOGWATCH"
}


###
# Configuration du service
##
debian_service_config()
{
    debug "debian_service_config (logwatch)"

    local FILECFG=$(Yaml.get "logwatch.filecfg")
    Debian.fileconfig.install "${__PATH_CONFIG}/$FILECFG" "/etc/logwatch/conf/logwatch.conf" \
        "Mise en place de ${CCYAN}$FILECFG${CVOID} vers /etc/logwatch/conf/logwatch.conf"

    # Mise en place du fichier de configuration de "logfiles"
    local LOGFILES=$(Yaml.get "logwatch.logfiles")
    info "Effacement des fichiers déjà présents dans /etc/logwatch/conf/logfiles"
    rm -f /etc/logwatch/conf/logfiles/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    info "Mise en place des fichiers dans /etc/logwatch/conf/logfiles"
    for I in $LOGFILES; do
        Debian.fileconfig.install "${__PATH_CONFIG}/logfiles/$I" "/etc/logwatch/conf/logfiles/" \
            "Mise en place de ${CCYAN}logfiles/$I${CVOID} vers /etc/logwatch/conf/logfiles"
    done

    # Mise en place du fichier de configuration de "services"
    local SERVICES=$(Yaml.get "logwatch.services")
    info "Effacement des fichiers déjà présents dans /etc/logwatch/conf/services"
    rm -f /etc/logwatch/conf/services/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    info "Mise en place des fichiers dans /etc/logwatch/conf/logfiles"
    for I in $SERVICES; do
        Debian.fileconfig.install "${__PATH_CONFIG}/services/$I" "/etc/logwatch/conf/services/" \
            "Mise en place de ${CCYAN}services/$I${CVOID} vers /etc/logwatch/conf/services"
    done
}


###
# Redemarrage du service
##
debian_service_restart()
{
    debug "debian_service_restart (logwatch)"
}


###
# Sauvegarde de la configuration
##
debian_service_savecfg()
{
    debug "debian_service_savecfg (logwatch)"
    local FILECFG=$(Yaml.get "logwatch.filecfg")
    local LOGFILES=$(Yaml.get "logwatch.logfiles")
    local SERVICES=$(Yaml.get "logwatch.services")

    Debian.fileconfig.save "/etc/logwatch/conf/logwatch.conf" "${__PATH_CONFIG}/${FILECFG}"
    for I in $LOGFILES; do
        Debian.fileconfig.save "/etc/logwatch/conf/logfiles/$I" "${__PATH_CONFIG}/logfiles/$I"
    done
    for I in $SERVICES; do
        Debian.fileconfig.save "/etc/logwatch/conf/services/$I" "${__PATH_CONFIG}/services/$I"
    done
}


###
# Synchronisation de la configuration
##
debian_service_synccfg()
{
    debug "debian_service_synccfg (logwatch)"
    local FILECFG=$(Yaml.get "logwatch.filecfg")
    local LOGFILES=$(Yaml.get "logwatch.logfiles")
    local SERVICES=$(Yaml.get "logwatch.services")

    echo "logwatch logwatch/logfiles logwatch/services"
    echo "logwatch/${FILECFG}"
    for I in $LOGFILES; do
        echo "logwatch/logfiles/$I"
    done
    for I in $SERVICES; do
        echo "logwatch/services/$I"
    done
}
