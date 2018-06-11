/**
 *  T8
 *  Author: Robin
 *  Description: Modelisation de la transition 800-1100, première version
 */

model t8

// L'ordre compte...
import "run.gaml"	
	
experiment Exp_5_0_A_gui type: gui until: (Annee >= fin_simulation){
	parameter 'save_outputs' var: save_outputs init: false;
	parameter 'prefix' var: prefix_output init: "5_0_gui";
	parameter "benchmark" var: benchmark init: false; // Changement pour connaitre perfs fonctions
	parameter "experimentType" var: experimentType init: "gui";
	parameter "serfs_mobiles" var: serfs_mobiles init: true;
	
	output {
		monitor "Annee" value: Annee;
		monitor "Nombre de Foyers paysans" value: length(Foyers_Paysans);
		monitor "Nombre FP dans agregat" value: Foyers_Paysans count (each.monAgregat != nil);
		monitor "Nombre d'agregats" value: length(Agregats);

		monitor "Nombre FP Comm." value: Foyers_Paysans count (each.communaute);
		monitor "Nombre Seigneurs" value: length(Seigneurs);
		monitor "Nombre Grands Seigneurs" value: Seigneurs count (each.type = "Grand Seigneur");
		monitor "Nombre Chatelains" value: Seigneurs count (each.type = "Chatelain");
		monitor "Nombre Petits Seigneurs" value: Seigneurs count (each.type = "Petit Seigneur");
		monitor "Nombre Eglises" value: length(Eglises);
		monitor "Nombre Eglises Paroissiales" value: Eglises count (each.eglise_paroissiale);
		monitor "Nombre Chateaux" value: length(Chateaux);
		monitor "% FP dispersés" value: Foyers_Paysans count (each.monAgregat = nil) / length(Foyers_Paysans) * 100;
		
		display "Carte" type: "opengl" {
			species Paroisses transparency: 0.9 ;
			species Zones_Prelevement transparency: 0.9;
			agents "Eglises Paroissiales" value: Eglises where (each.eglise_paroissiale) aspect: base transparency: 0.5;
			species Chateaux aspect: base ;
			species Foyers_Paysans transparency: 0.5;
			species Agregats transparency: 0.3;
	//		text string(Annee) size: 10000 position: {0, 1} color: rgb("black");
		}		
	}
}

experiment Exp_5_0_A type: batch repeat: 20 keep_seed: false until: (Annee >= fin_simulation){
	parameter 'save_outputs' var: save_outputs init: true;
	parameter 'prefix' var: prefix_output init: "5_0_A";
	parameter "benchmark" var: benchmark init: false; // Changement pour connaitre perfs fonctions
	parameter "serfs_mobiles" var: serfs_mobiles init: true;
}

experiment Exp_5_0_A_test type: batch repeat: 20 keep_seed: false until: (Annee >= fin_simulation){
	parameter 'save_outputs' var: save_outputs init: true;
	parameter 'prefix' var: prefix_output init: "5_0_A_win";
	parameter "benchmark" var: benchmark init: false; // Changement pour connaitre perfs fonctions
	parameter "serfs_mobiles" var: serfs_mobiles init: true;
}

experiment Exp_5_0_A_OM type: gui {
	parameter 'save_outputs' var: save_outputs init: false;
	parameter 'prefix' var: prefix_output init: "5_0_OM";
	parameter "benchmark" var: benchmark init: false; // Changement pour connaitre perfs fonctions
	parameter "experimentType" var: experimentType init: "gui";
	parameter "serfs_mobiles" var: serfs_mobiles init: true;
	parameter "summarised_outputs" var: summarised_outputs init:true;
}

experiment Exp_5_0_Test_01_06 type: batch repeat: 4 keep_seed: false until: (Annee >= fin_simulation){
	parameter 'save_outputs' var: save_outputs init: true;
	parameter 'prefix' var: prefix_output init: "5_0_Test_01_06";
	parameter "benchmark" var: benchmark init: false; // Changement pour connaitre perfs fonctions
	parameter "serfs_mobiles" var: serfs_mobiles init: true;
	parameter "nombre_fp_villages" var: nombre_FP_village among: [10, 9, 8, 7, 6, 5];
}

experiment Exp_5_0_Test_07_08 type: batch repeat: 20 keep_seed: false until: (Annee >= fin_simulation){
	parameter 'save_outputs' var: save_outputs init: true;
	parameter 'prefix' var: prefix_output init: "5_0_Test_07_08";
	parameter "benchmark" var: benchmark init: false; // Changement pour connaitre perfs fonctions
	parameter "serfs_mobiles" var: serfs_mobiles init: true;
	parameter "proba_ponderee_deplacement_lointain" var: proba_ponderee_deplacement_lointain among: [0.5, 0.7];
}

experiment Exp_5_0_Test_09_10 type: batch repeat: 20 keep_seed: false until: (Annee >= fin_simulation){
	parameter 'save_outputs' var: save_outputs init: true;
	parameter 'prefix' var: prefix_output init: "5_0_Test_09_10";
	parameter "benchmark" var: benchmark init: false; // Changement pour connaitre perfs fonctions
	parameter "serfs_mobiles" var: serfs_mobiles init: true;
	parameter "nombre_fp_villages" var: nombre_FP_village among: [5, 10];
	parameter "seuils_distance_max_dem_local" var: seuils_distance_max_dem_local init: [2500, 4000, 4000];
}

experiment Exp_5_0_Test_11_35 type: batch repeat: 20 keep_seed: false until: (Annee >= fin_simulation){
	parameter 'save_outputs' var: save_outputs init: true;
	parameter 'prefix' var: prefix_output init: "5_0_Test_11_35";
	parameter "benchmark" var: benchmark init: false; // Changement pour connaitre perfs fonctions
	parameter "serfs_mobiles" var: serfs_mobiles init: true;
	parameter "nombre_fp_villages" var: nombre_FP_village among: [5, 10];
	parameter "taux_augmentation_FP" var: taux_augmentation_FP among: [0.01, 0.03, 0.05, 0.1];
	parameter "proba_ponderee_deplacement_lointain" var: proba_ponderee_deplacement_lointain among: [0.2, 0.5, 0.7];
}