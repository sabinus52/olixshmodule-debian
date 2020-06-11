###
# Installation des packages
# ==============================================================================
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
##


###
# Librairies
##


###
# Affichage de l'aide
##
if [[ $# -lt 1 ]]; then
    Module.execute.usage "install"
    die 1
fi


###
# Charge le fichier de configuration contenant les paramètes necessaires à l'installation
###
Debian.config.load


###
# Traitement
##

# Mise à jour si installation complète
[[ $OLIX_MODULE_DEBIAN_PACKAGES_COMPLETE == true ]] && Debian.service.execute apt-update main

# Tous les packages pour l'installation
[[ $OLIX_MODULE_DEBIAN_PACKAGES_COMPLETE == true ]] && OLIX_MODULE_DEBIAN_PACKAGES=$OLIX_MODULE_DEBIAN_PACKAGES_INSTALL

# Variables d'environement global
OLIX_ENVNAME=$(Yaml.get "envname")
info "Environnement : ENVNAME=${OLIX_ENVNAME}"
echo "export ENVNAME=${OLIX_ENVNAME}" > /etc/profile.d/olixsh.sh

for I in $OLIX_MODULE_DEBIAN_PACKAGES; do
    info "Installation de '${I}'"
    if ! $(String.list.contains "$OLIX_MODULE_DEBIAN_PACKAGES_INSTALL" $I); then
        warning "Apparement le package '${I}' est inconnu !"
    elif [[ $OLIX_MODULE_DEBIAN_PACKAGES_COMPLETE == true && $I == "virtualbox" ]]; then
        warning "L'installation du package 'virtualbox' doit être installé séparement"
    else
        Debian.service.execute $I install
    fi
done

if [[ $OLIX_MODULE_DEBIAN_PACKAGES_COMPLETE == true ]]; then
    warning "L'installation du package 'virtualbox' doit être installé séparement"
fi

###
# FIN
##
echo -e "${CVERT}Action terminée avec succès${CVOID}"
