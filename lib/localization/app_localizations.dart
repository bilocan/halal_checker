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
      'uploadProductPhoto': 'Upload Photo',
      'uploadPhotoHint': 'Help others by contributing a photo of this product',
      'photoUploaded': 'Photo submitted — thank you!',
      'photoUploadFailed': 'Could not upload photo. Please try again.',
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
      'transparentSummary': 'Decision summary',
      'transparentResult': 'Result',
      'transparentIngredientsChecked': 'Ingredients checked',
      'transparentRulesChecked': 'Rules checked',
      'transparentRulesAvailable': '{count} rules available (nothing to check)',
      'transparentFlagged': 'Flagged',
      'transparentSuspicious': 'Needs verification',
      'transparentNoMatches': 'No rule matches found',
      'transparentNoIngredients': 'No ingredient text was available to check',
      'transparentExplanation': 'Explanation',
      'contributeIngredients': 'Add Ingredients',
      'contributeIngredientsHint':
          'No ingredient data found. Help the community by adding the ingredients from the packaging.',
      'ingredientTextLabel': 'Ingredient text',
      'ingredientTextHint':
          'Type or paste the ingredient list from the packaging',
      'ingredientSubmitted':
          'Thank you! Ingredients submitted — the product will be re-analysed.',
      'ingredientSubmitFailed':
          'Could not submit ingredients. Please try again.',
      'improveOnOpenFoodFacts': 'Edit on OpenFoodFacts',
      'improveOnOpenFoodFactsHint':
          'Help improve this product for everyone by adding data directly on OpenFoodFacts.',
      'extractingIngredients': 'Reading ingredients from image…',
      'ocrFailed':
          'Could not read ingredients from the image. You can type them manually below.',
      'ocrSuccess': 'Ingredients extracted — please review before submitting.',
      'productImages': 'Product images',
      'extractFromExistingImage': 'Pick from gallery',
      'takePhotoOfIngredients': 'Take photo of ingredients',
      'cameraError': 'Could not open camera. Please check camera permissions.',
      'noIngredientsImageHint':
          'No ingredients image available for this product. Please take a photo of the ingredient list on the packaging.',
      'ocrNoIngredientsFound':
          'No ingredient list found in the available images. Please take a photo of the ingredient label instead.',
      'viewAllCheckedKeywords': 'View all checked keywords',
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
      'nutritionLabel': 'Nutrition',
      'producerReplyWarningTitle': 'Unverified Action',
      'producerReplyWarning':
          'Anyone can post using this button — replies are not verified as coming from the actual manufacturer. Proceed only if you are the producer.',
      'proceedAnyway': 'Proceed Anyway',
      'deletedFromHistory': 'Removed from history',
      'undo': 'Undo',
      'explanationClean':
          'No ingredients matched known animal-derived or alcohol-related keywords. This is an automated assessment based on ingredient text.',
      'explanationSuspiciousOnly':
          'No definitely haram ingredients found, but {ingredients} may be animal-derived. This is an automated assessment based on ingredient text.',
      'explanationHaram':
          'This product contains one or more ingredients that may be animal-derived or alcohol-related. Review the flagged ingredients below for details.',
      'unknown': '? UNKNOWN',
      'noCert': '⚠️ NO CERT',
      'explanationUnknown':
          'No ingredient data was found for this product. Halal status cannot be determined — check the packaging directly.',
      'explanationNoCert':
          'This is an animal-derived food product without a verified halal certification. Halal slaughter cannot be confirmed — check the packaging for a halal label.',
      'nonFood': 'ℹ️ NOT FOOD',
      'explanationNonFood':
          'This is a non-food product. Islamic dietary rules do not apply.',
      'about': 'About',
      'version': 'Version',
      'releaseNotes': 'Release Notes',
      'checkForUpdates': 'Check for Updates',
      'upToDate': "You're up to date!",
      'installed': 'Installed',
      'store': 'Store',
      'privacyPolicy': 'Privacy Policy',
      'latest': 'Latest',
      'updateAvailable': 'Update Available',
      'updateNow': 'Update Now',
      'reportWrongResult': 'Report Wrong Result',
      'reportWrongResultTitle': 'Is this result wrong?',
      'reportWrongResultSubtitle':
          'Tell us what it should be. '
          "We'll create a bug report and fix it.",
      'currentResultLabel': 'Current result',
      'expectedResultLabel': 'What should it be?',
      'optionalNote': 'Optional note (e.g. why you think so)',
      'reportSubmitted': 'Bug report submitted — thank you!',
      'reportFailed': 'Could not submit report. Try again later.',
      'reportResultHalal': 'Halal',
      'reportResultHaram': 'Not Halal',
      'reportResultNonFood': 'Non-Food',
      'reportResultUnknown': 'Unknown',
      'myNote': 'My Note',
      'noteHint': 'e.g. ask producer about E471, check later...',
      'noteSaved': 'Note saved',
      'checkLater': 'Check later',
      'flaggedOnly': 'Flagged only',
      'allScans': 'All scans',
      'deepAnalysis': 'Deep Analysis',
      'analyse': 'Analyse',
      'perIngredientAiAnalysis':
          'Per-ingredient AI analysis with Islamic basis',
      'communityDiscussion': 'Community Discussion',
      'noDiscussionsYet': 'No discussions yet — start one',
      'analysisQueued':
          'Analysis queued — results will appear after admin review.',
      'analysisFailed': 'Analysis failed — please try again.',
      'signInToDiscuss': 'Sign in to start a discussion.',
      'signInToChallenge': 'Sign in to submit a challenge.',
      'discussions': 'Discussions',
      'challenges': 'Challenges',
      'newDiscussion': 'New Discussion',
      'halalDirectory': 'Halal Directory',
      'signInFailed': 'Sign-in failed. Please try again.',
      'newVersionAvailable': 'A new version is available',
      'signIn': 'Sign in',
      'signOut': 'Sign out',
      'signedIn': 'Signed in',
      'adminPanel': 'Admin panel',
      'noDiscussionsHint': 'Be the first to start one!',
      'analysisTab': 'Analysis',
      'rulesEngineTab': 'Rules Engine',
      'photosTab': 'Photos',
      'ingredientsTab': 'Ingredients',
      'customRulesTab': 'Custom',
      'builtInRulesTab': 'Built-in',
      'suggestionsTab': 'Suggestions',
      'searchRules': 'Search rules...',
      'noCustomRules': 'No custom rules yet',
      'noMatchingRules': 'No matching rules found',
      'noSuggestions': 'No pending suggestions',
      'addRule': 'Add Rule',
      'editRule': 'Edit Rule',
      'delete': 'Delete',
      'deleteRuleTitle': 'Delete Rule',
      'deleteRuleConfirm': 'Remove "{keyword}" from the rules?',
      'ruleCreated': 'Rule created successfully',
      'ruleCreateFailed': 'Could not create rule. Please try again.',
      'ruleUpdated': 'Rule updated successfully',
      'ruleUpdateFailed': 'Could not update rule. Please try again.',
      'ruleDeleted': 'Rule deleted',
      'ruleDeleteFailed': 'Could not delete rule. Please try again.',
      'createRule': 'Create Rule',
      'updateRule': 'Update Rule',
      'variantsLabel': 'Variants',
      'variantsHint': 'e.g. schmalz, domuz yağı, saindoux',
      'variantsHelperText':
          'Comma-separated multilingual variants for matching',
      'builtInBadge': 'built-in',
      'approve': 'Approve',
      'reject': 'Reject',
      'suggestionApproved': 'Suggestion approved and added as a rule',
      'suggestionApproveFailed': 'Could not approve suggestion.',
      'suggestionRejected': 'Suggestion rejected',
      'suggestionRejectFailed': 'Could not reject suggestion.',
      'photoIngredientsButton': 'Check Ingredients Photo',
      'photoAnalysisProductName': 'Photo Analysis',
      'managedProduct': 'Verified by admin',
      'managedProductNoRefresh':
          'This product is managed by an admin and cannot be refreshed from external sources.',
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
      'uploadProductPhoto': 'Fotoğraf Yükle',
      'uploadPhotoHint':
          'Bu ürünün fotoğrafını ekleyerek diğerlerine yardım edin',
      'photoUploaded': 'Fotoğraf gönderildi — teşekkürler!',
      'photoUploadFailed': 'Fotoğraf yüklenemedi. Lütfen tekrar deneyin.',
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
      'transparentRulesAvailable':
          '{count} kural mevcut (kontrol edilecek veri yok)',
      'contributeIngredients': 'İçerik Ekle',
      'contributeIngredientsHint':
          'İçerik bilgisi bulunamadı. Ambalajdaki içerikleri ekleyerek topluluğa yardım edin.',
      'ingredientTextLabel': 'İçerik metni',
      'ingredientTextHint':
          'Ambalajdaki içerik listesini yazın veya yapıştırın',
      'ingredientSubmitted':
          'Teşekkürler! İçerikler gönderildi — ürün yeniden analiz edilecek.',
      'ingredientSubmitFailed':
          'İçerikler gönderilemedi. Lütfen tekrar deneyin.',
      'improveOnOpenFoodFacts': 'OpenFoodFacts\'ta Düzenle',
      'improveOnOpenFoodFactsHint':
          'OpenFoodFacts\'ta veri ekleyerek bu ürünü herkes için geliştirin.',
      'extractingIngredients': 'İçerikler görüntüden okunuyor…',
      'ocrFailed': 'Görüntüden içerik okunamadı. Aşağıya elle yazabilirsiniz.',
      'ocrSuccess': 'İçerikler çıkarıldı — göndermeden önce gözden geçirin.',
      'productImages': 'Ürün görselleri',
      'extractFromExistingImage': 'Galeriden seç',
      'takePhotoOfIngredients': 'İçerik fotoğrafı çek',
      'cameraError': 'Kamera açılamadı. Lütfen kamera izinlerini kontrol edin.',
      'noIngredientsImageHint':
          'Bu ürün için içerik görseli mevcut değil. Lütfen ambalajdaki içerik listesinin fotoğrafını çekin.',
      'ocrNoIngredientsFound':
          'Mevcut görsellerde içerik listesi bulunamadı. Lütfen içerik etiketinin fotoğrafını çekin.',
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
      'nutritionLabel': 'Beslenme Değerleri',
      'producerReplyWarningTitle': 'Doğrulanmamış İşlem',
      'producerReplyWarning':
          'Bu düğmeyi herkes kullanabilir — yanıtların gerçek üreticiden geldiği doğrulanmaz. Yalnızca üreticiyseniz devam edin.',
      'proceedAnyway': 'Yine de Devam Et',
      'deletedFromHistory': 'Geçmişten silindi',
      'undo': 'Geri Al',
      'explanationClean':
          'Bilinen hayvansal kaynaklı veya alkol içerikli anahtar kelimelerle eşleşen içerik bulunamadı. Bu, içerik metnine dayalı otomatik bir değerlendirmedir.',
      'explanationSuspiciousOnly':
          'Kesinlikle haram içerik bulunamadı, ancak {ingredients} hayvansal kaynaklı olabilir. Bu, içerik metnine dayalı otomatik bir değerlendirmedir.',
      'explanationHaram':
          'Bu ürün, hayvansal kaynaklı veya alkol içerikli olabilecek bir veya daha fazla içerik barındırmaktadır. Ayrıntılar için işaretlenen içerikleri inceleyin.',
      'unknown': '? BİLİNMİYOR',
      'noCert': '⚠️ SERTİFİKA YOK',
      'explanationUnknown':
          'Bu ürün için içerik bilgisi bulunamadı. Helal durumu belirlenemiyor — lütfen ambalajı doğrudan kontrol edin.',
      'explanationNoCert':
          'Bu ürün hayvansal kaynaklı bir gıdadır ancak doğrulanmış bir helal sertifikası bulunmamaktadır. Helal kesim teyit edilemez — ambalajda helal etiketi olup olmadığını kontrol edin.',
      'nonFood': 'ℹ️ GIDA DEĞİL',
      'explanationNonFood':
          'Bu bir gıda ürünü değildir. İslami beslenme kuralları bu ürün için geçerli değildir.',
      'about': 'Hakkında',
      'version': 'Versiyon',
      'releaseNotes': 'Sürüm Notları',
      'checkForUpdates': 'Güncellemeleri Kontrol Et',
      'upToDate': 'Güncel durumdasınız!',
      'installed': 'Kurulu',
      'store': 'Mağaza',
      'privacyPolicy': 'Gizlilik Politikası',
      'latest': 'En Son',
      'updateAvailable': 'Güncelleme Mevcut',
      'updateNow': 'Şimdi Güncelle',
      'reportWrongResult': 'Yanlış Sonucu Bildir',
      'reportWrongResultTitle': 'Bu sonuç yanlış mı?',
      'reportWrongResultSubtitle':
          'Ne olması gerektiğini söyleyin. '
          'Bir hata raporu oluşturup düzelteceğiz.',
      'currentResultLabel': 'Mevcut sonuç',
      'expectedResultLabel': 'Ne olmalı?',
      'optionalNote': 'İsteğe bağlı not (örn. neden öyle düşündüğünüz)',
      'reportSubmitted': 'Hata raporu gönderildi — teşekkürler!',
      'reportFailed': 'Rapor gönderilemedi. Daha sonra tekrar deneyin.',
      'reportResultHalal': 'Helal',
      'reportResultHaram': 'Haram',
      'reportResultNonFood': 'Gıda Değil',
      'reportResultUnknown': 'Bilinmiyor',
      'myNote': 'Notum',
      'noteHint': 'örn. üreticiye E471 sor, sonra kontrol et...',
      'noteSaved': 'Not kaydedildi',
      'checkLater': 'Sonra kontrol et',
      'flaggedOnly': 'Yalnızca işaretliler',
      'allScans': 'Tüm taramalar',
      'deepAnalysis': 'Detaylı Analiz',
      'analyse': 'Analiz Et',
      'perIngredientAiAnalysis':
          'İslami temelli içerik bazlı yapay zeka analizi',
      'communityDiscussion': 'Topluluk Tartışması',
      'noDiscussionsYet': 'Henüz tartışma yok — ilk siz başlatın',
      'analysisQueued':
          'Analiz sıraya alındı — sonuçlar yönetici incelemesinden sonra görünecektir.',
      'analysisFailed': 'Analiz başarısız oldu — lütfen tekrar deneyin.',
      'signInToDiscuss': 'Tartışma başlatmak için giriş yapın.',
      'signInToChallenge': 'İtiraz göndermek için giriş yapın.',
      'discussions': 'Tartışmalar',
      'challenges': 'İtirazlar',
      'newDiscussion': 'Yeni Tartışma',
      'halalDirectory': 'Helal Rehberi',
      'signInFailed': 'Giriş başarısız oldu. Lütfen tekrar deneyin.',
      'newVersionAvailable': 'Yeni bir sürüm mevcut',
      'signIn': 'Giriş Yap',
      'signOut': 'Çıkış Yap',
      'signedIn': 'Giriş yapıldı',
      'adminPanel': 'Yönetici paneli',
      'noDiscussionsHint': 'İlk tartışmayı siz başlatın!',
      'analysisTab': 'Analiz',
      'rulesEngineTab': 'Kural Motoru',
      'photosTab': 'Fotoğraflar',
      'ingredientsTab': 'Malzemeler',
      'customRulesTab': 'Özel',
      'builtInRulesTab': 'Yerleşik',
      'suggestionsTab': 'Öneriler',
      'searchRules': 'Kural ara...',
      'noCustomRules': 'Henüz özel kural yok',
      'noMatchingRules': 'Eşleşen kural bulunamadı',
      'noSuggestions': 'Bekleyen öneri yok',
      'addRule': 'Kural Ekle',
      'editRule': 'Kuralı Düzenle',
      'delete': 'Sil',
      'deleteRuleTitle': 'Kuralı Sil',
      'deleteRuleConfirm': '"{keyword}" kuralını silmek istiyor musunuz?',
      'ruleCreated': 'Kural başarıyla oluşturuldu',
      'ruleCreateFailed': 'Kural oluşturulamadı. Lütfen tekrar deneyin.',
      'ruleUpdated': 'Kural başarıyla güncellendi',
      'ruleUpdateFailed': 'Kural güncellenemedi. Lütfen tekrar deneyin.',
      'ruleDeleted': 'Kural silindi',
      'ruleDeleteFailed': 'Kural silinemedi. Lütfen tekrar deneyin.',
      'createRule': 'Kural Oluştur',
      'updateRule': 'Kuralı Güncelle',
      'variantsLabel': 'Varyantlar',
      'variantsHint': 'örn. schmalz, domuz yağı, saindoux',
      'variantsHelperText':
          'Eşleştirme için virgülle ayrılmış çok dilli varyantlar',
      'builtInBadge': 'yerleşik',
      'approve': 'Onayla',
      'reject': 'Reddet',
      'suggestionApproved': 'Öneri onaylandı ve kural olarak eklendi',
      'suggestionApproveFailed': 'Öneri onaylanamadı.',
      'suggestionRejected': 'Öneri reddedildi',
      'suggestionRejectFailed': 'Öneri reddedilemedi.',
      'photoIngredientsButton': 'Malzeme Fotoğrafını Kontrol Et',
      'photoAnalysisProductName': 'Fotoğraf Analizi',
      'managedProduct': 'Yönetici tarafından doğrulandı',
      'managedProductNoRefresh':
          'Bu ürün bir yönetici tarafından yönetiliyor ve dış kaynaklardan yenilenemez.',
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
      'uploadProductPhoto': 'Foto hochladen',
      'uploadPhotoHint':
          'Helfen Sie anderen, indem Sie ein Foto dieses Produkts beitragen',
      'photoUploaded': 'Foto eingereicht — vielen Dank!',
      'photoUploadFailed':
          'Foto konnte nicht hochgeladen werden. Bitte erneut versuchen.',
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
      'transparentRulesAvailable':
          '{count} Regeln verfügbar (keine Daten zu prüfen)',
      'contributeIngredients': 'Zutaten hinzufügen',
      'contributeIngredientsHint':
          'Keine Zutatendaten gefunden. Helfen Sie der Community, indem Sie die Zutaten von der Verpackung eingeben.',
      'ingredientTextLabel': 'Zutatentext',
      'ingredientTextHint':
          'Geben Sie die Zutatenliste von der Verpackung ein oder fügen Sie sie ein',
      'ingredientSubmitted':
          'Danke! Zutaten eingereicht — das Produkt wird erneut analysiert.',
      'ingredientSubmitFailed':
          'Zutaten konnten nicht eingereicht werden. Bitte erneut versuchen.',
      'improveOnOpenFoodFacts': 'Auf OpenFoodFacts bearbeiten',
      'improveOnOpenFoodFactsHint':
          'Verbessern Sie dieses Produkt für alle, indem Sie Daten direkt auf OpenFoodFacts hinzufügen.',
      'extractingIngredients': 'Zutaten werden aus dem Bild gelesen…',
      'ocrFailed':
          'Zutaten konnten nicht aus dem Bild gelesen werden. Sie können sie unten manuell eingeben.',
      'ocrSuccess': 'Zutaten extrahiert — bitte vor dem Absenden überprüfen.',
      'productImages': 'Produktbilder',
      'extractFromExistingImage': 'Aus Galerie auswählen',
      'takePhotoOfIngredients': 'Foto der Zutaten aufnehmen',
      'cameraError':
          'Kamera konnte nicht geöffnet werden. Bitte Kameraberechtigungen prüfen.',
      'noIngredientsImageHint':
          'Kein Zutatenbild für dieses Produkt verfügbar. Bitte fotografieren Sie die Zutatenliste auf der Verpackung.',
      'ocrNoIngredientsFound':
          'In den verfügbaren Bildern wurde keine Zutatenliste gefunden. Bitte fotografieren Sie das Zutatenetikett.',
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
      'nutritionLabel': 'Nährwerte',
      'producerReplyWarningTitle': 'Nicht verifiziert',
      'producerReplyWarning':
          'Jeder kann diese Schaltfläche verwenden — Antworten werden nicht als vom tatsächlichen Hersteller stammend verifiziert. Fahren Sie nur fort, wenn Sie der Hersteller sind.',
      'proceedAnyway': 'Trotzdem fortfahren',
      'deletedFromHistory': 'Aus Verlauf entfernt',
      'undo': 'Rückgängig',
      'explanationClean':
          'Keine Zutaten stimmten mit bekannten tierischen oder alkoholbezogenen Begriffen überein. Dies ist eine automatische Bewertung anhand des Zutatentexts.',
      'explanationSuspiciousOnly':
          'Keine eindeutig verbotenen Zutaten gefunden, aber {ingredients} könnten tierischen Ursprungs sein. Dies ist eine automatische Bewertung anhand des Zutatentexts.',
      'explanationHaram':
          'Dieses Produkt enthält eine oder mehrere Zutaten, die tierischen Ursprungs oder alkoholbezogen sein könnten. Prüfen Sie die markierten Zutaten.',
      'unknown': '? UNBEKANNT',
      'noCert': '⚠️ KEIN ZERTIFIKAT',
      'explanationUnknown':
          'Für dieses Produkt wurden keine Zutatendaten gefunden. Der Halal-Status kann nicht bestimmt werden — bitte prüfen Sie die Verpackung direkt.',
      'explanationNoCert':
          'Dies ist ein tierisches Lebensmittelprodukt ohne geprüfte Halal-Zertifizierung. Eine islamkonforme Schlachtung kann nicht bestätigt werden — prüfen Sie die Verpackung auf ein Halal-Siegel.',
      'nonFood': 'ℹ️ KEIN LEBENSMITTEL',
      'explanationNonFood':
          'Dies ist kein Lebensmittelprodukt. Islamische Ernährungsregeln gelten nicht für dieses Produkt.',
      'about': 'Über',
      'version': 'Version',
      'releaseNotes': 'Versionshinweise',
      'checkForUpdates': 'Nach Updates suchen',
      'upToDate': 'Sie sind auf dem neuesten Stand!',
      'installed': 'Installiert',
      'store': 'Store',
      'privacyPolicy': 'Datenschutzrichtlinie',
      'latest': 'Neueste',
      'updateAvailable': 'Update verfügbar',
      'updateNow': 'Jetzt aktualisieren',
      'reportWrongResult': 'Falsches Ergebnis melden',
      'reportWrongResultTitle': 'Ist dieses Ergebnis falsch?',
      'reportWrongResultSubtitle':
          'Sagen Sie uns, was es sein sollte. '
          'Wir erstellen einen Fehlerbericht und beheben ihn.',
      'currentResultLabel': 'Aktuelles Ergebnis',
      'expectedResultLabel': 'Was sollte es sein?',
      'optionalNote': 'Optionale Notiz (z. B. warum Sie das denken)',
      'reportSubmitted': 'Fehlerbericht eingereicht — danke!',
      'reportFailed':
          'Bericht konnte nicht gesendet werden. Später erneut versuchen.',
      'reportResultHalal': 'Halal',
      'reportResultHaram': 'Nicht Halal',
      'reportResultNonFood': 'Kein Lebensmittel',
      'reportResultUnknown': 'Unbekannt',
      'myNote': 'Meine Notiz',
      'noteHint': 'z. B. Hersteller nach E471 fragen, später prüfen...',
      'noteSaved': 'Notiz gespeichert',
      'checkLater': 'Später prüfen',
      'flaggedOnly': 'Nur markierte',
      'allScans': 'Alle Scans',
      'deepAnalysis': 'Detailanalyse',
      'analyse': 'Analysieren',
      'perIngredientAiAnalysis':
          'KI-Analyse pro Zutat auf islamischer Grundlage',
      'communityDiscussion': 'Community-Diskussion',
      'noDiscussionsYet': 'Noch keine Diskussionen — starten Sie eine',
      'analysisQueued':
          'Analyse in Warteschlange — Ergebnisse erscheinen nach Admin-Prüfung.',
      'analysisFailed': 'Analyse fehlgeschlagen — bitte erneut versuchen.',
      'signInToDiscuss': 'Anmelden, um eine Diskussion zu starten.',
      'signInToChallenge': 'Anmelden, um eine Anfechtung einzureichen.',
      'discussions': 'Diskussionen',
      'challenges': 'Anfechtungen',
      'newDiscussion': 'Neue Diskussion',
      'halalDirectory': 'Halal-Verzeichnis',
      'signInFailed': 'Anmeldung fehlgeschlagen. Bitte erneut versuchen.',
      'newVersionAvailable': 'Eine neue Version ist verfügbar',
      'signIn': 'Anmelden',
      'signOut': 'Abmelden',
      'signedIn': 'Angemeldet',
      'adminPanel': 'Admin-Panel',
      'noDiscussionsHint': 'Seien Sie der Erste!',
      'analysisTab': 'Analyse',
      'rulesEngineTab': 'Regelwerk',
      'photosTab': 'Fotos',
      'ingredientsTab': 'Zutaten',
      'customRulesTab': 'Benutzerdefiniert',
      'builtInRulesTab': 'Eingebaut',
      'suggestionsTab': 'Vorschläge',
      'searchRules': 'Regeln suchen...',
      'noCustomRules': 'Noch keine benutzerdefinierten Regeln',
      'noMatchingRules': 'Keine passenden Regeln gefunden',
      'noSuggestions': 'Keine ausstehenden Vorschläge',
      'addRule': 'Regel hinzufügen',
      'editRule': 'Regel bearbeiten',
      'delete': 'Löschen',
      'deleteRuleTitle': 'Regel löschen',
      'deleteRuleConfirm': '"{keyword}" aus den Regeln entfernen?',
      'ruleCreated': 'Regel erfolgreich erstellt',
      'ruleCreateFailed':
          'Regel konnte nicht erstellt werden. Bitte erneut versuchen.',
      'ruleUpdated': 'Regel erfolgreich aktualisiert',
      'ruleUpdateFailed':
          'Regel konnte nicht aktualisiert werden. Bitte erneut versuchen.',
      'ruleDeleted': 'Regel gelöscht',
      'ruleDeleteFailed':
          'Regel konnte nicht gelöscht werden. Bitte erneut versuchen.',
      'createRule': 'Regel erstellen',
      'updateRule': 'Regel aktualisieren',
      'variantsLabel': 'Varianten',
      'variantsHint': 'z. B. Schmalz, domuz yağı, saindoux',
      'variantsHelperText':
          'Kommagetrennte mehrsprachige Varianten für den Abgleich',
      'builtInBadge': 'eingebaut',
      'approve': 'Genehmigen',
      'reject': 'Ablehnen',
      'suggestionApproved': 'Vorschlag genehmigt und als Regel hinzugefügt',
      'suggestionApproveFailed': 'Vorschlag konnte nicht genehmigt werden.',
      'suggestionRejected': 'Vorschlag abgelehnt',
      'suggestionRejectFailed': 'Vorschlag konnte nicht abgelehnt werden.',
      'photoIngredientsButton': 'Zutatenfoto prüfen',
      'photoAnalysisProductName': 'Fotoanalyse',
      'managedProduct': 'Vom Admin verifiziert',
      'managedProductNoRefresh':
          'Dieses Produkt wird von einem Admin verwaltet und kann nicht aus externen Quellen aktualisiert werden.',
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
  String get uploadProductPhoto => _translate('uploadProductPhoto');
  String get uploadPhotoHint => _translate('uploadPhotoHint');
  String get photoUploaded => _translate('photoUploaded');
  String get photoUploadFailed => _translate('photoUploadFailed');
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
  String get transparentSummary => _translate('transparentSummary');
  String get transparentResult => _translate('transparentResult');
  String get transparentIngredientsChecked =>
      _translate('transparentIngredientsChecked');
  String get transparentRulesChecked => _translate('transparentRulesChecked');
  String transparentRulesAvailable(int count) => _translate(
    'transparentRulesAvailable',
  ).replaceAll('{count}', count.toString());
  String get transparentFlagged => _translate('transparentFlagged');
  String get transparentSuspicious => _translate('transparentSuspicious');
  String get transparentNoMatches => _translate('transparentNoMatches');
  String get transparentNoIngredients => _translate('transparentNoIngredients');
  String get transparentExplanation => _translate('transparentExplanation');
  String get viewAllCheckedKeywords => _translate('viewAllCheckedKeywords');
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
  String get nutritionLabel => _translate('nutritionLabel');
  String get producerReplyWarningTitle =>
      _translate('producerReplyWarningTitle');
  String get producerReplyWarning => _translate('producerReplyWarning');
  String get proceedAnyway => _translate('proceedAnyway');
  String get deletedFromHistory => _translate('deletedFromHistory');
  String get undo => _translate('undo');
  String get explanationClean => _translate('explanationClean');
  String explanationSuspiciousOnlyWith(List<String> ingredients) => _translate(
    'explanationSuspiciousOnly',
  ).replaceAll('{ingredients}', ingredients.join(', '));
  String get explanationHaram => _translate('explanationHaram');
  String get unknown => _translate('unknown');
  String get noCert => _translate('noCert');
  String get explanationUnknown => _translate('explanationUnknown');
  String get explanationNoCert => _translate('explanationNoCert');
  String get nonFood => _translate('nonFood');
  String get explanationNonFood => _translate('explanationNonFood');
  String get about => _translate('about');
  String get version => _translate('version');
  String get releaseNotes => _translate('releaseNotes');
  String get checkForUpdates => _translate('checkForUpdates');
  String get upToDate => _translate('upToDate');
  String get installed => _translate('installed');
  String get store => _translate('store');
  String get privacyPolicy => _translate('privacyPolicy');
  String get latest => _translate('latest');
  String get updateAvailable => _translate('updateAvailable');
  String get updateNow => _translate('updateNow');
  String get reportWrongResult => _translate('reportWrongResult');
  String get reportWrongResultTitle => _translate('reportWrongResultTitle');
  String get reportWrongResultSubtitle =>
      _translate('reportWrongResultSubtitle');
  String get currentResultLabel => _translate('currentResultLabel');
  String get expectedResultLabel => _translate('expectedResultLabel');
  String get optionalNote => _translate('optionalNote');
  String get reportSubmitted => _translate('reportSubmitted');
  String get reportFailed => _translate('reportFailed');
  String get reportResultHalal => _translate('reportResultHalal');
  String get reportResultHaram => _translate('reportResultHaram');
  String get reportResultNonFood => _translate('reportResultNonFood');
  String get reportResultUnknown => _translate('reportResultUnknown');
  String get myNote => _translate('myNote');
  String get noteHint => _translate('noteHint');
  String get noteSaved => _translate('noteSaved');
  String get checkLater => _translate('checkLater');
  String get deepAnalysis => _translate('deepAnalysis');
  String get analyse => _translate('analyse');
  String get perIngredientAiAnalysis => _translate('perIngredientAiAnalysis');
  String get communityDiscussion => _translate('communityDiscussion');
  String get noDiscussionsYet => _translate('noDiscussionsYet');
  String get analysisQueued => _translate('analysisQueued');
  String get analysisFailed => _translate('analysisFailed');
  String get signInToDiscuss => _translate('signInToDiscuss');
  String get signInToChallenge => _translate('signInToChallenge');
  String get discussions => _translate('discussions');
  String get challenges => _translate('challenges');
  String get newDiscussion => _translate('newDiscussion');
  String get halalDirectory => _translate('halalDirectory');
  String get signInFailed => _translate('signInFailed');
  String get newVersionAvailable => _translate('newVersionAvailable');
  String get signIn => _translate('signIn');
  String get signOut => _translate('signOut');
  String get signedIn => _translate('signedIn');
  String get adminPanel => _translate('adminPanel');
  String get noDiscussionsHint => _translate('noDiscussionsHint');
  String get contributeIngredients => _translate('contributeIngredients');
  String get contributeIngredientsHint =>
      _translate('contributeIngredientsHint');
  String get ingredientTextLabel => _translate('ingredientTextLabel');
  String get ingredientTextHint => _translate('ingredientTextHint');
  String get ingredientSubmitted => _translate('ingredientSubmitted');
  String get ingredientSubmitFailed => _translate('ingredientSubmitFailed');
  String get improveOnOpenFoodFacts => _translate('improveOnOpenFoodFacts');
  String get improveOnOpenFoodFactsHint =>
      _translate('improveOnOpenFoodFactsHint');
  String get extractingIngredients => _translate('extractingIngredients');
  String get ocrFailed => _translate('ocrFailed');
  String get ocrSuccess => _translate('ocrSuccess');
  String get productImages => _translate('productImages');
  String get extractFromExistingImage => _translate('extractFromExistingImage');
  String get takePhotoOfIngredients => _translate('takePhotoOfIngredients');
  String get cameraError => _translate('cameraError');
  String get noIngredientsImageHint => _translate('noIngredientsImageHint');
  String get ocrNoIngredientsFound => _translate('ocrNoIngredientsFound');
  String get flaggedOnly => _translate('flaggedOnly');
  String get allScans => _translate('allScans');
  String get analysisTab => _translate('analysisTab');
  String get rulesEngineTab => _translate('rulesEngineTab');
  String get photosTab => _translate('photosTab');
  String get ingredientsTab => _translate('ingredientsTab');
  String get customRulesTab => _translate('customRulesTab');
  String get builtInRulesTab => _translate('builtInRulesTab');
  String get suggestionsTab => _translate('suggestionsTab');
  String get searchRules => _translate('searchRules');
  String get noCustomRules => _translate('noCustomRules');
  String get noMatchingRules => _translate('noMatchingRules');
  String get noSuggestions => _translate('noSuggestions');
  String get addRule => _translate('addRule');
  String get editRule => _translate('editRule');
  String get delete => _translate('delete');
  String get deleteRuleTitle => _translate('deleteRuleTitle');
  String deleteRuleConfirm(String keyword) =>
      _translate('deleteRuleConfirm').replaceAll('{keyword}', keyword);
  String get ruleCreated => _translate('ruleCreated');
  String get ruleCreateFailed => _translate('ruleCreateFailed');
  String get ruleUpdated => _translate('ruleUpdated');
  String get ruleUpdateFailed => _translate('ruleUpdateFailed');
  String get ruleDeleted => _translate('ruleDeleted');
  String get ruleDeleteFailed => _translate('ruleDeleteFailed');
  String get createRule => _translate('createRule');
  String get updateRule => _translate('updateRule');
  String get variantsLabel => _translate('variantsLabel');
  String get variantsHint => _translate('variantsHint');
  String get variantsHelperText => _translate('variantsHelperText');
  String get builtInBadge => _translate('builtInBadge');
  String get approve => _translate('approve');
  String get reject => _translate('reject');
  String get suggestionApproved => _translate('suggestionApproved');
  String get suggestionApproveFailed => _translate('suggestionApproveFailed');
  String get suggestionRejected => _translate('suggestionRejected');
  String get suggestionRejectFailed => _translate('suggestionRejectFailed');
  String get photoIngredientsButton => _translate('photoIngredientsButton');
  String get photoAnalysisProductName => _translate('photoAnalysisProductName');
  String get managedProduct => _translate('managedProduct');
  String get managedProductNoRefresh => _translate('managedProductNoRefresh');

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
