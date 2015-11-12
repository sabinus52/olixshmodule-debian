###
# Installation et configuration de NFS
# ==============================================================================
# - Installation des paquets NFS
# - Installation des fichiers de configuration
# ------------------------------------------------------------------------------
# nfs:
#    enabled: 
#    filecfg: Fichier exports à utiliser
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
            echo -e "${CBLANC} Installation de NFS ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        config)
            echo
            echo -e "${CBLANC} Configuration de NFS ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        savecfg)
            echo -e "${CBLANC} Sauvegarde de la configuration de NFS ${CVOID}"
            ;;
    esac
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_include_main()
{
    logger_debug "ubuntu_include_main (nfs, $1)"

    if [[ "$(yaml_getConfig "nfs.enabled")" != true ]]; then
        logger_warning "Service 'nfs' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname ${OLIX_MODULE_DEBIAN_CONFIG})/nfs"

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
    logger_debug "ubuntu_include_install (nfs)"

    logger_info "Installation des packages NFS"
    apt-get --yes install nfs-common nfs-kernel-server
    [[ $? -ne 0 ]] && logger_critical "Impossible d'installer les packages NFS"
}


###
# Configuration du service
##
debian_include_config()
{
    logger_debug "ubuntu_include_config (nfs)"
    local FILECFG=$(yaml_getConfig "nfs.filecfg")

    module_debian_backupFileOriginal "/etc/exports"
    module_debian_installFileConfiguration "${__PATH_CONFIG}/${FILECFG}" "/etc/exports" \
        "Mise en place de ${CCYAN}${FILECFG}${CVOID} vers /etc/exports"
}


###
# Redemarrage du service
##
debian_include_restart()
{
    logger_debug "ubuntu_include_restart (nfs)"

    logger_info "Redémarrage du service NFS"
    systemctl restart nfs-kernel-server
    [[ $? -ne 0 ]] && logger_critical "Service NFS NOT running"
}


###
# Sauvegarde de la configuration
##
debian_include_savecfg()
{
    logger_debug "ubuntu_include_savecfg (nfs)"
    local FILECFG=$(yaml_getConfig "nfs.filecfg")

    module_debian_backupFileConfiguration "/etc/exports" "${__PATH_CONFIG}/${FILECFG}"
}


###
# Synchronisation de la configuration
##
debian_include_synccfg()
{
    logger_debug "ubuntu_include_synccfg (nfs)"
    local FILECFG=$(yaml_getConfig "nfs.filecfg")

    echo "nfs"
    echo "nfs/${FILECFG}"
}
