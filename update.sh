###
# Mise à jour du système
# ==============================================================================
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
##

###
# Librairies
##


###
# Traitement
##
Debian.service.execute apt-update main


###
# FIN
##
echo -e "${CVERT}Action terminée avec succès${CVOID}"
