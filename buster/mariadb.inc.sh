###
# Installation et configuration de MariaDB
# ==============================================================================
# - Installation des paquets MariaDB
# - Déplacement des fichiers de l'instance
# - Installation des fichiers de configuration
# - Configuration des droits
# ------------------------------------------------------------------------------
# mysql:
#   enabled: 
#   filecfg: Fichier my.cnf à utiliser
#   script:  Script sql
#   users:   Liste des utilisateurs à créer
#     user_1:
#        name:  Nom de l'utilisateur (Ex : 'root'@'192.168.%')
#        grant: Sql (Ex : GRANT ALL PRIVILEGES ON \*.\* TO 'root'@'192.168.%' WITH GRANT OPTION)
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
            echo -e "${CBLANC} Installation de MariaDB ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        config)
            echo
            echo -e "${CBLANC} Configuration de MariaDB ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        savecfg)
            echo -e "${CBLANC} Sauvegarde de la configuration de MariaDB ${CVOID}"
            ;;
    esac
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_service_main()
{
    debug "debian_service_main (mariadb, $1)"

    if [[ "$(Yaml.get "mariadb.enabled")" != true ]]; then
        warning "Service 'mariadb' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname $OLIX_MODULE_DEBIAN_CONFIG)/mariadb"

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
    debug "debian_service_install (mariadb)"

    info "Installation des packages MariaDB"
    apt-get --yes install mariadb-server
    [[ $? -ne 0 ]] && critical "Impossible d'installer les packages MariaDB"
}


###
# Configuration du service
##
debian_service_config()
{
    debug "debian_service_config (mariadb)"
    local FILECFG=$(Yaml.get "mariadb.filecfg")

    # Mise en place du fichier de configuration
    Debian.fileconfig.install \
        "${__PATH_CONFIG}/$FILECFG" "/etc/mysql/mariadb.conf.d/" \
        "Mise en place de ${CCYAN}${FILECFG}${CVOID} vers /etc/mysql/mariadb.conf.d"

    # Reinitialisation de la base
    echo -e "${CJAUNE}ATTENTION !!! Reinitialisation l'instance MariaDB"
    Read.confirm "Confirmer pour ECRASEMENT" false
    if [[ $OLIX_FUNCTION_RETURN == true ]]; then
        echo -en "Effacement de l'instance : "
        systemctl stop mysql
        rm -rf /var/lib/mysql/*
        echo -e "${CVERT}OK${CVOID}"
        mysql_install_db  --auth-root-authentication-method=socket --skip-test-db
        [[ $? -ne 0 ]] && critical
        systemctl start mysql
        [[ $? -ne 0 ]] && critical "Service MariaDB NOT running"
        mysql --execute="DELETE FROM mysql.user WHERE User = ''" > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical
    fi

    debian_service_restart

    # Execution du script
    debian_service_mariadb_script

    # Déclaration des utilisateurs
    debian_service_mariadb_users
}


###
# Redemarrage du service
##
debian_service_restart()
{
    debug "debian_service_restart (mariadb)"

    info "Redémarrage du service MariaDB"
    systemctl restart mysql
    [[ $? -ne 0 ]] && critical "Service MariaDB NOT running"
}


###
# Sauvegarde de la configuration
##
debian_service_savecfg()
{
    debug "debian_service_savecfg (mariadb)"
    local FILECFG=$(Yaml.get "mariadb.filecfg")

    Debian.fileconfig.save "/etc/mysql/mariadb.conf.d/$FILECFG" "${__PATH_CONFIG}/$FILECFG"
}


###
# Synchronisation de la configuration
##
debian_service_synccfg()
{
    debug "debian_service_synccfg (mariadb)"
    local FILECFG=$(Yaml.get "mariadb.filecfg")

    echo "mysql"
    echo "mysql/$FILECFG"
}


###
# Execution du script SQL
##
function debian_service_mariadb_script()
{
    debug "debian_service_mariadb_script ()"

    local SCRIPTNAME=$(Yaml.get "mariadb.script")
    [[ -z $SCRIPTNAME ]] && return

    local SCRIPT=${__PATH_CONFIG}/$SCRIPTNAME

    info "Execution du script ${SCRIPTNAME}"
    [[ ! -f $SCRIPT ]] && critical "Le fichier ${SCRIPT} n'existe pas"
    cat $SCRIPT | mysql > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    echo -e "Execution du script SQL : ${CVERT}OK ...${CVOID}"
}


###
# Déclaration des utilisateurs et des privilèges
##
function debian_service_mariadb_users()
{
    debug "debian_service_mariadb_users ()"
    local USERNAME USERGRANT

    for (( I = 1; I < 10; I++ )); do
        eval "USERNAME=\${OLIX_MODULE_DEBIAN_MARIADB__USERS__USER_${I}__NAME}"
        USERNAME=$(Yaml.get "mariadb.users.user_${I}.name")
        [[ -z $USERNAME ]] && break
        USERGRANT=$(Yaml.get "mariadb.users.user_${I}.grant")
        USERGRANT=$(echo $USERGRANT | sed "s/\\\\//g")
        info "Privilège de l'utilisateur '${USERNAME}'"

        # Création de l'utilisateur si celui-ci n'existe pas
        debug "CONCAT(QUOTE(user), '@', QUOTE(host)) = \"${USERNAME}\""
        if echo "SELECT COUNT(*) FROM mysql.user WHERE CONCAT(QUOTE(user), '@', QUOTE(host)) = \"${USERNAME}\";" \
            | mysql | grep 0 > /dev/null; then
            Read.passwordx2 "Choisir un mot de passe pour l'utilisateur ${CCYAN}${USERNAME}${CVOID}"
            debug "CREATE USER ${USERNAME} IDENTIFIED BY '????'"
            mysql  \
                --execute="CREATE USER $USERNAME IDENTIFIED BY '$OLIX_FUNCTION_RETURN'" > ${OLIX_LOGGER_FILE_ERR} 2>&1
            [[ $? -ne 0 ]] && critical
        fi

        debug "'${USERGRANT}'"
        mysql --execute="$USERGRANT" > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical

        echo -e "Privilèges de l'utilisateur ${CCYAN}${USERNAME}${CVOID} : ${CVERT}OK ...${CVOID}"
    done
}
