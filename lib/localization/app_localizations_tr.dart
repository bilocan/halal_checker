// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'HalalScan';

  @override
  String get startTitle => 'HalalScan';

  @override
  String get tagline => 'Şeffaf helal, topluluk gücüyle.';

  @override
  String get taglineSubtitle =>
      'Her içerik kontrol edilir ve açıklanır — geri bildirimlerinizle gelişir.';

  @override
  String get newScan => 'Yeni Tara';

  @override
  String get lastResults => 'Son Sonuçlar';

  @override
  String get noRecentResults => 'Henüz kaydedilmiş tarama yok.';

  @override
  String get noRecentResultsHint =>
      'Başlamak için yukarıdaki tarama düğmesine dokunun.';

  @override
  String get scanButton => 'Taramayı Başlat';

  @override
  String get scanAnotherProduct => 'Başka ürün tara';

  @override
  String get manualEntry => 'Barkodu elle gir';

  @override
  String get enterBarcodeManually => 'Barkodu elle gir';

  @override
  String get cancel => 'İptal';

  @override
  String get submit => 'Gönder';

  @override
  String get scanAgain => 'Tekrar Tara';

  @override
  String get readyToScan => 'Tarama için hazır';

  @override
  String get analyzingBarcode => 'Barkod analiz ediliyor...';

  @override
  String get pointCameraAtBarcode =>
      'Kamerayı ürün ambalajındaki barkoda doğrultun';

  @override
  String get barcodeNotSupported =>
      'Barkod algılandı ama format desteklenmiyor. Lütfen manuel girin.';

  @override
  String get pleaseEnterValidBarcode => 'Lütfen geçerli bir barkod girin.';

  @override
  String get productNotFound => 'Ürün bulunamadı';

  @override
  String get noProductImageAvailable => 'Ürün resmi yok';

  @override
  String get uploadProductPhoto => 'Fotoğraf Yükle';

  @override
  String get uploadPhotoHint =>
      'Bu ürünün fotoğrafını ekleyerek diğerlerine yardım edin';

  @override
  String get photoUploaded => 'Fotoğraf gönderildi — teşekkürler!';

  @override
  String get photoUploadFailed =>
      'Fotoğraf yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String get additionalImages => 'Ek Görseller';

  @override
  String get ingredients => 'İçindekiler';

  @override
  String get flaggedIngredients => 'İşaretli İçindekiler';

  @override
  String get mayBeAnimalDerived => 'Hayvansal Kaynaklı Olabilir';

  @override
  String get communityFeedback => 'Topluluk Geri Bildirimi';

  @override
  String get noFeedbackYet => 'Henüz geri bildirim yok. İlk siz olun!';

  @override
  String get provideFeedback => 'Geri Bildirim Ver';

  @override
  String get replyAsProducer => 'Üretici olarak yanıtla';

  @override
  String get producerReply => 'Üretici Yanıtı';

  @override
  String get userFeedback => 'Kullanıcı Geri Bildirimi';

  @override
  String get imageNotAvailable => 'Resim mevcut değil';

  @override
  String get fairTrade => 'Adil Ticaret';

  @override
  String get organic => 'Organik';

  @override
  String get glutenFree => 'Glutensiz';

  @override
  String get vegetarian => 'Vejetaryen';

  @override
  String get vegan => 'Vegan';

  @override
  String get halal => 'HELAL';

  @override
  String get notHalal => 'HARAM';

  @override
  String get lastScanned => 'Son tarama';

  @override
  String get today => 'Bugün';

  @override
  String get yesterday => 'Dün';

  @override
  String daysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String errorFetchingProduct(String error) {
    return 'Ürün alınırken hata: $error';
  }

  @override
  String get productCouldNotBeRefreshed => 'Ürün verisi yenilenemedi';

  @override
  String get thankYouFeedback => 'Geri bildiriminiz için teşekkürler!';

  @override
  String errorSubmittingFeedback(String error) {
    return 'Geri bildirim gönderilirken hata: $error';
  }

  @override
  String get replySubmitted => 'Yanıt başarıyla gönderildi!';

  @override
  String get noResultsSaved => 'Henüz kayıtlı tarama geçmişi yok.';

  @override
  String get language => 'Dil';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Türkçe';

  @override
  String get german => 'Deutsch';

  @override
  String get scanHistoryTitle => 'Son taramalar';

  @override
  String get filterScan => 'Ürünü tara veya barkodu gir';

  @override
  String get openResult => 'Sonucu aç';

  @override
  String get resultTitle => 'Sonuç';

  @override
  String get noIngredientData => 'İçerik bilgisi mevcut değil.';

  @override
  String get foundInIngredients => 'Ürün içeriklerinde bulundu.';

  @override
  String get mayBeAnimalDerivedNote => 'Hayvansal kaynaklı olabilir.';

  @override
  String get couldNotLoadFeedback => 'Geri bildirim yüklenemedi.';

  @override
  String get couldNotSubmitFeedback => 'Geri bildirim gönderilemedi.';

  @override
  String get couldNotSubmitReply => 'Yanıt gönderilemedi.';

  @override
  String get couldNotRefreshProduct => 'Ürün verisi güncellenemedi.';

  @override
  String get attachFiles => 'Dosya Ekle';

  @override
  String get feedbackInputHint => 'Geri bildiriminiz...';

  @override
  String get replyInputHint => 'Yanıtınız...';

  @override
  String get submitReply => 'Yanıtı Gönder';

  @override
  String get refreshTooltip => 'Ürün verisini yenile';

  @override
  String get feedbackDialogHint =>
      'Geri bildiriminizle helal değerlendirmemizi geliştirin.';

  @override
  String get replyDialogHint => 'Bu geri bildirime resmi bir yanıt verin.';

  @override
  String get aiAnalysis => 'Yapay Zeka Analizi';

  @override
  String get keywordAnalysis => 'Anahtar Kelime Analizi';

  @override
  String get analysisTransparency => 'Analiz Şeffaflığı';

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
    return '$count kural mevcut (kontrol edilecek veri yok)';
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
  String get contributeIngredients => 'İçerik Ekle';

  @override
  String get contributeIngredientsHint =>
      'İçerik bilgisi bulunamadı. Ambalajdaki içerikleri ekleyerek topluluğa yardım edin.';

  @override
  String get ingredientTextLabel => 'İçerik metni';

  @override
  String get ingredientTextHint =>
      'Ambalajdaki içerik listesini yazın veya yapıştırın';

  @override
  String get ingredientSubmitted =>
      'Teşekkürler! İçerikler gönderildi — ürün yeniden analiz edilecek.';

  @override
  String get ingredientSubmitFailed =>
      'İçerikler gönderilemedi. Lütfen tekrar deneyin.';

  @override
  String get improveOnOpenFoodFacts => 'OpenFoodFacts\'ta Düzenle';

  @override
  String get improveOnOpenFoodFactsHint =>
      'OpenFoodFacts\'ta veri ekleyerek bu ürünü herkes için geliştirin.';

  @override
  String get extractingIngredients => 'İçerikler görüntüden okunuyor…';

  @override
  String get ocrFailed =>
      'Görüntüden içerik okunamadı. Aşağıya elle yazabilirsiniz.';

  @override
  String get ocrSuccess =>
      'İçerikler çıkarıldı — göndermeden önce gözden geçirin.';

  @override
  String get productImages => 'Ürün görselleri';

  @override
  String get extractFromExistingImage => 'Galeriden seç';

  @override
  String get takePhotoOfIngredients => 'İçerik fotoğrafı çek';

  @override
  String get cameraError =>
      'Kamera açılamadı. Lütfen kamera izinlerini kontrol edin.';

  @override
  String get noIngredientsImageHint =>
      'Bu ürün için içerik görseli mevcut değil. Lütfen ambalajdaki içerik listesinin fotoğrafını çekin.';

  @override
  String get ocrNoIngredientsFound =>
      'Mevcut görsellerde içerik listesi bulunamadı. Lütfen içerik etiketinin fotoğrafını çekin.';

  @override
  String get viewAllCheckedKeywords => 'View all checked keywords';

  @override
  String get haramKeywordsChecked => 'Kontrol Ettiğimiz Haram İçerikler';

  @override
  String get suspiciousKeywordsChecked => 'Kontrol Ettiğimiz Şüpheli İçerikler';

  @override
  String get transparencyNote => 'Listemizde eksik mi? Geri bildirim gönderin!';

  @override
  String get recheck => 'Yeniden Kontrol Et';

  @override
  String get foundNotFlagged =>
      'İçeriklerde bulundu, ancak analiz tarafından işaretlenmedi (örn. yağ alkolü, iz miktarı veya bağlama güvenli kullanım).';

  @override
  String get fattyAlcoholNote =>
      'Bu bir yağ alkolüdür (örn. setil veya stearil alkol) — bitkisel kaynaklı bir emülgatördür. İçki alkolüyle hiçbir ilgisi yoktur ve helaldir.';

  @override
  String get keywords => 'Anahtar Kelimeler';

  @override
  String get haramTab => 'Haram';

  @override
  String get suspiciousTab => 'Şüpheli';

  @override
  String get suggestKeyword => 'Anahtar Kelime Öner';

  @override
  String get suggestKeywordHint =>
      'Bir şeyi atladığımızı mı düşünüyorsunuz? Önerin incelememize gönderin.';

  @override
  String get keywordLabel => 'Anahtar Kelime';

  @override
  String get keywordHint => 'örn. domuz yağı, etanol, karmin';

  @override
  String get keywordRequired => 'Lütfen bir anahtar kelime girin.';

  @override
  String get categoryLabel => 'Kategori';

  @override
  String get haramCategory => 'Haram (kesinlikle yasak)';

  @override
  String get suspiciousCategory => 'Şüpheli (hayvansal kaynaklı olabilir)';

  @override
  String get reasonLabel => 'Sebep';

  @override
  String get reasonHint => 'Bu anahtar kelime neden eklenmeli?';

  @override
  String get reasonRequired => 'Lütfen bir sebep belirtin.';

  @override
  String get suggestionSubmitted =>
      'Teşekkürler! Öneriniz incelenmek üzere gönderildi.';

  @override
  String get suggestionError => 'Öneri gönderilemedi. Lütfen tekrar deneyin.';

  @override
  String get customBadge => 'özel';

  @override
  String get nutritionLabel => 'Beslenme Değerleri';

  @override
  String get producerReplyWarningTitle => 'Doğrulanmamış İşlem';

  @override
  String get producerReplyWarning =>
      'Bu düğmeyi herkes kullanabilir — yanıtların gerçek üreticiden geldiği doğrulanmaz. Yalnızca üreticiyseniz devam edin.';

  @override
  String get proceedAnyway => 'Yine de Devam Et';

  @override
  String get deletedFromHistory => 'Geçmişten silindi';

  @override
  String get undo => 'Geri Al';

  @override
  String get explanationClean =>
      'Bilinen hayvansal kaynaklı veya alkol içerikli anahtar kelimelerle eşleşen içerik bulunamadı. Bu, içerik metnine dayalı otomatik bir değerlendirmedir.';

  @override
  String explanationSuspiciousOnly(String ingredients) {
    return 'Kesinlikle haram içerik bulunamadı, ancak $ingredients hayvansal kaynaklı olabilir. Bu, içerik metnine dayalı otomatik bir değerlendirmedir.';
  }

  @override
  String get explanationHaram =>
      'Bu ürün, hayvansal kaynaklı veya alkol içerikli olabilecek bir veya daha fazla içerik barındırmaktadır. Ayrıntılar için işaretlenen içerikleri inceleyin.';

  @override
  String get unknown => '? BİLİNMİYOR';

  @override
  String get noCert => '⚠️ SERTİFİKA YOK';

  @override
  String get explanationUnknown =>
      'Bu ürün için içerik bilgisi bulunamadı. Helal durumu belirlenemiyor — lütfen ambalajı doğrudan kontrol edin.';

  @override
  String get explanationNoCert =>
      'Bu ürün hayvansal kaynaklı bir gıdadır ancak doğrulanmış bir helal sertifikası bulunmamaktadır. Helal kesim teyit edilemez — ambalajda helal etiketi olup olmadığını kontrol edin.';

  @override
  String get nonFood => 'ℹ️ GIDA DEĞİL';

  @override
  String get explanationNonFood =>
      'Bu bir gıda ürünü değildir. İslami beslenme kuralları bu ürün için geçerli değildir.';

  @override
  String get about => 'Hakkında';

  @override
  String get version => 'Versiyon';

  @override
  String get releaseNotes => 'Sürüm Notları';

  @override
  String get checkForUpdates => 'Güncellemeleri Kontrol Et';

  @override
  String get upToDate => 'Güncel durumdasınız!';

  @override
  String get installed => 'Kurulu';

  @override
  String get store => 'Mağaza';

  @override
  String get privacyPolicy => 'Gizlilik Politikası';

  @override
  String get latest => 'En Son';

  @override
  String get updateAvailable => 'Güncelleme Mevcut';

  @override
  String get updateNow => 'Şimdi Güncelle';

  @override
  String get reportWrongResult => 'Yanlış Sonucu Bildir';

  @override
  String get reportWrongResultTitle => 'Bu sonuç yanlış mı?';

  @override
  String get reportWrongResultSubtitle =>
      'Ne olması gerektiğini söyleyin. Bir hata raporu oluşturup düzelteceğiz.';

  @override
  String get currentResultLabel => 'Mevcut sonuç';

  @override
  String get expectedResultLabel => 'Ne olmalı?';

  @override
  String get optionalNote => 'İsteğe bağlı not (örn. neden öyle düşündüğünüz)';

  @override
  String get reportSubmitted => 'Hata raporu gönderildi — teşekkürler!';

  @override
  String get reportFailed => 'Rapor gönderilemedi. Daha sonra tekrar deneyin.';

  @override
  String get reportResultHalal => 'Helal';

  @override
  String get reportResultHaram => 'Haram';

  @override
  String get reportResultNonFood => 'Gıda Değil';

  @override
  String get reportResultUnknown => 'Bilinmiyor';

  @override
  String get myNote => 'Notum';

  @override
  String get noteHint => 'örn. üreticiye E471 sor, sonra kontrol et...';

  @override
  String get noteSaved => 'Not kaydedildi';

  @override
  String get checkLater => 'Sonra kontrol et';

  @override
  String get flaggedOnly => 'Yalnızca işaretliler';

  @override
  String get allScans => 'Tüm taramalar';

  @override
  String get deepAnalysis => 'Detaylı Analiz';

  @override
  String get analyse => 'Analiz Et';

  @override
  String get perIngredientAiAnalysis =>
      'İslami temelli içerik bazlı yapay zeka analizi';

  @override
  String get communityDiscussion => 'Topluluk Tartışması';

  @override
  String get noDiscussionsYet => 'Henüz tartışma yok — ilk siz başlatın';

  @override
  String get analysisQueued =>
      'Analiz sıraya alındı — sonuçlar yönetici incelemesinden sonra görünecektir.';

  @override
  String get analysisFailed => 'Analiz başarısız oldu — lütfen tekrar deneyin.';

  @override
  String get signInToDiscuss => 'Tartışma başlatmak için giriş yapın.';

  @override
  String get signInToChallenge => 'İtiraz göndermek için giriş yapın.';

  @override
  String get discussions => 'Tartışmalar';

  @override
  String get challenges => 'İtirazlar';

  @override
  String get newDiscussion => 'Yeni Tartışma';

  @override
  String get halalDirectory => 'Helal Rehberi';

  @override
  String get signInFailed => 'Giriş başarısız oldu. Lütfen tekrar deneyin.';

  @override
  String get newVersionAvailable => 'Yeni bir sürüm mevcut';

  @override
  String get signIn => 'Giriş Yap';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get signedIn => 'Giriş yapıldı';

  @override
  String get adminPanel => 'Yönetici paneli';

  @override
  String get noDiscussionsHint => 'İlk tartışmayı siz başlatın!';

  @override
  String get analysisTab => 'Analiz';

  @override
  String get rulesEngineTab => 'Kural Motoru';

  @override
  String get photosTab => 'Fotoğraflar';

  @override
  String get ingredientsTab => 'Malzemeler';

  @override
  String get customRulesTab => 'Özel';

  @override
  String get builtInRulesTab => 'Yerleşik';

  @override
  String get suggestionsTab => 'Öneriler';

  @override
  String get searchRules => 'Kural ara...';

  @override
  String get noCustomRules => 'Henüz özel kural yok';

  @override
  String get noMatchingRules => 'Eşleşen kural bulunamadı';

  @override
  String get noSuggestions => 'Bekleyen öneri yok';

  @override
  String get addRule => 'Kural Ekle';

  @override
  String get editRule => 'Kuralı Düzenle';

  @override
  String get delete => 'Sil';

  @override
  String get deleteRuleTitle => 'Kuralı Sil';

  @override
  String deleteRuleConfirm(String keyword) {
    return '\"$keyword\" kuralını silmek istiyor musunuz?';
  }

  @override
  String get ruleCreated => 'Kural başarıyla oluşturuldu';

  @override
  String get ruleCreateFailed => 'Kural oluşturulamadı. Lütfen tekrar deneyin.';

  @override
  String get ruleUpdated => 'Kural başarıyla güncellendi';

  @override
  String get ruleUpdateFailed => 'Kural güncellenemedi. Lütfen tekrar deneyin.';

  @override
  String get ruleDeleted => 'Kural silindi';

  @override
  String get ruleDeleteFailed => 'Kural silinemedi. Lütfen tekrar deneyin.';

  @override
  String get createRule => 'Kural Oluştur';

  @override
  String get updateRule => 'Kuralı Güncelle';

  @override
  String get variantsLabel => 'Varyantlar';

  @override
  String get variantsHint => 'örn. schmalz, domuz yağı, saindoux';

  @override
  String get variantsHelperText =>
      'Eşleştirme için virgülle ayrılmış çok dilli varyantlar';

  @override
  String get suggestVariantsLabel => 'Diğer diller (isteğe bağlı)';

  @override
  String get suggestVariantsHint => 'örn. schwein, domuz, porc';

  @override
  String get suggestVariantsHelperText =>
      'Aynı bileşen için diğer dillerdeki yazılışlar, virgülle ayrılmış';

  @override
  String get translationsLabel => 'Dile göre çeviriler';

  @override
  String get translationsHint => 'de: schwein\ntr: domuz';

  @override
  String get translationsHelperText =>
      'Satır başına bir tane: dil kodu ve terim (de, tr, fr, es, it, nl, sr, hu, cs). Eşleştirme ve arayüz için.';

  @override
  String get mergeKeywordTitle => 'Mevcut kurala birleştirilsin mi?';

  @override
  String mergeKeywordMessage(String alias, String canonical) {
    return '\"$alias\", mevcut \"$canonical\" kuralıyla eşleşiyor. Yinelenen kural yerine bu kurala birleştirilsin mi?';
  }

  @override
  String get mergeKeywordConfirm => 'Birleştir';

  @override
  String get approveAsNewRule => 'Yeni kural oluştur';

  @override
  String get suggestionMerged => 'Öneri mevcut kurala birleştirildi';

  @override
  String get builtInBadge => 'yerleşik';

  @override
  String get approve => 'Onayla';

  @override
  String get reject => 'Reddet';

  @override
  String get suggestionApproved => 'Öneri onaylandı ve kural olarak eklendi';

  @override
  String get suggestionApproveFailed => 'Öneri onaylanamadı.';

  @override
  String get suggestionRejected => 'Öneri reddedildi';

  @override
  String get suggestionRejectFailed => 'Öneri reddedilemedi.';

  @override
  String get photoIngredientsButton => 'Malzeme Fotoğrafını Kontrol Et';

  @override
  String get photoAnalysisProductName => 'Fotoğraf Analizi';

  @override
  String get managedProduct => 'Yönetici tarafından doğrulandı';

  @override
  String get managedProductNoRefresh =>
      'Bu ürün bir yönetici tarafından yönetiliyor ve dış kaynaklardan yenilenemez.';

  @override
  String get deleteAccount => 'Hesabı Sil';

  @override
  String get deleteAccountTitle => 'Hesap Silinsin mi?';

  @override
  String get deleteAccountConfirm =>
      'Bu işlem hesabınızı ve tüm ilişkili verileri kalıcı olarak silecektir. Bu işlem geri alınamaz.';

  @override
  String get deleteAccountSuccess => 'Hesabınız silindi.';

  @override
  String get deleteAccountFailed => 'Hesap silinemedi. Lütfen tekrar deneyin.';

  @override
  String get reportWrongIngredient => 'Yanlış İçerik Bildir';

  @override
  String get reportWrongIngredientTitle => 'Yanlış içerik bildir';

  @override
  String get reportWrongIngredientSubtitle =>
      'Yanlış listelendiğini düşündüğünüz içerikleri seçin.';

  @override
  String get reportWrongIngredientExplanation => 'Açıklama (isteğe bağlı)';

  @override
  String get reportWrongIngredientExplanationHint =>
      'örn. bu içerik bitkisel kaynaklıdır...';

  @override
  String get reportWrongIngredientNoSelection =>
      'Lütfen en az bir içerik seçin.';

  @override
  String get reportWrongIngredientSubmitted =>
      'Teşekkürler! Raporunuz gönderildi.';

  @override
  String get reportWrongIngredientFailed =>
      'Rapor gönderilemedi. Lütfen tekrar deneyin.';

  @override
  String get reportsTab => 'Raporlar';

  @override
  String get reportedIngredient => 'Yanlış olarak bildirildi';

  @override
  String get noReports => 'Bekleyen rapor yok';

  @override
  String get openProduct => 'Ürünü aç';

  @override
  String get resolveReport => 'Çözüldü';

  @override
  String get dismissReport => 'Reddet';
}
