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

MODULE_DEBIAN_POSTGRES_VERSION="9.6"


debian_service_title()
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
debian_service_main()
{
    debug "debian_service_main (postgres, $1)"

    if [[ "$(Yaml.get "postgres.enabled")" != true ]]; then
        warning "Service 'postgres' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname $OLIX_MODULE_DEBIAN_CONFIG)/postgres"

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
    debug "debian_service_install (postgres)"

    info "Installation des packages PostgreSQL"
    apt-get --yes install postgresql postgresql-contrib
    [[ $? -ne 0 ]] && critical "Impossible d'installer les packages PostgreSQL"

    local POSTGRES_PATH=$(Yaml.get "postgres.path")
    [[ -z $POSTGRES_PATH ]] && return 0
    echo -e "Création de l'instance PostgreSQL dans ${CCYAN}${POSTGRES_PATH}${CVOID}"
    OLIX_FUNCTION_RETURN=true
    if [[ -d $POSTGRES_PATH ]]; then
        echo -e "${CJAUNE}ATTENTION !!! L'instance existe déjà dans le répertoire '${POSTGRES_PATH}'${CVOID}"
        Read.confirm "Confirmer pour ECRASEMENT" false
    fi
    # Initialisation du répertoire contenant les données de la base
    [[ $OLIX_FUNCTION_RETURN == true ]] && debian_service_postgres_path
}


###
# Configuration du service
##
debian_service_config()
{
    debug "debian_service_config (postgres)"

    # Mise en place du fichier de configuration
    local FILECFG=$(Yaml.get "postgres.filecfg")
    if [[ -n "${FILECFG}" ]]; then
        Debian.fileconfig.keep "/etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/postgresql.conf"
        Debian.fileconfig.install \
            "${__PATH_CONFIG}/$FILECFG" "/etc/postgresql/$MODULE_DEBIAN_POSTGRES_VERSION/main/postgresql.conf" \
            "Mise en place de ${CCYAN}${FILECFG}${CVOID} vers /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/postgresql.conf"
        debug "chown postgres.postgres /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/postgresql.conf"
        chown postgres.postgres /etc/postgresql/$MODULE_DEBIAN_POSTGRES_VERSION/main/postgresql.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical
    fi

    # Mise en place du fichier d'authentification
    local FILEAUTH=$(Yaml.get "postgres.fileauth")
    if [[ -n "${FILEAUTH}" ]]; then
        Debian.fileconfig.keep "/etc/postgresql/$MODULE_DEBIAN_POSTGRES_VERSION/main/pg_hba.conf"
        Debian.fileconfig.install \
            "${__PATH_CONFIG}/$FILEAUTH" "/etc/postgresql/$MODULE_DEBIAN_POSTGRES_VERSION/main/pg_hba.conf" \
            "Mise en place de ${CCYAN}${FILEAUTH}${CVOID} vers /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_hba.conf"
        debug "chown postgres.postgres /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_hba.conf"
        chown postgres.postgres /etc/postgresql/$MODULE_DEBIAN_POSTGRES_VERSION/main/pg_hba.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical
    fi

    # Mise en place du fichier d'identification
    local FILEIDENT=$(Yaml.get "postgres.fileident")
    if [[ -n "${FILEIDENT}" ]]; then
        Debian.fileconfig.keep "/etc/postgresql/$MODULE_DEBIAN_POSTGRES_VERSION/main/pg_ident.conf"
        Debian.fileconfig.install \
            "${__PATH_CONFIG}/$FILEIDENT" "/etc/postgresql/$MODULE_DEBIAN_POSTGRES_VERSION/main/pg_ident.conf" \
            "Mise en place de ${CCYAN}${FILEIDENT}${CVOID} vers /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_ident.conf"
        debug "chown postgres.postgres /etc/postgresql/${MODULE_DEBIAN_POSTGRES_VERSION}/main/pg_ident.conf"
        chown postgres.postgres /etc/postgresql/$MODULE_DEBIAN_POSTGRES_VERSION/main/pg_ident.conf > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical
    fi

    debian_service_restart

    # Déclaration des utilisateurs
    debian_service_postgres_users
}


###
# Redemarrage du service
##
debian_service_restart()
{
    debug "debian_service_restart (postgres)"

    info "Redémarrage du service PostgreSQL"
    systemctl restart postgresql
    [[ $? -ne 0 ]] && critical "Service PostgreSQL NOT running"
}


