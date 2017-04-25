/**
 *  T8
 *  Author: Robin
 *  Description: Les agglomérations sont des agents "persistants", mais dont on vérifie l'existence à chaque pas de temps.
 */

model t8

import "../init.gaml"
import "../global.gaml"
import "Foyers_Paysans.gaml"
import "Chateaux.gaml"
import "Eglises.gaml"
import "Seigneurs.gaml"
import "Attracteurs.gaml"
import "Zones_Prelevement.gaml"

global {
	
	action update_agregats {
    	list<list<Foyers_Paysans>> agregats_detectees <- list<list<Foyers_Paysans>>(simple_clustering_by_distance(Foyers_Paysans, distance_detection_agregats) );
    	agregats_detectees <- agregats_detectees where (length(each) >= nombre_FP_agregat);
    	
    	ask Foyers_Paysans {
    		if (monAgregat != nil){
    			set typeInter <- "In";
    		} else {
    			set typeInter <- "Out";
    		}
    		set monAgregat <- nil ;
    	}
   		// 2 - On parcourt la liste des anciennes agglos
   		loop ancienAgregat over: Agregats {
   			bool encore_agregat <- false;
   			loop nouvelAgregat over: agregats_detectees {
   				list<Foyers_Paysans> FP_inclus <- nouvelAgregat;
   				geometry geom_agregat <- convex_hull(polygon(FP_inclus collect each.location));
   				if (ancienAgregat.shape intersects geom_agregat){
   					ask ancienAgregat {
   						set fp_agregat <- FP_inclus;
   						ask fp_agregat {
   							set monAgregat <- myself ;
   							set typeInter <- typeInter + "In";
   						}
					set mesChateaux <- ancienAgregat.mesChateaux;
					ask mesChateaux {
						set monAgregat <- nouvelAgregat as Agregats;
					}
					do update_shape;
					if (Annee >= apparition_communautes){do update_communaute;}
   					}
					agregats_detectees >> nouvelAgregat;
					set encore_agregat <- true;
					// sortir de la boucle j
					break;
   				}
   			}
   			if (!encore_agregat) {
				ask ancienAgregat { do die;}
				ask (Chateaux where (each.monAgregat = ancienAgregat)) {set monAgregat <- nil;}	   				
   			}
   		}
   		loop nouvel_agregat over: agregats_detectees {
   			create Agregats {
   				set fp_agregat <- nouvel_agregat;
   				ask fp_agregat {
   					set monAgregat <- myself;
   					set typeInter <- typeInter + "In";
   				}
   				do update_shape;
   				if (Annee >= apparition_communautes){do update_communaute;}
   			}
   		}
    	ask Foyers_Paysans where (each.monAgregat = nil){
    		set typeInter <- typeInter + "Out";
    	}
    }
    
    
   action update_agregats_alternate {
   	    	list<Eglises> eglises_paroissiales <- Eglises where (each.reel);
    	list<list<agent>> agregats_detectes <- simple_clustering_by_distance((Foyers_Paysans + Chateaux + eglises_paroissiales),distance_detection_agregats);
    	list<list<agent>> agregats_corrects <- agregats_detectes where (length(each of_species Foyers_Paysans) >= nombre_FP_agregat);

    	//list<list<agent>> agregats_debut <- agregats_detectes;
    	//list<list<agent>> agregats_cibles <- agregats_debut;
    	//write agregats_corrects;
    	// Fusion //
    	
    	// Nouvelle règle de fusion //
    	//write agregats_detectes;
    	loop nouveauxAgregats over: agregats_corrects {
			create tmpAgregats number: 1 {
				list<point> mesPoints <- nouveauxAgregats collect each.location;			
				geometry monPoly <- convex_hull(polygon(mesPoints));
	    		set shape <- monPoly + 100;
	    		set mesAgents <- agents overlapping self;
	    		set mesFP <- mesAgents of_species Foyers_Paysans;
	    		set mesEglisesParoissiales <- mesAgents of_species Eglises;
	    		set mesChateaux <- mesAgents of_species Chateaux;
	    		
			}
    	}

    			// Desaffectation des FP //
		ask Foyers_Paysans {
		if (monAgregat != nil){
			set typeInter <- "In";
		} else {
			set typeInter <- "Out";
		}
		set monAgregat <- nil ;
		}
		
		
		ask tmpAgregats {
			geometry myShape <- shape;
			Agregats thisOldAgregat <- nil;
			float thisGeomArea <- 0.0;
			loop ancienAgregat over: Agregats {
				if (ancienAgregat.shape intersects myShape){
					geometry thisUnion <- ancienAgregat.shape inter myShape;
					if (thisUnion.area > thisGeomArea) {
						thisOldAgregat <- ancienAgregat;
						thisGeomArea <- thisUnion.area;
					}
				}
			}
			if (thisOldAgregat != nil) {
				if (thisOldAgregat.communaute){
					CA <- true;
				}
			}
		}

		ask Agregats {
			do die;
		}
	
		ask tmpAgregats {
			geometry myShape <- shape;
			bool recreateCA <- CA;
			list<Eglises> cesParoisses <- mesEglisesParoissiales;
			create Agregats number: 1 {
				set communaute <- recreateCA;
				set shape <- myShape;
				set mesParoisses <- cesParoisses;
				list<Chateaux> chateaux_proches <- Chateaux at_distance 2000;
				geometry maGeom <- shape + 200;
				
				loop ceChateau over: chateaux_proches {
					if (ceChateau intersects maGeom) {
						self.mesChateaux <+ ceChateau; 
					}
				}
			set fp_agregat <- Foyers_Paysans overlapping self;	
			}
		}
    	// ***************************** //
    	//  Suppression des tmpAgregats  //
    	// ***************************** //
    	
    	ask tmpAgregats {do die;}
		
		ask Agregats {
			
//			set mesChateaux <- Chateaux overlapping self;
//			set mesParoisses <- (Eglises where (each.eglise_paroissiale) overlapping self);
			Agregats thisAg <- self;
			ask fp_agregat {
				if (monAgregat != nil) {
					monAgregat.fp_agregat >- self;
				}
				set monAgregat <- thisAg;
				set typeInter <- typeInter + "In";
			}
			if (Annee >= apparition_communautes){do update_communaute;}
			//write string(self) + " - FP (Ag) : " + length(fp_agregat) + " / FP (fp) : " + (Foyers_Paysans count (each.monAgregat = thisAg));
		}
		
    	ask Foyers_Paysans where (each.monAgregat = nil){	
    		set typeInter <- typeInter + "Out";
    	}

   	}

//    action update_agregats_alternate {
//    	
//    	// ******************************* //
//    	// Detection des nouveaux agrégats //
//    	// ******************************* //
//    	
//    	
//    	// Clustering //
//    	list<Eglises> eglises_paroissiales <- Eglises where (each.reel);
//    	list<list<agent>> agregats_detectes <- list<list<agent>>(simple_clustering_by_distance((Foyers_Paysans + Chateaux + eglises_paroissiales), 
//    		distance_detection_agregats
//    		)  where (length(each) >= nombre_FP_agregat));
//    	list<list<agent>> agregats_debut <- agregats_detectes where (length(each of_species Foyers_Paysans) >= nombre_FP_agregat);
//    	list<list<agent>> agregats_cibles <- agregats_debut;
//    	
//    	// Fusion //
//    	
//    	loop petitAgregat over: agregats_debut {
//    		list<agent> thisAg <- petitAgregat;
//    		list<Foyers_Paysans> thisFP <- thisAg of_species Foyers_Paysans;
//			list<Eglises> thisEglisesParoissiales <- thisAg of_species Eglises;
//			list<Chateaux> thisChateaux <- thisAg of_species Chateaux;
//			list<point> thisPoints <- (thisFP collect each.location) +
//				(thisEglisesParoissiales collect each.location) +
//				(thisChateaux collect each.location);
//			geometry thisPoly <- convex_hull(polygon(thisPoints));
//    		geometry thisShape <- thisPoly + 100;
//    		
//    		loop agregat_cible over: (agregats_cibles){
//    			if (thisAg != agregat_cible){
//		    		list<agent> thoseAg <- agregat_cible;
//		    		list<Foyers_Paysans> thoseFP <- thoseAg of_species Foyers_Paysans;
//					list<Eglises> thoseEglisesParoissiales <- thoseAg of_species Eglises;
//					list<Chateaux> thoseChateaux <- thoseAg of_species Chateaux;
//					list<point> thosePoints <- (thoseFP collect each.location) +
//						(thoseEglisesParoissiales collect each.location) +
//						(thoseChateaux collect each.location);
//					geometry thosePoly <- convex_hull(polygon(thosePoints));
//	    			geometry thoseShape <- thosePoly + 100;
//					
//					
//					if (thoseShape intersects thisShape){
//						agregats_cibles >- thisAg;
//						agregats_cibles >- thoseAg;
//						agregats_cibles <+ (thisAg + thoseAg);
//						break;
//					}
//    			}
//    		}
//    	}
//    	
//    	// Création des tmpAgregats //
//	
//		loop nouvelAgregat over: agregats_cibles {
//			create tmpAgregats number: 1 {
//	    		set mesFP <- nouvelAgregat of_species Foyers_Paysans;
//				set mesEglisesParoissiales <- nouvelAgregat of_species Eglises;
//				set mesChateaux <- nouvelAgregat of_species Chateaux;
//				
//				list<point> mesPoints <- (mesFP collect each.location) +
//					(mesEglisesParoissiales collect each.location) +
//					(mesChateaux collect each.location);
//				geometry monPoly <- convex_hull(polygon(mesPoints));
//	    		set shape <- monPoly + 100;
//			}
//		}
//	
//		// Desaffectation des FP //
//		ask Foyers_Paysans {
//		if (monAgregat != nil){
//			set typeInter <- "In";
//		} else {
//			set typeInter <- "Out";
//		}
//		set monAgregat <- nil ;
//		}
//		
//		
//    	// ****************************************************** //
//    	//  Detection des intersection anciens/nouveaux agrégats  //
//    	// ****************************************************** //
//		
//		list<list<agent>> AgClusters <- list<list<agent>>(simple_clustering_by_distance((tmpAgregats + Agregats), 0));
//		
//		list<list<agent>> agregatsIntersectes <- AgClusters where (length(each) > 1);
//		list<list<agent>> agregatsIsoles <- AgClusters where (length(each) = 1);
//		list<tmpAgregats> nouveauxAgregats <- (agregatsIsoles accumulate each) of_species tmpAgregats;
//		list<Agregats> agregatsDisparus <- (agregatsIsoles accumulate each) of_species Agregats;
//		
//		
//		// Suppression des anciens sans intersection //
//		ask agregatsDisparus {do die;}
//		list<list<agent>> goodClusters <- [];
//		
//		loop currAg over: agregatsIntersectes {
//			if (length(currAg of_species tmpAgregats) < 1){
//				ask currAg {do die;}
//			} else {
//				goodClusters <+ currAg;
//			}
//		}
//		
//		
//		
//		// Création des nouveaux sans intersection //
//		loop nouvelAgregat over: nouveauxAgregats {
//			create Agregats number: 1{
//				set fp_agregat <- nouvelAgregat.mesFP;
//				ask fp_agregat {
//					set monAgregat <- myself;
//					set typeInter <- typeInter + "In";
//				}
//				set shape <- nouvelAgregat.shape;
//				set mesChateaux <- nouvelAgregat.mesChateaux;
//				set mesParoisses <- nouvelAgregat.mesEglisesParoissiales;
//				if (Annee >= apparition_communautes){do update_communaute;}
//			}
//		}
//		
//		// Passation des Communautés des anciens aux nouveaux //
//		
//		
//		loop goodCluster over: goodClusters {
//			list<Agregats> anciensAg <- goodCluster of_species Agregats;
//			list<tmpAgregats> nouveauxAg <- goodCluster of_species tmpAgregats;
//			
//			Agregats predecesseurAg <- nil;
//			
//			if (length(nouveauxAg) > 1){
//				list<Agregats> cesAnciensAg <- anciensAg;
//				loop ceNouvelAg over: nouveauxAg {
//					if (length(cesAnciensAg) < 1){
//						create Agregats number: 1 {
//							set fp_agregat <- ceNouvelAg.mesFP;
//							ask fp_agregat {
//								set monAgregat <- myself;
//								set typeInter <- typeInter + "In";
//							}
//							set shape <- ceNouvelAg.shape;
//							set mesChateaux <- ceNouvelAg.mesChateaux;
//							set mesParoisses <- ceNouvelAg.mesEglisesParoissiales;
//							if (Annee >= apparition_communautes){do update_communaute;}
//						}
//					} else {
//						Agregats cetAncienAg <- one_of(cesAnciensAg);
//						ask cetAncienAg{
//							set fp_agregat <- ceNouvelAg.mesFP;
//							ask fp_agregat {
//								set monAgregat <- myself;
//								set typeInter <- typeInter + "In";
//							}
//							set shape <- ceNouvelAg.shape;
//							set mesChateaux <- ceNouvelAg.mesChateaux;
//							set mesParoisses <- ceNouvelAg.mesEglisesParoissiales;
//							if (Annee >= apparition_communautes){do update_communaute;}
//						}
//						cesAnciensAg >- cetAncienAg;
//					}
//				}
//			} else if (length(anciensAg) = 1){
//				set predecesseurAg <- one_of(anciensAg);
//			} else if (anciensAg count (each.communaute) >= 1 ) {
//				set predecesseurAg <- (anciensAg where each.communaute) with_max_of (each.attractivite);
//			} else {
//				set predecesseurAg <- anciensAg with_max_of (each.attractivite);
//			}
//			
//			if (predecesseurAg != nil){
//				ask predecesseurAg {
//					set fp_agregat <- one_of(nouveauxAg).mesFP;
//					ask fp_agregat {
//						set monAgregat <- myself;
//						set typeInter <- typeInter + "In";
//					}
//					set shape <- one_of(nouveauxAg).shape;
//					set mesChateaux <- one_of(nouveauxAg).mesChateaux;
//					set mesParoisses <- one_of(nouveauxAg).mesEglisesParoissiales;
//					if (Annee >= apparition_communautes){do update_communaute;}
//				}	
//			}
//
//		}
//	
//    	// ***************************** //
//    	//  Suppression des tmpAgregats  //
//    	// ***************************** //
//    	
//    	ask tmpAgregats {do die;}
//		
//		ask Agregats {
//			set fp_agregat <- agents_at_distance(0) of_species Foyers_Paysans;
//			ask fp_agregat {
//				set monAgregat <- myself;
//				set typeInter <- typeInter + "In";
//			}
//		}
//		
//    	ask Foyers_Paysans where (each.monAgregat = nil){	
//    		set typeInter <- typeInter + "Out";
//    	}
//    	
//    }
//    
//    action update_agregats_fp {
//    	
//    	ask Foyers_Paysans {
//    		if (monAgregat != nil){
//    			set typeIntra <- "In";
//    		} else {
//    			set typeIntra <- "Out";
//    		}
//    		set monAgregat <- nil;
//    	}
//    	
//    	ask Agregats {
//    		set nbfp_avant_dem <- length(fp_agregat);
//    		set fp_agregat <- agents_at_distance(0) of_species Foyers_Paysans;
//    		ask fp_agregat {
//    			set monAgregat <- myself;
//    			set typeIntra <- typeIntra + "In";
//    		}
//    		
//    	}
//    	ask Foyers_Paysans where (each.monAgregat = nil){
//    		set typeIntra <- typeIntra + "Out";
//    	}
//    	
//    }
//    
}

