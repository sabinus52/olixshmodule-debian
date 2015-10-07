###
# Usage du module DEBIAN
# ==============================================================================
# @package olixsh
# @module debian
# @author Olivier <sabinus52@gmail.com>
##


###
# Usage principale du module
##
function module_debian_usage_main()
{
    logger_debug "module_debian_usage_main ()"
    stdout_printVersion
    echo
    echo -e "Installation, configuration et gestion d'un serveur DEBIAN ${CBLANC}$(lsb_release -sr) (${OLIX_MODULE_DEBIAN_VERSION_RELEASE})${CVOID}"
    echo
    echo -e "${CBLANC} Usage : ${CVIOLET}$(basename ${OLIX_ROOT_SCRIPT}) ${CVERT}debian ${CJAUNE}<action>${CVOID}"
    echo
    echo -e "${CJAUNE}Liste des ACTIONS disponibles${CVOID} :"
    echo -e "${Cjaune} init    ${CVOID}  : Initialisation du module"
    echo -e "${Cjaune} help    ${CVOID}  : Affiche cet écran"
}
