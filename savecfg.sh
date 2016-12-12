###
# Sauvegarde de la configuration des services
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
    Module.execute.usage "savecfg"
    die 1
fi


###
# Parsing des paramètres
##
olixmodule_debian_params_parse "savecfg" $@


###
# Charge le fichier de configuration contenant les paramètes necessaires à l'installation
###
Debian.config.load


###
# Traitement
##

# Tous les packages pour la sauvegarde
[[ $OLIX_MODULE_DEBIAN_PACKAGES_COMPLETE == true ]] && OLIX_MODULE_DEBIAN_PACKAGES=$OLIX_MODULE_DEBIAN_PACKAGES_SAVECFG

for I in $OLIX_MODULE_DEBIAN_PACKAGES; do
    info "Sauvegarde de la configuration de '${I}'"
    if ! $(String.list.contains "$OLIX_MODULE_DEBIAN_PACKAGES_SAVECFG" $I); then
        warning "Apparement le package '${I}' est inconnu !"
    else
        Debian.service.execute $I savecfg
    fi
done


###
# FIN
##
echo -e "${CVERT}Action terminée avec succès${CVOID}"
