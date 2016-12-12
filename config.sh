###
# Configuration des packages
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
    Module.execute.usage "config"
    die 1
fi


###
# Parsing des paramètres
##
olixmodule_debian_params_parse "config" $@

if [[ $OLIX_MODULE_DEBIAN_PACKAGES_COMPLETE == true ]]; then
    Module.execute.usage "config"
    die 1
fi


###
# Charge le fichier de configuration contenant les paramètes necessaires à l'installation
###
Debian.config.load


###
# Traitement
##
for I in $OLIX_MODULE_DEBIAN_PACKAGES; do
    info "Configuration de '${I}'"
    if ! $(String.list.contains "$OLIX_MODULE_DEBIAN_PACKAGES_CONFIG" $I); then
        warning "Apparement le package '${I}' est inconnu !"
    else
        Debian.service.execute $I config
    fi
done


###
# FIN
##
echo -e "${CVERT}Action terminée avec succès${CVOID}"
