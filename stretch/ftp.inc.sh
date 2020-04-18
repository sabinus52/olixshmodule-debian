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


debian_service_title()
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
debian_service_main()
{
    debug "debian_service_main (ftp, $1)"

    if [[ "$(Yaml.get "ftp.enabled")" != true ]]; then
        warning "Service 'ftp' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname $OLIX_MODULE_DEBIAN_CONFIG)/ftp"

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
    debug "debian_service_install (ftp)"

    info "Installation des packages FTP"
    apt-get --yes install pure-ftpd
    [[ $? -ne 0 ]] && critical "Impossible d'installer les packages FTP"

    info "Modification du VirtualChRoot dans /etc/default/pure-ftpd-common"
    sed -i "s/^VIRTUALCHROOT=.*$/VIRTUALCHROOT=true/g" /etc/default/pure-ftpd-common > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical

    # Activation de PureDB
    info "Suppression de /etc/pure-ftpd/auth/75puredb"
    rm -f /etc/pure-ftpd/auth/75puredb > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    info "Activation de la base puredb pour les utilisateurs virtuels"
    cd /etc/pure-ftpd/auth
    ln -sf ../conf/PureDB 75puredb > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    cd ${OLIX_ROOT}
}


###
# Configuration du service
##
debian_service_config()
{
    debug "debian_service_config (ftp)"

    # Mise en place des paramètres de configuration
    debian_service_ftp_configs

    # Création des utilisateurs
    debian_service_ftp_users
}


###
# Redemarrage du service
##
debian_service_restart()
{
    debug "debian_service_restart (ftp)"

    info "Redémarrage du service FTP"
    systemctl restart pure-ftpd
    [[ $? -ne 0 ]] && critical "Service FTP NOT running"
}


###
# Sauvegarde de la configuration
##
debian_service_savecfg()
{
    debug "debian_service_savecfg (ftp)"
    local LIST_CONFIGS=$(Yaml.get "ftp.configs")

    for I in $LIST_CONFIGS; do
        Debian.fileconfig.save "/etc/pure-ftpd/conf/$I" "${__PATH_CONFIG}/$I"
    done
}


###
# Synchronisation de la configuration
##
debian_service_synccfg()
{
    debug "debian_service_synccfg (ftp)"
    local LIST_CONFIGS=$(Yaml.get "ftp.configs")

    echo "ftp"
    for I in $LIST_CONFIGS; do
       echo "ftp/$I.conf"
    done
}


###
# Mise en place des paramètres de configuration
##
function debian_service_ftp_configs()
{
    debug "debian_service_ftp_configs"
    local VALUE
    local LIST_CONFIGS=$(Yaml.get "ftp.configs")

    for I in $LIST_CONFIGS; do
        [[ -r ${__PATH_CONFIG}/$I ]] && VALUE=$(cat ${__PATH_CONFIG}/$I)
        Debian.fileconfig.install "${__PATH_CONFIG}/$I" "/etc/pure-ftpd/conf" \
            "Mise en place de ${CCYAN}$I${CVOID} = ${CCYAN}$VALUE${CVOID} vers /etc/pure-ftpd/conf"
    done
}


###
# Création des utilisateurs
##
function debian_service_ftp_users()
{
    debug "debian_service_ftp_users ()"
    local USERNAME USERPARAM

    for (( I = 1; I < 10; I++ )); do
        USERNAME=$(Yaml.get "ftp.users.user_${I}.name")
        [[ -z $USERNAME ]] && break
        USERPARAM=$(Yaml.get "ftp.users.user_$I.param")
        info "Création de l'utilisateur '${USERNAME}'"

        # Création de l'utilisateur si celui-ci n'existe pas
        debug "pure-pw show ${USERNAME}"
        if pure-pw show $USERNAME > /dev/null 2>&1; then
            debug "pure-pw usermod ${USERPARAM}"
            pure-pw usermod $USERNAME $USERPARAM -m 2> ${OLIX_LOGGER_FILE_ERR}
            [[ $? -ne 0 ]] && critical
            echo -e "Création de l'utilisateur ${CCYAN}$USERNAME${CVOID} : ${CBLEU}Déjà créé ...${CVOID}"
        else
            debug "pure-pw useradd $USERNAME ${USERPARAM}"
            echo -e "Initialisation du mot de passe de ${CCYAN}${USERNAME}${CVOID}"
            pure-pw useradd $USERNAME $USERPARAM -m 2> ${OLIX_LOGGER_FILE_ERR}
            [[ $? -ne 0 ]] && critical
            echo -e "Création de l'utilisateur ${CCYAN}${USERNAME}${CVOID} : ${CVERT}OK ...${CVOID}"
        fi
    done
}
