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


debian_include_title()
{
    echo
    echo -e "${CBLANC} Configuration réseau ${CVOID}"
    echo -e "-------------------------------------------------------------------------------"
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_include_main()
{
    logger_debug "debian_include_main (network, $1)"

    case $1 in
        install)
            debian_include_install
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
    logger_debug "debian_include_install (network)"

    local ADDRIP=$(yaml_getConfig "network.addrip")

    # Affichage des infos
    echo -en "Adresse IP courante : "
    local CURRENT_IP=`ifconfig eth0 | sed -n '/^[A-Za-z0-9]/ {N;/dr:/{;s/.*dr://;s/ .*//;p;}}'`
    local CURRENT_IP=`ifconfig eth0 | awk 'NR==2 {print $2}'| awk -F: '{print $2}'`
    echo -e "${CBLEU}${CURRENT_IP}${CVOID}"

    if [[ ${ADDRIP} == ${CURRENT_IP} ]]; then
        logger_warning "Configuration du réseau déjà effectué"
        return 1
    fi

    if [[ -z ${ADDRIP} ]]; then
        logger_warning "Pas de configuration du réseau : conservation de l'IP actuelle"
        return 1
    else
        echo -e "Adresse IP à modifier : ${CCYAN}${ADDRIP}${CVOID}"
    fi

    # Modifie si OK
    stdin_readYesOrNo "Confirmer pour la modification de la conf réseau" false
    if [[ ${OLIX_STDIN_RETURN} == true ]]; then
        debian_include_network_config
        echo -e "Adresse ${CCYAN}${ADDRIP}${CVOID} à modifier : ${CVERT}OK ...${CVOID}"
        debian_include_restart
    fi
    return 0
}


###
# Redemarrage du service
##
debian_include_restart()
{
    logger_debug "debian_include_restart (network)"

    logger_info "Arrêt de eth0"
    systemctl stop networking > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
    logger_info "Démarrage de eth0"
    systemctl start networking > ${OLIX_LOGGER_FILE_ERR} 2>&1
    [[ $? -ne 0 ]] && logger_critical
}


###
#  Ecrit dans le fichier de configuration /etc/network/interfaces
##
function debian_include_network_config()
{
    logger_debug "debian_include_network_config ()"

    local ADDRIP=$(yaml_getConfig "network.addrip")

    module_debian_backupFileOriginal "/etc/network/interfaces"

    logger_info "Ecriture de l'IP '${ADDRIP}' dans le fichier /etc/network/interfaces"
    cat > /etc/network/interfaces 2>${OLIX_LOGGER_FILE_ERR} <<EOT
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet static
  address $(yaml_getConfig "network.addrip")
  netmask $(yaml_getConfig "network.netmask")
  network $(yaml_getConfig "network.network")
  broadcast $(yaml_getConfig "network.broadcast")
  gateway $(yaml_getConfig "network.gateway")
  dns-nameservers $(yaml_getConfig "network.resolv")
EOT
    [[ $? -ne 0 ]] && logger_critical
}