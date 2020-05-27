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


debian_service_title()
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
debian_service_main()
{
    debug "debian_service_main (php, $1)"

    if [[ "$(Yaml.get "php.enabled")" != true ]]; then
        warning "Service 'php' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname $OLIX_MODULE_DEBIAN_CONFIG)/php"

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
    debug "debian_service_install (php)"
    local MODULES=$(Yaml.get "php.modules")

    info "Installation des packages PHP"
    apt-get --yes install php $MODULES
    [[ $? -ne 0 ]] && critical "Impossible d'installer les packages PHP"
}


###
# Configuration du service
##
debian_service_config()
{
    debug "debian_service_config (php)"
    local FILECFG=$(Yaml.get "php.filecfg")

    Debian.fileconfig.install "${__PATH_CONFIG}/$FILECFG" "/etc/php/7.3/apache2/conf.d/"
    Debian.fileconfig.install "${__PATH_CONFIG}/$FILECFG" "/etc/php/7.3/cli/conf.d/"
    echo -e "Activation de la conf ${CCYAN}${FILECFG}${CVOID} : ${CVERT}OK ...${CVOID}"
}


###
# Redemarrage du service
##
debian_service_restart()
{
    debug "debian_service_restart (php)"

    info "Redémarrage du service APACHE"
    systemctl restart apache2
    [[ $? -ne 0 ]] && critical "Service APACHE NOT running"
}


###
# Sauvegarde de la configuration
##
debian_service_savecfg()
{
    debug "debian_service_savecfg (php)"
    local FILECFG=$(Yaml.get "php.filecfg")

    Debian.fileconfig.save "/etc/php/7.0/apache2/conf.d/$FILECFG" "${__PATH_CONFIG}/$FILECFG"
}



###
# Synchronisation de la configuration
##
debian_service_synccfg()
{
    debug "debian_service_synccfg (php)"
    local FILECFG=$(Yaml.get "php.filecfg")

    echo "php"
    echo "php/$FILECFG"
}
