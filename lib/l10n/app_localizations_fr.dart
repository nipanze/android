// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Nipanze';

  @override
  String get welcomeTitle => 'Empruntez. Prêtez. Grandissez.';

  @override
  String get welcomeTagline => 'Découvrez les annonces locales';

  @override
  String get welcomeSubtitle =>
      'Une plateforme de confiance reliant emprunteurs et prêteurs.';

  @override
  String get selectLanguage => 'Sélectionnez la langue';

  @override
  String get choosePreferredLanguage => 'Choisissez votre langue préférée';

  @override
  String get continueWithPhone => 'Continuer avec le téléphone';

  @override
  String get continueWithEmail => 'Continuer avec l\'e-mail';

  @override
  String get getStartedTitle => 'Commencez avec Nipanze';

  @override
  String get getStartedSubtitle => 'Choisissez comment vous souhaitez procéder';

  @override
  String get createAccount => 'Créer un compte';

  @override
  String get createAccountSubtitle =>
      'Nouveau sur Nipanze ? Inscrivez-vous par téléphone';

  @override
  String get logIn => 'Se connecter';

  @override
  String get logInSubtitle => 'Vous avez déjà un compte ? Connectez-vous';

  @override
  String get welcomeBack => 'Bon retour 👋';

  @override
  String get loginToAccount => 'Connectez-vous à votre compte';

  @override
  String get phone => 'Téléphone';

  @override
  String get email => 'E-mail';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get createPassword => 'Créer un mot de passe';

  @override
  String get rememberMe => 'Se souvenir de moi';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get dontHaveAccount => 'Vous n\'avez pas de compte ?';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get enterPhoneTitle => 'Entrez votre numéro de téléphone';

  @override
  String get enterPhoneSubtitle =>
      'Nous vous enverrons un code de vérification';

  @override
  String get sendCode => 'Envoyer le code de vérification';

  @override
  String get tellUsAboutYou => 'Parlez-nous de vous';

  @override
  String get completeProfileSubtitle =>
      'Créez votre profil et définissez un mot de passe';

  @override
  String get fullName => 'Nom complet';

  @override
  String get finish => 'Terminer';

  @override
  String get termsNotice =>
      'En continuant, vous acceptez nos conditions d\'utilisation et notre politique de confidentialité.';

  @override
  String get phoneSafeTitle => 'Votre numéro est en sécurité avec nous';

  @override
  String get phoneSafeSubtitle =>
      'Nous ne partagerons jamais votre numéro avec quiconque.';

  @override
  String get navMarkets => 'Marchés';

  @override
  String get navWatchlist => 'Favoris';

  @override
  String get navRequest => 'Demander';

  @override
  String get navPositions => 'Positions';

  @override
  String get navAccount => 'Compte';

  @override
  String get marketplaceTitle => 'Marché';

  @override
  String listingsLive(int count) {
    return '$count offres · en direct';
  }

  @override
  String get filtered => 'Filtré';

  @override
  String get applyingFilters => 'Application des filtres…';

  @override
  String get noListingsFound => 'Aucune offre trouvée';

  @override
  String get noListingsSubtitle =>
      'Revenez bientôt — de nouvelles offres apparaissent en temps réel.';

  @override
  String get noMatches => 'Aucun résultat';

  @override
  String get noMatchesSubtitle =>
      'Aucune offre ne correspond à vos filtres Pro.\nEssayez de modifier ou d\'effacer les critères.';

  @override
  String get adjustFilters => 'Ajuster les filtres';

  @override
  String get removeFromWatchlist => 'Retirer des favoris';

  @override
  String get saveToWatchlist => 'Ajouter aux favoris';

  @override
  String get months => 'mois';

  @override
  String daysLeft(int count) {
    return '${count}j restants';
  }

  @override
  String hoursLeft(int count) {
    return '${count}h restants';
  }

  @override
  String minutesLeft(int count) {
    return '${count}m restants';
  }

  @override
  String get expired => 'Expiré';

  @override
  String get watchlistTitle => 'Favoris';

  @override
  String get watchlistSubtitle => 'Annonces que vous suivez';

  @override
  String watchlistSaved(int count) {
    return '$count enregistré(s)';
  }

  @override
  String get watchlistInfoSubscribed =>
      'Gratuit pour tous. Soyez notifié quand les offres changent, les taux s\'améliorent ou une annonce se ferme.';

  @override
  String get watchlistInfoFree =>
      'Gratuit pour tous. Soyez notifié quand les offres changent. Abonnez-vous pour faire des offres.';

  @override
  String get watchlistError => 'Erreur de chargement des favoris';

  @override
  String get watchlistEmpty => 'Aucune annonce enregistrée';

  @override
  String get watchlistEmptySubtitle =>
      'Parcourez le marché et appuyez sur \"Ajouter aux favoris\" sur une annonce.';

  @override
  String get browseMarketplace => 'Parcourir le marché';

  @override
  String get removedFromWatchlist => 'Retiré des favoris';

  @override
  String get undo => 'Annuler';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get myActivityTitle => 'Mon Activité';

  @override
  String get myActivitySubtitle => 'Gérez vos annonces et offres';

  @override
  String myActivityStats(int listings, int offers) {
    return '$listings Annonces · $offers Offres Actives';
  }

  @override
  String get tabMyRequests => 'Mes Demandes';

  @override
  String get tabMyOffers => 'Mes Offres';

  @override
  String get noOffersYet => 'Aucune offre pour l\'instant';

  @override
  String get noOffersSubtitle =>
      'Les offres que vous placez sur les annonces apparaîtront ici.';

  @override
  String get browseMarketplaceBtn => 'Parcourir le marché';

  @override
  String get activeOffers => 'Offres Actives';

  @override
  String get matchedAccepted => 'Mises en correspondance / Acceptées';

  @override
  String get history => 'Historique';

  @override
  String get withdrawOffer => 'Retirer l\'offre ?';

  @override
  String withdrawConfirm(int amount) {
    return 'Êtes-vous sûr de retirer votre offre de UGX $amount ?';
  }

  @override
  String get keepOffer => 'Garder l\'offre';

  @override
  String get withdraw => 'Retirer';

  @override
  String get myRequestsTitle => 'Mes Demandes';

  @override
  String sectionActive(int count) {
    return 'Actif · $count';
  }

  @override
  String sectionContracted(int count) {
    return 'Contracté · $count';
  }

  @override
  String sectionClosed(int count) {
    return 'Fermé · $count';
  }

  @override
  String get noLoanRequests => 'Aucune demande de prêt pour l\'instant';

  @override
  String get noLoanRequestsSubtitle =>
      'Postez une demande et les prêteurs se disputeront pour vous offrir le meilleur taux.';

  @override
  String get createLoanRequest => 'Créer une demande de prêt';

  @override
  String get cancelListing => 'Annuler l\'annonce ?';

  @override
  String cancelListingConfirm(String title) {
    return 'Cela supprimera \"$title\" du marché. Toutes les offres en attente seront rejetées.';
  }

  @override
  String get keepIt => 'Garder';

  @override
  String get cancelListingBtn => 'Annuler l\'annonce';

  @override
  String get contractNotGenerated => 'Contrat pas encore généré.';

  @override
  String get accountTitle => 'Compte';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get contactUs => 'Contactez-nous';

  @override
  String get community => 'Communauté';

  @override
  String get legal => 'Légal';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signOutConfirm => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get cancel => 'Annuler';

  @override
  String get profileUpdated => 'Profil mis à jour.';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get identityVerification => 'Vérification d\'identité';

  @override
  String get security => 'Sécurité';

  @override
  String get notifications => 'Notifications';

  @override
  String get statListings => 'Annonces';

  @override
  String get statListingsSubtitle => 'Demandes publiées';

  @override
  String get statOffers => 'Offres';

  @override
  String get statOffersSubtitle => 'Offres soumises';

  @override
  String get statMatches => 'Correspondances';

  @override
  String get statMatchesSubtitle => 'Correspondances réussies';

  @override
  String get trustReputation => 'Confiance & Réputation';

  @override
  String get subscription => 'Abonnement';

  @override
  String get upgradeToPro => 'Passer à Pro';

  @override
  String get viewPlansUpgrade => 'Voir les plans & passer';

  @override
  String get adminDashboard => 'Tableau de bord Admin';

  @override
  String memberSince(String date) {
    return 'Membre depuis $date';
  }

  @override
  String get verified => 'Vérifié';

  @override
  String get districtNotSet => 'District non défini';

  @override
  String get nipanzeDisclaimer =>
      'Nipanze est une plateforme de mise en relation non-dépositaire. Nous ne détenons, déplaçons ni réglons pas les fonds. Toutes les transactions se font directement entre participants.';

  @override
  String get lenderRequired => 'Niveau Prêteur requis';

  @override
  String get lenderRequiredSubtitle =>
      'Faire des offres fait partie du plan Prêteur (également inclus dans Pro). Passez au niveau supérieur pour débloquer le placement d\'offres.';

  @override
  String get lenderTier => 'Niveau Prêteur';

  @override
  String get lenderTierDesc =>
      'Pour quiconque est prêt à faire des offres structurées et à générer des rendements sur Nipanze.';

  @override
  String get everythingInFree => 'Tout ce qui est dans Gratuit';

  @override
  String get lenderFeature1 =>
      'Faire des offres avec des conditions complètes (taux, frais, calendrier)';

  @override
  String get lenderFeature2 =>
      'Voir les détails des offres auxquelles vous participez';

  @override
  String get chooseLender => 'Choisir Prêteur';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get paymentSecurityDisclaimer =>
      'Nipanze ne détient et ne déplace pas de fonds. Les changements d\'abonnement sont confirmés via un flux de paiement sécurisé.';

  @override
  String get proRequired => 'Niveau Pro requis';

  @override
  String get proRequiredSubtitle =>
      'Les fonctionnalités avancées comme la proposition de conditions personnalisées et les filtres avancés sont réservées aux abonnés Pro.';

  @override
  String get proTier => 'Niveau Pro';

  @override
  String get proTierDesc =>
      'Accès complet au marché, filtres avancés et positionnement prioritaire des demandes.';

  @override
  String get everythingInLender => 'Tout ce qui est dans Prêteur';

  @override
  String get proFeature1 =>
      'Suggérer des taux, pénalités de retard et conditions de remboursement';

  @override
  String get proFeature2 => 'Filtres avancés (revenu, emploi, vérifié)';

  @override
  String get proFeature3 =>
      'Badge vérifié, score de fiabilité et visibilité prioritaire';

  @override
  String get choosePro => 'Choisir Pro';

  @override
  String get plansAndPricing => 'Plans et tarifs';

  @override
  String get chooseAccessTitle => 'Choisissez l\'accès dont vous avez besoin';

  @override
  String chooseAccessSubtitle(String flag, String country) {
    return 'Un seul compte peut publier des demandes et faire des offres. Les prix correspondent à votre région ($flag $country).';
  }

  @override
  String get perMonth => ' / mois';

  @override
  String get freePlanSubtitle =>
      'Parcourir, suivre les annonces, publier des demandes de base et accepter des offres.';

  @override
  String get freeFeature1 => 'Parcourir le marché';

  @override
  String get freeFeature2 => 'Publier des demandes de prêt de base';

  @override
  String get freeFeature3 => 'Accepter les offres reçues';

  @override
  String get currentPlan => 'Plan actuel';

  @override
  String get useFree => 'Utiliser Gratuit';

  @override
  String choosePlan(String plan) {
    return 'Choisir $plan';
  }

  @override
  String planSelectedMessage(String plan) {
    return '$plan sélectionné. L\'activation du paiement sécurisé sera bientôt disponible.';
  }

  @override
  String get unlockDealTitle => 'Débloquer la transaction';

  @override
  String get unlockDealAndContact => 'Débloquer transaction & contact';

  @override
  String get dealAgreementLocked => 'Accord de transaction verrouillé';

  @override
  String get dealAgreementLockedSubtitle =>
      'L\'emprunteur et le prêteur ont tous deux confirmé la transaction. Vous pouvez maintenant débloquer les coordonnées pour vous connecter directement.';

  @override
  String includedInPlan(String plan) {
    return 'Inclus dans votre plan $plan';
  }

  @override
  String get unlimitedUnlocksSubtitle =>
      'Déblocages de contact illimités sans frais supplémentaires.';

  @override
  String welcomeGiftUnlocks(int count) {
    return '🎁 Cadeau de bienvenue — $count déblocage(s) gratuit(s) restant(s)';
  }

  @override
  String get welcomeGiftSubtitle =>
      'Cette transaction utilise l\'un de vos déblocages gratuits. Les déblocages supplémentaires coûtent UGX 5 000.';

  @override
  String get unlockFeeApplies => 'Frais de déblocage de UGX 5 000 appliqués';

  @override
  String get unlockFeeAppliesSubtitle =>
      'Votre déblocage de bienvenue a été utilisé. Passez à Prêteur ou Pro pour des déblocages gratuits illimités.';

  @override
  String get whatHappensNext => 'Que se passe-t-il ensuite';

  @override
  String get step1Title => 'Coordonnées révélées';

  @override
  String get step1Desc =>
      'Le nom légal, le téléphone et l\'e-mail des deux parties seront partagés.';

  @override
  String get step2Title => 'Connexion directe';

  @override
  String get step2Desc =>
      'Vous pouvez maintenant contacter votre partenaire en dehors de la plateforme Nipanze.';

  @override
  String get step3Title => 'Finaliser la transaction';

  @override
  String get step3Desc =>
      'Finalisez le contrat de prêt et échangez les fonds directement.';

  @override
  String get disclaimerNonCustodial =>
      'Nipanze ne détient ni ne déplace aucun fond. Vous et votre partenaire êtes seuls responsables de toutes les transactions financières et de la résolution des litiges.';

  @override
  String get payToUnlock => 'Payer UGX 5 000 pour débloquer';

  @override
  String get unlockWithFreeCredit => 'Débloquer avec crédit gratuit';

  @override
  String get unlockContactDetails => 'Débloquer les coordonnées';

  @override
  String get upgradeForUnlimited =>
      'Passer au niveau supérieur pour des déblocages illimités';

  @override
  String get contactDetailsRevealed => 'Coordonnées révélées';

  @override
  String get connectionSuccessful =>
      'Connexion réussie. Voici les coordonnées :';

  @override
  String get borrower => 'Emprunteur';

  @override
  String get lender => 'Prêteur';

  @override
  String get directContactNotice =>
      'Vous pouvez maintenant contacter votre partenaire directement pour effectuer la transaction en dehors de la plateforme Nipanze.';

  @override
  String get done => 'Terminé';

  @override
  String planTitle(String plan) {
    return 'Plan $plan';
  }

  @override
  String get nonCustodialAccess => 'Accès non-dépositaire';

  @override
  String get howTrustWorks => 'Comment fonctionne la confiance';

  @override
  String get trustExplanation =>
      'Les signaux de confiance reflètent uniquement l\'activité réalisée via Nipanze. Ils n\'évaluent ni n\'impliquent le comportement de remboursement hors plateforme.';

  @override
  String get trustScore => 'Score de confiance';

  @override
  String get completeDealsToBuild =>
      'Complétez des transactions pour augmenter votre score';

  @override
  String get noReviewsYet => 'Pas encore d\'avis';

  @override
  String successfulDeals(int count) {
    return '$count transactions réussies';
  }

  @override
  String get repeatParticipant => 'Participant régulier';

  @override
  String get notRepeatYet => 'Pas encore régulier';

  @override
  String get phoneVerified => 'Téléphone vérifié';

  @override
  String get phoneNotVerified => 'Téléphone non vérifié';

  @override
  String get publicTrustSignals =>
      'Les signaux publics de confiance reposent uniquement sur l\'activité effectuée via Nipanze.';

  @override
  String get advancedFilters => 'Filtres avancés';

  @override
  String get advancedFiltersBadge => 'Pro · Affiner le flux du marché';

  @override
  String get filterReset => 'Réinitialiser';

  @override
  String get filterClear => 'Effacer';

  @override
  String get filterApply => 'Appliquer les filtres';

  @override
  String get filterDone => 'Terminé';

  @override
  String get filterEmploymentType => 'Type d\'emploi';

  @override
  String get filterEmploymentSubtitle =>
      'Filtrer par l\'emploi déclaré de l\'emprunteur';

  @override
  String get filterIncomeRange => 'Tranche de revenu mensuel';

  @override
  String get filterIncomeSubtitle =>
      'Tranches approximatives — le revenu exact n\'est jamais affiché';

  @override
  String get filterQualitySignals => 'Signaux de qualité de l\'annonce';

  @override
  String get filterHasSuggestedTerms => 'Conditions suggérées';

  @override
  String get filterHasSuggestedTermsSubtitle =>
      'Uniquement les annonces Pro avec un taux d\'intérêts fixé, des pénalités de retard et un échéancier de remboursement';

  @override
  String get filterVerifiedBorrower => 'Emprunteur vérifié';

  @override
  String get filterVerifiedBorrowerSubtitle =>
      'Uniquement les demandes des titulaires de comptes approuvés KYC';

  @override
  String get filterPrivacyNote =>
      'Les noms d\'employeurs et le revenu exact ne sont jamais affichés. Les tranches de revenu et les catégories d\'emploi sont les seuls signaux disponibles, par conception.';

  @override
  String get empGovEmployee => 'Employé gouvernemental';

  @override
  String get empEmployedPrivate => 'Employé (privé)';

  @override
  String get empSelfEmployed => 'Indépendant';

  @override
  String get empSmallBusinessOwner => 'Propriétaire de petite entreprise';

  @override
  String get empBusinessOwner => 'Chef d\'entreprise';

  @override
  String get empStudent => 'Étudiant';

  @override
  String get empOther => 'Autre';

  @override
  String get incomeUnder2m => 'Moins de 2M UGX / mois';

  @override
  String get income2m5m => '2M – 5M UGX / mois';

  @override
  String get income5m10m => '5M – 10M UGX / mois';

  @override
  String get incomeOver10m => 'Plus de 10M UGX / mois';
}
