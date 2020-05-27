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
#    apache:  Conf apache pour l'alias des scripts de génération des graphs
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
debian_service_main()
{
    debug "debian_service_main (collectd, $1)"

    if [[ "$(Yaml.get "collectd.enabled")" != true ]]; then
        warning "Service 'collectd' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname $OLIX_MODULE_DEBIAN_CONFIG)/collectd"

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
    debug "debian_service_install (collectd)"

    info "Installation des packages COLLECTD"
    apt-get --yes install collectd
    [[ $? -ne 0 ]] && critical "Impossible d'installer les packages COLLECTD"

    # Activation des Plugins obligatoire
    debian_service_collectd_plugins_required

    # Reset des données
    debian_service_collectd_reset
}


###
# Configuration du service
##
debian_service_config()
{
    debug "debian_service_config (collectd)"

    debian_service_collectd_plugins
    debian_service_collectd_apache
}


###
# Redemarrage du service
##
debian_service_restart()
{
    debug "debian_service_restart (collectd)"

    info "Redémarrage du service COLLECTD"
    systemctl restart collectd
    [[ $? -ne 0 ]] && critical "Service COLLECTD NOT running"
}


###
# Sauvegarde de la configuration
##
debian_service_savecfg()
{
    debug "debian_service_savecfg (collectd)"
    local PLUGINS=$(Yaml.get "collectd.plugins")
    local APACHE=$(Yaml.get "collectd.apache")

    for I in $PLUGINS; do
        Debian.fileconfig.save "/etc/collectd/collectd.conf.d/$I.conf" "${__PATH_CONFIG}/$I.conf"
    done
    [[ -n "$APACHE" ]] && Debian.fileconfig.save "/etc/apache2/conf-available/collectd.conf" "${__PATH_CONFIG}/${APACHE}.conf"
}


###
# Synchronisation de la configuration
##
debian_service_synccfg()
{
    debug "debian_service_synccfg (collectd)"
    local PLUGINS=$(Yaml.get "collectd.plugins")
    local APACHE=$(Yaml.get "collectd.apache")

    echo "collectd"
    for I in $PLUGINS; do
       echo "collectd/$I.conf"
    done
    [[ -n "$APACHE" ]] && echo "collectd/$APACHE.conf"
}


###
# Activation des Plugins obligatoire
##
function debian_service_collectd_plugins_required()
{
    debug "debian_service_collectd_plugins_required ()"
    local PLUGINS="syslog rrdtool df cpu load memory processes swap users"

    Debian.fileconfig.keep "/etc/collectd/collectd.conf"
    info "Commentaire sur les LoadPlugin"
    sed -i "s/^LoadPlugin/\#LoadPlugin/g" /etc/collectd/collectd.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    for I in $PLUGINS; do
        info "Activation du plugin '${I}'"
        sed -i "s/^\#LoadPlugin $I/LoadPlugin $I/g" /etc/collectd/collectd.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical
    done
}


###
# Mise en place de la conf pour chaque plugin
##
function debian_service_collectd_plugins()
{
    debug "debian_service_collectd_plugins"
    local PLUGINS=$(Yaml.get "collectd.plugins")

    info "Effacement des anciennes configurations"
    rm -f /etc/collectd/collectd.conf.d/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    for I in $PLUGINS; do
        Debian.fileconfig.install "${__PATH_CONFIG}/$I.conf" "/etc/collectd/collectd.conf.d" \
            "Activation du plugin ${CCYAN}$I${CVOID}"
    done
}


###
# Installation du fichier de configuration Apache
##
function debian_service_collectd_apache()
{
    debug "debian_service_collectd_apache ()"
    
    local APACHE=$(Yaml.get "collectd.apache")
    [[ -z "$APACHE" ]] && return

    info "Suppression de la conf Apache actuelle"
    rm -rf /etc/apache2/conf-enabled/collectd.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    Debian.fileconfig.install "${__PATH_CONFIG}/$APACHE.conf" "/etc/apache2/conf-available/collectd.conf"
    info "Activation de la conf Apache collectd"
    a2enconf collectd > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    systemctl restart apache2
    [[ $? -ne 0 ]] && critical
    echo -e "Activation de la conf ${CCYAN}Apache collectd${CVOID} : ${CVERT}OK ...${CVOID}"
}


###
# Reset des données
##
function debian_service_collectd_reset()
{
    debug "debian_service_collectd_reset"

    echo -en "${Cjaune}ATTENTION !!! Ecrasement des fichiers de données RTM.${CVOID} : "
    Read.confirm "Confirmer" false
    if [ $OLIX_FUNCTION_RETURN} == true ]; then
        info "Effacement des fichiers de données RRD"
        rm -rf /var/lib/collectd/rrd/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical
        echo -e "Effacement des fichiers de données RRD : ${CVERT}OK ...${CVOID}"
    fi
}
