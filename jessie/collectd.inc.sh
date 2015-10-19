###
# Installation et configuration de COLLECTD
# ==============================================================================
# - Installation des paquets COLLECTD
# - Installation des fichiers de configuration
# - Reset des données
# ------------------------------------------------------------------------------
# collectd:
#    enabled:
#    plugins: Liste des plugins à activer
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
            echo -e "${CBLANC} Installation de COLLECTD ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        config)
            echo
            echo -e "${CBLANC} Configuration de COLLECTD ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        savecfg)
            echo -e "${CBLANC} Sauvegarde de la configuration de COLLECTD ${CVOID}"
            ;;
    esac
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_include_main()
{
    logger_debug "debian_include_main (collectd, $1)"

    if [[ "$(yaml_getConfig "collectd.enabled")" != true ]]; then
        logger_warning "Service 'collectd' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname ${OLIX_MODULE_DEBIAN_CONFIG})/collectd"

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
    logger_debug "debian_include_install (collectd)"

    logger_info "Installation des packages COLLECTD"
    apt-get --yes install collectd librrds-perl libconfig-general-perl libhtml-parser-perl libregexp-common-perl
    [[ $? -ne 0 ]] && logger_critical "Impossible d'installer les packages COLLECTD"

    # Activation des Plugins obligatoire
    debian_include_collectd_plugins_required

    # Reset des données
    debian_include_collectd_reset
}


###
# Configuration du service
##
debian_include_config()
{
    logger_debug "debian_include_config (collectd)"

    debian_include_collectd_plugins
}


###
# Redemarrage du service
##
debian_include_restart()
{
    logger_debug "debian_include_restart (collectd)"

    logger_info "Redémarrage du service COLLECTD"
    systemctl restart collectd
    [[ $? -ne 0 ]] && logger_critical "Service COLLECTD NOT running"
}


###
# Sauvegarde de la configuration
##
debian_include_savecfg()
{
    logger_debug "debian_include_savecfg (collectd)"
    local PLUGINS=$(yaml_getConfig "collectd.plugins")

    for I in ${PLUGINS}; do
        module_debian_backupFileConfiguration "/etc/collectd/collectd.conf.d/$I.conf" "${__PATH_CONFIG}/$I.conf"
    done
   
}


###
# Synchronisation de la configuration
##
debian_include_synccfg()
{
    logger_debug "debian_include_synccfg (collectd)"
    local PLUGINS=$(yaml_getConfig "collectd.plugins")

    echo "collectd"
    for I in ${PLUGINS}; do
       echo "collectd/$I.conf"
    done
}


###
# Activation des Plugins obligatoire
##
function debian_include_collectd_plugins_required()
{
    logger_debug "debian_include_collectd_plugins_required ()"
    local PLUGINS="syslog rrdtool df cpu load memory processes swap users"

    module_debian_backupFileOriginal "/etc/collectd/collectd.conf"
    logger_info "Commentaire sur les LoadPlugin"
    sed -i "s/^LoadPlugin/\#LoadPlugin/g" /etc/collectd/collectd.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    for I in ${PLUGINS}; do
        logger_info "Activation du plugin '${I}'"
        sed -i "s/^\#LoadPlugin $I/LoadPlugin $I/g" /etc/collectd/collectd.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical
    done
}


###
# Mise en place de la conf pour chaque plugin
##
function debian_include_collectd_plugins()
{
    logger_debug "debian_include_collectd_plugins"
    local PLUGINS=$(yaml_getConfig "collectd.plugins")

    logger_info "Effacement des anciennes configurations"
    rm -f /etc/collectd/collectd.conf.d/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    for I in ${PLUGINS}; do
        module_debian_installFileConfiguration "${__PATH_CONFIG}/${I}.conf" "/etc/collectd/collectd.conf.d" \
            "Activation du plugin ${CCYAN}${I}${CVOID}"
    done
}


###
# Reset des données
##
function debian_include_collectd_reset()
{
    logger_debug "debian_include_collectd_reset"

    echo -en "${Cjaune}ATTENTION !!! Ecrasement des fichiers de données RTM.${CVOID} : "
    stdin_readYesOrNo "Confirmer" false
    if [ ${OLIX_STDIN_RETURN} == true ]; then
        logger_info "Effacement des fichiers de données RRD"
        rm -rf /var/lib/collectd/rrd/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical
        echo -e "Effacement des fichiers de données RRD : ${CVERT}OK ...${CVOID}"
    fi
}
