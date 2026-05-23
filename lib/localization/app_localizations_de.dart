// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'HalalScan';

  @override
  String get startTitle => 'HalalScan';

  @override
  String get home => 'Startseite';

  @override
  String get tagline => 'Transparentes Halal, von der Community.';

  @override
  String get taglineSubtitle =>
      'Jede Zutat geprüft und erklärt — verbessert durch Ihr Feedback.';

  @override
  String get newScan => 'Neu scannen';

  @override
  String get lastResults => 'Letzte Ergebnisse';

  @override
  String get noRecentResults => 'Noch keine letzten Scans gespeichert.';

  @override
  String get noRecentResultsHint =>
      'Tippen Sie auf die Schaltfläche oben, um loszulegen.';

  @override
  String get scanButton => 'Scan starten';

  @override
  String get scanAnotherProduct => 'Anderes Produkt scannen';

  @override
  String get manualEntry => 'Barcode manuell eingeben';

  @override
  String get enterBarcodeManually => 'Barcode manuell eingeben';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get submit => 'Absenden';

  @override
  String get scanAgain => 'Erneut scannen';

  @override
  String get readyToScan => 'Bereit zum Scannen';

  @override
  String get analyzingBarcode => 'Barkod wird analysiert...';

  @override
  String get pointCameraAtBarcode =>
      'Richten Sie die Kamera auf den Barcode auf der Verpackung';

  @override
  String get barcodeNotSupported =>
      'Barcode erkannt, Format wird aber nicht unterstützt. Versuchen Sie die manuelle Eingabe.';

  @override
  String get pleaseEnterValidBarcode =>
      'Bitte geben Sie einen gültigen Barcode ein.';

  @override
  String get productNotFound => 'Produkt nicht gefunden';

  @override
  String get noProductImageAvailable => 'Kein Produktbild verfügbar';

  @override
  String get uploadProductPhoto => 'Foto hochladen';

  @override
  String get uploadPhotoHint =>
      'Helfen Sie anderen, indem Sie ein Foto dieses Produkts beitragen';

  @override
  String get photoUploaded => 'Foto eingereicht — vielen Dank!';

  @override
  String get photoUploadFailed =>
      'Foto konnte nicht hochgeladen werden. Bitte erneut versuchen.';

  @override
  String get additionalImages => 'Zusätzliche Bilder';

  @override
  String get ingredients => 'Zutaten';

  @override
  String get flaggedIngredients => 'Markierte Zutaten';

  @override
  String get mayBeAnimalDerived => 'Kann tierischen Ursprungs sein';

  @override
  String get communityFeedback => 'Community-Feedback';

  @override
  String get noFeedbackYet => 'Noch kein Feedback. Sei der Erste!';

  @override
  String get provideFeedback => 'Feedback geben';

  @override
  String get replyAsProducer => 'Als Hersteller antworten';

  @override
  String get producerReply => 'Hersteller-Antwort';

  @override
  String get userFeedback => 'Nutzer-Feedback';

  @override
  String get imageNotAvailable => 'Bild nicht verfügbar';

  @override
  String get fairTrade => 'Fair Trade';

  @override
  String get organic => 'Bio';

  @override
  String get glutenFree => 'Glutenfrei';

  @override
  String get vegetarian => 'Vegetarisch';

  @override
  String get vegan => 'Vegan';

  @override
  String get halal => 'HALAL';

  @override
  String get notHalal => 'HARAM';

  @override
  String get lastScanned => 'Zuletzt gescannt';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String daysAgo(int count) {
    return 'vor $count Tagen';
  }

  @override
  String errorFetchingProduct(String error) {
    return 'Fehler beim Laden des Produkts: $error';
  }

  @override
  String get productCouldNotBeRefreshed =>
      'Produktdaten konnten nicht aktualisiert werden';

  @override
  String get thankYouFeedback => 'Danke für Ihr Feedback!';

  @override
  String errorSubmittingFeedback(String error) {
    return 'Fehler beim Absenden des Feedbacks: $error';
  }

  @override
  String get replySubmitted => 'Antwort erfolgreich gesendet!';

  @override
  String get noResultsSaved => 'Noch keine Scan-History gespeichert.';

  @override
  String get language => 'Sprache';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Türkçe';

  @override
  String get german => 'Deutsch';

  @override
  String get scanHistoryTitle => 'Zuletzt gescannt';

  @override
  String get filterScan => 'Produkt scannen oder Barcode eingeben';

  @override
  String get openResult => 'Ergebnis öffnen';

  @override
  String get resultTitle => 'Ergebnis';

  @override
  String get noIngredientData => 'Keine Zutatendaten verfügbar.';

  @override
  String get foundInIngredients => 'In Produktzutaten gefunden.';

  @override
  String get mayBeAnimalDerivedNote => 'Kann tierischen Ursprungs sein.';

  @override
  String get couldNotLoadFeedback => 'Feedback konnte nicht geladen werden.';

  @override
  String get couldNotSubmitFeedback => 'Feedback konnte nicht gesendet werden.';

  @override
  String get couldNotSubmitReply => 'Antwort konnte nicht gesendet werden.';

  @override
  String get couldNotRefreshProduct =>
      'Produktdaten konnten nicht aktualisiert werden.';

  @override
  String get attachFiles => 'Dateien anhängen';

  @override
  String get feedbackInputHint => 'Ihr Feedback...';

  @override
  String get replyInputHint => 'Ihre Antwort...';

  @override
  String get submitReply => 'Antwort senden';

  @override
  String get refreshTooltip => 'Produktdaten aktualisieren';

  @override
  String get feedbackDialogHint =>
      'Helfen Sie uns, unsere Halal-Bewertung zu verbessern.';

  @override
  String get replyDialogHint =>
      'Geben Sie eine offizielle Antwort auf dieses Feedback.';

  @override
  String get aiAnalysis => 'KI-Analyse';

  @override
  String get keywordAnalysis => 'Schlüsselwortanalyse';

  @override
  String get analysisTransparency => 'Analysetransparenz';

  @override
  String get transparentSummary => 'Decision summary';

  @override
  String get transparentResult => 'Result';

  @override
  String get transparentIngredientsChecked => 'Ingredients checked';

  @override
  String get transparentRulesChecked => 'Rules checked';

  @override
  String transparentRulesAvailable(int count) {
    return '$count Regeln verfügbar (keine Daten zu prüfen)';
  }

  @override
  String get transparentFlagged => 'Flagged';

  @override
  String get transparentSuspicious => 'Needs verification';

  @override
  String get transparentNoMatches => 'No rule matches found';

  @override
  String get transparentNoIngredients =>
      'No ingredient text was available to check';

  @override
  String get transparentExplanation => 'Explanation';

  @override
  String get contributeIngredients => 'Zutaten hinzufügen';

  @override
  String get contributeIngredientsHint =>
      'Keine Zutatendaten gefunden. Helfen Sie der Community, indem Sie die Zutaten von der Verpackung eingeben.';

  @override
  String get ingredientTextLabel => 'Zutatentext';

  @override
  String get ingredientTextHint =>
      'Geben Sie die Zutatenliste von der Verpackung ein oder fügen Sie sie ein';

  @override
  String get ingredientSubmitted =>
      'Danke! Zutaten eingereicht — das Produkt wird erneut analysiert.';

  @override
  String get ingredientSubmitFailed =>
      'Zutaten konnten nicht eingereicht werden. Bitte erneut versuchen.';

  @override
  String get improveOnOpenFoodFacts => 'Auf OpenFoodFacts bearbeiten';

  @override
  String get improveOnOpenFoodFactsHint =>
      'Verbessern Sie dieses Produkt für alle, indem Sie Daten direkt auf OpenFoodFacts hinzufügen.';

  @override
  String get extractingIngredients => 'Zutaten werden aus dem Bild gelesen…';

  @override
  String get ocrFailed =>
      'Zutaten konnten nicht aus dem Bild gelesen werden. Sie können sie unten manuell eingeben.';

  @override
  String get ocrSuccess =>
      'Zutaten extrahiert — bitte vor dem Absenden überprüfen.';

  @override
  String get productImages => 'Produktbilder';

  @override
  String get extractFromExistingImage => 'Aus Galerie auswählen';

  @override
  String get takePhotoOfIngredients => 'Foto der Zutaten aufnehmen';

  @override
  String get cameraError =>
      'Kamera konnte nicht geöffnet werden. Bitte Kameraberechtigungen prüfen.';

  @override
  String get noIngredientsImageHint =>
      'Kein Zutatenbild für dieses Produkt verfügbar. Bitte fotografieren Sie die Zutatenliste auf der Verpackung.';

  @override
  String get ocrNoIngredientsFound =>
      'In den verfügbaren Bildern wurde keine Zutatenliste gefunden. Bitte fotografieren Sie das Zutatenetikett.';

  @override
  String get viewAllCheckedKeywords => 'View all checked keywords';

  @override
  String get haramKeywordsChecked => 'Haram-Zutaten, die wir prüfen';

  @override
  String get suspiciousKeywordsChecked => 'Verdächtige Zutaten, die wir prüfen';

  @override
  String get transparencyNote => 'Fehlt etwas? Teilen Sie es uns mit!';

  @override
  String get recheck => 'Erneut prüfen';

  @override
  String get foundNotFlagged =>
      'In Zutaten gefunden, aber nicht von der Analyse markiert (z. B. Fettalkohole, Spurenmengen oder kontextsichere Verwendung).';

  @override
  String get fattyAlcoholNote =>
      'Dies ist ein Fettalkohol (z. B. Cetyl- oder Stearylalkohol) – ein pflanzlicher Emulgator. Er hat keinen Bezug zu Trinkalkohol und ist halal.';

  @override
  String get keywords => 'Schlüsselwörter';

  @override
  String get haramTab => 'Haram';

  @override
  String get suspiciousTab => 'Verdächtig';

  @override
  String get suggestKeyword => 'Schlüsselwort vorschlagen';

  @override
  String get suggestKeywordHint =>
      'Fehlt etwas? Schlagen Sie ein Schlüsselwort vor – wir prüfen es.';

  @override
  String get keywordLabel => 'Schlüsselwort';

  @override
  String get keywordHint => 'z. B. Schmalz, Ethanol, Karmin';

  @override
  String get keywordRequired => 'Bitte ein Schlüsselwort eingeben.';

  @override
  String get categoryLabel => 'Kategorie';

  @override
  String get haramCategory => 'Haram (eindeutig verboten)';

  @override
  String get suspiciousCategory => 'Verdächtig (möglicherweise tierisch)';

  @override
  String get reasonLabel => 'Begründung';

  @override
  String get reasonHint =>
      'Warum sollte dieses Schlüsselwort aufgenommen werden?';

  @override
  String get reasonRequired => 'Bitte eine Begründung angeben.';

  @override
  String get suggestionSubmitted =>
      'Danke! Ihr Vorschlag wurde zur Prüfung eingereicht.';

  @override
  String get suggestionError =>
      'Vorschlag konnte nicht gesendet werden. Bitte erneut versuchen.';

  @override
  String get customBadge => 'benutzerdefiniert';

  @override
  String get nutritionLabel => 'Nährwerte';

  @override
  String get producerReplyWarningTitle => 'Nicht verifiziert';

  @override
  String get producerReplyWarning =>
      'Jeder kann diese Schaltfläche verwenden — Antworten werden nicht als vom tatsächlichen Hersteller stammend verifiziert. Fahren Sie nur fort, wenn Sie der Hersteller sind.';

  @override
  String get proceedAnyway => 'Trotzdem fortfahren';

  @override
  String get deletedFromHistory => 'Aus Verlauf entfernt';

  @override
  String get undo => 'Rückgängig';

  @override
  String get explanationClean =>
      'Keine Zutaten stimmten mit bekannten tierischen oder alkoholbezogenen Begriffen überein. Dies ist eine automatische Bewertung anhand des Zutatentexts.';

  @override
  String explanationSuspiciousOnly(String ingredients) {
    return 'Keine eindeutig verbotenen Zutaten gefunden, aber $ingredients könnten tierischen Ursprungs sein. Dies ist eine automatische Bewertung anhand des Zutatentexts.';
  }

  @override
  String get explanationHaram =>
      'Dieses Produkt enthält eine oder mehrere Zutaten, die tierischen Ursprungs oder alkoholbezogen sein könnten. Prüfen Sie die markierten Zutaten.';

  @override
  String get unknown => '? UNBEKANNT';

  @override
  String get noCert => '⚠️ KEIN ZERTIFIKAT';

  @override
  String get explanationUnknown =>
      'Für dieses Produkt wurden keine Zutatendaten gefunden. Der Halal-Status kann nicht bestimmt werden — bitte prüfen Sie die Verpackung direkt.';

  @override
  String get explanationNoCert =>
      'Dies ist ein tierisches Lebensmittelprodukt ohne geprüfte Halal-Zertifizierung. Eine islamkonforme Schlachtung kann nicht bestätigt werden — prüfen Sie die Verpackung auf ein Halal-Siegel.';

  @override
  String get nonFood => 'ℹ️ KEIN LEBENSMITTEL';

  @override
  String get explanationNonFood =>
      'Dies ist kein Lebensmittelprodukt. Islamische Ernährungsregeln gelten nicht für dieses Produkt.';

  @override
  String get about => 'Über';

  @override
  String get version => 'Version';

  @override
  String get releaseNotes => 'Versionshinweise';

  @override
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String get upToDate => 'Sie sind auf dem neuesten Stand!';

  @override
  String get installed => 'Installiert';

  @override
  String get store => 'Store';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get latest => 'Neueste';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get updateNow => 'Jetzt aktualisieren';

  @override
  String get reportWrongResult => 'Falsches Ergebnis melden';

  @override
  String get reportWrongResultTitle => 'Ist dieses Ergebnis falsch?';

  @override
  String get reportWrongResultSubtitle =>
      'Sagen Sie uns, was es sein sollte. Wir erstellen einen Fehlerbericht und beheben ihn.';

  @override
  String get currentResultLabel => 'Aktuelles Ergebnis';

  @override
  String get expectedResultLabel => 'Was sollte es sein?';

  @override
  String get optionalNote => 'Optionale Notiz (z. B. warum Sie das denken)';

  @override
  String get reportSubmitted => 'Fehlerbericht eingereicht — danke!';

  @override
  String get reportFailed =>
      'Bericht konnte nicht gesendet werden. Später erneut versuchen.';

  @override
  String get reportResultHalal => 'Halal';

  @override
  String get reportResultHaram => 'Nicht Halal';

  @override
  String get reportResultNonFood => 'Kein Lebensmittel';

  @override
  String get reportResultUnknown => 'Unbekannt';

  @override
  String get myNote => 'Meine Notiz';

  @override
  String get noteHint => 'z. B. Hersteller nach E471 fragen, später prüfen...';

  @override
  String get noteSaved => 'Notiz gespeichert';

  @override
  String get checkLater => 'Später prüfen';

  @override
  String get flaggedOnly => 'Nur markierte';

  @override
  String get allScans => 'Alle Scans';

  @override
  String get deepAnalysis => 'Detailanalyse';

  @override
  String get analyse => 'Analysieren';

  @override
  String get perIngredientAiAnalysis =>
      'KI-Analyse pro Zutat auf islamischer Grundlage';

  @override
  String get communityDiscussion => 'Community-Diskussion';

  @override
  String get noDiscussionsYet => 'Noch keine Diskussionen — starten Sie eine';

  @override
  String get analysisQueued =>
      'Analyse in Warteschlange — Ergebnisse erscheinen nach Admin-Prüfung.';

  @override
  String get analysisFailed =>
      'Analyse fehlgeschlagen — bitte erneut versuchen.';

  @override
  String get signInToDiscuss => 'Anmelden, um eine Diskussion zu starten.';

  @override
  String get signInToChallenge => 'Anmelden, um eine Anfechtung einzureichen.';

  @override
  String get discussions => 'Diskussionen';

  @override
  String get challenges => 'Anfechtungen';

  @override
  String get newDiscussion => 'Neue Diskussion';

  @override
  String get halalDirectory => 'Halal-Verzeichnis';

  @override
  String get signInFailed =>
      'Anmeldung fehlgeschlagen. Bitte erneut versuchen.';

  @override
  String get newVersionAvailable => 'Eine neue Version ist verfügbar';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signOut => 'Abmelden';

  @override
  String get signedIn => 'Angemeldet';

  @override
  String get adminPanel => 'Admin-Panel';

  @override
  String get noDiscussionsHint => 'Seien Sie der Erste!';

  @override
  String get analysisTab => 'Analyse';

  @override
  String get rulesEngineTab => 'Regelwerk';

  @override
  String get photosTab => 'Fotos';

  @override
  String get ingredientsTab => 'Zutaten';

  @override
  String get customRulesTab => 'Benutzerdefiniert';

  @override
  String get builtInRulesTab => 'Eingebaut';

  @override
  String get suggestionsTab => 'Vorschläge';

  @override
  String get searchRules => 'Regeln suchen...';

  @override
  String get noCustomRules => 'Noch keine benutzerdefinierten Regeln';

  @override
  String get noMatchingRules => 'Keine passenden Regeln gefunden';

  @override
  String get noSuggestions => 'Keine ausstehenden Vorschläge';

  @override
  String get addRule => 'Regel hinzufügen';

  @override
  String get editRule => 'Regel bearbeiten';

  @override
  String get delete => 'Löschen';

  @override
  String get deleteRuleTitle => 'Regel löschen';

  @override
  String deleteRuleConfirm(String keyword) {
    return '\"$keyword\" aus den Regeln entfernen?';
  }

  @override
  String get ruleCreated => 'Regel erfolgreich erstellt';

  @override
  String get ruleCreateFailed =>
      'Regel konnte nicht erstellt werden. Bitte erneut versuchen.';

  @override
  String get ruleUpdated => 'Regel erfolgreich aktualisiert';

  @override
  String get ruleUpdateFailed =>
      'Regel konnte nicht aktualisiert werden. Bitte erneut versuchen.';

  @override
  String get ruleDeleted => 'Regel gelöscht';

  @override
  String get ruleDeleteFailed =>
      'Regel konnte nicht gelöscht werden. Bitte erneut versuchen.';

  @override
  String get createRule => 'Regel erstellen';

  @override
  String get updateRule => 'Regel aktualisieren';

  @override
  String get variantsLabel => 'Varianten';

  @override
  String get variantsHint => 'z. B. Schmalz, domuz yağı, saindoux';

  @override
  String get variantsHelperText =>
      'Kommagetrennte mehrsprachige Varianten für den Abgleich';

  @override
  String get suggestVariantsLabel => 'Weitere Sprachen (optional)';

  @override
  String get suggestVariantsHint => 'z. B. schwein, domuz, porc';

  @override
  String get suggestVariantsHelperText =>
      'Kommagetrennte Schreibweisen derselben Zutat in anderen Sprachen';

  @override
  String get translationsLabel => 'Übersetzungen nach Sprache';

  @override
  String get translationsHint => 'de: schwein\ntr: domuz';

  @override
  String get translationsHelperText =>
      'Eine Zeile pro Eintrag: Sprachcode und Begriff (de, tr, fr, es, it, nl, sr, hu, cs). Für Abgleich und Anzeige.';

  @override
  String get mergeKeywordTitle => 'Mit bestehender Regel zusammenführen?';

  @override
  String mergeKeywordMessage(String alias, String canonical) {
    return '\"$alias\" passt zur bestehenden Regel \"$canonical\". Aliase dort zusammenführen statt eine Duplikat-Regel anzulegen?';
  }

  @override
  String get mergeKeywordConfirm => 'Zusammenführen';

  @override
  String get approveAsNewRule => 'Neue Regel anlegen';

  @override
  String get suggestionMerged => 'Vorschlag in bestehende Regel übernommen';

  @override
  String get builtInBadge => 'eingebaut';

  @override
  String get approve => 'Genehmigen';

  @override
  String get reject => 'Ablehnen';

  @override
  String get suggestionApproved =>
      'Vorschlag genehmigt und als Regel hinzugefügt';

  @override
  String get suggestionApproveFailed =>
      'Vorschlag konnte nicht genehmigt werden.';

  @override
  String get suggestionRejected => 'Vorschlag abgelehnt';

  @override
  String get suggestionRejectFailed =>
      'Vorschlag konnte nicht abgelehnt werden.';

  @override
  String get photoIngredientsButton => 'Zutatenfoto prüfen';

  @override
  String get photoAnalysisProductName => 'Fotoanalyse';

  @override
  String get managedProduct => 'Vom Admin verifiziert';

  @override
  String get managedProductNoRefresh =>
      'Dieses Produkt wird von einem Admin verwaltet und kann nicht aus externen Quellen aktualisiert werden.';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountTitle => 'Konto löschen?';

  @override
  String get deleteAccountConfirm =>
      'Ihr Konto und alle zugehörigen Daten werden dauerhaft gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get deleteAccountSuccess => 'Ihr Konto wurde gelöscht.';

  @override
  String get deleteAccountFailed =>
      'Konto konnte nicht gelöscht werden. Bitte erneut versuchen.';

  @override
  String get reportWrongIngredient => 'Falschen Inhaltsstoff melden';

  @override
  String get reportWrongIngredientTitle => 'Falschen Inhaltsstoff melden';

  @override
  String get reportWrongIngredientSubtitle =>
      'Wählen Sie die Inhaltsstoffe aus, die Ihrer Meinung nach falsch aufgeführt sind.';

  @override
  String get reportWrongIngredientExplanation => 'Erklärung (optional)';

  @override
  String get reportWrongIngredientExplanationHint =>
      'z. B. dieser Inhaltsstoff ist pflanzlichen Ursprungs...';

  @override
  String get reportWrongIngredientNoSelection =>
      'Bitte wählen Sie mindestens einen Inhaltsstoff aus.';

  @override
  String get reportWrongIngredientSubmitted =>
      'Danke! Ihre Meldung wurde eingereicht.';

  @override
  String get reportWrongIngredientFailed =>
      'Meldung konnte nicht gesendet werden. Bitte erneut versuchen.';

  @override
  String get reportsTab => 'Meldungen';

  @override
  String get reportedIngredient => 'Als falsch gemeldet';

  @override
  String get noReports => 'Keine ausstehenden Meldungen';

  @override
  String get openProduct => 'Produkt öffnen';

  @override
  String get resolveReport => 'Lösen';

  @override
  String get dismissReport => 'Ablehnen';

  @override
  String get signInRequired => 'Anmeldung erforderlich';

  @override
  String get signInRequiredMessage =>
      'Sie müssen angemeldet sein, um Feedback oder Vorschläge zu senden.';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get batchImport => 'Stapelimport';

  @override
  String get adminUpdateFailed =>
      'Aktualisierung fehlgeschlagen — Supabase-Logs prüfen';

  @override
  String get adminAiRequestsLoadFailed =>
      'KI-Anfragen konnten nicht geladen werden — Verbindung prüfen';

  @override
  String get aiRequestSubmitFailed =>
      'KI-Anfrage konnte nicht gesendet werden.';

  @override
  String get aiRequestSubmitted =>
      'KI-Anfrage gesendet — wartet auf Admin-Prüfung.';

  @override
  String get aiRequestAlreadyPending =>
      'Für dieses Produkt liegt bereits eine ausstehende KI-Anfrage vor.';

  @override
  String adminAiRefetching(String barcode) {
    return 'KI-Zutaten für $barcode werden erneut abgerufen…';
  }
}
