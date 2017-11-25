###
# Installation et configuration d'APACHE
# ==============================================================================
# - Installation des paquets APACHE
# - Installation de la clé privée
# - Activation des modules
# - Installation des fichiers de configuration
# ------------------------------------------------------------------------------
# apache:
#    enabled: 
#    modules: Liste des modules apache à activer
#    configs: Liste des fichiers de configuration
#    default: Site par défaut
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
            echo -e "${CBLANC} Installation de APACHE ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        config)
            echo
            echo -e "${CBLANC} Configuration de APACHE ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        savecfg)
            echo -e "${CBLANC} Sauvegarde de la configuration de APACHE ${CVOID}"
            ;;
    esac
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_service_main()
{
    debug "debian_service_main (apache, $1)"

    if [[ "$(Yaml.get "apache.enabled")" != true ]]; then
        warning "Service 'apache' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname $OLIX_MODULE_DEBIAN_CONFIG)/apache"

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
    debug "debian_service_install (apache)"

    info "Installation des packages APACHE"
    apt-get --yes install apache2-mpm-prefork ssl-cert
    [[ $? -ne 0 ]] && critical "Impossible d'installer les packages APACHE"
}


###
# Configuration du service
##
debian_service_config()
{
    debug "debian_service_config (apache)"

    # Activation des modules Apache
    debian_service_apache_modules
    # Installation des fichiers de configuration
    debian_service_apache_configs
    # Activation du site par défaut
    debian_service_apache_default
}


###
# Redemarrage du service
##
debian_service_restart()
{
    debug "debian_service_restart (apache)"

    info "Redémarrage du service APACHE"
    systemctl restart apache2
    [[ $? -ne 0 ]] && critical "Service APACHE NOT running"
}


###
# Sauvegarde de la configuration
##
debian_service_savecfg()
{
    debug "debian_service_savecfg (apache)"
    local CONFIGS=$(Yaml.get "apache.configs")
    local DEFAULT=$(Yaml.get "apache.default")

    for I in $CONFIGS; do
        Debian.fileconfig.save "/etc/apache2/conf-available/$I.conf" "${__PATH_CONFIG}/conf/$I.conf"
    done
    Debian.fileconfig.save "/etc/apache2/sites-available/000-default.conf" "${__PATH_CONFIG}/default/$DEFAULT"
}


###
# Synchronisation de la configuration
##
debian_service_synccfg()
{
    debug "debian_service_synccfg (apache)"
    local CONFIGS=$(Yaml.get "apache.configs")
    local DEFAULT=$(Yaml.get "apache.default")

    echo "apache apache/conf apache/default"
    for I in $CONFIGS; do
       echo "apache/conf/$I.conf"
    done
    echo "apache/default/$DEFAULT"
}


###
# Activation des modules Apache
##
function debian_service_apache_modules()
{
    debug "debian_service_apache_modules ()"
    local MODULES=$(Yaml.get "apache.modules")

    for I in $MODULES; do
        info "Activation du module $I"
        a2enmod $I > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical
        echo -e "Activation du module ${CCYAN}$I${CVOID} : ${CVERT}OK ...${CVOID}"
    done
}


###
# Installation des fichiers de configuration
##
function debian_service_apache_configs()
{
    debug "debian_service_apache_configs ()"
    local CONFIGS_AVAILABLE=$(Yaml.get "apache.configs.available")
    local CONFIGS_ENABLED=$(Yaml.get "apache.configs.enabled")

    info "Suppression de la conf actuelle"
    rm -rf /etc/apache2/conf-enabled/olix* > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    for I in $CONFIGS_AVAILABLE; do
        Debian.fileconfig.install "${__PATH_CONFIG}/conf/$I.conf" "/etc/apache2/conf-available/"
    done
    for I in $CONFIGS_ENABLED; do
        info "Activation de la conf $I"
        a2enconf $I > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical
        echo -e "Activation de la conf ${CCYAN}$I${CVOID} : ${CVERT}OK ...${CVOID}"
    done
}


###
# Activation du site par défaut
##
function debian_service_apache_default()
{
    debug "debian_service_apache_default ()"
    local DEFAULT=$(Yaml.get "apache.default")

    if [[ -z $DEFAULT ]]; then
        warning "Pas de site par défaut défini"
        return 1
    fi

    Debian.fileconfig.keep "/etc/apache2/sites-available/000-default.conf"

    info "Effacement de /etc/apache2/sites-enabled/000-default.conf"
    rm -rf /etc/apache2/sites-enabled/000-default.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical

    Debian.fileconfig.install "${__PATH_CONFIG}/default/$DEFAULT" "/etc/apache2/sites-available/000-default.conf"

    info "Activation du site 000-default.conf"
    a2ensite 000-default.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    echo -e "Activation du site ${CCYAN}default.conf${CVOID} : ${CVERT}OK ...${CVOID}"
}
