###
# Installation et configuration de MySQL
# ==============================================================================
# - Installation des paquets MySQL
# - Déplacement des fichiers de l'instance
# - Installation des fichiers de configuration
# - Configuration des droits
# ------------------------------------------------------------------------------
# mysql:
#   enabled: 
#   path:    Chemin des bases mysql
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
            echo -e "${CBLANC} Installation de MYSQL ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        config)
            echo
            echo -e "${CBLANC} Configuration de MYSQL ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        savecfg)
            echo -e "${CBLANC} Sauvegarde de la configuration de MYSQL ${CVOID}"
            ;;
    esac
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_service_main()
{
    debug "debian_service_main (mysql, $1)"

    if [[ "$(Yaml.get "mysql.enabled")" != true ]]; then
        warning "Service 'mysql' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname $OLIX_MODULE_DEBIAN_CONFIG)/mysql"

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
    debug "debian_service_install (mysql)"

    info "Installation des packages MYSQL"
    apt-get --yes install mysql-server
    [[ $? -ne 0 ]] && critical "Impossible d'installer les packages MYSQL"
    
    local MYSQL_PATH=$(Yaml.get "mysql.path")
    [[ -z $MYSQL_PATH ]] && return 0
    echo -e "Création de l'instance MySQL dans ${CCYAN}${MYSQL_PATH}${CVOID}"
    OLIX_FUNCTION_RETURN=true
    if [[ -d $MYSQL_PATH ]]; then
        echo -e "${CJAUNE}ATTENTION !!! L'instance existe déjà dans le répertoire '${MYSQL_PATH}'${CVOID}"
        Read.confirm "Confirmer pour ECRASEMENT" false
    fi
    # Initialisation du répertoire contenant les données de la base
    [[ $OLIX_FUNCTION_RETURN == true ]] && debian_service_mysql_path
}


###
# Configuration du service
##
debian_service_config()
{
    debug "debian_service_config (mysql)"
    local FILECFG=$(Yaml.get "mysql.filecfg")

    # Mise en place du fichier de configuration
    Debian.fileconfig.install \
        "${__PATH_CONFIG}/$FILECFG" "/etc/mysql/conf.d/" \
        "Mise en place de ${CCYAN}${FILECFG}${CVOID} vers /etc/mysql/conf.d"

    debian_service_restart

    # Demande du mot de passe
    Read.password "Mot de passe du serveur MYSQL en tant que root"
    MYSQL_PASSWORD=$OLIX_FUNCTION_RETURN

    # Execution du script
    debian_service_mysql_script

    # Déclaration des utilisateurs
    debian_service_mysql_users
}


###
# Redemarrage du service
##
debian_service_restart()
{
    debug "debian_service_restart (mysql)"

    info "Redémarrage du service MYSQL"
    systemctl restart mysql
    [[ $? -ne 0 ]] && critical "Service MYSQL NOT running"
}


###
# Sauvegarde de la configuration
##
debian_service_savecfg()
{
    debug "debian_service_savecfg (mysql)"
    local FILECFG=$(Yaml.get "mysql.filecfg")

    Debian.fileconfig.save "/etc/mysql/conf.d/$FILECFG" "${__PATH_CONFIG}/$FILECFG"
}


###
# Synchronisation de la configuration
##
debian_service_synccfg()
{
    debug "debian_service_synccfg (mysql)"
    local FILECFG=$(Yaml.get "mysql.filecfg")

    echo "mysql"
    echo "mysql/$FILECFG"
}


###
# Initialisation du répertoire contenant les données de la base
##
function debian_service_mysql_path()
{
    debug "debian_service_mysql_path ()"
    local MYSQL_PATH=$(Yaml.get "mysql.path")

    systemctl stop mysql
    info "Initialisation de ${MYSQL_PATH}"
    if [[ -d $MYSQL_PATH ]]; then
        debug "rm -rf ${MYSQL_PATH}"
        rm -rf $MYSQL_PATH/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical
    else
        debug "mkdir -p ${MYSQL_PATH}"
        mkdir -p $MYSQL_PATH > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical
    fi
    debug "chown -R mysql.mysql ${MYSQL_PATH}"
    chown -R mysql:mysql $MYSQL_PATH > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    debug "cp -rp /var/lib/mysql/ ${MYSQL_PATH}"
    cp -rp /var/lib/mysql/* $MYSQL_PATH > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    echo -e "Regenération de l'instance MySQL : ${CVERT}OK ...${CVOID}"
    systemctl start mysql
}


###
# Execution du script SQL
##
function debian_service_mysql_script()
{
    debug "debian_service_mysql_script ()"

    local SCRIPTNAME=$(Yaml.get "mysql.script")
    [[ -z $SCRIPTNAME ]] && return

    local SCRIPT=${__PATH_CONFIG}/$SCRIPTNAME

    info "Execution du script ${SCRIPTNAME}"
    [[ ! -f $SCRIPT ]] && critical "Le fichier ${SCRIPT} n'existe pas"
    cat $SCRIPT | mysql --user=root --password=$MYSQL_PASSWORD > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    echo -e "Execution du script SQL : ${CVERT}OK ...${CVOID}"
}


###
# Déclaration des utilisateurs et des privilèges
##
function debian_service_mysql_users()
{
    debug "debian_service_mysql_users ()"
    local USERNAME USERGRANT

    for (( I = 1; I < 10; I++ )); do
        eval "USERNAME=\${OLIX_MODULE_DEBIAN_MYSQL__USERS__USER_${I}__NAME}"
        USERNAME=$(Yaml.get "mysql.users.user_${I}.name")
        [[ -z $USERNAME ]] && break
        USERGRANT=$(Yaml.get "mysql.users.user_${I}.grant")
        USERGRANT=$(echo $USERGRANT | sed "s/\\\\//g")
        info "Privilège de l'utilisateur '${USERNAME}'"

        # Création de l'utilisateur si celui-ci n'existe pas
        debug "CONCAT(QUOTE(user), '@', QUOTE(host)) = \"${USERNAME}\""
        if echo "SELECT COUNT(*) FROM mysql.user WHERE CONCAT(QUOTE(user), '@', QUOTE(host)) = \"${USERNAME}\";" \
            | mysql --user=root --password=$MYSQL_PASSWORD | grep 0 > /dev/null; then
            Read.passwordx2 "Choisir un mot de passe pour l'utilisateur ${CCYAN}${USERNAME}${CVOID}"
            debug "CREATE USER ${USERNAME} IDENTIFIED BY '????'"
            mysql --user=root --password=$MYSQL_PASSWORD \
                --execute="CREATE USER $USERNAME IDENTIFIED BY '$OLIX_FUNCTION_RETURN'" > ${OLIX_LOGGER_FILE_ERR} 2>&1
            [[ $? -ne 0 ]] && critical
        fi

        debug "${USERGRANT}"
        mysql --user=root --password=$MYSQL_PASSWORD --execute="$USERGRANT" > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical

        echo -e "Privilèges de l'utilisateur ${CCYAN}${USERNAME}${CVOID} : ${CVERT}OK ...${CVOID}"
    done
}