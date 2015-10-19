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


debian_include_title()
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
debian_include_main()
{
    logger_debug "debian_include_main (tools, $1)"

    __PATH_CONFIG="$(dirname ${OLIX_MODULE_DEBIAN_CONFIG})/tools"

    case $1 in
        install)
            debian_include_install
            debian_include_config
            ;;
        config)
            debian_include_config
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
    logger_debug "debian_include_install (tools)"
    local TOOLS_APT=$(yaml_getConfig "tools.apt")

    if [[ -n ${TOOLS_APT} ]]; then
        logger_info "Installation des packages additionnels"
        apt-get --yes install vim ${TOOLS_APT}
        [[ $? -ne 0 ]] && logger_critical "Impossible d'installer les packages additionnels"
    fi
}


###
# Configuration du service
##
debian_include_config()
{
    logger_debug "debian_include_config (tools)"
    local CRONTAB=$(yaml_getConfig "tools.crontab")
    local LOGROTATE=$(yaml_getConfig "tools.logrotate")

    # Installation des fichiers CRONTAB
    if [ -n "${CRONTAB}" ]; then
        module_debian_installFileConfiguration "${__PATH_CONFIG}/${CRONTAB}" "/etc/cron.d/" \
            "Mise en place de ${CCYAN}${CRONTAB}${CVOID} vers /etc/cron.d"
    fi

    # Installation des fichiers LOGROTATE
    if [ -n "${LOGROTATE}" ]; then
        module_debian_installFileConfiguration "${__PATH_CONFIG}/${LOGROTATE}" "/etc/logrotate.d/" \
            "Mise en place de ${CCYAN}${LOGROTATE}${CVOID} vers /etc/logrotate.d"
    fi

    debian_include_tools_tuning
}


###
# Sauvegarde de la configuration
##
debian_include_savecfg()
{
    logger_debug "debian_include_savecfg (tools)"
    local CRONTAB=$(yaml_getConfig "tools.crontab")
    local LOGROTATE=$(yaml_getConfig "tools.logrotate")

    [[ -n "${CRONTAB}" ]] && module_debian_backupFileConfiguration "/etc/cron.d/${CRONTAB}" "${__PATH_CONFIG}/${CRONTAB}"
    [[ -n "${LOGROTATE}" ]] && module_debian_backupFileConfiguration "/etc/logrotate.d/${LOGROTATE}" "${__PATH_CONFIG}/${LOGROTATE}"
}


###
# Synchronisation de la configuration
##
debian_include_synccfg()
{
    logger_debug "debian_include_synccfg (tools)"
    local CRONTAB=$(yaml_getConfig "tools.crontab")
    local LOGROTATE=$(yaml_getConfig "tools.logrotate")

    echo "tools"
    [[ -n "${CRONTAB}" ]] && echo "postgres/${CRONTAB}"
    [[ -n "${LOGROTATE}" ]] && echo "postgres/${LOGROTATE}"
}


###
# Un peu de tuning
##
function debian_include_tools_tuning()
{
    logger_debug "debian_include_tools_tuning ()"

    # Mode color dans vi
    logger_info "Activation de la coloration syntaxique dans vi"
    sed -i "s/\"syntax on/syntax on/g" /etc/vim/vimrc
    [[ $? -ne 0 ]] && logger_critical "Erreur de remplacement 'syntax on'"
}
