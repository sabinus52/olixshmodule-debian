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


debian_service_title()
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
debian_service_main()
{
    debug "debian_service_main (postfix, $1)"

    if [[ "$(Yaml.get "postfix.enabled")" != true ]]; then
        warning "Service 'postfix' non activé"
        return 1
    fi

    __PATH_CONFIG="$(dirname $OLIX_MODULE_DEBIAN_CONFIG)/postfix"

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
    esac
}


###
# Installation du service
##
debian_service_install()
{
    debug "debian_service_install (postfix)"

    info "Installation des packages POSTFIX"
    apt-get --yes install mailutils postfix libsasl2-modules sasl2-bin
    [[ $? -ne 0 ]] && critical "Impossible d'installer les packages POSTFIX"
}


###
# Configuration du service
##
debian_service_config()
{
    debug "debian_service_config (postfix)"
    local RELAY_HOST=$(Yaml.get "postfix.relay.host")
    local RELAY_PORT=$(Yaml.get "postfix.relay.port")
    local AUTH_LOGIN=$(Yaml.get "postfix.auth.login")

    # Changement du relais
    info "Changement du relais SMTP"
    debug "relayhost = ${RELAY_HOST}:${RELAY_PORT}"
    postconf -e "relayhost = ${RELAY_HOST}:${RELAY_PORT}"

    # Authentification
    if [[ ! -z $AUTH_LOGIN ]]; then
        debian_service_postfix_authentification
    fi
}


###
# Redemarrage du service
##
debian_service_restart()
{
    debug "debian_service_restart (postfix)"

    info "Redémarrage du service POSTFIX"
    systemctl restart postfix
    [[ $? -ne 0 ]] && critical "Service POSTFIX NOT running"
}


###
# Modification de la conf en mode authentification
##
function debian_service_postfix_authentification()
{
    debug "debian_service_postfix_authentification ()"
    local RELAY_HOST=$(Yaml.get "postfix.relay.host")
    local RELAY_PORT=$(Yaml.get "postfix.relay.port")
    local AUTH_LOGIN=$(Yaml.get "postfix.auth.login")
    local AUTH_PASSWORD=$(Yaml.get "postfix.auth.password")

    info "Modification de la conf postfix"
    postconf -e 'smtpd_sasl_auth_enable = no'
    postconf -e 'smtp_sasl_auth_enable = yes'
    postconf -e 'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd'
    postconf -e 'smtpd_sasl_local_domain = $myhostname'
    postconf -e 'smtp_sasl_security_options = noanonymous'
    postconf -e 'smtp_sasl_tls_security_options = noanonymous'

    info "Création du fichier d'authentification sasl_passwd"
    if [[ -z $AUTH_PASSWORD ]]; then
        Read.password "Mot de passe au serveur SMTP ${RELAY_HOST} en tant que ${AUTH_LOGIN}"
        AUTH_PASSWORD=$OLIX_FUNCTION_RETURN
    fi
    debug "${RELAY_HOST}:${RELAY_PORT}    ${AUTH_LOGIN}:${AUTH_PASSWORD} > /etc/postfix/sasl_passwd"
    echo "${RELAY_HOST}:${RELAY_PORT}    ${AUTH_LOGIN}:${AUTH_PASSWORD}" > /etc/postfix/sasl_passwd
    debug "postmap /etc/postfix/sasl_passwd"
    postmap /etc/postfix/sasl_passwd > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    rm -f /etc/postfix/sasl_passwd
    echo -e "Authentification sur ${CCYAN}${RELAY_HOST}:${RELAY_PORT}${CVOID} : ${CVERT}OK ...${CVOID}"
}
