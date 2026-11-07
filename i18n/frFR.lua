if GetLocale() ~= "frFR" then
    return
end

local _, ns = ...
local L = ns.L

L["TITLE"] = "Trésors";

L["KIND_CONTAINER"] = "Conteneurs";
L["KIND_LOCKBOX"] = "Coffrets verrouillés";
L["KIND_TOY"] = "Jouets";
L["KIND_MOUNT"] = "Montures";
L["KIND_PET"] = "Mascottes";
L["KIND_APPEARANCE"] = "Apparences";
L["KIND_RECIPE"] = "Recettes";
L["KIND_LISTED"] = "Vos objets";

L["CATEGORY_SINGLE"] = "Trésors";
L["CATEGORY_KIND"] = "Trésors : %s";

L["OPTIONS_DESC"] = "Trouve les trésors dans vos sacs : les objets à ouvrir, et ce qui s'apprend ou se collectionne. La détection utilise les données du jeu, elle fonctionne donc dans toutes les langues.";
L["OPTIONS_CATEGORIES"] = "Catégories";
L["OPTIONS_CATEGORY_MODE"] = "Regrouper les trésors";
L["OPTIONS_CATEGORY_MODE_DESC"] = "Met tous les trésors dans une catégorie Trésors, donne à chaque type sa propre catégorie, ou les laisse dans leurs catégories habituelles (ils restent mis en évidence).";
L["OPTIONS_CATEGORY_OFF"] = "Ne pas les regrouper";
L["OPTIONS_CATEGORY_SINGLE"] = "Une catégorie Trésors";
L["OPTIONS_CATEGORY_SPLIT"] = "Une catégorie par type";
L["OPTIONS_KINDS"] = "Trésors à trouver";
L["OPTIONS_KINDS_DESC"] = "Les types d'objets qui comptent comme des trésors, pour les catégories et la mise en évidence.";
L["OPTIONS_KIND"] = "Trouver";
L["OPTIONS_UNCOLLECTED"] = "Seulement ce que je n'ai pas encore collectionné";
L["OPTIONS_UNCOLLECTED_DESC"] = "Les jouets, montures, mascottes, apparences et recettes que vous connaissez déjà ne sont pas des trésors : les doublons restent là où vous pouvez les vendre ou les échanger.";
L["OPTIONS_HIGHLIGHT"] = "Mise en évidence";
L["OPTIONS_STYLE"] = "Style de mise en évidence";
L["OPTIONS_STYLE_DESC"] = "Comment les trésors sont marqués sur leurs boutons.";
L["OPTIONS_STYLE_NONE"] = "Aucun";
L["OPTIONS_STYLE_GLOW"] = "Halo";
L["OPTIONS_STYLE_BADGE"] = "Badge dans un coin";
L["OPTIONS_STYLE_BOTH"] = "Halo et badge";
L["OPTIONS_COLOR"] = "Couleur du halo";
L["OPTIONS_CORNER"] = "Coin du badge";
L["OPTIONS_CORNER_TOPLEFT"] = "En haut à gauche";
L["OPTIONS_CORNER_TOPRIGHT"] = "En haut à droite";
L["OPTIONS_CORNER_BOTTOMLEFT"] = "En bas à gauche";
L["OPTIONS_PULSE"] = "Pulsation";
L["OPTIONS_PULSE_DESC"] = "La mise en évidence apparaît et disparaît lentement. Désactivée, elle reste fixe.";
L["OPTIONS_GREY"] = "Griser ce que je ne peux pas encore ouvrir ou utiliser";
L["OPTIONS_GREY_DESC"] = "Les coffrets encore verrouillés, et les trésors au-dessus de votre niveau, sont mis en évidence en gris.";
L["OPTIONS_LISTS"] = "Vos objets";
L["OPTIONS_LISTS_DESC"] = "Les objets que vous voulez toujours comme trésors, ou jamais. Tapez un ID d'objet dans une case, ou dans le chat (Maj-clic sur un objet pour y mettre son lien) : |cffffd100/treasures always <objet>|r, |cffffd100/treasures never <objet>|r, |cffffd100/treasures remove <objet>|r.";
L["OPTIONS_ALWAYS_ADD"] = "Toujours un trésor";
L["OPTIONS_NEVER_ADD"] = "Jamais un trésor";
L["OPTIONS_LISTED"] = "Objets de la liste";
L["OPTIONS_REMOVE"] = "Retirer de la liste";
L["OPTIONS_INVALID_ITEM"] = "Ce n'est ni un ID d'objet ni un lien d'objet.";

L["LIST_ALWAYS"] = "Toujours";
L["LIST_NEVER"] = "Jamais";
L["LIST_ADDED_ALWAYS"] = "%s est maintenant toujours un trésor.";
L["LIST_ADDED_NEVER"] = "%s n'est maintenant jamais un trésor.";
L["LIST_REMOVED"] = "%s a été retiré de votre liste.";
L["LIST_NOT_LISTED"] = "%s n'est pas dans votre liste.";
L["SLASH_HELP"] = "Commandes : |cffffd100/treasures always <objet>|r, |cffffd100/treasures never <objet>|r, |cffffd100/treasures remove <objet>|r, |cffffd100/treasures list|r.";
L["LIST_EMPTY"] = "Votre liste est vide.";