entities {
	
	species tmpAgregats schedules: shuffle(tmpAgregats){
		bool CA <- false;
		geometry shape <- nil;
		list<agent> mesAgents <- [];
		list<Foyers_Paysans> mesFP <- [];
		list<Eglises> mesEglisesParoissiales <- [];
		list<Chateaux> mesChateaux <- [];
	}

	species Agregats parent: Attracteurs schedules: shuffle(Agregats){
		bool fake_agregat <- false;
		int attractivite <- 0;
		list<Foyers_Paysans> fp_agregat ;
		bool communaute <- false;
		list<Chateaux> mesChateaux <- [];
		bool reel <- false;
		list<Eglises> mesParoisses;
		int nb_fp_attires <- 0 update: 0;
		int nbfp_avant_dem <- 0 update: 0;
		
		action update_chateau {
			// FIXME : Chateaux trop proches sinon
			
			if (length(mesChateaux) = 0 or (self distance_to one_of(mesChateaux) > 1000)) {
				list<Chateaux> Chateaux_proches <- Chateaux at_distance 1000;
				if (empty(Chateaux_proches)) {
					mesChateaux <- [];
				} else {
					mesChateaux <- Chateaux_proches;
				}
			}
		}
		
		action update_shape {
			set shape <- convex_hull(polygon(fp_agregat collect each.location));
			set mesParoisses <- (Eglises where (each.eglise_paroissiale) inside shape);
		}
		
		action update_shape_alternate {
			set shape <- convex_hull(polygon(fp_agregat collect each.location));
			set mesParoisses <- (Eglises where (each.eglise_paroissiale) inside shape);
		}
		
		action update_attractivite {
			// Temporairement désactivé
			//set attractivite <- length(fp_agregat) +  sum(Chateaux where (self = each.monAgregat) collect each.attractivite);
			set attractivite <- length(fp_agregat);
			
			//int attrac_chateau; // 0 si 0, = S
			//int attrac_eglises;
			//set attractivite <- attrac_chateau + attrac_eglises;
		}
		
		
		action update_communaute {
			if (!self.communaute) {
				if (flip(proba_apparition_communaute)) {
					set communaute <- true;
					set reel <- true;
					ask self.fp_agregat {
						set communaute <- true;
					}
				} else {
					ask self.fp_agregat {
						set communaute <- false;
					}
				}
			} else {
				ask self.fp_agregat {
					set communaute <- true;
				}
			}
		}
		
		
	}
}