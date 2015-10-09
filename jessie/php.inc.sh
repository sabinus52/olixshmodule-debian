###
# Installation et configuration de PHP
# ==============================================================================
# - Installation des paquets PHP
# - Installation des fichiers de configuration
# ------------------------------------------------------------------------------
# php:
#    enabled: 
#    modules: Liste des modules php à installer
#    filecfg: Fichier php.ini à utiliser
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
            echo -e "${CBLANC} Installation de PHP ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        config)
            echo
            echo -e "${CBLANC} Configuration de PHP ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        savecfg)
            echo -e "${CBLANC} Sauvegarde de la configuration de PHP ${CVOID}"
            ;;
    esac
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_include_main()
{
    logger_debug "debian_include_main (php, $1)"

    if [[ "$(yaml_getConfig "php.enabled")" != true ]]; then
        logger_warning "Service 'php' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname ${OLIX_MODULE_DEBIAN_CONFIG})/php"

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
    logger_debug "debian_include_install (php)"
    local MODULES=$(yaml_getConfig "php.modules")

    logger_info "Installation des packages PHP"
    apt-get --yes install libapache2-mod-php5 php5 ${MODULES}
    [[ $? -ne 0 ]] && logger_critical "Impossible d'installer les packages PHP"
}


###
# Configuration du service
##
debian_include_config()
{
    logger_debug "debian_include_config (php)"
    local FILECFG=$(yaml_getConfig "php.filecfg")

    module_debian_installFileConfiguration "${__PATH_CONFIG}/${FILECFG}" "/etc/php5/apache2/conf.d/"
    module_debian_installFileConfiguration "${__PATH_CONFIG}/${FILECFG}" "/etc/php5/cli/conf.d/"
    echo -e "Activation de la conf ${CCYAN}${FILECFG}${CVOID} : ${CVERT}OK ...${CVOID}"
}


###
# Redemarrage du service
##
debian_include_restart()
{
    logger_debug "debian_include_restart (php)"

    logger_info "Redémarrage du service APACHE"
    systemctl restart apache2
    [[ $? -ne 0 ]] && logger_critical "Service APACHE NOT running"
}


###
# Sauvegarde de la configuration
##
debian_include_savecfg()
{
    logger_debug "debian_include_savecfg (php)"
    local FILECFG=$(yaml_getConfig "php.filecfg")

    module_debian_backupFileConfiguration "/etc/php5/apache2/conf.d/${FILECFG}" "${__PATH_CONFIG}/${FILECFG}"
}



###
# Synchronisation de la configuration
##
debian_include_synccfg()
{
    logger_debug "debian_include_synccfg (php)"
    local FILECFG=$(yaml_getConfig "php.filecfg")

    echo "php"
    echo "php/${FILECFG}"
}
