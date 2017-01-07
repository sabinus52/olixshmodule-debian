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


debian_service_title()
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
debian_service_main()
{
    debug "ubuntu_include_main (nfs, $1)"

    if [[ "$(Yaml.get "nfs.enabled")" != true ]]; then
        warning "Service 'nfs' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname $OLIX_MODULE_DEBIAN_CONFIG)/nfs"

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
    debug "ubuntu_include_install (nfs)"

    info "Installation des packages NFS"
    apt-get --yes install nfs-common nfs-kernel-server
    [[ $? -ne 0 ]] && critical "Impossible d'installer les packages NFS"
}


###
# Configuration du service
##
debian_service_config()
{
    debug "ubuntu_include_config (nfs)"
    local FILECFG=$(Yaml.get "nfs.filecfg")

    Debian.fileconfig.keep "/etc/exports"
    Debian.fileconfig.install "${__PATH_CONFIG}/${FILECFG}" "/etc/exports" \
        "Mise en place de ${CCYAN}$FILECFG${CVOID} vers /etc/exports"
}


###
# Redemarrage du service
##
debian_service_restart()
{
    debug "ubuntu_include_restart (nfs)"

    info "Redémarrage du service NFS"
    systemctl restart nfs-kernel-server
    [[ $? -ne 0 ]] && critical "Service NFS NOT running"
}


###
# Sauvegarde de la configuration
##
debian_service_savecfg()
{
    debug "ubuntu_include_savecfg (nfs)"
    local FILECFG=$(Yaml.get "nfs.filecfg")

    Debian.fileconfig.save "/etc/exports" "${__PATH_CONFIG}/$FILECFG"
}


###
# Synchronisation de la configuration
##
debian_service_synccfg()
{
    debug "ubuntu_include_synccfg (nfs)"
    local FILECFG=$(Yaml.get "nfs.filecfg")

    echo "nfs"
    echo "nfs/$FILECFG"
}
