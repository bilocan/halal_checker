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
  String get home => 'Ana Sayfa';

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
  String get missingProductFlowTitle => 'Ürünü ekle';

  @override
  String get missingProductFlowIntro =>
      'Bu barkod henüz veritabanlarımızda yok. Ambalajın net fotoğraflarını gönderin — ekibimiz bunları kullanarak daha sonra ürünü herkes için işleyecek.';

  @override
  String get missingProductFlowHelpHint =>
      'Yüklemeden önce boyut ve keskinliği kontrol ediyoruz. Çok küçük veya bulanık görseller işlenemez.';

  @override
  String get missingProductStepBarcodeTitle => 'Adım 1 — Barkod';

  @override
  String get missingProductStepBarcodeSubtitle =>
      'Fotoğraflarınız şu kod ile ilişkilendirilecek:';

  @override
  String get missingProductStepFrontTitle => 'Adım 2 — Ürünün önü';

  @override
  String get missingProductStepFrontSubtitle =>
      'Marka, ürün adı ve barkod görünürse bu yüzünde düz bir fotoğraf çekin.';

  @override
  String get missingProductStepIngredientsTitle => 'Adım 3 — İçindekiler';

  @override
  String get missingProductStepIngredientsSubtitle =>
      'Sadece içindekiler bölümü. Yansıma olmasın, yazı okunaklı olsun.';

  @override
  String get missingProductExampleLayout => 'İyi bir kadraj böyle görünür';

  @override
  String get missingProductPickCamera => 'Fotoğraf çek';

  @override
  String get missingProductPickGallery => 'Galeriden seç';

  @override
  String get missingProductRetake => 'Fotoğrafı değiştir';

  @override
  String get missingProductContinue => 'Devam';

  @override
  String get missingProductBack => 'Geri';

  @override
  String get missingProductSubmit => 'Fotoğrafları gönder';

  @override
  String get missingProductSubmitting => 'Yükleniyor…';

  @override
  String get missingProductThankYou =>
      'Teşekkürler. Fotoğraflarınız inceleme sırasına alındı.';

  @override
  String get missingProductUploadFailed =>
      'Yükleme başarısız oldu. İnternetinizi kontrol edip yeniden deneyin.';

  @override
  String missingProductPhotoTooLarge(int maxMb) {
    return 'Dosya çok büyük — en fazla $maxMb MB.';
  }

  @override
  String get missingProductPhotoUnreadable =>
      'Bu dosya görüntü olarak açılamıyor.';

  @override
  String get missingProductPhotoTooSmall =>
      'Çözünürlük yetersiz — etiketi kadrajın büyük kısmını dolduracak kadar yaklaşın.';

  @override
  String get missingProductNeedBoth =>
      'Göndermeden önce her iki fotoğrafı ekleyin.';

  @override
  String get missingProductOpenFlow => 'Ambalaj fotoğrafları gönder';

  @override
  String get missingProductOneOfTwoFailed =>
      'Bir fotoğraf yüklenemedi. Bu ekranı yeniden açıp tekrar deneyebilirsiniz.';

  @override
  String get missingProductReviewHint =>
      'Önizlemeleri kontrol edin; net ve okunaklıysa gönder’e dokunun.';

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
  String get halal => 'Sorun bulunamadı';

  @override
  String get notHalal => 'Haram içerik tespit edildi';

  @override
  String get suspiciousVerdict => 'Şüpheli içerik tespit edildi';

  @override
  String get suspiciousResult => 'Şüpheli içerik tespit edildi';

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
  String get scanHistoryLoadFailed => 'Tarama geçmişi yüklenemedi.';

  @override
  String get scanHistoryRetry => 'Yeniden dene';

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
  String get flaggedLabels => 'İşaretli Etiketler';

  @override
  String get foundInLabels => 'Ürün etiketlerinde bulundu.';

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
  String get transparentSummary => 'Karar özeti';

  @override
  String get transparentResult => 'Sonuç';

  @override
  String get transparentIngredientsChecked => 'Kontrol edilen içerikler';

  @override
  String get transparentRulesChecked => 'Kontrol edilen kurallar';

  @override
  String transparentRulesAvailable(int count) {
    return '$count kural mevcut (kontrol edilecek veri yok)';
  }

  @override
  String get transparentFlagged => 'İşaretlendi (Haram)';

  @override
  String get transparentSuspicious => 'Doğrulama gerekiyor';

  @override
  String get transparentNoMatches => 'Kural eşleşmesi bulunamadı';

  @override
  String get transparentNoIngredients =>
      'Kontrol edilecek içerik metni bulunamadı';

  @override
  String get transparentExplanation => 'Açıklama';

  @override
  String get transparentMatchSource => 'Eşleşme kaynağı';

  @override
  String get transparentMatchSourcePrimary => 'Orijinal içerik etiketi';

  @override
  String get transparentMatchSourceOffTaxonomy =>
      'Open Food Facts içerik taksonomisi (EN)';

  @override
  String get transparentMatchSourceUnanalyzable =>
      'Analiz edilemedi — desteklenmeyen dil';

  @override
  String get transparentMatchSourceNone => 'Anahtar kelime eşleşmesi yok';

  @override
  String transparentMatchSourceOffLang(String lang) {
    return '$lang çevirisi (Open Food Facts)';
  }

  @override
  String get transparentMatchOrigins => 'Eşleşme kaynakları';

  @override
  String get transparentDisplayLanguage => 'Etiket dili';

  @override
  String get transparentLabelsChecked => 'Kontrol edilen etiketler';

  @override
  String get transparentFlaggedLabels => 'İşaretlenen etiketler';

  @override
  String get transparentSuspiciousLabels => 'Şüpheli etiketler';

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
  String explanationHaramWithIngredients(String ingredients) {
    return 'Bu ürün izin verilmeyen içerik(ler) içeriyor: $ingredients. Ayrıntılar için aşağıdaki işaretli içerikleri inceleyin.';
  }

  @override
  String explanationHaramAdditives(String additives) {
    return 'Bu ürünün izin verilmeyen katkı maddeleri içeriyor: $additives. Ayrıntılar için aşağıdaki işaretli öğeleri inceleyin.';
  }

  @override
  String explanationHaramCategory(String category) {
    return 'Bu ürün izin verilmeyen bir kategoriye ait: $category.';
  }

  @override
  String get explanationHalalInherentCategory =>
      'Bu ürün doğası gereği helal bir kategoridedir (ör. su, tuz). Zararlı içerik beklenmez.';

  @override
  String get explanationUnanalyzableLanguage =>
      'İçerikler analiz edemediğimiz bir dilde. Helal durumu belirlenemiyor — lütfen ambalajı doğrudan kontrol edin.';

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
  String get changeUsername => 'Görünen adı değiştir';

  @override
  String get firstLoginUsernameTitle => 'Topluluk adınız';

  @override
  String get publicDisplayNameHint =>
      'Bu ad tartışma ve yorumlarda görünür. Profilden istediğiniz zaman değiştirebilirsiniz.';

  @override
  String get usernameSaved => 'Görünen ad güncellendi.';

  @override
  String get usernameInvalid =>
      '2–40 karakter: harf, rakam, boşluk ve . _ - \'';

  @override
  String get usernameSaveFailed =>
      'Görünen ad kaydedilemedi. Lütfen tekrar deneyin.';

  @override
  String get keepThisName => 'Bu adı kullan';

  @override
  String get save => 'Kaydet';

  @override
  String get signInDisplayNameHint =>
      'Girişteki adınız, profilden değiştirene kadar topluluk tartışmalarında görünebilir.';

  @override
  String profileRole(String role) {
    return 'Rol: $role';
  }

  @override
  String get roleUser => 'Üye';

  @override
  String get roleModerator => 'Moderatör';

  @override
  String get roleScholar => 'Alim';

  @override
  String get roleAdmin => 'Yönetici';

  @override
  String get roleSuperadmin => 'Süper yönetici';

  @override
  String get adminPanel => 'Yönetici paneli';

  @override
  String get noDiscussionsHint => 'İlk tartışmayı siz başlatın!';

  @override
  String get approvalsTab => 'Onaylar';

  @override
  String get analysisTab => 'Analiz';

  @override
  String get rulesEngineTab => 'Kural Motoru';

  @override
  String get photosTab => 'Fotoğraflar';

  @override
  String get ingredientsTab => 'Malzemeler';

  @override
  String get ingredientContributionsTab => 'İçerik Katkıları';

  @override
  String get aiIngredientsLookupTab => 'Yapay Zeka İçerik Araması';

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

  @override
  String get signInRequired => 'Giriş gerekli';

  @override
  String get signInRequiredMessage =>
      'Geri bildirim veya öneri göndermek için giriş yapmalısınız.';

  @override
  String get signInWithGoogle => 'Google ile giriş yap';

  @override
  String get batchImport => 'Toplu İçe Aktarma';

  @override
  String get adminUpdateFailed =>
      'Güncellenemedi — Supabase günlüklerini kontrol edin';

  @override
  String get adminAiRequestsLoadFailed =>
      'Yapay zeka istekleri yüklenemedi — bağlantıyı kontrol edin';

  @override
  String get aiRequestSubmitFailed => 'Yapay zeka isteği gönderilemedi.';

  @override
  String get aiRequestSubmitted =>
      'Yapay zeka isteği gönderildi — yönetici incelemesi bekleniyor.';

  @override
  String get aiRequestAlreadyPending =>
      'Bu ürün için zaten bekleyen bir yapay zeka isteği var.';

  @override
  String labelCopied(String label) {
    return '$label kopyalandı';
  }

  @override
  String get replacePhoto => 'Değiştir';

  @override
  String get batchImportAccessDenied =>
      'Erişim reddedildi: yalnızca süper yönetici';

  @override
  String get systemSettingsTab => 'Ayarlar';

  @override
  String get systemSettingsTitle => 'Sistem ayarları';

  @override
  String get systemSettingsSubtitle =>
      'Yalnızca süper yönetici. Sonraki ürün aramalarında tüm kullanıcılar için geçerlidir.';

  @override
  String get geminiLookupEmptyOffTitle => 'Otomatik Gemini içerik araması';

  @override
  String get geminiLookupEmptyOffDescription =>
      'Open Food Facts içerik vermezse Gemini ile web araması (sunucuda GEMINI_API_KEY gerekir).';

  @override
  String get geminiLookupEmptyOffEnabled =>
      'Otomatik Gemini içerik araması açık';

  @override
  String get geminiLookupEmptyOffDisabled =>
      'Otomatik Gemini içerik araması kapalı';

  @override
  String get systemSettingsLoadFailed => 'Sistem ayarları yüklenemedi';

  @override
  String get systemSettingsSaveFailed =>
      'Ayar kaydedilemedi (yalnızca süper yönetici)';

  @override
  String get batchImportNoBarcodes => 'Dosyada geçerli barkod bulunamadı';

  @override
  String get signInToComment => 'Yorum yapmak için giriş yapın.';

  @override
  String get discussionFallbackTitle => 'Tartışma';

  @override
  String get noCommentsYet => 'Henüz yorum yok. İlk siz yazın!';

  @override
  String replyingTo(String username) {
    return '$username kullanıcısına yanıt';
  }

  @override
  String get writeCommentHint => 'Yorum yazın…';

  @override
  String get reply => 'Yanıtla';

  @override
  String get failedStartDiscussion =>
      'Tartışma başlatılamadı. Lütfen tekrar deneyin.';

  @override
  String get startDiscussionTitle => 'Tartışma Başlat';

  @override
  String get topicOptionalLabel => 'Konu (isteğe bağlı)';

  @override
  String get topicOptionalHint => 'örn. Jelatin kaynağı belirtilmiş mi?';

  @override
  String get startDiscussionButton => 'Tartışmayı Başlat';

  @override
  String get linkedToChallenge => 'İtiraza bağlı';

  @override
  String get locked => 'Kilitli';

  @override
  String get anonymous => 'Anonim';

  @override
  String get noChallengesYet => 'Henüz içerik itirazı yok.';

  @override
  String get noChallengesHint =>
      'Kararı itiraz etmek için Derin Analiz\'de bir içeriğe dokunun.';

  @override
  String challengeBy(String username) {
    return '$username tarafından';
  }

  @override
  String get commentDeleted => '[silindi]';

  @override
  String get couldNotPostComment =>
      'Yorumunuz gönderilemedi. Lütfen tekrar deneyin.';

  @override
  String get timeJustNow => 'az önce';

  @override
  String timeMinutesAgo(int count) {
    return '$count dk önce';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count sa önce';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String get aiApprovalHint =>
      'Gemini/Claude ile yapay zeka içerik aramasını başlatmak için onaylayın. Ürün otomatik güncellenir.';

  @override
  String get refetchAiIngredients => 'Yapay zeka içeriklerini yeniden al';

  @override
  String get approveAndFetch => 'Onayla ve al';

  @override
  String get photoReplacement => 'değiştirme';

  @override
  String get photoCurrentLabel => 'Mevcut';

  @override
  String get photoNewLabel => 'Yeni';

  @override
  String get noPendingPhotoSubmissions => 'Bekleyen fotoğraf gönderimi yok';

  @override
  String get noPendingIngredientContributions => 'Bekleyen içerik katkısı yok';

  @override
  String get filterPending => 'Bekleyen';

  @override
  String get filterApproved => 'Onaylandı';

  @override
  String get filterAll => 'Tümü';

  @override
  String get filterDone => 'Tamamlandı';

  @override
  String get noPendingAiRequests => 'Bekleyen yapay zeka içerik isteği yok';

  @override
  String get noApprovedAiRequests => 'Onaylanmış yapay zeka içerik isteği yok';

  @override
  String get adminBatchRequestFailed =>
      'Toplu istek başarısız — Supabase günlüklerini kontrol edin';

  @override
  String adminBatchDoneSummary(int done, int skipped) {
    return 'Tamam: $done, atlandı: $skipped';
  }

  @override
  String adminBatchDoneWithErrors(int done, int skipped, int errors) {
    return 'Tamam: $done, atlandı: $skipped, başarısız: $errors — günlüklere bakın';
  }

  @override
  String get challengeVerdictWas => 'önce';

  @override
  String get challengeVerdictShouldBe => 'olmalı';

  @override
  String get noAnalysesYet => 'Henüz analiz yok';

  @override
  String get filterNothingHere => 'Burada bir şey yok';

  @override
  String get runAll => 'Tümünü çalıştır';

  @override
  String get runningLabel => 'Çalışıyor…';

  @override
  String runSelectedCount(int count) {
    return '$count çalıştır';
  }

  @override
  String get selectAllPending => 'Bekleyenlerin tümünü seç';

  @override
  String get deselectAllPending => 'Tümünün seçimini kaldır';

  @override
  String get unknownProduct => 'Bilinmeyen ürün';

  @override
  String adminAiRefetching(String barcode) {
    return '$barcode için yapay zeka içerikleri yeniden alınıyor…';
  }

  @override
  String get close => 'Kapat';

  @override
  String get barcodeLabel => 'Barkod';

  @override
  String barcodeWithValue(String barcode) {
    return 'Barkod: $barcode';
  }

  @override
  String localDbDebugTitle(String barcode) {
    return 'Yerel DB — $barcode';
  }

  @override
  String get localDbDebugTooltip => 'Yerel DB hata ayıklama';

  @override
  String get debugCacheSection => '── SharedPreferences önbelleği ──';

  @override
  String get debugRemoteDbSection => '── Uzak DB (products tablosu) ──';

  @override
  String get debugEmpty => '(boş)';

  @override
  String get debugNotFound => '(bulunamadı)';

  @override
  String get debugCacheCleared => 'Önbellek temizlendi';

  @override
  String get debugClearCache => 'Önbelleği temizle';

  @override
  String get showOriginal => 'Orijinal';

  @override
  String get copyIngredientsTooltip => 'İçerikleri kopyala';

  @override
  String get findIngredientsViaAi => 'Yapay zeka ile içerik bul';

  @override
  String get aiLookupPendingHint =>
      'Yapay zeka araması istendi — bir yönetici kısa süre içinde inceleyip onaylayacak.';

  @override
  String get aiLookupRejectedHint =>
      'Yapay zeka isteği bir yönetici tarafından reddedildi.';

  @override
  String get aiLookupPromptHint =>
      'Yapay zekadan bu ürünün içerik listesini webde aramasını isteyin.';

  @override
  String get aiWebIngredientLookupAlreadyRanTitle =>
      'Yapay zeka içerik araması zaten yapıldı';

  @override
  String get aiWebIngredientLookupAlreadyRanHint =>
      'Gemini ile web araması bu ürün adı için zaten yapıldı; kullanılabilir bir içerik listesi bulunamadı. Yine de içerik ekleyebilir veya Open Food Facts verisini geliştirebilirsiniz.';

  @override
  String get requestViaAi => 'Yapay zeka ile iste';

  @override
  String get requestAgain => 'Tekrar iste';

  @override
  String showAllIngredients(int count) {
    return 'Tüm $count içeriği göster';
  }

  @override
  String get showLessIngredients => 'Daha az göster';

  @override
  String get allergens => 'Alerjenler';

  @override
  String get additives => 'Katkı maddeleri';

  @override
  String get mayContain => 'İz içerebilir';

  @override
  String get findings => 'Bulgular';

  @override
  String get seeFullDetails => 'Tüm detayları gör';

  @override
  String get fullDetailsTitle => 'Tam Detaylar';
}
