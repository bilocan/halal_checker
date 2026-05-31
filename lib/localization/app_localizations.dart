import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HalalScan'**
  String get appTitle;

  /// No description provided for @startTitle.
  ///
  /// In en, this message translates to:
  /// **'HalalScan'**
  String get startTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Transparent halal, powered by community.'**
  String get tagline;

  /// No description provided for @taglineSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every ingredient checked and explained — shaped by your feedback.'**
  String get taglineSubtitle;

  /// No description provided for @newScan.
  ///
  /// In en, this message translates to:
  /// **'New Scan'**
  String get newScan;

  /// No description provided for @lastResults.
  ///
  /// In en, this message translates to:
  /// **'Last Results'**
  String get lastResults;

  /// No description provided for @noRecentResults.
  ///
  /// In en, this message translates to:
  /// **'No recent scans saved yet.'**
  String get noRecentResults;

  /// No description provided for @noRecentResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the scan button above to get started.'**
  String get noRecentResultsHint;

  /// No description provided for @scanButton.
  ///
  /// In en, this message translates to:
  /// **'Start Scan'**
  String get scanButton;

  /// No description provided for @scanAnotherProduct.
  ///
  /// In en, this message translates to:
  /// **'Scan Another Product'**
  String get scanAnotherProduct;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Enter barcode manually'**
  String get manualEntry;

  /// No description provided for @enterBarcodeManually.
  ///
  /// In en, this message translates to:
  /// **'Enter barcode manually'**
  String get enterBarcodeManually;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @scanAgain.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scanAgain;

  /// No description provided for @readyToScan.
  ///
  /// In en, this message translates to:
  /// **'Ready to scan'**
  String get readyToScan;

  /// No description provided for @analyzingBarcode.
  ///
  /// In en, this message translates to:
  /// **'Analyzing barcode...'**
  String get analyzingBarcode;

  /// No description provided for @pointCameraAtBarcode.
  ///
  /// In en, this message translates to:
  /// **'Point camera at barcode on product packaging'**
  String get pointCameraAtBarcode;

  /// No description provided for @barcodeNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Barcode detected but format not supported. Try manual entry.'**
  String get barcodeNotSupported;

  /// No description provided for @pleaseEnterValidBarcode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid barcode.'**
  String get pleaseEnterValidBarcode;

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found'**
  String get productNotFound;

  /// No description provided for @missingProductFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Add this product'**
  String get missingProductFlowTitle;

  /// No description provided for @missingProductFlowIntro.
  ///
  /// In en, this message translates to:
  /// **'This barcode is not in our databases yet. Submit clear pack photos — our team uses them so everyone can analyse this item later.'**
  String get missingProductFlowIntro;

  /// No description provided for @missingProductFlowHelpHint.
  ///
  /// In en, this message translates to:
  /// **'We check photo size and sharpness before upload. Blurry or very small images cannot be processed.'**
  String get missingProductFlowHelpHint;

  /// No description provided for @missingProductStepBarcodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 1 — Barcode'**
  String get missingProductStepBarcodeTitle;

  /// No description provided for @missingProductStepBarcodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your photos will be linked to:'**
  String get missingProductStepBarcodeSubtitle;

  /// No description provided for @missingProductStepFrontTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 2 — Front of pack'**
  String get missingProductStepFrontTitle;

  /// No description provided for @missingProductStepFrontSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Straight photo showing brand, product name, and barcode if it is printed on this side.'**
  String get missingProductStepFrontSubtitle;

  /// No description provided for @missingProductStepIngredientsTitle.
  ///
  /// In en, this message translates to:
  /// **'Step 3 — Ingredients list'**
  String get missingProductStepIngredientsTitle;

  /// No description provided for @missingProductStepIngredientsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only the ingredient list panel. Avoid glare and keep text readable.'**
  String get missingProductStepIngredientsSubtitle;

  /// No description provided for @missingProductExampleLayout.
  ///
  /// In en, this message translates to:
  /// **'What a good shot looks like'**
  String get missingProductExampleLayout;

  /// No description provided for @missingProductPickCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get missingProductPickCamera;

  /// No description provided for @missingProductPickGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get missingProductPickGallery;

  /// No description provided for @missingProductRetake.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get missingProductRetake;

  /// No description provided for @missingProductContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get missingProductContinue;

  /// No description provided for @missingProductBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get missingProductBack;

  /// No description provided for @missingProductSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit photos'**
  String get missingProductSubmit;

  /// No description provided for @missingProductSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Uploading…'**
  String get missingProductSubmitting;

  /// No description provided for @missingProductThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you. Your photos are in the review queue.'**
  String get missingProductThankYou;

  /// No description provided for @missingProductUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Check your connection and try again.'**
  String get missingProductUploadFailed;

  /// No description provided for @missingProductPhotoTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large — maximum {maxMb} MB.'**
  String missingProductPhotoTooLarge(int maxMb);

  /// No description provided for @missingProductPhotoUnreadable.
  ///
  /// In en, this message translates to:
  /// **'This file cannot be opened as an image.'**
  String get missingProductPhotoUnreadable;

  /// No description provided for @missingProductPhotoTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Photo is too low resolution — move closer so the label fills the frame.'**
  String get missingProductPhotoTooSmall;

  /// No description provided for @missingProductNeedBoth.
  ///
  /// In en, this message translates to:
  /// **'Add both photos before submitting.'**
  String get missingProductNeedBoth;

  /// No description provided for @missingProductOpenFlow.
  ///
  /// In en, this message translates to:
  /// **'Submit pack photos'**
  String get missingProductOpenFlow;

  /// No description provided for @missingProductOneOfTwoFailed.
  ///
  /// In en, this message translates to:
  /// **'One photo did not upload. You can reopen this screen and try again.'**
  String get missingProductOneOfTwoFailed;

  /// No description provided for @missingProductReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Check that both previews are sharp and readable, then tap submit.'**
  String get missingProductReviewHint;

  /// No description provided for @noProductImageAvailable.
  ///
  /// In en, this message translates to:
  /// **'No product image available'**
  String get noProductImageAvailable;

  /// No description provided for @uploadProductPhoto.
  ///
  /// In en, this message translates to:
  /// **'Upload Photo'**
  String get uploadProductPhoto;

  /// No description provided for @uploadPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Help others by contributing a photo of this product'**
  String get uploadPhotoHint;

  /// No description provided for @photoUploaded.
  ///
  /// In en, this message translates to:
  /// **'Photo submitted — thank you!'**
  String get photoUploaded;

  /// No description provided for @photoUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload photo. Please try again.'**
  String get photoUploadFailed;

  /// No description provided for @additionalImages.
  ///
  /// In en, this message translates to:
  /// **'Additional Images'**
  String get additionalImages;

  /// No description provided for @ingredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredients;

  /// No description provided for @flaggedIngredients.
  ///
  /// In en, this message translates to:
  /// **'Flagged Ingredients'**
  String get flaggedIngredients;

  /// No description provided for @mayBeAnimalDerived.
  ///
  /// In en, this message translates to:
  /// **'May Be Animal-Derived'**
  String get mayBeAnimalDerived;

  /// No description provided for @communityFeedback.
  ///
  /// In en, this message translates to:
  /// **'Community Feedback'**
  String get communityFeedback;

  /// No description provided for @noFeedbackYet.
  ///
  /// In en, this message translates to:
  /// **'No feedback yet. Be the first to share your thoughts!'**
  String get noFeedbackYet;

  /// No description provided for @provideFeedback.
  ///
  /// In en, this message translates to:
  /// **'Provide Feedback'**
  String get provideFeedback;

  /// No description provided for @replyAsProducer.
  ///
  /// In en, this message translates to:
  /// **'Reply as Producer'**
  String get replyAsProducer;

  /// No description provided for @producerReply.
  ///
  /// In en, this message translates to:
  /// **'Producer Reply'**
  String get producerReply;

  /// No description provided for @userFeedback.
  ///
  /// In en, this message translates to:
  /// **'User Feedback'**
  String get userFeedback;

  /// No description provided for @imageNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Image not available'**
  String get imageNotAvailable;

  /// No description provided for @fairTrade.
  ///
  /// In en, this message translates to:
  /// **'Fair Trade'**
  String get fairTrade;

  /// No description provided for @organic.
  ///
  /// In en, this message translates to:
  /// **'Organic'**
  String get organic;

  /// No description provided for @glutenFree.
  ///
  /// In en, this message translates to:
  /// **'Gluten Free'**
  String get glutenFree;

  /// No description provided for @vegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get vegetarian;

  /// No description provided for @vegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get vegan;

  /// No description provided for @halal.
  ///
  /// In en, this message translates to:
  /// **'HALAL'**
  String get halal;

  /// No description provided for @notHalal.
  ///
  /// In en, this message translates to:
  /// **'HARAM'**
  String get notHalal;

  /// No description provided for @suspiciousVerdict.
  ///
  /// In en, this message translates to:
  /// **'⚠️ VERIFY'**
  String get suspiciousVerdict;

  /// No description provided for @suspiciousResult.
  ///
  /// In en, this message translates to:
  /// **'VERIFY'**
  String get suspiciousResult;

  /// No description provided for @lastScanned.
  ///
  /// In en, this message translates to:
  /// **'Last scanned'**
  String get lastScanned;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @errorFetchingProduct.
  ///
  /// In en, this message translates to:
  /// **'Error fetching product: {error}'**
  String errorFetchingProduct(String error);

  /// No description provided for @productCouldNotBeRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh product data'**
  String get productCouldNotBeRefreshed;

  /// No description provided for @thankYouFeedback.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get thankYouFeedback;

  /// No description provided for @errorSubmittingFeedback.
  ///
  /// In en, this message translates to:
  /// **'Error submitting feedback: {error}'**
  String errorSubmittingFeedback(String error);

  /// No description provided for @replySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Reply submitted successfully!'**
  String get replySubmitted;

  /// No description provided for @noResultsSaved.
  ///
  /// In en, this message translates to:
  /// **'No saved scan history yet.'**
  String get noResultsSaved;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @scanHistoryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load scan history.'**
  String get scanHistoryLoadFailed;

  /// No description provided for @scanHistoryRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get scanHistoryRetry;

  /// No description provided for @scanHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent scans'**
  String get scanHistoryTitle;

  /// No description provided for @filterScan.
  ///
  /// In en, this message translates to:
  /// **'Scan product or enter barcode'**
  String get filterScan;

  /// No description provided for @openResult.
  ///
  /// In en, this message translates to:
  /// **'Open result'**
  String get openResult;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get resultTitle;

  /// No description provided for @noIngredientData.
  ///
  /// In en, this message translates to:
  /// **'No ingredient data available.'**
  String get noIngredientData;

  /// No description provided for @foundInIngredients.
  ///
  /// In en, this message translates to:
  /// **'Found in product ingredients.'**
  String get foundInIngredients;

  /// No description provided for @flaggedLabels.
  ///
  /// In en, this message translates to:
  /// **'Flagged Labels'**
  String get flaggedLabels;

  /// No description provided for @foundInLabels.
  ///
  /// In en, this message translates to:
  /// **'Found in product labels.'**
  String get foundInLabels;

  /// No description provided for @mayBeAnimalDerivedNote.
  ///
  /// In en, this message translates to:
  /// **'May be animal-derived.'**
  String get mayBeAnimalDerivedNote;

  /// No description provided for @couldNotLoadFeedback.
  ///
  /// In en, this message translates to:
  /// **'Could not load feedback.'**
  String get couldNotLoadFeedback;

  /// No description provided for @couldNotSubmitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Could not submit feedback.'**
  String get couldNotSubmitFeedback;

  /// No description provided for @couldNotSubmitReply.
  ///
  /// In en, this message translates to:
  /// **'Could not submit reply.'**
  String get couldNotSubmitReply;

  /// No description provided for @couldNotRefreshProduct.
  ///
  /// In en, this message translates to:
  /// **'Could not refresh product data.'**
  String get couldNotRefreshProduct;

  /// No description provided for @attachFiles.
  ///
  /// In en, this message translates to:
  /// **'Attach Files'**
  String get attachFiles;

  /// No description provided for @feedbackInputHint.
  ///
  /// In en, this message translates to:
  /// **'Your feedback...'**
  String get feedbackInputHint;

  /// No description provided for @replyInputHint.
  ///
  /// In en, this message translates to:
  /// **'Your reply...'**
  String get replyInputHint;

  /// No description provided for @submitReply.
  ///
  /// In en, this message translates to:
  /// **'Submit Reply'**
  String get submitReply;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh product data'**
  String get refreshTooltip;

  /// No description provided for @feedbackDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Help improve our halal assessment by providing feedback about this product.'**
  String get feedbackDialogHint;

  /// No description provided for @replyDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Provide an official response to this feedback.'**
  String get replyDialogHint;

  /// No description provided for @aiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis'**
  String get aiAnalysis;

  /// No description provided for @keywordAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Keyword Analysis'**
  String get keywordAnalysis;

  /// No description provided for @analysisTransparency.
  ///
  /// In en, this message translates to:
  /// **'Analysis Transparency'**
  String get analysisTransparency;

  /// No description provided for @transparentSummary.
  ///
  /// In en, this message translates to:
  /// **'Decision summary'**
  String get transparentSummary;

  /// No description provided for @transparentResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get transparentResult;

  /// No description provided for @transparentIngredientsChecked.
  ///
  /// In en, this message translates to:
  /// **'Ingredients checked'**
  String get transparentIngredientsChecked;

  /// No description provided for @transparentRulesChecked.
  ///
  /// In en, this message translates to:
  /// **'Rules checked'**
  String get transparentRulesChecked;

  /// No description provided for @transparentRulesAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} rules available (nothing to check)'**
  String transparentRulesAvailable(int count);

  /// No description provided for @transparentFlagged.
  ///
  /// In en, this message translates to:
  /// **'Flagged'**
  String get transparentFlagged;

  /// No description provided for @transparentSuspicious.
  ///
  /// In en, this message translates to:
  /// **'Needs verification'**
  String get transparentSuspicious;

  /// No description provided for @transparentNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No rule matches found'**
  String get transparentNoMatches;

  /// No description provided for @transparentNoIngredients.
  ///
  /// In en, this message translates to:
  /// **'No ingredient text was available to check'**
  String get transparentNoIngredients;

  /// No description provided for @transparentExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get transparentExplanation;

  /// No description provided for @transparentMatchSource.
  ///
  /// In en, this message translates to:
  /// **'Matched via'**
  String get transparentMatchSource;

  /// No description provided for @transparentMatchSourcePrimary.
  ///
  /// In en, this message translates to:
  /// **'Original ingredient label'**
  String get transparentMatchSourcePrimary;

  /// No description provided for @transparentMatchSourceOffTaxonomy.
  ///
  /// In en, this message translates to:
  /// **'Open Food Facts ingredient taxonomy (EN)'**
  String get transparentMatchSourceOffTaxonomy;

  /// No description provided for @transparentMatchSourceUnanalyzable.
  ///
  /// In en, this message translates to:
  /// **'Could not analyze — unsupported language'**
  String get transparentMatchSourceUnanalyzable;

  /// No description provided for @transparentMatchSourceNone.
  ///
  /// In en, this message translates to:
  /// **'No keyword rule matches'**
  String get transparentMatchSourceNone;

  /// No description provided for @transparentMatchSourceOffLang.
  ///
  /// In en, this message translates to:
  /// **'{lang} translation (Open Food Facts)'**
  String transparentMatchSourceOffLang(String lang);

  /// No description provided for @transparentMatchOrigins.
  ///
  /// In en, this message translates to:
  /// **'Match origins'**
  String get transparentMatchOrigins;

  /// No description provided for @transparentDisplayLanguage.
  ///
  /// In en, this message translates to:
  /// **'Label language'**
  String get transparentDisplayLanguage;

  /// No description provided for @contributeIngredients.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredients'**
  String get contributeIngredients;

  /// No description provided for @contributeIngredientsHint.
  ///
  /// In en, this message translates to:
  /// **'No ingredient data found. Help the community by adding the ingredients from the packaging.'**
  String get contributeIngredientsHint;

  /// No description provided for @ingredientTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Ingredient text'**
  String get ingredientTextLabel;

  /// No description provided for @ingredientTextHint.
  ///
  /// In en, this message translates to:
  /// **'Type or paste the ingredient list from the packaging'**
  String get ingredientTextHint;

  /// No description provided for @ingredientSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Ingredients submitted — the product will be re-analysed.'**
  String get ingredientSubmitted;

  /// No description provided for @ingredientSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit ingredients. Please try again.'**
  String get ingredientSubmitFailed;

  /// No description provided for @improveOnOpenFoodFacts.
  ///
  /// In en, this message translates to:
  /// **'Edit on OpenFoodFacts'**
  String get improveOnOpenFoodFacts;

  /// No description provided for @improveOnOpenFoodFactsHint.
  ///
  /// In en, this message translates to:
  /// **'Help improve this product for everyone by adding data directly on OpenFoodFacts.'**
  String get improveOnOpenFoodFactsHint;

  /// No description provided for @extractingIngredients.
  ///
  /// In en, this message translates to:
  /// **'Reading ingredients from image…'**
  String get extractingIngredients;

  /// No description provided for @ocrFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read ingredients from the image. You can type them manually below.'**
  String get ocrFailed;

  /// No description provided for @ocrSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ingredients extracted — please review before submitting.'**
  String get ocrSuccess;

  /// No description provided for @productImages.
  ///
  /// In en, this message translates to:
  /// **'Product images'**
  String get productImages;

  /// No description provided for @extractFromExistingImage.
  ///
  /// In en, this message translates to:
  /// **'Pick from gallery'**
  String get extractFromExistingImage;

  /// No description provided for @takePhotoOfIngredients.
  ///
  /// In en, this message translates to:
  /// **'Take photo of ingredients'**
  String get takePhotoOfIngredients;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Could not open camera. Please check camera permissions.'**
  String get cameraError;

  /// No description provided for @noIngredientsImageHint.
  ///
  /// In en, this message translates to:
  /// **'No ingredients image available for this product. Please take a photo of the ingredient list on the packaging.'**
  String get noIngredientsImageHint;

  /// No description provided for @ocrNoIngredientsFound.
  ///
  /// In en, this message translates to:
  /// **'No ingredient list found in the available images. Please take a photo of the ingredient label instead.'**
  String get ocrNoIngredientsFound;

  /// No description provided for @viewAllCheckedKeywords.
  ///
  /// In en, this message translates to:
  /// **'View all checked keywords'**
  String get viewAllCheckedKeywords;

  /// No description provided for @haramKeywordsChecked.
  ///
  /// In en, this message translates to:
  /// **'Haram Ingredients We Check'**
  String get haramKeywordsChecked;

  /// No description provided for @suspiciousKeywordsChecked.
  ///
  /// In en, this message translates to:
  /// **'Suspicious Ingredients We Check'**
  String get suspiciousKeywordsChecked;

  /// No description provided for @transparencyNote.
  ///
  /// In en, this message translates to:
  /// **'Something missing from our list? Let us know via feedback!'**
  String get transparencyNote;

  /// No description provided for @recheck.
  ///
  /// In en, this message translates to:
  /// **'Recheck'**
  String get recheck;

  /// No description provided for @foundNotFlagged.
  ///
  /// In en, this message translates to:
  /// **'Found in ingredients, but not flagged by the analysis (e.g. fatty alcohol, trace amount, or context-safe use).'**
  String get foundNotFlagged;

  /// No description provided for @fattyAlcoholNote.
  ///
  /// In en, this message translates to:
  /// **'This is a fatty alcohol (e.g. cetyl or stearyl alcohol) — a plant-derived emulsifier. It has no relation to drinking alcohol and is halal.'**
  String get fattyAlcoholNote;

  /// No description provided for @keywords.
  ///
  /// In en, this message translates to:
  /// **'Keywords'**
  String get keywords;

  /// No description provided for @haramTab.
  ///
  /// In en, this message translates to:
  /// **'Haram'**
  String get haramTab;

  /// No description provided for @suspiciousTab.
  ///
  /// In en, this message translates to:
  /// **'Suspicious'**
  String get suspiciousTab;

  /// No description provided for @suggestKeyword.
  ///
  /// In en, this message translates to:
  /// **'Suggest a Keyword'**
  String get suggestKeyword;

  /// No description provided for @suggestKeywordHint.
  ///
  /// In en, this message translates to:
  /// **'Think we\'re missing something? Suggest a keyword and we\'ll review it.'**
  String get suggestKeywordHint;

  /// No description provided for @keywordLabel.
  ///
  /// In en, this message translates to:
  /// **'Keyword'**
  String get keywordLabel;

  /// No description provided for @keywordHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. lard, ethanol, cochineal'**
  String get keywordHint;

  /// No description provided for @keywordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a keyword.'**
  String get keywordRequired;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @haramCategory.
  ///
  /// In en, this message translates to:
  /// **'Haram (definitively not permissible)'**
  String get haramCategory;

  /// No description provided for @suspiciousCategory.
  ///
  /// In en, this message translates to:
  /// **'Suspicious (may be animal-derived)'**
  String get suspiciousCategory;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// No description provided for @reasonHint.
  ///
  /// In en, this message translates to:
  /// **'Why should this keyword be added?'**
  String get reasonHint;

  /// No description provided for @reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason.'**
  String get reasonRequired;

  /// No description provided for @suggestionSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your suggestion has been submitted for review.'**
  String get suggestionSubmitted;

  /// No description provided for @suggestionError.
  ///
  /// In en, this message translates to:
  /// **'Could not submit suggestion. Please try again.'**
  String get suggestionError;

  /// No description provided for @customBadge.
  ///
  /// In en, this message translates to:
  /// **'custom'**
  String get customBadge;

  /// No description provided for @nutritionLabel.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutritionLabel;

  /// No description provided for @producerReplyWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Unverified Action'**
  String get producerReplyWarningTitle;

  /// No description provided for @producerReplyWarning.
  ///
  /// In en, this message translates to:
  /// **'Anyone can post using this button — replies are not verified as coming from the actual manufacturer. Proceed only if you are the producer.'**
  String get producerReplyWarning;

  /// No description provided for @proceedAnyway.
  ///
  /// In en, this message translates to:
  /// **'Proceed Anyway'**
  String get proceedAnyway;

  /// No description provided for @deletedFromHistory.
  ///
  /// In en, this message translates to:
  /// **'Removed from history'**
  String get deletedFromHistory;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @explanationClean.
  ///
  /// In en, this message translates to:
  /// **'No ingredients matched known animal-derived or alcohol-related keywords. This is an automated assessment based on ingredient text.'**
  String get explanationClean;

  /// No description provided for @explanationSuspiciousOnly.
  ///
  /// In en, this message translates to:
  /// **'No definitely haram ingredients found, but {ingredients} may be animal-derived. This is an automated assessment based on ingredient text.'**
  String explanationSuspiciousOnly(String ingredients);

  /// No description provided for @explanationHaram.
  ///
  /// In en, this message translates to:
  /// **'This product contains one or more ingredients that may be animal-derived or alcohol-related. Review the flagged ingredients below for details.'**
  String get explanationHaram;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'? UNKNOWN'**
  String get unknown;

  /// No description provided for @noCert.
  ///
  /// In en, this message translates to:
  /// **'⚠️ NO CERT'**
  String get noCert;

  /// No description provided for @explanationUnknown.
  ///
  /// In en, this message translates to:
  /// **'No ingredient data was found for this product. Halal status cannot be determined — check the packaging directly.'**
  String get explanationUnknown;

  /// No description provided for @explanationNoCert.
  ///
  /// In en, this message translates to:
  /// **'This is an animal-derived food product without a verified halal certification. Halal slaughter cannot be confirmed — check the packaging for a halal label.'**
  String get explanationNoCert;

  /// No description provided for @nonFood.
  ///
  /// In en, this message translates to:
  /// **'ℹ️ NOT FOOD'**
  String get nonFood;

  /// No description provided for @explanationNonFood.
  ///
  /// In en, this message translates to:
  /// **'This is a non-food product. Islamic dietary rules do not apply.'**
  String get explanationNonFood;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @releaseNotes.
  ///
  /// In en, this message translates to:
  /// **'Release Notes'**
  String get releaseNotes;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkForUpdates;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date!'**
  String get upToDate;

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @latest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @reportWrongResult.
  ///
  /// In en, this message translates to:
  /// **'Report Wrong Result'**
  String get reportWrongResult;

  /// No description provided for @reportWrongResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Is this result wrong?'**
  String get reportWrongResultTitle;

  /// No description provided for @reportWrongResultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what it should be. We\'ll create a bug report and fix it.'**
  String get reportWrongResultSubtitle;

  /// No description provided for @currentResultLabel.
  ///
  /// In en, this message translates to:
  /// **'Current result'**
  String get currentResultLabel;

  /// No description provided for @expectedResultLabel.
  ///
  /// In en, this message translates to:
  /// **'What should it be?'**
  String get expectedResultLabel;

  /// No description provided for @optionalNote.
  ///
  /// In en, this message translates to:
  /// **'Optional note (e.g. why you think so)'**
  String get optionalNote;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Bug report submitted — thank you!'**
  String get reportSubmitted;

  /// No description provided for @reportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit report. Try again later.'**
  String get reportFailed;

  /// No description provided for @reportResultHalal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get reportResultHalal;

  /// No description provided for @reportResultHaram.
  ///
  /// In en, this message translates to:
  /// **'Not Halal'**
  String get reportResultHaram;

  /// No description provided for @reportResultNonFood.
  ///
  /// In en, this message translates to:
  /// **'Non-Food'**
  String get reportResultNonFood;

  /// No description provided for @reportResultUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get reportResultUnknown;

  /// No description provided for @myNote.
  ///
  /// In en, this message translates to:
  /// **'My Note'**
  String get myNote;

  /// No description provided for @noteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ask producer about E471, check later...'**
  String get noteHint;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get noteSaved;

  /// No description provided for @checkLater.
  ///
  /// In en, this message translates to:
  /// **'Check later'**
  String get checkLater;

  /// No description provided for @flaggedOnly.
  ///
  /// In en, this message translates to:
  /// **'Flagged only'**
  String get flaggedOnly;

  /// No description provided for @allScans.
  ///
  /// In en, this message translates to:
  /// **'All scans'**
  String get allScans;

  /// No description provided for @deepAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Deep Analysis'**
  String get deepAnalysis;

  /// No description provided for @analyse.
  ///
  /// In en, this message translates to:
  /// **'Analyse'**
  String get analyse;

  /// No description provided for @perIngredientAiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Per-ingredient AI analysis with Islamic basis'**
  String get perIngredientAiAnalysis;

  /// No description provided for @communityDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Community Discussion'**
  String get communityDiscussion;

  /// No description provided for @noDiscussionsYet.
  ///
  /// In en, this message translates to:
  /// **'No discussions yet — start one'**
  String get noDiscussionsYet;

  /// No description provided for @analysisQueued.
  ///
  /// In en, this message translates to:
  /// **'Analysis queued — results will appear after admin review.'**
  String get analysisQueued;

  /// No description provided for @analysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Analysis failed — please try again.'**
  String get analysisFailed;

  /// No description provided for @signInToDiscuss.
  ///
  /// In en, this message translates to:
  /// **'Sign in to start a discussion.'**
  String get signInToDiscuss;

  /// No description provided for @signInToChallenge.
  ///
  /// In en, this message translates to:
  /// **'Sign in to submit a challenge.'**
  String get signInToChallenge;

  /// No description provided for @discussions.
  ///
  /// In en, this message translates to:
  /// **'Discussions'**
  String get discussions;

  /// No description provided for @challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// No description provided for @newDiscussion.
  ///
  /// In en, this message translates to:
  /// **'New Discussion'**
  String get newDiscussion;

  /// No description provided for @halalDirectory.
  ///
  /// In en, this message translates to:
  /// **'Halal Directory'**
  String get halalDirectory;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get signInFailed;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version is available'**
  String get newVersionAvailable;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedIn;

  /// No description provided for @changeUsername.
  ///
  /// In en, this message translates to:
  /// **'Change display name'**
  String get changeUsername;

  /// No description provided for @firstLoginUsernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Your community name'**
  String get firstLoginUsernameTitle;

  /// No description provided for @publicDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'This name is shown on discussions and comments. You can change it anytime in your profile.'**
  String get publicDisplayNameHint;

  /// No description provided for @usernameSaved.
  ///
  /// In en, this message translates to:
  /// **'Display name updated.'**
  String get usernameSaved;

  /// No description provided for @usernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 2–40 characters: letters, numbers, spaces, and . _ - \''**
  String get usernameInvalid;

  /// No description provided for @usernameSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save display name. Please try again.'**
  String get usernameSaveFailed;

  /// No description provided for @keepThisName.
  ///
  /// In en, this message translates to:
  /// **'Keep this name'**
  String get keepThisName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @signInDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name from sign-in may appear in community discussions until you change it in your profile.'**
  String get signInDisplayNameHint;

  /// No description provided for @profileRole.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String profileRole(String role);

  /// No description provided for @roleUser.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleUser;

  /// No description provided for @roleModerator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get roleModerator;

  /// No description provided for @roleScholar.
  ///
  /// In en, this message translates to:
  /// **'Scholar'**
  String get roleScholar;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleSuperadmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get roleSuperadmin;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin panel'**
  String get adminPanel;

  /// No description provided for @noDiscussionsHint.
  ///
  /// In en, this message translates to:
  /// **'Be the first to start one!'**
  String get noDiscussionsHint;

  /// No description provided for @approvalsTab.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvalsTab;

  /// No description provided for @analysisTab.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysisTab;

  /// No description provided for @rulesEngineTab.
  ///
  /// In en, this message translates to:
  /// **'Rules Engine'**
  String get rulesEngineTab;

  /// No description provided for @photosTab.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photosTab;

  /// No description provided for @ingredientsTab.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientsTab;

  /// No description provided for @ingredientContributionsTab.
  ///
  /// In en, this message translates to:
  /// **'Ingredient Contributions'**
  String get ingredientContributionsTab;

  /// No description provided for @aiIngredientsLookupTab.
  ///
  /// In en, this message translates to:
  /// **'AI Ingredients Lookup'**
  String get aiIngredientsLookupTab;

  /// No description provided for @customRulesTab.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customRulesTab;

  /// No description provided for @builtInRulesTab.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get builtInRulesTab;

  /// No description provided for @suggestionsTab.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestionsTab;

  /// No description provided for @searchRules.
  ///
  /// In en, this message translates to:
  /// **'Search rules...'**
  String get searchRules;

  /// No description provided for @noCustomRules.
  ///
  /// In en, this message translates to:
  /// **'No custom rules yet'**
  String get noCustomRules;

  /// No description provided for @noMatchingRules.
  ///
  /// In en, this message translates to:
  /// **'No matching rules found'**
  String get noMatchingRules;

  /// No description provided for @noSuggestions.
  ///
  /// In en, this message translates to:
  /// **'No pending suggestions'**
  String get noSuggestions;

  /// No description provided for @addRule.
  ///
  /// In en, this message translates to:
  /// **'Add Rule'**
  String get addRule;

  /// No description provided for @editRule.
  ///
  /// In en, this message translates to:
  /// **'Edit Rule'**
  String get editRule;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteRuleTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Rule'**
  String get deleteRuleTitle;

  /// No description provided for @deleteRuleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{keyword}\" from the rules?'**
  String deleteRuleConfirm(String keyword);

  /// No description provided for @ruleCreated.
  ///
  /// In en, this message translates to:
  /// **'Rule created successfully'**
  String get ruleCreated;

  /// No description provided for @ruleCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create rule. Please try again.'**
  String get ruleCreateFailed;

  /// No description provided for @ruleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Rule updated successfully'**
  String get ruleUpdated;

  /// No description provided for @ruleUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update rule. Please try again.'**
  String get ruleUpdateFailed;

  /// No description provided for @ruleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Rule deleted'**
  String get ruleDeleted;

  /// No description provided for @ruleDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete rule. Please try again.'**
  String get ruleDeleteFailed;

  /// No description provided for @createRule.
  ///
  /// In en, this message translates to:
  /// **'Create Rule'**
  String get createRule;

  /// No description provided for @updateRule.
  ///
  /// In en, this message translates to:
  /// **'Update Rule'**
  String get updateRule;

  /// No description provided for @variantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Variants'**
  String get variantsLabel;

  /// No description provided for @variantsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. schmalz, domuz yağı, saindoux'**
  String get variantsHint;

  /// No description provided for @variantsHelperText.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated multilingual variants for matching'**
  String get variantsHelperText;

  /// No description provided for @suggestVariantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Other languages (optional)'**
  String get suggestVariantsLabel;

  /// No description provided for @suggestVariantsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. schwein, domuz, porc'**
  String get suggestVariantsHint;

  /// No description provided for @suggestVariantsHelperText.
  ///
  /// In en, this message translates to:
  /// **'Comma-separated spellings in other languages for the same ingredient'**
  String get suggestVariantsHelperText;

  /// No description provided for @translationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Translations by locale'**
  String get translationsLabel;

  /// No description provided for @translationsHint.
  ///
  /// In en, this message translates to:
  /// **'de: schwein\ntr: domuz'**
  String get translationsHint;

  /// No description provided for @translationsHelperText.
  ///
  /// In en, this message translates to:
  /// **'One per line: locale code and term (de, tr, fr, es, it, nl, sr, hu, cs). Used for matching and UI labels.'**
  String get translationsHelperText;

  /// No description provided for @mergeKeywordTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge with existing rule?'**
  String get mergeKeywordTitle;

  /// No description provided for @mergeKeywordMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{alias}\" matches the existing rule \"{canonical}\". Merge aliases into that rule instead of creating a duplicate?'**
  String mergeKeywordMessage(String alias, String canonical);

  /// No description provided for @mergeKeywordConfirm.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get mergeKeywordConfirm;

  /// No description provided for @approveAsNewRule.
  ///
  /// In en, this message translates to:
  /// **'Create new rule'**
  String get approveAsNewRule;

  /// No description provided for @suggestionMerged.
  ///
  /// In en, this message translates to:
  /// **'Suggestion merged into existing rule'**
  String get suggestionMerged;

  /// No description provided for @builtInBadge.
  ///
  /// In en, this message translates to:
  /// **'built-in'**
  String get builtInBadge;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @suggestionApproved.
  ///
  /// In en, this message translates to:
  /// **'Suggestion approved and added as a rule'**
  String get suggestionApproved;

  /// No description provided for @suggestionApproveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not approve suggestion.'**
  String get suggestionApproveFailed;

  /// No description provided for @suggestionRejected.
  ///
  /// In en, this message translates to:
  /// **'Suggestion rejected'**
  String get suggestionRejected;

  /// No description provided for @suggestionRejectFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reject suggestion.'**
  String get suggestionRejectFailed;

  /// No description provided for @photoIngredientsButton.
  ///
  /// In en, this message translates to:
  /// **'Check Ingredients Photo'**
  String get photoIngredientsButton;

  /// No description provided for @photoAnalysisProductName.
  ///
  /// In en, this message translates to:
  /// **'Photo Analysis'**
  String get photoAnalysisProductName;

  /// No description provided for @managedProduct.
  ///
  /// In en, this message translates to:
  /// **'Verified by admin'**
  String get managedProduct;

  /// No description provided for @managedProductNoRefresh.
  ///
  /// In en, this message translates to:
  /// **'This product is managed by an admin and cannot be refreshed from external sources.'**
  String get managedProductNoRefresh;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all associated data. This action cannot be undone.'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get deleteAccountSuccess;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account. Please try again.'**
  String get deleteAccountFailed;

  /// No description provided for @reportWrongIngredient.
  ///
  /// In en, this message translates to:
  /// **'Report Wrong Ingredient'**
  String get reportWrongIngredient;

  /// No description provided for @reportWrongIngredientTitle.
  ///
  /// In en, this message translates to:
  /// **'Report wrong ingredient'**
  String get reportWrongIngredientTitle;

  /// No description provided for @reportWrongIngredientSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the ingredients you believe are incorrectly listed.'**
  String get reportWrongIngredientSubtitle;

  /// No description provided for @reportWrongIngredientExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation (optional)'**
  String get reportWrongIngredientExplanation;

  /// No description provided for @reportWrongIngredientExplanationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. this ingredient is plant-based...'**
  String get reportWrongIngredientExplanationHint;

  /// No description provided for @reportWrongIngredientNoSelection.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one ingredient.'**
  String get reportWrongIngredientNoSelection;

  /// No description provided for @reportWrongIngredientSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your report has been submitted.'**
  String get reportWrongIngredientSubmitted;

  /// No description provided for @reportWrongIngredientFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit report. Please try again.'**
  String get reportWrongIngredientFailed;

  /// No description provided for @reportsTab.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reportsTab;

  /// No description provided for @reportedIngredient.
  ///
  /// In en, this message translates to:
  /// **'Reported as wrong'**
  String get reportedIngredient;

  /// No description provided for @noReports.
  ///
  /// In en, this message translates to:
  /// **'No pending reports'**
  String get noReports;

  /// No description provided for @openProduct.
  ///
  /// In en, this message translates to:
  /// **'Open product'**
  String get openProduct;

  /// No description provided for @resolveReport.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolveReport;

  /// No description provided for @dismissReport.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissReport;

  /// No description provided for @signInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in required'**
  String get signInRequired;

  /// No description provided for @signInRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'You need to be signed in to submit feedback or suggestions.'**
  String get signInRequiredMessage;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @batchImport.
  ///
  /// In en, this message translates to:
  /// **'Batch Import'**
  String get batchImport;

  /// No description provided for @adminUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update — check Supabase logs'**
  String get adminUpdateFailed;

  /// No description provided for @adminAiRequestsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load AI requests — check connection'**
  String get adminAiRequestsLoadFailed;

  /// No description provided for @aiRequestSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit AI request.'**
  String get aiRequestSubmitFailed;

  /// No description provided for @aiRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'AI request submitted — pending admin review.'**
  String get aiRequestSubmitted;

  /// No description provided for @aiRequestAlreadyPending.
  ///
  /// In en, this message translates to:
  /// **'An AI request for this product is already pending.'**
  String get aiRequestAlreadyPending;

  /// No description provided for @labelCopied.
  ///
  /// In en, this message translates to:
  /// **'{label} copied'**
  String labelCopied(String label);

  /// No description provided for @replacePhoto.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replacePhoto;

  /// No description provided for @batchImportAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied: superadmin only'**
  String get batchImportAccessDenied;

  /// No description provided for @systemSettingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get systemSettingsTab;

  /// No description provided for @systemSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'System settings'**
  String get systemSettingsTitle;

  /// No description provided for @systemSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Superadmin only. Changes apply to all users on the next product lookup.'**
  String get systemSettingsSubtitle;

  /// No description provided for @geminiLookupEmptyOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto Gemini ingredient lookup'**
  String get geminiLookupEmptyOffTitle;

  /// No description provided for @geminiLookupEmptyOffDescription.
  ///
  /// In en, this message translates to:
  /// **'When Open Food Facts has no ingredients, search the web with Gemini (requires GEMINI_API_KEY on the server).'**
  String get geminiLookupEmptyOffDescription;

  /// No description provided for @geminiLookupEmptyOffEnabled.
  ///
  /// In en, this message translates to:
  /// **'Auto Gemini ingredient lookup enabled'**
  String get geminiLookupEmptyOffEnabled;

  /// No description provided for @geminiLookupEmptyOffDisabled.
  ///
  /// In en, this message translates to:
  /// **'Auto Gemini ingredient lookup disabled'**
  String get geminiLookupEmptyOffDisabled;

  /// No description provided for @systemSettingsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load system settings'**
  String get systemSettingsLoadFailed;

  /// No description provided for @systemSettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save setting (superadmin only)'**
  String get systemSettingsSaveFailed;

  /// No description provided for @batchImportNoBarcodes.
  ///
  /// In en, this message translates to:
  /// **'No valid barcodes found in file'**
  String get batchImportNoBarcodes;

  /// No description provided for @signInToComment.
  ///
  /// In en, this message translates to:
  /// **'Sign in to comment.'**
  String get signInToComment;

  /// No description provided for @discussionFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get discussionFallbackTitle;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first!'**
  String get noCommentsYet;

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {username}'**
  String replyingTo(String username);

  /// No description provided for @writeCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Write a comment…'**
  String get writeCommentHint;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @failedStartDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Failed to start discussion. Try again.'**
  String get failedStartDiscussion;

  /// No description provided for @startDiscussionTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a Discussion'**
  String get startDiscussionTitle;

  /// No description provided for @topicOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Topic (optional)'**
  String get topicOptionalLabel;

  /// No description provided for @topicOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Is the gelatin source specified?'**
  String get topicOptionalHint;

  /// No description provided for @startDiscussionButton.
  ///
  /// In en, this message translates to:
  /// **'Start Discussion'**
  String get startDiscussionButton;

  /// No description provided for @linkedToChallenge.
  ///
  /// In en, this message translates to:
  /// **'Linked to challenge'**
  String get linkedToChallenge;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @noChallengesYet.
  ///
  /// In en, this message translates to:
  /// **'No ingredient challenges yet.'**
  String get noChallengesYet;

  /// No description provided for @noChallengesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an ingredient in Deep Analysis to challenge its verdict.'**
  String get noChallengesHint;

  /// No description provided for @challengeBy.
  ///
  /// In en, this message translates to:
  /// **'by {username}'**
  String challengeBy(String username);

  /// No description provided for @commentDeleted.
  ///
  /// In en, this message translates to:
  /// **'[deleted]'**
  String get commentDeleted;

  /// No description provided for @couldNotPostComment.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t post your comment. Please try again.'**
  String get couldNotPostComment;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @aiApprovalHint.
  ///
  /// In en, this message translates to:
  /// **'Approve to trigger AI ingredient lookup via Gemini/Claude. The product will be updated automatically.'**
  String get aiApprovalHint;

  /// No description provided for @refetchAiIngredients.
  ///
  /// In en, this message translates to:
  /// **'Re-fetch AI Ingredients'**
  String get refetchAiIngredients;

  /// No description provided for @approveAndFetch.
  ///
  /// In en, this message translates to:
  /// **'Approve & Fetch'**
  String get approveAndFetch;

  /// No description provided for @photoReplacement.
  ///
  /// In en, this message translates to:
  /// **'replacement'**
  String get photoReplacement;

  /// No description provided for @photoCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get photoCurrentLabel;

  /// No description provided for @photoNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get photoNewLabel;

  /// No description provided for @noPendingPhotoSubmissions.
  ///
  /// In en, this message translates to:
  /// **'No pending photo submissions'**
  String get noPendingPhotoSubmissions;

  /// No description provided for @noPendingIngredientContributions.
  ///
  /// In en, this message translates to:
  /// **'No pending ingredient contributions'**
  String get noPendingIngredientContributions;

  /// No description provided for @filterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get filterPending;

  /// No description provided for @filterApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get filterApproved;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get filterDone;

  /// No description provided for @noPendingAiRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending AI ingredient requests'**
  String get noPendingAiRequests;

  /// No description provided for @noApprovedAiRequests.
  ///
  /// In en, this message translates to:
  /// **'No approved AI ingredient requests'**
  String get noApprovedAiRequests;

  /// No description provided for @adminBatchRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Batch request failed — check Supabase logs'**
  String get adminBatchRequestFailed;

  /// No description provided for @adminBatchDoneSummary.
  ///
  /// In en, this message translates to:
  /// **'Done: {done}, skipped: {skipped}'**
  String adminBatchDoneSummary(int done, int skipped);

  /// No description provided for @adminBatchDoneWithErrors.
  ///
  /// In en, this message translates to:
  /// **'Done: {done}, skipped: {skipped}, failed: {errors} — see logs'**
  String adminBatchDoneWithErrors(int done, int skipped, int errors);

  /// No description provided for @challengeVerdictWas.
  ///
  /// In en, this message translates to:
  /// **'was'**
  String get challengeVerdictWas;

  /// No description provided for @challengeVerdictShouldBe.
  ///
  /// In en, this message translates to:
  /// **'should be'**
  String get challengeVerdictShouldBe;

  /// No description provided for @noAnalysesYet.
  ///
  /// In en, this message translates to:
  /// **'No analyses yet'**
  String get noAnalysesYet;

  /// No description provided for @filterNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here'**
  String get filterNothingHere;

  /// No description provided for @runAll.
  ///
  /// In en, this message translates to:
  /// **'Run all'**
  String get runAll;

  /// No description provided for @runningLabel.
  ///
  /// In en, this message translates to:
  /// **'Running…'**
  String get runningLabel;

  /// No description provided for @runSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'Run {count}'**
  String runSelectedCount(int count);

  /// No description provided for @selectAllPending.
  ///
  /// In en, this message translates to:
  /// **'Select all pending'**
  String get selectAllPending;

  /// No description provided for @deselectAllPending.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAllPending;

  /// No description provided for @unknownProduct.
  ///
  /// In en, this message translates to:
  /// **'Unknown product'**
  String get unknownProduct;

  /// No description provided for @adminAiRefetching.
  ///
  /// In en, this message translates to:
  /// **'Re-fetching AI ingredients for {barcode}…'**
  String adminAiRefetching(String barcode);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @barcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeLabel;

  /// No description provided for @barcodeWithValue.
  ///
  /// In en, this message translates to:
  /// **'Barcode: {barcode}'**
  String barcodeWithValue(String barcode);

  /// No description provided for @localDbDebugTitle.
  ///
  /// In en, this message translates to:
  /// **'Local DB — {barcode}'**
  String localDbDebugTitle(String barcode);

  /// No description provided for @localDbDebugTooltip.
  ///
  /// In en, this message translates to:
  /// **'Local DB debug'**
  String get localDbDebugTooltip;

  /// No description provided for @debugCacheSection.
  ///
  /// In en, this message translates to:
  /// **'── SharedPreferences cache ──'**
  String get debugCacheSection;

  /// No description provided for @debugRemoteDbSection.
  ///
  /// In en, this message translates to:
  /// **'── Remote DB (products table) ──'**
  String get debugRemoteDbSection;

  /// No description provided for @debugEmpty.
  ///
  /// In en, this message translates to:
  /// **'(empty)'**
  String get debugEmpty;

  /// No description provided for @debugNotFound.
  ///
  /// In en, this message translates to:
  /// **'(not found)'**
  String get debugNotFound;

  /// No description provided for @debugCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get debugCacheCleared;

  /// No description provided for @debugClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get debugClearCache;

  /// No description provided for @showOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get showOriginal;

  /// No description provided for @copyIngredientsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy ingredients'**
  String get copyIngredientsTooltip;

  /// No description provided for @findIngredientsViaAi.
  ///
  /// In en, this message translates to:
  /// **'Find ingredients via AI'**
  String get findIngredientsViaAi;

  /// No description provided for @aiLookupPendingHint.
  ///
  /// In en, this message translates to:
  /// **'AI lookup requested — an admin will review and approve it shortly.'**
  String get aiLookupPendingHint;

  /// No description provided for @aiLookupRejectedHint.
  ///
  /// In en, this message translates to:
  /// **'The AI request was rejected by an admin.'**
  String get aiLookupRejectedHint;

  /// No description provided for @aiLookupPromptHint.
  ///
  /// In en, this message translates to:
  /// **'Ask AI to search the web for this product\'s ingredient list.'**
  String get aiLookupPromptHint;

  /// No description provided for @aiWebIngredientLookupAlreadyRanTitle.
  ///
  /// In en, this message translates to:
  /// **'AI ingredient lookup already ran'**
  String get aiWebIngredientLookupAlreadyRanTitle;

  /// No description provided for @aiWebIngredientLookupAlreadyRanHint.
  ///
  /// In en, this message translates to:
  /// **'Gemini web search already ran for this product name but no usable ingredient list was found. You can still contribute ingredients or improve data on Open Food Facts.'**
  String get aiWebIngredientLookupAlreadyRanHint;

  /// No description provided for @requestViaAi.
  ///
  /// In en, this message translates to:
  /// **'Request via AI'**
  String get requestViaAi;

  /// No description provided for @requestAgain.
  ///
  /// In en, this message translates to:
  /// **'Request again'**
  String get requestAgain;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
