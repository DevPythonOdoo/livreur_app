import 'package:flutter/material.dart';

/// Modèle représentant une livraison avec toutes ses informations
/// (client, adresse, statut, paiement, événements).
class Livraison {
  final int id;
  final String commandeNumero;
  final String clientNom;
  final String clientTelephone;
  final String adresseComplete;
  final String adresse;
  final String codePostal;
  final String ville;
  final String statut;
  final String? statutLabel;
  final DateTime? dateLivraisonSouhaitee;
  final bool enRetard;
  final String? dateDepart;
  final String? dateArrivee;
  final double fraisLivraison;
  final double commandeMontantTtc;
  final int commandeArticlesCount;
  final String commandeModePaiement;
  final String? notes;
  final String? signature;
  final String? photoLivraison;
  final int? tempsAttente;
  final String? confirmedByName;
  final String? motifEchec;
  final String dateCreation;
  final int ordre;
  final int priorite;
  final double fraisPriorite;
  final List<LivraisonEvent> evenements;

  Livraison({
    required this.id,
    required this.commandeNumero,
    required this.clientNom,
    required this.clientTelephone,
    required this.adresseComplete,
    required this.adresse,
    required this.codePostal,
    required this.ville,
    required this.statut,
    this.statutLabel,
    this.dateLivraisonSouhaitee,
    this.enRetard = false,
    this.dateDepart,
    this.dateArrivee,
    required this.fraisLivraison,
    this.commandeMontantTtc = 0,
    this.commandeArticlesCount = 0,
    this.commandeModePaiement = '',
    this.notes,
    this.signature,
    this.photoLivraison,
    this.tempsAttente,
    this.confirmedByName,
    this.motifEchec,
    required this.dateCreation,
    this.ordre = 0,
    this.priorite = 0,
    this.fraisPriorite = 0,
    this.evenements = const [],
  });

  /// Construit une instance [Livraison] à partir d'un JSON.
  factory Livraison.fromJson(Map<String, dynamic> json) {
    return Livraison(
      id: json['id'],
      commandeNumero: json['commande_numero'] ?? '#${json['id']}',
      clientNom: json['client_nom'] ?? '',
      clientTelephone: json['client_telephone'] ?? '',
      adresseComplete: json['adresse_complete'] ?? '',
      adresse: json['adresse_livraison'] ?? '',
      codePostal: json['code_postal'] ?? '',
      ville: json['ville'] ?? '',
      statut: json['statut'] ?? 'preparation',
      statutLabel: json['statut_label'],
      dateLivraisonSouhaitee: json['date_livraison_souhaitee'] != null
          ? DateTime.tryParse(json['date_livraison_souhaitee'] as String)
          : null,
      enRetard: json['en_retard'] == true,
      dateDepart: json['date_depart'],
      dateArrivee: json['date_arrivee'],
      fraisLivraison: double.tryParse('${json['frais_livraison'] ?? '0'}') ?? 0,
      commandeMontantTtc: double.tryParse(
          '${json['commande_montant_ttc'] ?? '0'}') ?? 0,
      commandeArticlesCount: int.tryParse(
          '${json['commande_articles_count'] ?? '0'}') ?? 0,
      commandeModePaiement: json['commande_mode_paiement'] ?? '',
      notes: json['notes'],
      signature: json['signature'],
      photoLivraison: json['photo_livraison'],
      tempsAttente: json['temps_attente'],
      confirmedByName: json['confirmed_by_name'],
      motifEchec: json['motif_echec'],
      dateCreation: json['date_creation'] ?? '',
      ordre: json['ordre'] ?? 0,
      priorite: int.tryParse('${json['priorite'] ?? '0'}') ?? 0,
      fraisPriorite: double.tryParse(
          '${json['frais_priorite'] ?? '0'}') ?? 0,
      evenements: (json['evenements'] as List<dynamic>?)
              ?.map((e) => LivraisonEvent.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Retourne le libellé français du statut de la livraison.
  String get statutDisplay {
    switch (statut) {
      case 'preparation': return 'À livrer';
      case 'en_cours': return 'En route';
      case 'arrive_destination': return 'Arrivé';
      case 'livree': return 'Livrée';
      case 'echec': return 'Échec';
      case 'annulee': return 'Annulée';
      default: return statut;
    }
  }

  /// Retourne le libellé français du mode de paiement.
  String get paiementDisplay {
    switch (commandeModePaiement) {
      case 'especes': return 'Espèces';
      case 'carte': return 'Carte bancaire';
      case 'mobile_money': return 'Mobile Money';
      case 'virement': return 'Virement';
      case 'cheque': return 'Chèque';
      default:
        return commandeModePaiement.isNotEmpty
            ? commandeModePaiement : 'Non spécifié';
    }
  }

  /// Icône correspondant au mode de paiement.
  IconData get paiementIcon {
    switch (commandeModePaiement) {
      case 'especes': return Icons.money_rounded;
      case 'carte': return Icons.credit_card_rounded;
      case 'mobile_money': return Icons.phone_android_rounded;
      case 'virement': return Icons.account_balance_rounded;
      case 'cheque': return Icons.receipt_long_rounded;
      default: return Icons.payments_rounded;
    }
  }

  /// Vrai si la livraison est en cours (statut actif).
  bool get isActive =>
      statut == 'preparation' ||
      statut == 'en_cours' ||
      statut == 'arrive_destination';

  /// Vrai si la livraison est prioritaire (au moins 1 étoile).
  bool get estPrioritaire => priorite > 0;

  /// Libellé français du niveau de priorité.
  String get prioriteLabel {
    switch (priorite) {
      case 1: return 'Priorité basse';
      case 2: return 'Priorité moyenne';
      case 3: return 'Priorité élevée';
      case 4: return 'Très prioritaire';
      case 5: return 'URGENCE MAXIMALE';
      default: return 'Normale';
    }
  }
}

/// Modèle représentant un événement lié à une livraison
/// (prise en charge, départ, arrivée, etc.).
class LivraisonEvent {
  final int id;
  final String type;
  final String typeLabel;
  final String date;
  final String? notes;

  LivraisonEvent({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.date,
    this.notes,
  });

  /// Construit une instance [LivraisonEvent] à partir d'un JSON.
  factory LivraisonEvent.fromJson(Map<String, dynamic> json) {
    return LivraisonEvent(
      id: json['id'],
      type: json['type'],
      typeLabel: json['type_label'],
      date: json['date'],
      notes: json['notes'],
    );
  }
}

/// Statistiques globales du livreur (aujourd'hui, en cours, livrées, échecs, en retard).
class DeliveryStats {
  final int aujourdHui;
  final int enCours;
  final int livrees;
  final int echecs;
  final int enRetard;

  DeliveryStats({
    required this.aujourdHui,
    required this.enCours,
    required this.livrees,
    required this.echecs,
    this.enRetard = 0,
  });

  /// Construit une instance [DeliveryStats] à partir d'un JSON.
  factory DeliveryStats.fromJson(Map<String, dynamic> json) {
    return DeliveryStats(
      aujourdHui: json['aujourd_hui'] ?? 0,
      enCours: json['en_cours'] ?? 0,
      livrees: json['livrees'] ?? 0,
      echecs: json['echecs'] ?? 0,
      enRetard: json['en_retard'] ?? 0,
    );
  }
}
