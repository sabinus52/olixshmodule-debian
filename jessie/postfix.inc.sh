###
# Installation et configuration de POSTFIX
# ==============================================================================
# - Installation des paquets POSTFIX
# - Changement de la configuration
# ------------------------------------------------------------------------------
# postfix:
#   enabled:
#   relay:
#     host:     Host du relais SMTP
#     port:     Port du relais SMTP
#  auth:
#     login:    Login de l'authentification
#     password: Mot de passe FACULTATIF de l'authentification
# ------------------------------------------------------------------------------
# @modified 11/05/2014
# Plus besoin de changer le hostname du postfix : utilisation du FQDN du système
# @modified 16/06/2014
# sendmail obselete -> postfix obligatoire
# Permettre un relai SMTP avec authentification
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
            echo -e "${CBLANC} Installation de POSTFIX ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        config)
            echo
            echo -e "${CBLANC} Configuration de POSTFIX ${CVOID}"
            echo -e "-------------------------------------------------------------------------------"
            ;;
        savecfg)
            echo -e "${CBLANC} Sauvegarde de la configuration de POSTFIX ${CVOID}"
            ;;
    esac
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_include_main()
{
    logger_debug "debian_include_main (postfix, $1)"

    if [[ "$(yaml_getConfig "postfix.enabled")" != true ]]; then
        logger_warning "Service 'postfix' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname ${OLIX_MODULE_DEBIAN_CONFIG})/postfix"

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
    esac
}


###
# Installation du service
##
debian_include_install()
{
    logger_debug "debian_include_install (postfix)"

    logger_info "Installation des packages POSTFIX"
    apt-get --yes install mailutils postfix libsasl2-modules sasl2-bin
    [[ $? -ne 0 ]] && logger_critical "Impossible d'installer les packages POSTFIX"
}


###
# Configuration du service
##
debian_include_config()
{
    logger_debug "debian_include_config (postfix)"
    local RELAY_HOST=$(yaml_getConfig "postfix.relay.host")
    local RELAY_PORT=$(yaml_getConfig "postfix.relay.port")
    local AUTH_LOGIN=$(yaml_getConfig "postfix.auth.login")

    # Changement du relais
    logger_info "Changement du relais SMTP"
    logger_debug "relayhost = ${RELAY_HOST}:${RELAY_PORT}"
    postconf -e "relayhost = ${RELAY_HOST}:${RELAY_PORT}"

    # Authentification
    if [[ ! -z ${AUTH_LOGIN} ]]; then
        debian_include_postfix_authentification
    fi
}


###
# Redemarrage du service
##
debian_include_restart()
{
    logger_debug "debian_include_restart (postfix)"

    logger_info "Redémarrage du service POSTFIX"
    systemctl restart postfix
    [[ $? -ne 0 ]] && logger_critical "Service POSTFIX NOT running"
}


###
# Modification de la conf en mode authentification
##
function debian_include_postfix_authentification()
{
    logger_debug "debian_include_postfix_authentification ()"
    local RELAY_HOST=$(yaml_getConfig "postfix.relay.host")
    local RELAY_PORT=$(yaml_getConfig "postfix.relay.port")
    local AUTH_LOGIN=$(yaml_getConfig "postfix.auth.login")
    local AUTH_PASSWORD=$(yaml_getConfig "postfix.auth.password")

    logger_info "Modification de la conf postfix"
    postconf -e 'smtpd_sasl_auth_enable = no'
    postconf -e 'smtp_sasl_auth_enable = yes'
    postconf -e 'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd'
    postconf -e 'smtpd_sasl_local_domain = $myhostname'
    postconf -e 'smtp_sasl_security_options = noanonymous'
    postconf -e 'smtp_sasl_tls_security_options = noanonymous'

    logger_info "Création du fichier d'authentification sasl_passwd"
    if [[ -z ${AUTH_PASSWORD} ]]; then
        stdin_readPassword "Mot de passe au serveur SMTP ${RELAY_HOST} en tant que ${AUTH_LOGIN}"
        AUTH_PASSWORD=${OLIX_STDIN_RETURN}
    fi
    logger_debug "${RELAY_HOST}:${RELAY_PORT}    ${AUTH_LOGIN}:${AUTH_PASSWORD} > /etc/postfix/sasl_passwd"
    echo "${RELAY_HOST}:${RELAY_PORT}    ${AUTH_LOGIN}:${AUTH_PASSWORD}" > /etc/postfix/sasl_passwd
    logger_debug "postmap /etc/postfix/sasl_passwd"
    postmap /etc/postfix/sasl_passwd > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    rm -f /etc/postfix/sasl_passwd
    echo -e "Authentification sur ${CCYAN}${RELAY_HOST}:${RELAY_PORT}${CVOID} : ${CVERT}OK ...${CVOID}"
}
