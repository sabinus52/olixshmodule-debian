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


debian_include_title()
{
    echo
    echo -e "${CBLANC} Création et configuration du profile des utilisateurs ${CVOID}"
    echo -e "-------------------------------------------------------------------------------"
}


###
# Fonction principal
# @param $1 : action à faire
##
debian_include_main()
{
    logger_debug "debian_include_main (users, $1)"

    case $1 in
        install)
            debian_include_install
            ;;
        config)
            debian_include_config
            ;;
    esac
}


###
# Installation du service
##
debian_include_install()
{
    logger_debug "debian_include_install (users)"

    debian_include_users_skel

    debian_include_users_root
    echo -e "Configuration de l'utilisateur ${CCYAN}root${CVOID} : ${CVERT}OK ...${CVOID}"

    local USERLOCAL USERPARAM
    for (( I = 1; I < 10; I++ )); do
        USERLOCAL=$(yaml_getConfig "users.user_${I}.name")
        [[ -z ${USERLOCAL} ]] && break
        USERPARAM=$(yaml_getConfig "users.user_${I}.param")

        debian_include_users_user "${USERLOCAL}" "${USERPARAM}"
        echo -e "Configuration de l'utilisateur ${CCYAN}${USERLOCAL}${CVOID} : ${CVERT}OK ...${CVOID}"
    done
}


###
# Configuration du service
##
debian_include_config()
{
    logger_debug "debian_include_config (users)"

    debian_include_install
}


###
# Configuration de l'utilisateur root
##
function debian_include_users_root()
{
    logger_debug "debian_include_users_root ()"

    module_debian_backupFileOriginal "/root/.bashrc"

    logger_info "Customisation du prompt de root"
    cat > /root/.bashrc 2>${OLIX_LOGGER_FILE_ERR} <<EOT
# Creation par l'utilitaire OliXsh

# Coloration du ls
eval "`dircolors`"
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Coloration du prompt
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;31m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOT
    [[ $? -ne 0 ]] && logger_critical

    if [ ! -f /root/.ssh/id_dsa ]; then
        logger_info "Génération des clés publiques de root"
        ssh-keygen -q -t dsa -f ~/.ssh/id_dsa -N ""
        [[ $? -ne 0 ]] && logger_critical "Génération des clés publiques de root"
    fi
    return 0
}


###
# Configuration du skeleton
##
function debian_include_users_skel ()
{
    logger_debug "debian_include_users_skel ()"

    module_debian_backupFileOriginal "/etc/skel/.bashrc"

    logger_info "Customisation du .bashrc"
    sed -i "s/\#force_color_prompt/force_color_prompt/g" /etc/skel/.bashrc
    sed -i "s/#alias l/alias l/g" /etc/skel/.bashrc
    sed -i "s/#alias grep/alias grep/g" /etc/skel/.bashrc
}


###
# Création et configuration de l'utilisateur
# @param $1 : Nom de l'utilisateur
# @param $2 : Paramètres de création
##
function debian_include_users_user()
{
    logger_debug "debian_include_users_user ($1)"
    local UTILISATEUR=$1
    local USERPARAMS=$2
    [[ -z $1 ]] && return 1

    # Test si l'utilisateur existe deja
    if cut -d : -f 1 /etc/passwd | grep ^${UTILISATEUR}$ > /dev/null; then

        logger_info "Modification de l'utilisateur '${UTILISATEUR}'"
        logger_debug "usermod ${USERPARAMS} ${UTILISATEUR}"
        usermod ${USERPARAMS} ${UTILISATEUR} > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical "Modification de l'utilisateur '${UTILISATEUR}'"

        logger_debug "cp /etc/skel/.bashrc ~/.bashrc"
        su - ${UTILISATEUR} -c "cp /etc/skel/.bashrc ~/.bashrc" > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical "Copie du .bashrc de '${UTILISATEUR}'"

    else

        logger_info "Création de l'utilisateur '${UTILISATEUR}'"
        logger_debug "useradd ${USERPARAMS} ${UTILISATEUR}"
        useradd ${USERPARAMS} ${UTILISATEUR} > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical "Création de l'utilisateur '${UTILISATEUR}'"

        echo -e "Mode de passe pour ${CCYAN}${UTILISATEUR}${CVOID}"
        passwd ${UTILISATEUR}
        
   fi
   
   # Clé privée et publique
    if [ ! -f /home/${UTILISATEUR}/.ssh/id_dsa ]; then
        logger_info "Génération de la clé publique et privée de '${UTILISATEUR}'"
        su - ${UTILISATEUR} -c "ssh-keygen -q -t dsa -f ~/.ssh/id_dsa -N ''" > ${OLIX_LOGGER_FILE_ERR} 2>&1
        [[ $? -ne 0 ]] && logger_critical "Génération de la clé publique et privée de '${UTILISATEUR}'"
    fi
}
