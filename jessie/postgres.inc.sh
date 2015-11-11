###
# Installation et configuration de PostgreSQL
# ==============================================================================
# - Installation des paquets PostgreSQL
# - Déplacement des fichiers de l'instance
# - Installation des fichiers de configuration
# - Configuration des droits
# ------------------------------------------------------------------------------
# postgres:
#   enabled:   true
#   path:      Chemin de données de la base
#   filecfg:   Fichier postgres.conf
#   fileauth:  Fichier pg_hba.conf
#   fileident: Fichier pg_ident.conf
# ------------------------------------------------------------------------------
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
# @version 8 (jessie)
##

MODULE_DEBIAN_POSTGRES_VERSION="9.4"


debian_include_title()
{
    case $1 in
        install)
            echo
            echo -e "${CBLANC} Installation de PostgreSQL ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        config)
            echo
            echo -e "${CBLANC} Configuration de PostgreSQL ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        savecfg)
            echo -e "${CBLANC} Sauvegarde de la configuration de PostgreSQL ${CVOID}"
            ;;
    esac
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_include_main()
{
    logger_debug "debian_include_main (postgres, $1)"

    if [[ "$(yaml_getConfig "postgres.enabled")" != true ]]; then
        logger_warning "Service 'postgres' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname ${OLIX_MODULE_DEBIAN_CONFIG})/postgres"

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
    logger_debug "debian_include_install (postgres)"

    logger_info "Installation des packages PostgreSQL"
    apt-get --yes install postgresql postgresql-contrib
    [[ $? -ne 0 ]] && logger_critical "Impossible d'installer les packages PostgreSQL"

    local POSTGRES_PATH=$(yaml_getConfig "postgres.path")
    [[ -z ${POSTGRES_PATH} ]] && return 0
    echo -e "Création de l'instance PostgreSQL dans ${CCYAN}${POSTGRES_PATH}${CVOID}"
    OLIX_STDIN_RETURN=true
    if [[ -d ${POSTGRES_PATH} ]]; then
        echo -e "${CJAUNE}ATTENTION !!! L'instance existe déjà dans le répertoire '${POSTGRES_PATH}'${CVOID}"
        stdin_readYesOrNo "Confirmer pour ECRASEMENT" false
    fi
    # Initialisation du répertoire contenant les données de la base
    [[ ${OLIX_STDIN_RETURN} == true ]] && debian_include_postgres_path
}


###
# Configuration du service
##
debian_include_config()
{
    logger_debug "debian_include_config (postgres)"

    # Mise en place du fichier de configuration
    local FILECFG=$(yaml_getConfig "postgres.filecfg")
    if [[ -n "${FILECFG}" ]]; then
        module_debian_backupFileOriginal "/etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/postgresql.conf"
        module_debian_installFileConfiguration \
            "${__PATH_CONFIG}/${FILECFG}" "/etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/postgresql.conf" \
            "Mise en place de ${CCYAN}${FILECFG}${CVOID} vers /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/postgresql.conf"
        logger_debug "chown postgres.postgres /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/postgresql.conf"
        chown postgres.postgres /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/postgresql.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical
    fi

    # Mise en place du fichier d'authentification
    local FILEAUTH=$(yaml_getConfig "postgres.fileauth")
    if [[ -n "${FILEAUTH}" ]]; then
        module_debian_backupFileOriginal "/etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_hba.conf"
        module_debian_installFileConfiguration \
            "${__PATH_CONFIG}/${FILEAUTH}" "/etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_hba.conf" \
            "Mise en place de ${CCYAN}${FILEAUTH}${CVOID} vers /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_hba.conf"
        logger_debug "chown postgres.postgres /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_hba.conf"
        chown postgres.postgres /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_hba.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical
    fi

    # Mise en place du fichier d'identification
    local FILEIDENT=$(yaml_getConfig "postgres.fileident")
    if [[ -n "${FILEIDENT}" ]]; then
        module_debian_backupFileOriginal "/etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_ident.conf"
        module_debian_installFileConfiguration \
            "${__PATH_CONFIG}/${FILEIDENT}" "/etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_ident.conf" \
            "Mise en place de ${CCYAN}${FILEIDENT}${CVOID} vers /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_ident.conf"
        logger_debug "chown postgres.postgres /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_ident.conf"
        chown postgres.postgres /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_ident.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical
    fi

    debian_include_restart

    # Déclaration des utilisateurs
    debian_include_postgres_users
}


###
# Redemarrage du service
##
debian_include_restart()
{
    logger_debug "debian_include_restart (postgres)"

    logger_info "Redémarrage du service PostgreSQL"
    systemctl restart postgresql
    [[ $? -ne 0 ]] && logger_critical "Service PostgreSQL NOT running"
}