###
# Sauvegarde de la configuration
##
debian_service_savecfg()
{
    debug "debian_service_savecfg (postgres)"
    local FILECFG=$(Yaml.get "postgres.filecfg")
    local FILEAUTH=$(Yaml.get "postgres.fileauth")
    local FILEIDENT=$(Yaml.get "postgres.fileident")

    [[ -n "$FILECFG" ]] && Debian.fileconfig.save "/etc/postgresql/$MODULE_DEBIAN_POSTGRES_VERSION/main/postgresql.conf" "${__PATH_CONFIG}/$FILECFG"
    [[ -n "$FILEAUTH" ]] && Debian.fileconfig.save "/etc/postgresql/$MODULE_DEBIAN_POSTGRES_VERSION/main/pg_hba.conf" "${__PATH_CONFIG}/$FILEAUTH"
    [[ -n "$FILEIDENT" ]] && Debian.fileconfig.save "/etc/postgresql/$MODULE_DEBIAN_POSTGRES_VERSION/main/pg_ident.conf" "${__PATH_CONFIG}/$FILEIDENT"
}


###
# Synchronisation de la configuration
##
debian_service_synccfg()
{
    debug "debian_service_synccfg (postgres)"
    local FILECFG=$(Yaml.get "postgres.filecfg")
    local FILEAUTH=$(Yaml.get "postgres.fileauth")
    local FILEIDENT=$(Yaml.get "postgres.fileident")

    echo "postgres"
    [[ -n "$FILECFG" ]] && echo "postgres/$FILECFG"
    [[ -n "$FILEAUTH" ]] && echo "postgres/$FILEAUTH"
    [[ -n "$FILEIDENT" ]] && echo "postgres/$FILEIDENT"
}


###
# Initialisation du répertoire contenant les données de la base
##
function debian_service_postgres_path()
{
    debug "debian_service_postgres_path ()"
    local POSTGRES_PATH=$(Yaml.get "postgres.path")

    service postgresql stop
    info "Initialisation de ${POSTGRES_PATH}"
    if [[ -d $POSTGRES_PATH ]]; then
        debug "rm -rf ${POSTGRES_PATH}"
        rm -rf $POSTGRES_PATH/* > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical
    else
        debug "mkdir -p ${POSTGRES_PATH}"
        mkdir -p $POSTGRES_PATH > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical
    fi
    debug "chown -R postgres.postgres ${POSTGRES_PATH}"
    chown -R postgres:postgres $POSTGRES_PATH > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    debug "chmod 700 ${POSTGRES_PATH}"
    chmod 700 $POSTGRES_PATH > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    debug "/usr/lib/postgresql/9.3/bin/initdb -D ${POSTGRES_PATH}; exit $?"
    su - postgres --command "/usr/lib/postgresql/$MODULE_DEBIAN_POSTGRES_VERSION/bin/initdb -D $POSTGRES_PATH; exit $?"
    [[ $? -ne 0 ]] && critical
    echo -e "Regenération de l'instance PostgreSQL : ${CVERT}OK ...${CVOID}"
}


###
# Déclaration des utilisateurs et des privilèges
##
function debian_service_postgres_users()
{
    debug "debian_service_postgres_users ()"
    local USERNAME USERGRANT

    for (( I = 1; I < 10; I++ )); do
        USERNAME=$(Yaml.get "postgres.users.user_${I}.name")
        [[ -z $USERNAME ]] && break
        USERGRANT=$(Yaml.get "postgres.users.user_${I}.grant")
        info "Privilège de l'utilisateur '${USERNAME}'"

        # Création de l'utilisateur si celui-ci n'existe pas
        debug "SELECT 1 FROM pg_roles WHERE rolname='${USERNAME}'"
        su -l postgres -c "psql postgres -tAc \"SELECT 1 FROM pg_roles WHERE rolname='$USERNAME'\"" | grep -q 1
        if [[ $? -ne 0 ]]; then
            Read.passwordx2 "Choisir un mot de passe pour l'utilisateur ${CCYAN}${USERNAME}${CVOID}"
            debug "CREATE ROLE ${USERNAME} ENCRYPTED PASSWORD '???'"
            su -l postgres -c "psql postgres -tAc \"CREATE ROLE $USERNAME ENCRYPTED PASSWORD '$OLIX_FUNCTION_RETURN'\"" > ${OLIX_LOGGER_FILE_ERR} 2>&1
            [[ $? -ne 0 ]] && critical
        fi

        debug "ALTER ROLE ${USERNAME} LOGIN ${USERGRANT}"
        su -l postgres -c "psql postgres -tAc \"ALTER ROLE $USERNAME LOGIN $USERGRANT\"" > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical

        echo -e "Privilèges de l'utilisateur ${CCYAN}${USERNAME}${CVOID} : ${CVERT}OK ...${CVOID}"
    done
}
