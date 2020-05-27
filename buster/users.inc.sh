###
# Création des utilisateurs
# ==============================================================================
# - Modification de l'utilisateur root
# - Création ou modification de l'utilisateur
# - Changement du prompt
# - Création des clés public et privée
# ------------------------------------------------------------------------------
# users:
#    user_1:
#        name:  Nom de l'utilisateur
#        param: Paramètres de l'utilisateur pour la création
#    user_N:
#        name:  
#        param: 
# ------------------------------------------------------------------------------
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
# @version 8 (jessie)
##


debian_service_title()
{
    echo
    echo -e "${CBLANC} Création et configuration du profile des utilisateurs ${CVOID}"
    echo -e "-------------------------------------------------------------------------------"
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_service_main()
{
    debug "debian_service_main (users, $1)"

    case $1 in
        install)
            debian_service_install
            ;;
        config)
            debian_service_config
            ;;
    esac
}


###
# Installation du service
##
debian_service_install()
{
    debug "debian_service_install (users)"

    debian_service_users_skel

    debian_service_users_root
    echo -e "Configuration de l'utilisateur ${CCYAN}root${CVOID} : ${CVERT}OK ...${CVOID}"

    local USERLOCAL USERPARAM
    for (( I = 1; I < 10; I++ )); do
        USERLOCAL=$(Yaml.get "users.user_${I}.name")
        [[ -z ${USERLOCAL} ]] && break
        USERPARAM=$(Yaml.get "users.user_${I}.param")

        debian_service_users_user "$USERLOCAL" "$USERPARAM"
        echo -e "Configuration de l'utilisateur ${CCYAN}${USERLOCAL}${CVOID} : ${CVERT}OK ...${CVOID}"
    done
}


###
# Configuration du service
##
debian_service_config()
{
    debug "debian_service_config (users)"

    debian_service_install
}


###
# Configuration de l'utilisateur root
##
function debian_service_users_root()
{
    debug "debian_service_users_root ()"

    Debian.fileconfig.keep "/root/.bashrc"

    info "Customisation du prompt de root"
    sed -i "s/# export/export/g" /root/.bashrc
    sed -i "s/# eval/eval/g" /root/.bashrc
    sed -i "s/# alias/alias/g" /root/.bashrc
    echo "PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" >> /root/.bashrc

    if [ ! -f /root/.ssh/id_rsa ]; then
        info "Génération des clés publiques de root"
        ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ""
        [[ $? -ne 0 ]] && critical "Génération des clés publiques de root"
    fi
    return 0
}


###
# Configuration du skeleton
##
function debian_service_users_skel ()
{
    debug "debian_service_users_skel ()"

    Debian.fileconfig.keep "/etc/skel/.bashrc"

    info "Customisation du .bashrc"
    sed -i "s/\#force_color_prompt/force_color_prompt/g" /etc/skel/.bashrc
    sed -i "s/#alias l/alias l/g" /etc/skel/.bashrc
    sed -i "s/#alias grep/alias grep/g" /etc/skel/.bashrc
}


###
# Création et configuration de l'utilisateur
# @param $1 : Nom de l'utilisateur
# @param $2 : Paramètres de création
##
function debian_service_users_user()
{
    debug "debian_service_users_user ($1)"
    local UTILISATEUR=$1
    local USERPARAMS=$2
    [[ -z $1 ]] && return 1

    # Test si l'utilisateur existe deja
    if cut -d : -f 1 /etc/passwd | grep ^${UTILISATEUR}$ > /dev/null; then

        info "Modification de l'utilisateur '${UTILISATEUR}'"
        debug "usermod ${USERPARAMS} ${UTILISATEUR}"
        usermod $USERPARAMS $UTILISATEUR > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical "Modification de l'utilisateur '${UTILISATEUR}'"

        debug "cp /etc/skel/.bashrc ~/.bashrc"
        su - $UTILISATEUR -c "cp /etc/skel/.bashrc ~/.bashrc" > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical "Copie du .bashrc de '${UTILISATEUR}'"

    else

        info "Création de l'utilisateur '${UTILISATEUR}'"
        debug "useradd ${USERPARAMS} ${UTILISATEUR}"
        useradd $USERPARAMS $UTILISATEUR > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical "Création de l'utilisateur '${UTILISATEUR}'"

        echo -e "Mode de passe pour ${CCYAN}${UTILISATEUR}${CVOID}"
        passwd $UTILISATEUR
        
   fi
   
   # Clé privée et publique
    if [ ! -f /home/${UTILISATEUR}/.ssh/id_rsa ]; then
        info "Génération de la clé publique et privée de '${UTILISATEUR}'"
        su - $UTILISATEUR -c "ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ''" > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && critical "Génération de la clé publique et privée de '${UTILISATEUR}'"
    fi
}
