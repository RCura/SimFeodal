/**
 *  T8
 *  Author: Robin
 *  Description: Modélisation de la transition 800-1100, première version
 */
model t8

import "init.gaml"
import "GUI.gaml"
import "Agents/Agregats.gaml"
import "Agents/Foyers_Paysans.gaml"

import "Agents/Chateaux.gaml"
import "Agents/Eglises.gaml"
import "Agents/Seigneurs.gaml"
import "Agents/Attracteurs.gaml"
import "Agents/Zones_Prelevement.gaml"

global {
	int Annee <- 800 update: Annee + 20;
	int nombre_foyers_paysans <- 1000 ;
	int nombre_agglos_antiques <- 3 ;
	int nombre_villages <- 20 ;
	int nombre_foyers_villages <- 10 ;
	int nombre_eglises <- 150 ;
	float Seuil_satisfaction <- 0.8 ;
	float taux_renouvellement <- 0.05 ;
	float taux_mobilite <- 0.8;
	int nb_demenagement_local <- 0;
	int nb_demenagement_lointain <- 0;
	int nb_non_demenagement <- 0;
	float proba_devenir_seigneur <- 0.01;
	
	float proba_don_chateau_GS <- 0.33;
	float proba_creer_chateau_GS <- 1.0;
	
	float proba_don_chateau_PS <- 0.15;
	float proba_creer_chateau_PS <- 1.0;
	
	
	bool chatelain_cree_chateau <- false ;
	int nombre_grands_seigneurs <- 2;
	int nombre_petits_seigneurs <- 18;
	int debut_simulation <- 800;
	int fin_simulation <- 1160;
	float puissance_comm_agraire <- 0.5;
	int debut_besoin_protection <- 900;
	int nombre_seigneurs_objectif <- 200;
	int puissance_grand_seigneur1 <- 5;
	int puissance_grand_seigneur2 <- 5;
	
	float min_fourchette_loyers_PS_init <- 0.05;
	float max_fourchette_loyers_PS_init <- 0.25;
	float min_fourchette_loyers_PS_nouveau <- 0.0;
	float max_fourchette_loyers_PS_nouveau <- 0.15;
	float proba_collecter_loyer <- 0.1;
	
	int rayon_min_PS_init <- 1000;
	int rayon_max_PS_init <- 5000;
	int rayon_min_PS_nouveau <- 300;
	int rayon_max_PS_nouveau <- 2000;
	
	float proba_gain_droits_hauteJustice_chateau <- 0.1;
	float proba_gain_droits_banaux_chateau <- 0.1;
	float proba_gain_droits_basseMoyenneJustice_chateau <- 0.1;
	
	float proba_creation_ZP_banaux <- 0.05;
	float proba_creation_ZP_basseMoyenneJustice <- 0.05;
	
	float proba_gain_droits_paroissiaux <- 0.05;
	
	int nb_seigneurs_a_creer_total <- nombre_seigneurs_objectif - (nombre_grands_seigneurs + nombre_petits_seigneurs);
	int nb_moyen_petits_seigneurs_par_tour <- round(nb_seigneurs_a_creer_total / ((fin_simulation - debut_simulation) / 20));
	
	const shape_file_bounds type: file<- file("../includes/Emprise_territoire.shp");

	
	const shape type: geometry <- envelope(shape_file_bounds) ;
	const worldextent type: geometry<- envelope(shape_file_bounds) ;
	const reduced_worldextent type: geometry<- worldextent scaled_by 0.99;
	
	
    action reset_globals {
		set nb_demenagement_local <- 0;
		set nb_demenagement_lointain <- 0;
		set nb_non_demenagement <- 0;
	}
	

	
	action renouvellement_FP{
		int attractivite_totale <- length(Foyers_Paysans) + sum(Chateaux collect each.attractivite);

		int nb_FP_impactes <- int(taux_renouvellement * length(Foyers_Paysans));
		ask nb_FP_impactes among Foyers_Paysans {
			if (monAgregat != nil){
				ask monAgregat {
					fp_agregat >- myself;
				}
			}
			do die;
		}
		create Agregats number: 1 {
			set fake_agregat <- true;
			set attractivite <- attractivite_totale - sum(Agregats collect each.attractivite);
		}
		create Foyers_Paysans number: nb_FP_impactes {
			int attractivite_cagnotte <- attractivite_totale;
			point FPlocation <- nil;
			loop agregat over: shuffle(Agregats) {
				if (agregat.attractivite >= attractivite_cagnotte){
					if (length(agregat.fp_agregat) > 0) {
						set FPlocation <- any_location_in(200 around one_of(agregat.fp_agregat).location);
					} else {
						set FPlocation <- any_location_in(worldextent);
					}
					break;
				} else {
					set attractivite_cagnotte <- attractivite_cagnotte - agregat.attractivite;
				}
			}
			set location <- FPlocation;
			set mobile <- flip (taux_mobilite);
			
		}
		
		ask Agregats where each.fake_agregat {
			do die;
		}
	}
	
    action update_agregats {
    	
    	// 1 - On crée une liste des nouvelles agglos
    	list agregats_detectees <- connected_components_of(list(Foyers_Paysans) as_distance_graph 200) where (length(each) >= 5) ;
    	ask Foyers_Paysans {
    		set monAgregat <- nil ;
    	}
   		// 2 - On parcourt la liste des anciennes agglos
   		list<geometry> agregats_existantes <- Agregats collect each.shape;
   		loop i over: Agregats {
   			bool encore_agregat <- false;
   			loop j over: agregats_detectees {
   				list<Foyers_Paysans>FP_inclus <- list<Foyers_Paysans>(j);
   				geometry geom_agregat <- convex_hull(polygon(FP_inclus collect each.location));
   				if (i.shape intersects geom_agregat){
   					ask i {
   						set fp_agregat <- FP_inclus;
   						ask fp_agregat {
   							set monAgregat <- myself ;
   						}
					set monChateau <- i.monChateau;
					ask monChateau {
						set monAgregat <- j as Agregats;
					}
					do update_shape;
					do update_comm_agraire;
   					}
					agregats_detectees >> j;
					set encore_agregat <- true;
					// sortir de la boucle j
					break;
   				}
   			}
   			if (!encore_agregat) {
				ask i { do die;}
				ask (Chateaux where (each.monAgregat = i)) {set monAgregat <- nil;}	   				
   			}
   		}
   		loop nouvel_agregat over: agregats_detectees{
   			create Agregats {
   				set fp_agregat <- list<Foyers_Paysans>(nouvel_agregat);
   				ask fp_agregat {
   					set monAgregat <- myself;
   				}
   				do update_shape;
   				do update_comm_agraire;
   			}
   		}
    }
	
	
	action creation_nouveaux_seigneurs {
		int variabilite_nb_seigneurs <- round(nb_moyen_petits_seigneurs_par_tour / 3);
		int nb_seigneurs_a_creer <- nb_moyen_petits_seigneurs_par_tour + variabilite_nb_seigneurs - rnd(variabilite_nb_seigneurs * 2);
		// Varie entre -1/3 et +1/3 autour de la moyenne
		create Seigneurs number: nb_seigneurs_a_creer {
			set type <- "Petit Seigneur";
			set initialement_present <- false;
			set taux_prelevement <- 1.0;
			
			set location <- any_location_in(one_of(Agregats collect each.shape));
			
			set droits_loyer <- flip(proba_collecter_loyer);
			set droits_hauteJustice <- false;
			set droits_banaux <- false;
			set droits_moyenneBasseJustice <- false;
			
			if (droits_loyer){
				int rayon_zone <- rayon_min_PS_nouveau + rnd(rayon_max_PS_nouveau - rayon_min_PS_nouveau);
				float txPrelev <- min_fourchette_loyers_PS_nouveau + rnd(max_fourchette_loyers_PS_nouveau - min_fourchette_loyers_PS_nouveau);
				do creer_zone_prelevement(self.location, rayon_zone, self, "Loyer", txPrelev);
			}			
		}
	}
	
	
	action attribution_loyers_FP {
		list<Foyers_Paysans> FP_dispos <- Foyers_Paysans where (each.seigneur_loyer = nil);
		
		ask Zones_Prelevement where (each.type_droit = "Loyer") {
			list<Foyers_Paysans> FP_zone <- FP_dispos inside self.shape;
			int nbFP_concernes <- round(self.taux_captation * length(FP_zone));
			ask nbFP_concernes among FP_zone {
				set seigneur_loyer <- myself.proprietaire;
				FP_dispos >- self;
			}
		}
		
		ask Seigneurs where (each.type = "Grand Seigneur") {
			int nbFP_concernes <- round(self.puissance_init * length(FP_dispos));
			ask nbFP_concernes among FP_dispos {
				set seigneur_loyer <- myself;
			}
			set FP_dispos <- Foyers_Paysans where (each.seigneur_loyer = nil);
		}
	}
}