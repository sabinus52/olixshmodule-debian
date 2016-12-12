###
# Installation et configuration de SAMBA
# ==============================================================================
# - Installation des paquets SAMBA
# - Installation des fichiers de configuration
# - Activation des utilisateurs
# ------------------------------------------------------------------------------
# samba:
#   enabled: 
#   filecfg: Fichier smb.conf à utiliser
#   users:   Liste des utilisateurs à créer
#     user_1:
#        name:
#     user_N:
#        name:
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
            echo -e "${CBLANC} Installation de SAMBA ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        config)
            echo
            echo -e "${CBLANC} Configuration de SAMBA ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        savecfg)
            echo -e "${CBLANC} Sauvegarde de la configuration de SAMBA ${CVOID}"
            ;;
    esac
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_service_main()
{
    debug "debian_service_main (samba, $1)"

    if [[ "$(Yaml.get "samba.enabled")" != true ]]; then
        warning "Service 'samba' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname $OLIX_MODULE_DEBIAN_CONFIG)/samba"

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
    debug "debian_service_install (samba)"

    info "Installation des packages SAMBA"
    apt-get --yes install samba smbclient cifs-utils
    [[ $? -ne 0 ]] && critical "Impossible d'installer les packages SAMBA"
}


###
# Configuration du service
##
debian_service_config()
{
    debug "debian_service_config (samba)"
    local FILECFG=$(Yaml.get "samba.filecfg")

    Debian.fileconfig.keep "/etc/samba/smb.conf"
    Debian.fileconfig.install "${__PATH_CONFIG}/$FILECFG" "/etc/samba/smb.conf" \
        "Mise en place de ${CCYAN}${FILECFG}${CVOID} vers /etc/samba/smb.conf"

    # Déclaration des utilisateurs
    debian_service_samba_users
}


###
# Redemarrage du service
##
debian_service_restart()
{
    debug "debian_service_restart (samba)"

    info "Redémarrage du service SAMBA"
    systemctl restart smbd
    [[ $? -ne 0 ]] && critical "Service SAMBA NOT running"
}


###
# Sauvegarde de la configuration
##
debian_service_savecfg()
{
    debug "debian_service_savecfg (samba)"
    local FILECFG=$(Yaml.get "samba.filecfg")

    Debian.fileconfig.save "/etc/samba/smb.conf" "${__PATH_CONFIG}/$FILECFG"
}


###
# Synchronisation de la configuration
##
debian_service_synccfg()
{
    debug "debian_service_synccfg (samba)"
    local FILECFG=$(Yaml.get "samba.filecfg")

    echo "samba"
    echo "samba/$FILECFG"
}


###
# Déclaration des utilisateurs
##
function debian_service_samba_users()
{
    debug "debian_service_samba_users ()"
    local USERNAME

    for (( I = 1; I < 10; I++ )); do
        local USERNAME=$(Yaml.get "samba.users.user_${I}.name")
        [[ -z $USERNAME ]] && break

        info "Activation de l'utilisateur '${USERNAME}'"
        smbpasswd -a $USERNAME

        echo -e "Activation de l'utilisateur ${CCYAN}${USERNAME}${CVOID} : ${CVERT}OK ...${CVOID}"
    done
}
