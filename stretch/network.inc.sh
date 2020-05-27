###
# Configuration du réseau
# ==============================================================================
# - Changement de l'adresse IP
# ------------------------------------------------------------------------------
# network:
#    addrip:     Valeur de l'adresse IP à ajouter
#    netmask:    Masque réseau de cette IP
#    network:    Adresse du réseau
#    broadcast:  Adresse du broadcast
#    gateway:    Adresse de la passerelle
#    resolv:     Liste des serveurs DNS
# ------------------------------------------------------------------------------
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
# @version 8 (jessie)
##


debian_service_title()
{
    echo
    echo -e "${CBLANC} Configuration réseau ${CVOID}"
    echo -e "-------------------------------------------------------------------------------"
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_service_main()
{
    debug "debian_service_main (network, $1)"

    case $1 in
        install)
            debian_service_install
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
    debug "debian_service_install (network)"

    local ADDRIP=$(Yaml.get "network.addrip")

    # Affichage des infos
    echo -en "Adresse IP courante : "
    local CURRENT_IP=$(ip a s|sed -ne '/127.0.0.1/!{s/^[ \t]*inet[ \t]*\([0-9.]\+\)\/.*$/\1/p}')
    echo -e "${CBLEU}${CURRENT_IP}${CVOID}"

    if [[ $ADDRIP == $CURRENT_IP ]]; then
        warning "Configuration du réseau déjà effectué"
        return 1
    fi

    if [[ -z $ADDRIP ]]; then
        warning "Pas de configuration du réseau : conservation de l'IP actuelle"
        return 1
    else
        echo -e "Adresse IP à modifier : ${CCYAN}${ADDRIP}${CVOID}"
    fi

    # Modifie si OK
    Read.confirm "Confirmer pour la modification de la conf réseau" false
    if [[ ${OLIX_FUNCTION_RETURN} == true ]]; then
        debian_service_network_config
        echo -e "Adresse ${CCYAN}${ADDRIP}${CVOID} à modifier : ${CVERT}OK ...${CVOID}"
        #debian_service_restart
    fi
    return 0
}


###
# Redemarrage du service
##
debian_service_restart()
{
    debug "debian_service_restart (network)"

    info "Arrêt de eth0"
    systemctl stop networking > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
    info "Démarrage de eth0"
    systemctl start networking > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && critical
}


###
#  Ecrit dans le fichier de configuration /etc/network/interfaces
##
function debian_service_network_config()
{
    debug "debian_service_network_config ()"

    local ADDRIP=$(Yaml.get "network.addrip")

    Debian.fileconfig.keep "/etc/network/interfaces"

    info "Ecriture de l'IP '${ADDRIP}' dans le fichier /etc/network/interfaces"
    cat > /etc/network/interfaces 2>${OLIX_LOGGER_FILE_ERR} <<EOT
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
  address $(Yaml.get "network.addrip")
  netmask $(Yaml.get "network.netmask")
  network $(Yaml.get "network.network")
  broadcast $(Yaml.get "network.broadcast")
  gateway $(Yaml.get "network.gateway")
  dns-nameservers $(Yaml.get "network.resolv")
EOT
    [[ $? -ne 0 ]] && critical
}
