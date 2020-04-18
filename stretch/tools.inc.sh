###
# Installation et configuration de TOOLS
# ==============================================================================
# - Installation des paquets additionnels
# - Installation des fichiers de crontab
# - Installation des fichiers de logrotate
# ------------------------------------------------------------------------------
# tools:
#   apt:       Liste des packets à intaller
#   crontab:   Fichier de conf pour les taches planifiées
#   logrotate: Fichier de conf pour la rotation de log
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
            echo -e "${CBLANC} Installation des TOOLS ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        config)
            echo
            echo -e "${CBLANC} Configuration des TOOLS ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        savecfg)
            echo -e "${CBLANC} Sauvegarde de la configuration des TOOLS ${CVOID}"
            ;;
    esac
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_service_main()
{
    debug "debian_service_main (tools, $1)"

    __PATH_CONFIG="$(dirname $OLIX_MODULE_DEBIAN_CONFIG)/tools"

    case $1 in
        install)
            debian_service_install
            debian_service_config
            ;;
        config)
            debian_service_config
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
    debug "debian_service_install (tools)"
    local TOOLS_APT=$(Yaml.get "tools.apt")

    if [[ -n $TOOLS_APT ]]; then
        info "Installation des packages additionnels"
        apt-get --yes install vim $TOOLS_APT
        [[ $? -ne 0 ]] && critical "Impossible d'installer les packages additionnels"
    fi
}


###
# Configuration du service
##
debian_service_config()
{
    debug "debian_service_config (tools)"
    local CRONTAB=$(Yaml.get "tools.crontab")
    local LOGROTATE=$(Yaml.get "tools.logrotate")

    # Installation des fichiers CRONTAB
    if [ -n "$CRONTAB" ]; then
        Debian.fileconfig.install "${__PATH_CONFIG}/$CRONTAB" "/etc/cron.d/" \
            "Mise en place de ${CCYAN}${CRONTAB}${CVOID} vers /etc/cron.d"
    fi

    # Installation des fichiers LOGROTATE
    if [ -n "$LOGROTATE" ]; then
        Debian.fileconfig.install "${__PATH_CONFIG}/$LOGROTATE" "/etc/logrotate.d/" \
            "Mise en place de ${CCYAN}${LOGROTATE}${CVOID} vers /etc/logrotate.d"
    fi

    debian_service_tools_tuning
}


###
# Sauvegarde de la configuration
##
debian_service_savecfg()
{
    debug "debian_service_savecfg (tools)"
    local CRONTAB=$(Yaml.get "tools.crontab")
    local LOGROTATE=$(Yaml.get "tools.logrotate")

    [[ -n "$CRONTAB" ]] && Debian.fileconfig.save "/etc/cron.d/$CRONTAB" "${__PATH_CONFIG}/$CRONTAB"
    [[ -n "$LOGROTATE" ]] && Debian.fileconfig.save "/etc/logrotate.d/$LOGROTATE" "${__PATH_CONFIG}/$LOGROTATE"
}


###
# Synchronisation de la configuration
##
debian_service_synccfg()
{
    debug "debian_service_synccfg (tools)"
    local CRONTAB=$(Yaml.get "tools.crontab")
    local LOGROTATE=$(Yaml.get "tools.logrotate")

    echo "tools"
    [[ -n "$CRONTAB" ]] && echo "postgres/$CRONTAB"
    [[ -n "$LOGROTATE" ]] && echo "postgres/$LOGROTATE"
}


###
# Un peu de tuning
##
function debian_service_tools_tuning()
{
    debug "debian_service_tools_tuning ()"
}
