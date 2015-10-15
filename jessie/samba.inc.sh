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


debian_include_title()
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
debian_include_main()
{
    logger_debug "debian_include_main (samba, $1)"

    if [[ "$(yaml_getConfig "samba.enabled")" != true ]]; then
        logger_warning "Service 'samba' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname ${OLIX_MODULE_DEBIAN_CONFIG})/samba"

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
    logger_debug "debian_include_install (samba)"

    logger_info "Installation des packages SAMBA"
    apt-get --yes install samba smbclient cifs-utils
    [[ $? -ne 0 ]] && logger_critical "Impossible d'installer les packages SAMBA"
}


###
# Configuration du service
##
debian_include_config()
{
    logger_debug "debian_include_config (samba)"
    local FILECFG=$(yaml_getConfig "samba.filecfg")

    module_debian_backupFileOriginal "/etc/samba/smb.conf"
    module_debian_installFileConfiguration "${__PATH_CONFIG}/${FILECFG}" "/etc/samba/smb.conf" \
        "Mise en place de ${CCYAN}${FILECFG}${CVOID} vers /etc/samba/smb.conf"

    # Déclaration des utilisateurs
    debian_include_samba_users
}


###
# Redemarrage du service
##
debian_include_restart()
{
    logger_debug "debian_include_restart (samba)"

    logger_info "Redémarrage du service SAMBA"
    systemctl restart smbd
    [[ $? -ne 0 ]] && logger_critical "Service SAMBA NOT running"
}


###
# Sauvegarde de la configuration
##
debian_include_savecfg()
{
    logger_debug "debian_include_savecfg (samba)"
    local FILECFG=$(yaml_getConfig "samba.filecfg")

    module_debian_backupFileConfiguration "/etc/samba/smb.conf" "${__PATH_CONFIG}/${FILECFG}"
}


###
# Synchronisation de la configuration
##
debian_include_synccfg()
{
    logger_debug "debian_include_synccfg (samba)"
    local FILECFG=$(yaml_getConfig "samba.filecfg")

    echo "samba"
    echo "samba/${FILECFG}"
}


###
# Déclaration des utilisateurs
##
function debian_include_samba_users()
{
    logger_debug "debian_include_samba_users ()"
    local USERNAME

    for (( I = 1; I < 10; I++ )); do
        local USERNAME=$(yaml_getConfig "samba.users.user_${I}.name")
        [[ -z ${USERNAME} ]] && break

        logger_info "Activation de l'utilisateur '${USERNAME}'"
        smbpasswd -a ${USERNAME}

        echo -e "Activation de l'utilisateur ${CCYAN}${USERNAME}${CVOID} : ${CVERT}OK ...${CVOID}"
    done
}