###
# Sauvegarde de la configuration
##
debian_include_savecfg()
{
    logger_debug "debian_include_savecfg (postgres)"
    local FILECFG=$(yaml_getConfig "postgres.filecfg")
    local FILEAUTH=$(yaml_getConfig "postgres.fileauth")
    local FILEIDENT=$(yaml_getConfig "postgres.fileident")

    [[ -n "${FILECFG}" ]] && module_debian_backupFileConfiguration "/etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/postgresql.conf" "${__PATH_CONFIG}/${FILECFG}"
    [[ -n "${FILEAUTH}" ]] && module_debian_backupFileConfiguration "/etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_hba.conf" "${__PATH_CONFIG}/${FILEAUTH}"
    [[ -n "${FILEIDENT}" ]] && module_debian_backupFileConfiguration "/etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_ident.conf" "${__PATH_CONFIG}/${FILEIDENT}"
}


###
# Synchronisation de la configuration
##
debian_include_synccfg()
{
    logger_debug "debian_include_synccfg (postgres)"
    local FILECFG=$(yaml_getConfig "postgres.filecfg")
    local FILEAUTH=$(yaml_getConfig "postgres.fileauth")
    local FILEIDENT=$(yaml_getConfig "postgres.fileident")

    echo "postgres"
    [[ -n "${FILECFG}" ]] && echo "postgres/${FILECFG}"
    [[ -n "${FILEAUTH}" ]] && echo "postgres/${FILEAUTH}"
    [[ -n "${FILEIDENT}" ]] && echo "postgres/${FILEIDENT}"
}


###
# Initialisation du répertoire contenant les données de la base
##
function debian_include_postgres_path()
{
    logger_debug "debian_include_postgres_path ()"
    local POSTGRES_PATH=$(yaml_getConfig "postgres.path")

    service postgresql stop
    logger_info "Initialisation de ${POSTGRES_PATH}"
    if [[ -d ${POSTGRES_PATH} ]]; then
        logger_debug "rm -rf ${POSTGRES_PATH}"
        rm -rf ${POSTGRES_PATH}/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical
    else
        logger_debug "mkdir -p ${POSTGRES_PATH}"
        mkdir -p ${POSTGRES_PATH} > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical
    fi
    logger_debug "chown -R postgres.postgres ${POSTGRES_PATH}"
    chown -R postgres:postgres ${POSTGRES_PATH} > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    logger_debug "chmod 700 ${POSTGRES_PATH}"
    chmod 700 ${POSTGRES_PATH} > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    logger_debug "/usr/lib/postgresql/9.3/bin/initdb -D ${POSTGRES_PATH}; exit $?"
    su - postgres --command "/usr/lib/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/bin/initdb -D ${POSTGRES_PATH}; exit $?"
    [[ $? -ne 0 ]] && logger_critical
    echo -e "Regenération de l'instance PostgreSQL : ${CVERT}OK ...${CVOID}"
}


###
# Déclaration des utilisateurs et des privilèges
##
function debian_include_postgres_users()
{
    logger_debug "debian_include_postgres_users ()"
    local USERNAME USERGRANT

    for (( I = 1; I < 10; I++ )); do
        USERNAME=$(yaml_getConfig "postgres.users.user_${I}.name")
        [[ -z ${USERNAME} ]] && break
        USERGRANT=$(yaml_getConfig "postgres.users.user_${I}.grant")
        logger_info "Privilège de l'utilisateur '${USERNAME}'"

        # Création de l'utilisateur si celui-ci n'existe pas
        logger_debug "SELECT 1 FROM pg_roles WHERE rolname='${USERNAME}'"
        su -l postgres -c "psql postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='${USERNAME}'\"" | grep -q 1
        if [[ $? -ne 0 ]]; then
            stdin_readDoublePassword "Choisir un mot de passe pour l'utilisateur ${CCYAN}${USERNAME}${CVOID}"
            logger_debug "CREATE ROLE ${USERNAME} ENCRYPTED PASSWORD '???'"
            su -l postgres -c "psql postgres -tAc \"CREATE ROLE ${USERNAME} ENCRYPTED PASSWORD '${OLIX_STDIN_RETURN}'\"" > ${OLIX_LOGGER_FILE_ERR} 2>&1
            [[ $? -ne 0 ]] && logger_critical
        fi

        logger_debug "ALTER ROLE ${USERNAME} LOGIN ${USERGRANT}"
        su -l postgres -c "psql postgres -tAc \"ALTER ROLE ${USERNAME} LOGIN ${USERGRANT}\"" > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical

        echo -e "Privilèges de l'utilisateur ${CCYAN}${USERNAME}${CVOID} : ${CVERT}OK ...${CVOID}"
    done
}
