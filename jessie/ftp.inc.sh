###
# Installation et configuration de FTP
# ==============================================================================
# - Installation des paquets PUREFTPD
# - Modification de base de pureftpd
# - Modification de la configuration de pureftpd
# - Création des utilisateurs virtuels
# ------------------------------------------------------------------------------
# ftp:
#    enabled:
#    configs: Configuration de pure-ftpd avec les fichiers de parametre = valeur
#   users:    Création des utilisateurs virtuels Exemple : "otop -u otop -g users -d /home/otop"
#     user_1:                                   
#        name:
#        grant:
#     user_N:
#        name:
#        grant:
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
            echo -e "${CBLANC} Installation de FTP ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        config)
            echo
            echo -e "${CBLANC} Configuration de FTP ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        savecfg)
            echo -e "${CBLANC} Sauvegarde de la configuration de FTP ${CVOID}"
            ;;
    esac
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_include_main()
{
    logger_debug "debian_include_main (ftp, $1)"

    if [[ "$(yaml_getConfig "ftp.enabled")" != true ]]; then
        logger_warning "Service 'ftp' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname ${OLIX_MODULE_DEBIAN_CONFIG})/ftp"

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
    logger_debug "debian_include_install (ftp)"

    logger_info "Installation des packages FTP"
    apt-get --yes install pure-ftpd
    [[ $? -ne 0 ]] && logger_critical "Impossible d'installer les packages FTP"

    logger_info "Modification du VirtualChRoot dans /etc/default/pure-ftpd-common"
    sed -i "s/^VIRTUALCHROOT=.*$/VIRTUALCHROOT=true/g" /etc/default/pure-ftpd-common > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical

    # Activation de PureDB
    logger_info "Suppression de /etc/pure-ftpd/auth/75puredb"
    rm -f /etc/pure-ftpd/auth/75puredb > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    logger_info "Activation de la base puredb pour les utilisateurs virtuels"
    cd /etc/pure-ftpd/auth
    ln -sf ../conf/PureDB 75puredb > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    cd ${OLIX_ROOT}
}


###
# Configuration du service
##
debian_include_config()
{
    logger_debug "debian_include_config (ftp)"

    # Mise en place des paramètres de configuration
    debian_include_ftp_configs

    # Création des utilisateurs
    debian_include_ftp_users
}


###
# Redemarrage du service
##
debian_include_restart()
{
    logger_debug "debian_include_restart (ftp)"

    logger_info "Redémarrage du service FTP"
    systemctl restart pure-ftpd
    [[ $? -ne 0 ]] && logger_critical "Service FTP NOT running"
}


###
# Sauvegarde de la configuration
##
debian_include_savecfg()
{
    logger_debug "debian_include_savecfg (ftp)"
    local LIST_CONFIGS=$(yaml_getConfig "ftp.configs")

    for I in ${LIST_CONFIGS}; do
        module_debian_backupFileConfiguration "/etc/pure-ftpd/conf/${I}" "${__PATH_CONFIG}/${I}"
    done
}


###
# Synchronisation de la configuration
##
debian_include_synccfg()
{
    logger_debug "debian_include_synccfg (ftp)"
    local LIST_CONFIGS=$(yaml_getConfig "ftp.configs")

    echo "ftp"
    for I in ${LIST_CONFIGS}; do
       echo "ftp/$I.conf"
    done
}


###
# Mise en place des paramètres de configuration
##
function debian_include_ftp_configs()
{
    logger_debug "debian_include_ftp_configs"
    local VALUE
    local LIST_CONFIGS=$(yaml_getConfig "ftp.configs")

    for I in ${LIST_CONFIGS}; do
        [[ -r ${__PATH_CONFIG}/${I} ]] && VALUE=$(cat ${__PATH_CONFIG}/${I})
        module_debian_installFileConfiguration "${__PATH_CONFIG}/${I}" "/etc/pure-ftpd/conf" \
            "Mise en place de ${CCYAN}${I}${CVOID} = ${CCYAN}${VALUE}${CVOID} vers /etc/pure-ftpd/conf"
    done
}


###
# Création des utilisateurs
##
function debian_include_ftp_users()
{
    logger_debug "debian_include_ftp_users ()"
    local USERNAME USERPARAM

    for (( I = 1; I < 10; I++ )); do
        USERNAME=$(yaml_getConfig "ftp.users.user_${I}.name")
        [[ -z ${USERNAME} ]] && break
        USERPARAM=$(yaml_getConfig "ftp.users.user_${I}.param")
        logger_info "Création de l'utilisateur '${USERNAME}'"

        # Création de l'utilisateur si celui-ci n'existe pas
        logger_debug "pure-pw show ${USERNAME}"
        if pure-pw show ${USERNAME} > /dev/null 2>&1; then
            logger_debug "pure-pw usermod ${USERPARAM}"
            pure-pw usermod ${USERNAME} ${USERPARAM} -m 2> ${OLIX_LOGGER_FILE_ERR}
            [[ $? -ne 0 ]] && logger_critical
            echo -e "Création de l'utilisateur ${CCYAN}${USERNAME}${CVOID} : ${CBLEU}Déjà créé ...${CVOID}"
        else
            logger_debug "pure-pw useradd ${USERNAME} ${USERPARAM}"
            echo -e "Initialisation du mot de passe de ${CCYAN}${USERNAME}${CVOID}"
            pure-pw useradd ${USERNAME} ${USERPARAM} -m 2> ${OLIX_LOGGER_FILE_ERR}
            [[ $? -ne 0 ]] && logger_critical
            echo -e "Création de l'utilisateur ${CCYAN}${USERNAME}${CVOID} : ${CVERT}OK ...${CVOID}"
        fi
    done
}
