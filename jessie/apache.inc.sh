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


debian_include_title()
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
debian_include_main()
{
    logger_debug "debian_include_main (apache, $1)"

    if [[ "$(yaml_getConfig "apache.enabled")" != true ]]; then
        logger_warning "Service 'apache' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname ${OLIX_MODULE_DEBIAN_CONFIG})/apache"

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
    logger_debug "debian_include_install (apache)"

    logger_info "Installation des packages APACHE"
    apt-get --yes install apache2-mpm-prefork ssl-cert
    [[ $? -ne 0 ]] && logger_critical "Impossible d'installer les packages APACHE"
}


###
# Configuration du service
##
debian_include_config()
{
    logger_debug "debian_include_config (apache)"

    # Activation des modules Apache
    debian_include_apache_modules
    # Installation des fichiers de configuration
    debian_include_apache_configs
    # Activation du site par défaut
    debian_include_apache_default
}


###
# Redemarrage du service
##
debian_include_restart()
{
    logger_debug "debian_include_restart (apache)"

    logger_info "Redémarrage du service APACHE"
    systemctl restart apache2
    [[ $? -ne 0 ]] && logger_critical "Service APACHE NOT running"
}


###
# Sauvegarde de la configuration
##
debian_include_savecfg()
{
    logger_debug "debian_include_savecfg (apache)"
    local CONFIGS=$(yaml_getConfig "apache.configs")
    local DEFAULT=$(yaml_getConfig "apache.default")

    for I in ${CONFIGS}; do
        module_debian_backupFileConfiguration "/etc/apache2/conf-available/$I.conf" "${__PATH_CONFIG}/conf/$I.conf"
    done
    module_debian_backupFileConfiguration "/etc/apache2/sites-available/000-default.conf" "${__PATH_CONFIG}/default/${DEFAULT}"
}


###
# Synchronisation de la configuration
##
debian_include_synccfg()
{
    logger_debug "debian_include_synccfg (apache)"
    local CONFIGS=$(yaml_getConfig "apache.configs")
    local DEFAULT=$(yaml_getConfig "apache.default")

    echo "apache apache/conf apache/default"
    for I in ${CONFIGS}; do
       echo "apache/conf/$I.conf"
    done
    echo "apache/default/${DEFAULT}"
}


###
# Activation des modules Apache
##
function debian_include_apache_modules()
{
    logger_debug "debian_include_apache_modules ()"
    local MODULES=$(yaml_getConfig "apache.modules")

    for I in ${MODULES}; do
        logger_info "Activation du module $I"
        a2enmod $I > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical
        echo -e "Activation du module ${CCYAN}$I${CVOID} : ${CVERT}OK ...${CVOID}"
    done
}


###
# Installation des fichiers de configuration
##
function debian_include_apache_configs()
{
    logger_debug "debian_include_apache_configs ()"
    local CONFIGS=$(yaml_getConfig "apache.configs")

    logger_info "Suppression de la conf actuelle"
    rm -rf /etc/apache2/conf-enabled/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    rm -rf /etc/apache2/conf-available/olix* > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    for I in $(ls ${__PATH_CONFIG}/conf/olix*); do
        module_debian_installFileConfiguration "$I" "/etc/apache2/conf-available/"
    done
    for I in ${CONFIGS}; do
        logger_info "Activation de la conf $I"
        a2enconf $I > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical
        echo -e "Activation de la conf ${CCYAN}$I${CVOID} : ${CVERT}OK ...${CVOID}"
    done
}


###
# Activation du site par défaut
##
function debian_include_apache_default()
{
    logger_debug "debian_include_apache_default ()"
    local DEFAULT=$(yaml_getConfig "apache.default")

    if [[ -z ${DEFAULT} ]]; then
        logger_warning "Pas de site par défaut défini"
        return 1
    fi

    module_debian_backupFileOriginal "/etc/apache2/sites-available/000-default.conf"

    logger_info "Effacement de /etc/apache2/sites-enabled/000-default.conf"
    rm -rf /etc/apache2/sites-enabled/000-default.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical

    module_debian_installFileConfiguration "${__PATH_CONFIG}/default/${DEFAULT}" "/etc/apache2/sites-available/000-default.conf"

    logger_info "Activation du site 000-default.conf"
    a2ensite 000-default.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    echo -e "Activation du site ${CCYAN}default.conf${CVOID} : ${CVERT}OK ...${CVOID}"
}
