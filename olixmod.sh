###
# Module d'installation et de configuration d'un serveur DEBIAN
# ==============================================================================
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
##

OLIX_MODULE_NAME="debian"

# Version en cours d'Ubuntu
OLIX_MODULE_DEBIAN_VERSION=$(cat /etc/debian_version)
OLIX_MODULE_DEBIAN_VERSION_RELEASE=$(cat /etc/os-release |grep VERSION= |cut -f 2 -d \(|cut -f 1 -d \))

# Si on doit utiliser tous les packages
OLIX_MODULE_DEBIAN_PACKAGES_COMPLETE=false

# Liste des packages en fonction de l'action à traiter
OLIX_MODULE_DEBIAN_PACKAGES_INSTALL="network virtualbox vmware users apache php mysql postgres nfs samba ftp postfix collectd logwatch monit snmpd tools"
OLIX_MODULE_DEBIAN_PACKAGES_CONFIG="apache php mysql postgres nfs samba ftp postfix collectd logwatch monit snmpd tools"
OLIX_MODULE_DEBIAN_PACKAGES_SAVECFG="apache php mysql postgres nfs samba ftp postfix collectd logwatch monit snmpd tools"

# Emplacement du fichier de configuration des paramètres (/etc/olixsh/debian.conf)
OLIX_MODULE_DEBIAN_CONFIG=

# Addresse du serveur distant du dépôt de la configuration (/etc/olixsh/debian.conf | $param)
OLIX_MODULE_DEBIAN_SYNC_SERVER=
# Port du serveur distant du dépôt de la configuration (/etc/olixsh/debian.conf | --port=)
OLIX_MODULE_DEBIAN_SYNC_PORT=22



###
# Retourne la liste des modules requis
##
olixmod_require_module()
{
    echo -e ""
}


###
# Retourne la liste des binaires requis
##
olixmod_require_binary()
{
    echo -e "rsync"
}


###
# Usage de la commande
##
olixmod_usage()
{
    logger_debug "module_debian__olixmod_usage ()"

    source modules/debian/lib/usage.lib.sh
    module_debian_usage_main
}


###
# Fonction de liste
##
olixmod_list()
{
    logger_debug "module_debian__olixmod_list ($@)"
    echo
}


###
# Initialisation du module
##
olixmod_init()
{
    logger_debug "module_debian__olixmod_init (null)"
    source modules/debian/lib/action.lib.sh
    module_initialize $@
    module_debian_action_init $@
}


###
# Function principale
##
olixmod_main()
{
    logger_debug "module_debian__olixmod_main ($@)"
    local ACTION=$1

    # Affichage de l'aide
    [ $# -lt 1 ] && olixmod_usage && core_exit 1
    [[ "$1" == "help" ]] && olixmod_usage && core_exit 0

    # Librairies necessaires
    source modules/debian/lib/debian.lib.sh
    source modules/debian/lib/usage.lib.sh
    source modules/debian/lib/action.lib.sh
    source lib/stdin.lib.sh
    source lib/file.lib.sh
    source lib/yaml.lib.sh
    source lib/filesystem.lib.sh

    if ! type "module_debian_action_$ACTION" >/dev/null 2>&1; then
        logger_warning "Action inconnu : '$ACTION'"
        olixmod_usage 
        core_exit 1
    fi
    logger_info "Execution de l'action '${ACTION}' du module ${OLIX_MODULE_NAME} version ${OLIX_MODULE_UBUNTU_VERSION_RELEASE}"

    # Affichage de l'aide de l'action
    [[ "$2" == "help" && "$1" != "init" ]] && module_debian_usage_$ACTION && core_exit 0

    # Charge la configuration du module
    [[ "$1" != "synccfg" ]] && config_loadConfigModule "${OLIX_MODULE_NAME}"

    shift
    module_debian_usage_getParams $@
    module_debian_action_$ACTION $@
}
