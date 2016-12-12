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
# Parsing des paramètres
##
olixmodule_debian_params_parse "install" $@


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

for I in $OLIX_MODULE_DEBIAN_PACKAGES; do
    info "Installation de '${I}'"
    if ! $(String.list.contains "$OLIX_MODULE_DEBIAN_PACKAGES_INSTALL" $I); then
        warning "Apparement le package '${I}' est inconnu !"
    else
        Debian.service.execute $I install
    fi
done


###
# FIN
##
echo -e "${CVERT}Action terminée avec succès${CVOID}"
