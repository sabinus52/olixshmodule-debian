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


debian_include_title()
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
debian_include_main()
{
    logger_debug "debian_include_main (mysql, $1)"

    if [[ "$(yaml_getConfig "mysql.enabled")" != true ]]; then
        logger_warning "Service 'mysql' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname ${OLIX_MODULE_DEBIAN_CONFIG})/mysql"

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
    logger_debug "debian_include_install (mysql)"

    logger_info "Installation des packages MYSQL"
    apt-get --yes install mariadb-server
    [[ $? -ne 0 ]] && logger_critical "Impossible d'installer les packages MYSQL"
    
    local MYSQL_PATH=$(yaml_getConfig "mysql.path")
    [[ -z ${MYSQL_PATH} ]] && return 0
    echo -e "Création de l'instance MySQL dans ${CCYAN}${MYSQL_PATH}${CVOID}"
    OLIX_STDIN_RETURN=true
    if [[ -d ${MYSQL_PATH} ]]; then
        echo -e "${CJAUNE}ATTENTION !!! L'instance existe déjà dans le répertoire '${MYSQL_PATH}'${CVOID}"
        stdin_readYesOrNo "Confirmer pour ECRASEMENT" false
    fi
    # Initialisation du répertoire contenant les données de la base
    [[ ${OLIX_STDIN_RETURN} == true ]] && debian_include_mysql_path
}


###
# Configuration du service
##
debian_include_config()
{
    logger_debug "debian_include_config (mysql)"
    local FILECFG=$(yaml_getConfig "mysql.filecfg")

    # Mise en place du fichier de configuration
    module_debian_installFileConfiguration \
        "${__PATH_CONFIG}/${FILECFG}" "/etc/mysql/conf.d/" \
        "Mise en place de ${CCYAN}${FILECFG}${CVOID} vers /etc/mysql/conf.d"

    debian_include_restart

    # Demande du mot de passe
    stdin_readPassword "Mot de passe du serveur MYSQL en tant que root"
    MYSQL_PASSWORD=${OLIX_STDIN_RETURN}

    # Execution du script
    debian_include_mysql_script

    # Déclaration des utilisateurs
    debian_include_mysql_users
}


###
# Redemarrage du service
##
debian_include_restart()
{
    logger_debug "debian_include_restart (mysql)"

    logger_info "Redémarrage du service MYSQL"
    systemctl restart mysql
    [[ $? -ne 0 ]] && logger_critical "Service MYSQL NOT running"
}


###
# Sauvegarde de la configuration
##
debian_include_savecfg()
{
    logger_debug "debian_include_savecfg (mysql)"
    local FILECFG=$(yaml_getConfig "mysql.filecfg")

    module_debian_backupFileConfiguration "/etc/mysql/conf.d/${FILECFG}" "${__PATH_CONFIG}/${FILECFG}"
}


###
# Synchronisation de la configuration
##
debian_include_synccfg()
{
    logger_debug "debian_include_synccfg (mysql)"
    local FILECFG=$(yaml_getConfig "mysql.filecfg")

    echo "mysql"
    echo "mysql/${FILECFG}"
}


###
# Initialisation du répertoire contenant les données de la base
##
function debian_include_mysql_path()
{
    logger_debug "debian_include_mysql_path ()"
    local MYSQL_PATH=$(yaml_getConfig "mysql.path")

    systemctl stop mysql
    logger_info "Initialisation de ${MYSQL_PATH}"
    if [[ -d ${MYSQL_PATH} ]]; then
        logger_debug "rm -rf ${MYSQL_PATH}"
        rm -rf ${MYSQL_PATH}/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical
    else
        logger_debug "mkdir -p ${MYSQL_PATH}"
        mkdir -p ${MYSQL_PATH} > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical
    fi
    logger_debug "chown -R mysql.mysql ${MYSQL_PATH}"
    chown -R mysql:mysql ${MYSQL_PATH} > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    logger_debug "cp -rp /var/lib/mysql/ ${MYSQL_PATH}"
    cp -rp /var/lib/mysql/* ${MYSQL_PATH} > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    echo -e "Regenération de l'instance MySQL : ${CVERT}OK ...${CVOID}"
    systemctl start mysql
}


###
# Execution du script SQL
##
function debian_include_mysql_script()
{
    logger_debug "debian_include_mysql_script ()"

    local SCRIPTNAME=$(yaml_getConfig "mysql.script")
    [[ -z ${SCRIPTNAME} ]] && return

    local SCRIPT=${__PATH_CONFIG}/${SCRIPTNAME}

    logger_info "Execution du script ${SCRIPTNAME}"
    [[ ! -f ${SCRIPT} ]] && logger_critical "Le fichier ${SCRIPT} n'existe pas"
    cat ${SCRIPT} | mysql --user=root --password=${MYSQL_PASSWORD} > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    echo -e "Execution du script SQL : ${CVERT}OK ...${CVOID}"
}


###
# Déclaration des utilisateurs et des privilèges
##
function debian_include_mysql_users()
{
    logger_debug "debian_include_mysql_users ()"
    local USERNAME USERGRANT

    for (( I = 1; I < 10; I++ )); do
        eval "USERNAME=\${OLIX_MODULE_DEBIAN_MYSQL__USERS__USER_${I}__NAME}"
        USERNAME=$(yaml_getConfig "mysql.users.user_${I}.name")
        [[ -z ${USERNAME} ]] && break
        USERGRANT=$(yaml_getConfig "mysql.users.user_${I}.grant")
        USERGRANT=$(echo ${USERGRANT} | sed "s/\\\\//g")
        logger_info "Privilège de l'utilisateur '${USERNAME}'"

        # Création de l'utilisateur si celui-ci n'existe pas
        logger_debug "CONCAT(QUOTE(user), '@', QUOTE(host)) = \"${USERNAME}\""
        if echo "SELECT COUNT(*) FROM mysql.user WHERE CONCAT(QUOTE(user), '@', QUOTE(host)) = \"${USERNAME}\";" \
            | mysql --user=root --password=${MYSQL_PASSWORD} | grep 0 > /dev/null; then
            stdin_readDoublePassword "Choisir un mot de passe pour l'utilisateur ${CCYAN}${USERNAME}${CVOID}"
            logger_debug "CREATE USER ${USERNAME} IDENTIFIED BY '????'"
            mysql --user=root --password=${MYSQL_PASSWORD} \
                --execute="CREATE USER ${USERNAME} IDENTIFIED BY '${OLIX_STDIN_RETURN}'" > ${OLIX_LOGGER_FILE_ERR} 2>&1
            [[ $? -ne 0 ]] && logger_critical
        fi

        logger_debug "'${USERGRANT}'"
        mysql --user=root --password=${MYSQL_PASSWORD} --execute="${USERGRANT}" > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical

        echo -e "Privilèges de l'utilisateur ${CCYAN}${USERNAME}${CVOID} : ${CVERT}OK ...${CVOID}"
    done
}