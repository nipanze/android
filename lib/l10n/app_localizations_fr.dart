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
}
