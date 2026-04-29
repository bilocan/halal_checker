import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'HalalScan',
      'startTitle': 'HalalScan',
      'tagline': 'Transparent halal, powered by community.',
      'taglineSubtitle':
          'Every ingredient checked and explained — shaped by your feedback.',
      'newScan': 'New Scan',
      'lastResults': 'Last Results',
      'noRecentResults': 'No recent scans saved yet.',
      'noRecentResultsHint': 'Tap the scan button above to get started.',
      'scanButton': 'Start Scan',
      'scanAnotherProduct': 'Scan Another Product',
      'manualEntry': 'Enter barcode manually',
      'enterBarcodeManually': 'Enter barcode manually',
      'cancel': 'Cancel',
      'submit': 'Submit',
      'scanAgain': 'Scan Again',
      'readyToScan': 'Ready to scan',
      'analyzingBarcode': 'Analyzing barcode...',
      'pointCameraAtBarcode': 'Point camera at barcode on product packaging',
      'barcodeNotSupported':
          'Barcode detected but format not supported. Try manual entry.',
      'pleaseEnterValidBarcode': 'Please enter a valid barcode.',
      'productNotFound': 'Product not found',
      'noProductImageAvailable': 'No product image available',
      'additionalImages': 'Additional Images',
      'ingredients': 'Ingredients',
      'flaggedIngredients': 'Flagged Ingredients',
      'mayBeAnimalDerived': 'May Be Animal-Derived',
      'communityFeedback': 'Community Feedback',
      'noFeedbackYet': 'No feedback yet. Be the first to share your thoughts!',
      'provideFeedback': 'Provide Feedback',
      'replyAsProducer': 'Reply as Producer',
      'producerReply': 'Producer Reply',
      'userFeedback': 'User Feedback',
      'imageNotAvailable': 'Image not available',
      'fairTrade': 'Fair Trade',
      'organic': 'Organic',
      'glutenFree': 'Gluten Free',
      'vegetarian': 'Vegetarian',
      'vegan': 'Vegan',
      'halal': 'HALAL',
      'notHalal': 'HARAM',
      'lastScanned': 'Last scanned',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'daysAgo': '{count} days ago',
      'errorFetchingProduct': 'Error fetching product: {error}',
      'productCouldNotBeRefreshed': 'Could not refresh product data',
      'thankYouFeedback': 'Thank you for your feedback!',
      'errorSubmittingFeedback': 'Error submitting feedback: {error}',
      'replySubmitted': 'Reply submitted successfully!',
      'noResultsSaved': 'No saved scan history yet.',
      'language': 'Language',
      'english': 'English',
      'turkish': 'Türkçe',
      'german': 'Deutsch',
      'scanHistoryTitle': 'Recent scans',
      'filterScan': 'Scan product or enter barcode',
      'openResult': 'Open result',
      'resultTitle': 'Result',
      'noIngredientData': 'No ingredient data available.',
      'foundInIngredients': 'Found in product ingredients.',
      'mayBeAnimalDerivedNote': 'May be animal-derived.',
      'couldNotLoadFeedback': 'Could not load feedback.',
      'couldNotSubmitFeedback': 'Could not submit feedback.',
      'couldNotSubmitReply': 'Could not submit reply.',
      'couldNotRefreshProduct': 'Could not refresh product data.',
      'attachFiles': 'Attach Files',
      'feedbackInputHint': 'Your feedback...',
      'replyInputHint': 'Your reply...',
      'submitReply': 'Submit Reply',
      'refreshTooltip': 'Refresh product data',
      'feedbackDialogHint':
          'Help improve our halal assessment by providing feedback about this product.',
      'replyDialogHint': 'Provide an official response to this feedback.',
      'aiAnalysis': 'AI Analysis',
      'keywordAnalysis': 'Keyword Analysis',
      'analysisTransparency': 'Analysis Transparency',
      'haramKeywordsChecked': 'Haram Ingredients We Check',
      'suspiciousKeywordsChecked': 'Suspicious Ingredients We Check',
      'transparencyNote':
          'Something missing from our list? Let us know via feedback!',
      'recheck': 'Recheck',
      'foundNotFlagged':
          'Found in ingredients, but not flagged by the analysis (e.g. fatty alcohol, trace amount, or context-safe use).',
      'fattyAlcoholNote':
          'This is a fatty alcohol (e.g. cetyl or stearyl alcohol) — a plant-derived emulsifier. It has no relation to drinking alcohol and is halal.',
      'keywords': 'Keywords',
      'haramTab': 'Haram',
      'suspiciousTab': 'Suspicious',
      'suggestKeyword': 'Suggest a Keyword',
      'suggestKeywordHint':
          'Think we\'re missing something? Suggest a keyword and we\'ll review it.',
      'keywordLabel': 'Keyword',
      'keywordHint': 'e.g. lard, ethanol, cochineal',
      'keywordRequired': 'Please enter a keyword.',
      'categoryLabel': 'Category',
      'haramCategory': 'Haram (definitively not permissible)',
      'suspiciousCategory': 'Suspicious (may be animal-derived)',
      'reasonLabel': 'Reason',
      'reasonHint': 'Why should this keyword be added?',
      'reasonRequired': 'Please provide a reason.',
      'suggestionSubmitted':
          'Thank you! Your suggestion has been submitted for review.',
      'suggestionError': 'Could not submit suggestion. Please try again.',
      'customBadge': 'custom',
    },
    'tr': {
      'appTitle': 'HalalScan',
      'startTitle': 'HalalScan',
      'tagline': 'Şeffaf helal, topluluk gücüyle.',
      'taglineSubtitle':
          'Her içerik kontrol edilir ve açıklanır — geri bildirimlerinizle gelişir.',
      'newScan': 'Yeni Tara',
      'lastResults': 'Son Sonuçlar',
      'noRecentResults': 'Henüz kaydedilmiş tarama yok.',
      'noRecentResultsHint':
          'Başlamak için yukarıdaki tarama düğmesine dokunun.',
      'scanButton': 'Taramayı Başlat',
      'scanAnotherProduct': 'Başka ürün tara',
      'manualEntry': 'Barkodu elle gir',
      'enterBarcodeManually': 'Barkodu elle gir',
      'cancel': 'İptal',
      'submit': 'Gönder',
      'scanAgain': 'Tekrar Tara',
      'readyToScan': 'Tarama için hazır',
      'analyzingBarcode': 'Barkod analiz ediliyor...',
      'pointCameraAtBarcode': 'Kamerayı ürün ambalajındaki barkoda doğrultun',
      'barcodeNotSupported':
          'Barkod algılandı ama format desteklenmiyor. Lütfen manuel girin.',
      'pleaseEnterValidBarcode': 'Lütfen geçerli bir barkod girin.',
      'productNotFound': 'Ürün bulunamadı',
      'noProductImageAvailable': 'Ürün resmi yok',
      'additionalImages': 'Ek Görseller',
      'ingredients': 'İçindekiler',
      'flaggedIngredients': 'İşaretli İçindekiler',
      'mayBeAnimalDerived': 'Hayvansal Kaynaklı Olabilir',
      'communityFeedback': 'Topluluk Geri Bildirimi',
      'noFeedbackYet': 'Henüz geri bildirim yok. İlk siz olun!',
      'provideFeedback': 'Geri Bildirim Ver',
      'replyAsProducer': 'Üretici olarak yanıtla',
      'producerReply': 'Üretici Yanıtı',
      'userFeedback': 'Kullanıcı Geri Bildirimi',
      'imageNotAvailable': 'Resim mevcut değil',
      'fairTrade': 'Adil Ticaret',
      'organic': 'Organik',
      'glutenFree': 'Glutensiz',
      'vegetarian': 'Vejetaryen',
      'vegan': 'Vegan',
      'halal': 'HELAL',
      'notHalal': 'HARAM',
      'lastScanned': 'Son tarama',
      'today': 'Bugün',
      'yesterday': 'Dün',
      'daysAgo': '{count} gün önce',
      'errorFetchingProduct': 'Ürün alınırken hata: {error}',
      'productCouldNotBeRefreshed': 'Ürün verisi yenilenemedi',
      'thankYouFeedback': 'Geri bildiriminiz için teşekkürler!',
      'errorSubmittingFeedback': 'Geri bildirim gönderilirken hata: {error}',
      'replySubmitted': 'Yanıt başarıyla gönderildi!',
      'noResultsSaved': 'Henüz kayıtlı tarama geçmişi yok.',
      'language': 'Dil',
      'english': 'English',
      'turkish': 'Türkçe',
      'german': 'Deutsch',
      'scanHistoryTitle': 'Son taramalar',
      'filterScan': 'Ürünü tara veya barkodu gir',
      'openResult': 'Sonucu aç',
      'resultTitle': 'Sonuç',
      'noIngredientData': 'İçerik bilgisi mevcut değil.',
      'foundInIngredients': 'Ürün içeriklerinde bulundu.',
      'mayBeAnimalDerivedNote': 'Hayvansal kaynaklı olabilir.',
      'couldNotLoadFeedback': 'Geri bildirim yüklenemedi.',
      'couldNotSubmitFeedback': 'Geri bildirim gönderilemedi.',
      'couldNotSubmitReply': 'Yanıt gönderilemedi.',
      'couldNotRefreshProduct': 'Ürün verisi güncellenemedi.',
      'attachFiles': 'Dosya Ekle',
      'feedbackInputHint': 'Geri bildiriminiz...',
      'replyInputHint': 'Yanıtınız...',
      'submitReply': 'Yanıtı Gönder',
      'refreshTooltip': 'Ürün verisini yenile',
      'feedbackDialogHint':
          'Geri bildiriminizle helal değerlendirmemizi geliştirin.',
      'replyDialogHint': 'Bu geri bildirime resmi bir yanıt verin.',
      'aiAnalysis': 'Yapay Zeka Analizi',
      'keywordAnalysis': 'Anahtar Kelime Analizi',
      'analysisTransparency': 'Analiz Şeffaflığı',
      'haramKeywordsChecked': 'Kontrol Ettiğimiz Haram İçerikler',
      'suspiciousKeywordsChecked': 'Kontrol Ettiğimiz Şüpheli İçerikler',
      'transparencyNote': 'Listemizde eksik mi? Geri bildirim gönderin!',
      'recheck': 'Yeniden Kontrol Et',
      'foundNotFlagged':
          'İçeriklerde bulundu, ancak analiz tarafından işaretlenmedi (örn. yağ alkolü, iz miktarı veya bağlama güvenli kullanım).',
      'fattyAlcoholNote':
          'Bu bir yağ alkolüdür (örn. setil veya stearil alkol) — bitkisel kaynaklı bir emülgatördür. İçki alkolüyle hiçbir ilgisi yoktur ve helaldir.',
      'keywords': 'Anahtar Kelimeler',
      'haramTab': 'Haram',
      'suspiciousTab': 'Şüpheli',
      'suggestKeyword': 'Anahtar Kelime Öner',
      'suggestKeywordHint':
          'Bir şeyi atladığımızı mı düşünüyorsunuz? Önerin incelememize gönderin.',
      'keywordLabel': 'Anahtar Kelime',
      'keywordHint': 'örn. domuz yağı, etanol, karmin',
      'keywordRequired': 'Lütfen bir anahtar kelime girin.',
      'categoryLabel': 'Kategori',
      'haramCategory': 'Haram (kesinlikle yasak)',
      'suspiciousCategory': 'Şüpheli (hayvansal kaynaklı olabilir)',
      'reasonLabel': 'Sebep',
      'reasonHint': 'Bu anahtar kelime neden eklenmeli?',
      'reasonRequired': 'Lütfen bir sebep belirtin.',
      'suggestionSubmitted':
          'Teşekkürler! Öneriniz incelenmek üzere gönderildi.',
      'suggestionError': 'Öneri gönderilemedi. Lütfen tekrar deneyin.',
      'customBadge': 'özel',
    },
    'de': {
      'appTitle': 'HalalScan',
      'startTitle': 'HalalScan',
      'tagline': 'Transparentes Halal, von der Community.',
      'taglineSubtitle':
          'Jede Zutat geprüft und erklärt — verbessert durch Ihr Feedback.',
      'newScan': 'Neu scannen',
      'lastResults': 'Letzte Ergebnisse',
      'noRecentResults': 'Noch keine letzten Scans gespeichert.',
      'noRecentResultsHint':
          'Tippen Sie auf die Schaltfläche oben, um loszulegen.',
      'scanButton': 'Scan starten',
      'scanAnotherProduct': 'Anderes Produkt scannen',
      'manualEntry': 'Barcode manuell eingeben',
      'enterBarcodeManually': 'Barcode manuell eingeben',
      'cancel': 'Abbrechen',
      'submit': 'Absenden',
      'scanAgain': 'Erneut scannen',
      'readyToScan': 'Bereit zum Scannen',
      'analyzingBarcode': 'Barkod wird analysiert...',
      'pointCameraAtBarcode':
          'Richten Sie die Kamera auf den Barcode auf der Verpackung',
      'barcodeNotSupported':
          'Barcode erkannt, Format wird aber nicht unterstützt. Versuchen Sie die manuelle Eingabe.',
      'pleaseEnterValidBarcode': 'Bitte geben Sie einen gültigen Barcode ein.',
      'productNotFound': 'Produkt nicht gefunden',
      'noProductImageAvailable': 'Kein Produktbild verfügbar',
      'additionalImages': 'Zusätzliche Bilder',
      'ingredients': 'Zutaten',
      'flaggedIngredients': 'Markierte Zutaten',
      'mayBeAnimalDerived': 'Kann tierischen Ursprungs sein',
      'communityFeedback': 'Community-Feedback',
      'noFeedbackYet': 'Noch kein Feedback. Sei der Erste!',
      'provideFeedback': 'Feedback geben',
      'replyAsProducer': 'Als Hersteller antworten',
      'producerReply': 'Hersteller-Antwort',
      'userFeedback': 'Nutzer-Feedback',
      'imageNotAvailable': 'Bild nicht verfügbar',
      'fairTrade': 'Fair Trade',
      'organic': 'Bio',
      'glutenFree': 'Glutenfrei',
      'vegetarian': 'Vegetarisch',
      'vegan': 'Vegan',
      'halal': 'HALAL',
      'notHalal': 'HARAM',
      'lastScanned': 'Zuletzt gescannt',
      'today': 'Heute',
      'yesterday': 'Gestern',
      'daysAgo': 'vor {count} Tagen',
      'errorFetchingProduct': 'Fehler beim Laden des Produkts: {error}',
      'productCouldNotBeRefreshed':
          'Produktdaten konnten nicht aktualisiert werden',
      'thankYouFeedback': 'Danke für Ihr Feedback!',
      'errorSubmittingFeedback': 'Fehler beim Absenden des Feedbacks: {error}',
      'replySubmitted': 'Antwort erfolgreich gesendet!',
      'noResultsSaved': 'Noch keine Scan-History gespeichert.',
      'language': 'Sprache',
      'english': 'English',
      'turkish': 'Türkçe',
      'german': 'Deutsch',
      'scanHistoryTitle': 'Zuletzt gescannt',
      'filterScan': 'Produkt scannen oder Barcode eingeben',
      'openResult': 'Ergebnis öffnen',
      'resultTitle': 'Ergebnis',
      'noIngredientData': 'Keine Zutatendaten verfügbar.',
      'foundInIngredients': 'In Produktzutaten gefunden.',
      'mayBeAnimalDerivedNote': 'Kann tierischen Ursprungs sein.',
      'couldNotLoadFeedback': 'Feedback konnte nicht geladen werden.',
      'couldNotSubmitFeedback': 'Feedback konnte nicht gesendet werden.',
      'couldNotSubmitReply': 'Antwort konnte nicht gesendet werden.',
      'couldNotRefreshProduct':
          'Produktdaten konnten nicht aktualisiert werden.',
      'attachFiles': 'Dateien anhängen',
      'feedbackInputHint': 'Ihr Feedback...',
      'replyInputHint': 'Ihre Antwort...',
      'submitReply': 'Antwort senden',
      'refreshTooltip': 'Produktdaten aktualisieren',
      'feedbackDialogHint':
          'Helfen Sie uns, unsere Halal-Bewertung zu verbessern.',
      'replyDialogHint':
          'Geben Sie eine offizielle Antwort auf dieses Feedback.',
      'aiAnalysis': 'KI-Analyse',
      'keywordAnalysis': 'Schlüsselwortanalyse',
      'analysisTransparency': 'Analysetransparenz',
      'haramKeywordsChecked': 'Haram-Zutaten, die wir prüfen',
      'suspiciousKeywordsChecked': 'Verdächtige Zutaten, die wir prüfen',
      'transparencyNote': 'Fehlt etwas? Teilen Sie es uns mit!',
      'recheck': 'Erneut prüfen',
      'foundNotFlagged':
          'In Zutaten gefunden, aber nicht von der Analyse markiert (z. B. Fettalkohole, Spurenmengen oder kontextsichere Verwendung).',
      'fattyAlcoholNote':
          'Dies ist ein Fettalkohol (z. B. Cetyl- oder Stearylalkohol) – ein pflanzlicher Emulgator. Er hat keinen Bezug zu Trinkalkohol und ist halal.',
      'keywords': 'Schlüsselwörter',
      'haramTab': 'Haram',
      'suspiciousTab': 'Verdächtig',
      'suggestKeyword': 'Schlüsselwort vorschlagen',
      'suggestKeywordHint':
          'Fehlt etwas? Schlagen Sie ein Schlüsselwort vor – wir prüfen es.',
      'keywordLabel': 'Schlüsselwort',
      'keywordHint': 'z. B. Schmalz, Ethanol, Karmin',
      'keywordRequired': 'Bitte ein Schlüsselwort eingeben.',
      'categoryLabel': 'Kategorie',
      'haramCategory': 'Haram (eindeutig verboten)',
      'suspiciousCategory': 'Verdächtig (möglicherweise tierisch)',
      'reasonLabel': 'Begründung',
      'reasonHint': 'Warum sollte dieses Schlüsselwort aufgenommen werden?',
      'reasonRequired': 'Bitte eine Begründung angeben.',
      'suggestionSubmitted':
          'Danke! Ihr Vorschlag wurde zur Prüfung eingereicht.',
      'suggestionError':
          'Vorschlag konnte nicht gesendet werden. Bitte erneut versuchen.',
      'customBadge': 'benutzerdefiniert',
    },
  };

  String _translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }

  String get appTitle => _translate('appTitle');
  String get startTitle => _translate('startTitle');
  String get tagline => _translate('tagline');
  String get taglineSubtitle => _translate('taglineSubtitle');
  String get newScan => _translate('newScan');
  String get lastResults => _translate('lastResults');
  String get noRecentResults => _translate('noRecentResults');
  String get noRecentResultsHint => _translate('noRecentResultsHint');
  String get scanButton => _translate('scanButton');
  String get scanAnotherProduct => _translate('scanAnotherProduct');
  String get manualEntry => _translate('manualEntry');
  String get enterBarcodeManually => _translate('enterBarcodeManually');
  String get cancel => _translate('cancel');
  String get submit => _translate('submit');
  String get scanAgain => _translate('scanAgain');
  String get readyToScan => _translate('readyToScan');
  String get analyzingBarcode => _translate('analyzingBarcode');
  String get pointCameraAtBarcode => _translate('pointCameraAtBarcode');
  String get barcodeNotSupported => _translate('barcodeNotSupported');
  String get pleaseEnterValidBarcode => _translate('pleaseEnterValidBarcode');
  String get productNotFound => _translate('productNotFound');
  String get noProductImageAvailable => _translate('noProductImageAvailable');
  String get additionalImages => _translate('additionalImages');
  String get ingredients => _translate('ingredients');
  String get flaggedIngredients => _translate('flaggedIngredients');
  String get mayBeAnimalDerived => _translate('mayBeAnimalDerived');
  String get communityFeedback => _translate('communityFeedback');
  String get noFeedbackYet => _translate('noFeedbackYet');
  String get provideFeedback => _translate('provideFeedback');
  String get replyAsProducer => _translate('replyAsProducer');
  String get producerReply => _translate('producerReply');
  String get userFeedback => _translate('userFeedback');
  String get imageNotAvailable => _translate('imageNotAvailable');
  String get fairTrade => _translate('fairTrade');
  String get organic => _translate('organic');
  String get glutenFree => _translate('glutenFree');
  String get vegetarian => _translate('vegetarian');
  String get vegan => _translate('vegan');
  String get halal => _translate('halal');
  String get notHalal => _translate('notHalal');
  String get lastScanned => _translate('lastScanned');
  String get today => _translate('today');
  String get yesterday => _translate('yesterday');
  String daysAgo(int count) =>
      _translate('daysAgo').replaceAll('{count}', count.toString());
  String errorFetchingProduct(String error) =>
      _translate('errorFetchingProduct').replaceAll('{error}', error);
  String get productCouldNotBeRefreshed =>
      _translate('productCouldNotBeRefreshed');
  String get thankYouFeedback => _translate('thankYouFeedback');
  String errorSubmittingFeedback(String error) =>
      _translate('errorSubmittingFeedback').replaceAll('{error}', error);
  String get replySubmitted => _translate('replySubmitted');
  String get noResultsSaved => _translate('noResultsSaved');
  String get language => _translate('language');
  String get english => _translate('english');
  String get turkish => _translate('turkish');
  String get german => _translate('german');
  String get openResult => _translate('openResult');
  String get resultTitle => _translate('resultTitle');
  String get noIngredientData => _translate('noIngredientData');
  String get foundInIngredients => _translate('foundInIngredients');
  String get mayBeAnimalDerivedNote => _translate('mayBeAnimalDerivedNote');
  String get couldNotLoadFeedback => _translate('couldNotLoadFeedback');
  String get couldNotSubmitFeedback => _translate('couldNotSubmitFeedback');
  String get couldNotSubmitReply => _translate('couldNotSubmitReply');
  String get couldNotRefreshProduct => _translate('couldNotRefreshProduct');
  String get attachFiles => _translate('attachFiles');
  String get feedbackInputHint => _translate('feedbackInputHint');
  String get replyInputHint => _translate('replyInputHint');
  String get submitReply => _translate('submitReply');
  String get refreshTooltip => _translate('refreshTooltip');
  String get feedbackDialogHint => _translate('feedbackDialogHint');
  String get replyDialogHint => _translate('replyDialogHint');
  String get aiAnalysis => _translate('aiAnalysis');
  String get keywordAnalysis => _translate('keywordAnalysis');
  String get analysisTransparency => _translate('analysisTransparency');
  String get haramKeywordsChecked => _translate('haramKeywordsChecked');
  String get suspiciousKeywordsChecked =>
      _translate('suspiciousKeywordsChecked');
  String get transparencyNote => _translate('transparencyNote');
  String get recheck => _translate('recheck');
  String get foundNotFlagged => _translate('foundNotFlagged');
  String get fattyAlcoholNote => _translate('fattyAlcoholNote');
  String get keywords => _translate('keywords');
  String get haramTab => _translate('haramTab');
  String get suspiciousTab => _translate('suspiciousTab');
  String get suggestKeyword => _translate('suggestKeyword');
  String get suggestKeywordHint => _translate('suggestKeywordHint');
  String get keywordLabel => _translate('keywordLabel');
  String get keywordHint => _translate('keywordHint');
  String get keywordRequired => _translate('keywordRequired');
  String get categoryLabel => _translate('categoryLabel');
  String get haramCategory => _translate('haramCategory');
  String get suspiciousCategory => _translate('suspiciousCategory');
  String get reasonLabel => _translate('reasonLabel');
  String get reasonHint => _translate('reasonHint');
  String get reasonRequired => _translate('reasonRequired');
  String get suggestionSubmitted => _translate('suggestionSubmitted');
  String get suggestionError => _translate('suggestionError');
  String get customBadge => _translate('customBadge');

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'No AppLocalizations found in context');
    return localizations!;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'tr', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      Future.value(AppLocalizations(locale));

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
