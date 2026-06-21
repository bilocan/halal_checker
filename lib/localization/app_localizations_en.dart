// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HalalScan';

  @override
  String get startTitle => 'HalalScan';

  @override
  String get home => 'Home';

  @override
  String get tagline => 'Transparent halal, powered by community.';

  @override
  String get taglineSubtitle =>
      'Every ingredient checked and explained — shaped by your feedback.';

  @override
  String get newScan => 'New Scan';

  @override
  String get lastResults => 'Last Results';

  @override
  String get noRecentResults => 'No recent scans saved yet.';

  @override
  String get noRecentResultsHint => 'Tap the scan button above to get started.';

  @override
  String get scanButton => 'Start Scan';

  @override
  String get scanAnotherProduct => 'Scan Another Product';

  @override
  String get manualEntry => 'Enter barcode manually';

  @override
  String get enterBarcodeManually => 'Enter barcode manually';

  @override
  String get cancel => 'Cancel';

  @override
  String get submit => 'Submit';

  @override
  String get scanAgain => 'Scan Again';

  @override
  String get readyToScan => 'Ready to scan';

  @override
  String get analyzingBarcode => 'Analyzing barcode...';

  @override
  String get pointCameraAtBarcode =>
      'Point camera at barcode on product packaging';

  @override
  String get barcodeNotSupported =>
      'Barcode detected but format not supported. Try manual entry.';

  @override
  String get pleaseEnterValidBarcode => 'Please enter a valid barcode.';

  @override
  String get productNotFound => 'Product not found';

  @override
  String get missingProductFlowTitle => 'Add this product';

  @override
  String get missingProductFlowIntro =>
      'This barcode is not in our databases yet. Submit clear pack photos — our team uses them so everyone can analyse this item later.';

  @override
  String get missingProductFlowHelpHint =>
      'We check photo size and sharpness before upload. Blurry or very small images cannot be processed.';

  @override
  String get missingProductStepBarcodeTitle => 'Step 1 — Barcode';

  @override
  String get missingProductStepBarcodeSubtitle =>
      'Your photos will be linked to:';

  @override
  String get missingProductStepFrontTitle => 'Step 2 — Front of pack';

  @override
  String get missingProductStepFrontSubtitle =>
      'Straight photo showing brand, product name, and barcode if it is printed on this side.';

  @override
  String get missingProductStepIngredientsTitle => 'Step 3 — Ingredients list';

  @override
  String get missingProductStepIngredientsSubtitle =>
      'Only the ingredient list panel. Avoid glare and keep text readable.';

  @override
  String get missingProductExampleLayout => 'What a good shot looks like';

  @override
  String get missingProductPickCamera => 'Take photo';

  @override
  String get missingProductPickGallery => 'Choose from gallery';

  @override
  String get missingProductRetake => 'Change photo';

  @override
  String get missingProductContinue => 'Continue';

  @override
  String get missingProductBack => 'Back';

  @override
  String get missingProductSubmit => 'Submit photos';

  @override
  String get missingProductSubmitting => 'Uploading…';

  @override
  String get missingProductThankYou =>
      'Thank you. Your photos are in the review queue.';

  @override
  String get missingProductUploadFailed =>
      'Upload failed. Check your connection and try again.';

  @override
  String missingProductPhotoTooLarge(int maxMb) {
    return 'File too large — maximum $maxMb MB.';
  }

  @override
  String get missingProductPhotoUnreadable =>
      'This file cannot be opened as an image.';

  @override
  String get missingProductPhotoTooSmall =>
      'Photo is too low resolution — move closer so the label fills the frame.';

  @override
  String get missingProductNeedBoth => 'Add both photos before submitting.';

  @override
  String get missingProductOpenFlow => 'Submit pack photos';

  @override
  String get missingProductOneOfTwoFailed =>
      'One photo did not upload. You can reopen this screen and try again.';

  @override
  String get missingProductReviewHint =>
      'Check that both previews are sharp and readable, then tap submit.';

  @override
  String get noProductImageAvailable => 'No product image available';

  @override
  String get uploadProductPhoto => 'Upload Photo';

  @override
  String get uploadPhotoHint =>
      'Help others by contributing a photo of this product';

  @override
  String get photoUploaded => 'Photo submitted — thank you!';

  @override
  String get photoUploadedLive => 'Photo published — thank you!';

  @override
  String get photoUploadedReviewNote =>
      'Photo submitted for review — we\'ll update the product after approval.';

  @override
  String get photoUploadFailed => 'Could not upload photo. Please try again.';

  @override
  String get photoPendingReview => 'Pending review';

  @override
  String get photoAlreadyPending =>
      'You already have a photo waiting for review on this slot.';

  @override
  String get photoSubmitReviewHint =>
      'Your photo will be reviewed by our team before it appears on the product.';

  @override
  String get additionalImages => 'Additional Images';

  @override
  String get ingredients => 'Ingredients';

  @override
  String get flaggedIngredients => 'Flagged Ingredients';

  @override
  String get mayBeAnimalDerived => 'Needs Verification';

  @override
  String get communityFeedback => 'Community Feedback';

  @override
  String get noFeedbackYet =>
      'No feedback yet. Be the first to share your thoughts!';

  @override
  String get provideFeedback => 'Provide Feedback';

  @override
  String get replyAsProducer => 'Reply as Producer';

  @override
  String get producerReply => 'Producer Reply';

  @override
  String get userFeedback => 'User Feedback';

  @override
  String get imageNotAvailable => 'Image not available';

  @override
  String get fairTrade => 'Fair Trade';

  @override
  String get organic => 'Organic';

  @override
  String get glutenFree => 'Gluten Free';

  @override
  String get vegetarian => 'Vegetarian';

  @override
  String get vegan => 'Vegan';

  @override
  String get halal => 'Nothing flagged';

  @override
  String get notHalal => 'Haram ingredients detected';

  @override
  String get suspiciousVerdict => 'Suspicious ingredients found';

  @override
  String get suspiciousResult => 'Suspicious ingredients found';

  @override
  String get lastScanned => 'Last scanned';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String errorFetchingProduct(String error) {
    return 'Error fetching product: $error';
  }

  @override
  String get productCouldNotBeRefreshed => 'Could not refresh product data';

  @override
  String get thankYouFeedback => 'Thank you for your feedback!';

  @override
  String errorSubmittingFeedback(String error) {
    return 'Error submitting feedback: $error';
  }

  @override
  String get replySubmitted => 'Reply submitted successfully!';

  @override
  String get noResultsSaved => 'No saved scan history yet.';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Türkçe';

  @override
  String get german => 'Deutsch';

  @override
  String get scanHistoryLoadFailed => 'Could not load scan history.';

  @override
  String get scanHistoryRetry => 'Retry';

  @override
  String get scanHistoryTitle => 'Recent scans';

  @override
  String get filterScan => 'Scan product or enter barcode';

  @override
  String get openResult => 'Open result';

  @override
  String get resultTitle => 'Result';

  @override
  String get noIngredientData => 'No ingredient data available.';

  @override
  String get foundInIngredients => 'Found in product ingredients.';

  @override
  String get flaggedLabels => 'Flagged Labels';

  @override
  String get foundInLabels => 'Found in product labels.';

  @override
  String get mayBeAnimalDerivedNote =>
      'Source may be animal-derived or involve alcohol extraction.';

  @override
  String get couldNotLoadFeedback => 'Could not load feedback.';

  @override
  String get couldNotSubmitFeedback => 'Could not submit feedback.';

  @override
  String get couldNotSubmitReply => 'Could not submit reply.';

  @override
  String get couldNotRefreshProduct => 'Could not refresh product data.';

  @override
  String get attachFiles => 'Attach Files';

  @override
  String get feedbackInputHint => 'Your feedback...';

  @override
  String get replyInputHint => 'Your reply...';

  @override
  String get submitReply => 'Submit Reply';

  @override
  String get refreshTooltip => 'Refresh product data';

  @override
  String get feedbackDialogHint =>
      'Help improve our halal assessment by providing feedback about this product.';

  @override
  String get replyDialogHint =>
      'Provide an official response to this feedback.';

  @override
  String get aiAnalysis => 'AI Analysis';

  @override
  String get keywordAnalysis => 'Keyword Analysis';

  @override
  String get analysisTransparency => 'Analysis Transparency';

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
    return '$count rules available (nothing to check)';
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
  String get transparentMatchSource => 'Matched via';

  @override
  String get transparentMatchSourcePrimary => 'Original ingredient label';

  @override
  String get transparentMatchSourceOffTaxonomy =>
      'Open Food Facts ingredient taxonomy (EN)';

  @override
  String get transparentMatchSourceUnanalyzable =>
      'Could not analyze — unsupported language';

  @override
  String get transparentMatchSourceNone => 'No keyword rule matches';

  @override
  String transparentMatchSourceOffLang(String lang) {
    return '$lang translation (Open Food Facts)';
  }

  @override
  String get transparentMatchOrigins => 'Match origins';

  @override
  String get transparentDisplayLanguage => 'Label language';

  @override
  String get transparentLabelsChecked => 'Labels checked';

  @override
  String get transparentFlaggedLabels => 'Flagged labels';

  @override
  String get transparentSuspiciousLabels => 'Suspicious labels';

  @override
  String get contributeIngredients => 'Add Ingredients';

  @override
  String get contributeIngredientsHint =>
      'No ingredient data found. Help the community by adding the ingredients from the packaging.';

  @override
  String get ingredientTextLabel => 'Ingredient text';

  @override
  String get ingredientTextHint =>
      'Type or paste the ingredient list from the packaging';

  @override
  String get ingredientSubmitted =>
      'Thank you! Ingredients submitted — the product will be re-analysed.';

  @override
  String get ingredientSubmitFailed =>
      'Could not submit ingredients. Please try again.';

  @override
  String get improveOnOpenFoodFacts => 'Edit on OpenFoodFacts';

  @override
  String get improveOnOpenFoodFactsHint =>
      'Help improve this product for everyone by adding data directly on OpenFoodFacts.';

  @override
  String get extractingIngredients => 'Reading ingredients from image…';

  @override
  String get ocrFailed =>
      'Could not read ingredients from the image. You can type them manually below.';

  @override
  String get ocrSuccess =>
      'Ingredients extracted — please review before submitting.';

  @override
  String get productImages => 'Product images';

  @override
  String get extractFromExistingImage => 'Pick from gallery';

  @override
  String get takePhotoOfIngredients => 'Take photo of ingredients';

  @override
  String get cameraError =>
      'Could not open camera. Please check camera permissions.';

  @override
  String get noIngredientsImageHint =>
      'No ingredients image available for this product. Please take a photo of the ingredient list on the packaging.';

  @override
  String get ocrNoIngredientsFound =>
      'No ingredient list found in the available images. Please take a photo of the ingredient label instead.';

  @override
  String get viewAllCheckedKeywords => 'View all checked keywords';

  @override
  String get haramKeywordsChecked => 'Haram Ingredients We Check';

  @override
  String get suspiciousKeywordsChecked => 'Suspicious Ingredients We Check';

  @override
  String get transparencyNote =>
      'Something missing from our list? Let us know via feedback!';

  @override
  String get recheck => 'Recheck';

  @override
  String get foundNotFlagged =>
      'Found in ingredients, but not flagged by the analysis (e.g. fatty alcohol, trace amount, or context-safe use).';

  @override
  String get fattyAlcoholNote =>
      'This is a fatty alcohol (e.g. cetyl or stearyl alcohol) — a plant-derived emulsifier. It has no relation to drinking alcohol and is halal.';

  @override
  String get keywords => 'Keywords';

  @override
  String get haramTab => 'Haram';

  @override
  String get suspiciousTab => 'Suspicious';

  @override
  String get suggestKeyword => 'Suggest a Keyword';

  @override
  String get suggestKeywordHint =>
      'Think we\'re missing something? Suggest a keyword and we\'ll review it.';

  @override
  String get keywordLabel => 'Keyword';

  @override
  String get keywordHint => 'e.g. lard, ethanol, cochineal';

  @override
  String get keywordRequired => 'Please enter a keyword.';

  @override
  String get categoryLabel => 'Category';

  @override
  String get haramCategory => 'Haram (definitively not permissible)';

  @override
  String get suspiciousCategory => 'Suspicious (may be animal-derived)';

  @override
  String get reasonLabel => 'Reason';

  @override
  String get reasonHint => 'Why should this keyword be added?';

  @override
  String get reasonRequired => 'Please provide a reason.';

  @override
  String get suggestionSubmitted =>
      'Thank you! Your suggestion has been submitted for review.';

  @override
  String get suggestionError =>
      'Could not submit suggestion. Please try again.';

  @override
  String get customBadge => 'custom';

  @override
  String get nutritionLabel => 'Nutrition';

  @override
  String get producerReplyWarningTitle => 'Unverified Action';

  @override
  String get producerReplyWarning =>
      'Anyone can post using this button — replies are not verified as coming from the actual manufacturer. Proceed only if you are the producer.';

  @override
  String get proceedAnyway => 'Proceed Anyway';

  @override
  String get deletedFromHistory => 'Removed from history';

  @override
  String get undo => 'Undo';

  @override
  String get explanationClean =>
      'No ingredients matched known animal-derived or alcohol-related keywords. This is an automated assessment based on ingredient text.';

  @override
  String explanationSuspiciousOnly(String ingredients) {
    return 'No definitely haram ingredients found, but $ingredients may be animal-derived. This is an automated assessment based on ingredient text.';
  }

  @override
  String explanationSuspiciousFlavouringOnly(String ingredients) {
    return 'No definitely haram ingredients found, but $ingredients may be animal-derived or extracted with alcohol. This is an automated assessment based on ingredient text.';
  }

  @override
  String explanationSuspiciousFlavouringAndOther(
    String flavouring,
    String other,
  ) {
    return 'No definitely haram ingredients found. $flavouring may be animal-derived or extracted with alcohol; $other may still be animal-derived. This is an automated assessment based on ingredient text.';
  }

  @override
  String explanationSuspiciousVeganFlavouringOnly(String ingredients) {
    return 'No definitely haram ingredients found. This product is vegan-certified; flagged aroma/flavouring is non-animal per certification, but alcohol content cannot be ruled out: $ingredients. This is an automated assessment based on ingredient text.';
  }

  @override
  String explanationSuspiciousVeganFlavouringAndOther(
    String flavouring,
    String other,
  ) {
    return 'No definitely haram ingredients found. This product is vegan-certified; flagged aroma/flavouring is non-animal per certification, but alcohol content cannot be ruled out: $flavouring. The following may still be animal-derived: $other. This is an automated assessment based on ingredient text.';
  }

  @override
  String get explanationHaram =>
      'This product contains one or more ingredients that may be animal-derived or alcohol-related. Review the flagged ingredients below for details.';

  @override
  String explanationHaramWithIngredients(String ingredients) {
    return 'This product contains ingredient(s) that are not permissible: $ingredients. Review the flagged ingredients below for details.';
  }

  @override
  String explanationHaramAdditives(String additives) {
    return 'This product\'s additives indicate it contains: $additives. Review the flagged items below for details.';
  }

  @override
  String explanationHaramCategory(String category) {
    return 'This product belongs to a category that is not permissible: $category.';
  }

  @override
  String get explanationHalalInherentCategory =>
      'This product is in an inherently halal category (e.g. water, salt). No harmful ingredients expected.';

  @override
  String get explanationUnanalyzableLanguage =>
      'Ingredients are in a language we cannot analyze. Halal status cannot be determined — check the packaging directly.';

  @override
  String get unknown => '? UNKNOWN';

  @override
  String get noCert => '⚠️ NO CERT';

  @override
  String get explanationUnknown =>
      'No ingredient data was found for this product. Halal status cannot be determined — check the packaging directly.';

  @override
  String get explanationNoCert =>
      'This is an animal-derived food product without a verified halal certification. Halal slaughter cannot be confirmed — check the packaging for a halal label.';

  @override
  String get nonFood => 'ℹ️ NOT FOOD';

  @override
  String get explanationNonFood =>
      'This is a non-food product. Islamic dietary rules do not apply.';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get releaseNotes => 'Release Notes';

  @override
  String get checkForUpdates => 'Check for Updates';

  @override
  String get upToDate => 'You\'re up to date!';

  @override
  String get installed => 'Installed';

  @override
  String get store => 'Store';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get latest => 'Latest';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get updateNow => 'Update Now';

  @override
  String get reportWrongResult => 'Report Wrong Result';

  @override
  String get reportWrongResultTitle => 'Is this result wrong?';

  @override
  String get reportWrongResultSubtitle =>
      'Tell us what it should be. We\'ll create a bug report and fix it.';

  @override
  String get currentResultLabel => 'Current result';

  @override
  String get expectedResultLabel => 'What should it be?';

  @override
  String get optionalNote => 'Optional note (e.g. why you think so)';

  @override
  String get reportSubmitted => 'Bug report submitted — thank you!';

  @override
  String get reportFailed => 'Could not submit report. Try again later.';

  @override
  String get reportResultHalal => 'Halal';

  @override
  String get reportResultHaram => 'Not Halal';

  @override
  String get reportResultNonFood => 'Non-Food';

  @override
  String get reportResultUnknown => 'Unknown';

  @override
  String get myNote => 'My Note';

  @override
  String get noteHint => 'e.g. ask producer about E471, check later...';

  @override
  String get noteSaved => 'Note saved';

  @override
  String get checkLater => 'Check later';

  @override
  String get flaggedOnly => 'Flagged only';

  @override
  String get allScans => 'All scans';

  @override
  String get deepAnalysis => 'Deep Analysis';

  @override
  String get analyse => 'Analyse';

  @override
  String get perIngredientAiAnalysis =>
      'Per-ingredient AI analysis with Islamic basis';

  @override
  String get communityDiscussion => 'Community Discussion';

  @override
  String get noDiscussionsYet => 'No discussions yet — start one';

  @override
  String get analysisQueued =>
      'Analysis queued — results will appear after admin review.';

  @override
  String get analysisFailed => 'Analysis failed — please try again.';

  @override
  String get signInToDiscuss => 'Sign in to start a discussion.';

  @override
  String get signInToChallenge => 'Sign in to submit a challenge.';

  @override
  String get discussions => 'Discussions';

  @override
  String get challenges => 'Challenges';

  @override
  String get newDiscussion => 'New Discussion';

  @override
  String get halalDirectory => 'Halal Directory';

  @override
  String get signInFailed => 'Sign-in failed. Please try again.';

  @override
  String get newVersionAvailable => 'A new version is available';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get signedIn => 'Signed in';

  @override
  String get changeUsername => 'Change display name';

  @override
  String get firstLoginUsernameTitle => 'Your community name';

  @override
  String get publicDisplayNameHint =>
      'This name is shown on discussions and comments. You can change it anytime in your profile.';

  @override
  String get usernameSaved => 'Display name updated.';

  @override
  String get usernameInvalid =>
      'Use 2–40 characters: letters, numbers, spaces, and . _ - \'';

  @override
  String get usernameSaveFailed =>
      'Could not save display name. Please try again.';

  @override
  String get keepThisName => 'Keep this name';

  @override
  String get save => 'Save';

  @override
  String get signInDisplayNameHint =>
      'Your name from sign-in may appear in community discussions until you change it in your profile.';

  @override
  String profileRole(String role) {
    return 'Role: $role';
  }

  @override
  String get roleUser => 'Member';

  @override
  String get roleModerator => 'Moderator';

  @override
  String get roleScholar => 'Scholar';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleSuperadmin => 'Super Admin';

  @override
  String get adminPanel => 'Admin panel';

  @override
  String get noDiscussionsHint => 'Be the first to start one!';

  @override
  String get approvalsTab => 'Approvals';

  @override
  String get analysisTab => 'Analysis';

  @override
  String get rulesEngineTab => 'Rules Engine';

  @override
  String get photosTab => 'Photos';

  @override
  String get ingredientsTab => 'Ingredients';

  @override
  String get ingredientContributionsTab => 'Ingredient Contributions';

  @override
  String get aiIngredientsLookupTab => 'AI Ingredients Lookup';

  @override
  String get customRulesTab => 'Custom';

  @override
  String get builtInRulesTab => 'Built-in';

  @override
  String get suggestionsTab => 'Suggestions';

  @override
  String get searchRules => 'Search rules...';

  @override
  String get noCustomRules => 'No custom rules yet';

  @override
  String get noMatchingRules => 'No matching rules found';

  @override
  String get noSuggestions => 'No pending suggestions';

  @override
  String get addRule => 'Add Rule';

  @override
  String get editRule => 'Edit Rule';

  @override
  String get delete => 'Delete';

  @override
  String get deleteRuleTitle => 'Delete Rule';

  @override
  String deleteRuleConfirm(String keyword) {
    return 'Remove \"$keyword\" from the rules?';
  }

  @override
  String get ruleCreated => 'Rule created successfully';

  @override
  String get ruleCreateFailed => 'Could not create rule. Please try again.';

  @override
  String get ruleUpdated => 'Rule updated successfully';

  @override
  String get ruleUpdateFailed => 'Could not update rule. Please try again.';

  @override
  String get ruleDeleted => 'Rule deleted';

  @override
  String get ruleDeleteFailed => 'Could not delete rule. Please try again.';

  @override
  String get createRule => 'Create Rule';

  @override
  String get updateRule => 'Update Rule';

  @override
  String get variantsLabel => 'Variants';

  @override
  String get variantsHint => 'e.g. schmalz, domuz yağı, saindoux';

  @override
  String get variantsHelperText =>
      'Comma-separated multilingual variants for matching';

  @override
  String get suggestVariantsLabel => 'Other languages (optional)';

  @override
  String get suggestVariantsHint => 'e.g. schwein, domuz, porc';

  @override
  String get suggestVariantsHelperText =>
      'Comma-separated spellings in other languages for the same ingredient';

  @override
  String get translationsLabel => 'Translations by locale';

  @override
  String get translationsHint => 'de: schwein\ntr: domuz';

  @override
  String get translationsHelperText =>
      'One per line: locale code and term (de, tr, fr, es, it, nl, sr, hu, cs). Used for matching and UI labels.';

  @override
  String get guideSlugsLabel => 'Related guide slugs';

  @override
  String get guideSlugsHint => 'e-numbers-guide, what-is-gelatin';

  @override
  String get guideSlugsHelperText =>
      'Comma-separated blog slugs on halalscan.at (no locale prefix). Merged with built-in guides for the same canonical.';

  @override
  String get guideSlugInvalid =>
      'Invalid slug — use lowercase letters, numbers, and hyphens only';

  @override
  String get editGuideLinks => 'Edit guide links';

  @override
  String get guideLinksUpdated => 'Guide links updated';

  @override
  String get guideLinksUpdateFailed =>
      'Could not update guide links. Please try again.';

  @override
  String get mergeKeywordTitle => 'Merge with existing rule?';

  @override
  String mergeKeywordMessage(String alias, String canonical) {
    return '\"$alias\" matches the existing rule \"$canonical\". Merge aliases into that rule instead of creating a duplicate?';
  }

  @override
  String get mergeKeywordConfirm => 'Merge';

  @override
  String get approveAsNewRule => 'Create new rule';

  @override
  String get suggestionMerged => 'Suggestion merged into existing rule';

  @override
  String get builtInBadge => 'built-in';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get suggestionApproved => 'Suggestion approved and added as a rule';

  @override
  String get suggestionApproveFailed => 'Could not approve suggestion.';

  @override
  String get suggestionRejected => 'Suggestion rejected';

  @override
  String get suggestionRejectFailed => 'Could not reject suggestion.';

  @override
  String get photoIngredientsButton => 'Check Ingredients Photo';

  @override
  String get photoAnalysisProductName => 'Photo Analysis';

  @override
  String get managedProduct => 'Verified by admin';

  @override
  String get managedProductNoRefresh =>
      'This product is managed by an admin and cannot be refreshed from external sources.';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountTitle => 'Delete Account?';

  @override
  String get deleteAccountConfirm =>
      'This will permanently delete your account and all associated data. This action cannot be undone.';

  @override
  String get deleteAccountSuccess => 'Your account has been deleted.';

  @override
  String get deleteAccountFailed =>
      'Could not delete account. Please try again.';

  @override
  String get reportWrongIngredient => 'Report Wrong Ingredient';

  @override
  String get reportWrongIngredientTitle => 'Report wrong ingredient';

  @override
  String get reportWrongIngredientSubtitle =>
      'Select the ingredients you believe are incorrectly listed.';

  @override
  String get reportWrongIngredientExplanation => 'Explanation (optional)';

  @override
  String get reportWrongIngredientExplanationHint =>
      'e.g. this ingredient is plant-based...';

  @override
  String get reportWrongIngredientNoSelection =>
      'Please select at least one ingredient.';

  @override
  String get reportWrongIngredientSubmitted =>
      'Thank you! Your report has been submitted.';

  @override
  String get reportWrongIngredientFailed =>
      'Could not submit report. Please try again.';

  @override
  String get reportsTab => 'Reports';

  @override
  String get reportedIngredient => 'Reported as wrong';

  @override
  String get noReports => 'No pending reports';

  @override
  String get openProduct => 'Open product';

  @override
  String get resolveReport => 'Resolve';

  @override
  String get dismissReport => 'Dismiss';

  @override
  String get signInRequired => 'Sign in required';

  @override
  String get signInRequiredMessage =>
      'You need to be signed in to submit feedback or suggestions.';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get batchImport => 'Batch Import';

  @override
  String get adminUpdateFailed => 'Failed to update — check Supabase logs';

  @override
  String get adminAiRequestsLoadFailed =>
      'Could not load AI requests — check connection';

  @override
  String get aiRequestSubmitFailed => 'Failed to submit AI request.';

  @override
  String get aiRequestSubmitted =>
      'AI request submitted — pending admin review.';

  @override
  String get aiRequestAlreadyPending =>
      'An AI request for this product is already pending.';

  @override
  String labelCopied(String label) {
    return '$label copied';
  }

  @override
  String get replacePhoto => 'Replace';

  @override
  String get batchImportAccessDenied => 'Access denied: superadmin only';

  @override
  String get systemSettingsTab => 'Settings';

  @override
  String get systemSettingsTitle => 'System settings';

  @override
  String get systemSettingsSubtitle =>
      'Superadmin only. Changes apply to all users on the next product lookup.';

  @override
  String get geminiLookupEmptyOffTitle => 'Auto Gemini ingredient lookup';

  @override
  String get geminiLookupEmptyOffDescription =>
      'When Open Food Facts has no ingredients, search the web with Gemini (requires GEMINI_API_KEY on the server).';

  @override
  String get geminiLookupEmptyOffEnabled =>
      'Auto Gemini ingredient lookup enabled';

  @override
  String get geminiLookupEmptyOffDisabled =>
      'Auto Gemini ingredient lookup disabled';

  @override
  String get closedBetaBannerTitle => 'Closed beta — help us test';

  @override
  String get closedBetaBannerSubtitle =>
      'Your feedback helps us reach production on Google Play. Please try these flows and report anything broken.';

  @override
  String get closedBetaBannerTasks =>
      '• Scan a barcode (day 1)\n• Open a result and read ingredients (day 3)\n• Scan again on day 7\n• Send feedback from this banner or About';

  @override
  String get sendBetaFeedback => 'Send beta feedback';

  @override
  String get closedBetaBannerAdminTitle => 'Closed beta home banner';

  @override
  String get closedBetaBannerAdminDescription =>
      'Show a dismissible checklist banner on the Android home tab for Play closed testers (iOS is unaffected).';

  @override
  String get closedBetaBannerEnabled => 'Closed beta banner enabled';

  @override
  String get closedBetaBannerDisabled => 'Closed beta banner disabled';

  @override
  String get deepAnalysisAdminTitle => 'Deep Analysis';

  @override
  String get deepAnalysisAdminDescription =>
      'Show per-ingredient Deep Analysis on the result screen and the Analysis queue in Admin approvals. When off, users cannot queue new analyses.';

  @override
  String get deepAnalysisEnabled => 'Deep Analysis enabled';

  @override
  String get deepAnalysisDisabled => 'Deep Analysis disabled';

  @override
  String get photoSubmissionsAutoApproveAdminTitle =>
      'Auto-approve photo submissions';

  @override
  String get photoSubmissionsAutoApproveAdminDescription =>
      'When on, user photo uploads skip the admin queue and go live on the product immediately.';

  @override
  String get photoSubmissionsAutoApproveEnabled => 'Photo auto-approve enabled';

  @override
  String get photoSubmissionsAutoApproveDisabled =>
      'Photo auto-approve disabled';

  @override
  String get photoSubmissionsAutoApproveQueueEmpty =>
      'Auto-approve is on — no photo approval queue.';

  @override
  String get systemSettingsLoadFailed => 'Could not load system settings';

  @override
  String get systemSettingsSaveFailed =>
      'Could not save setting (superadmin only)';

  @override
  String get batchImportNoBarcodes => 'No valid barcodes found in file';

  @override
  String get signInToComment => 'Sign in to comment.';

  @override
  String get discussionFallbackTitle => 'Discussion';

  @override
  String get noCommentsYet => 'No comments yet. Be the first!';

  @override
  String replyingTo(String username) {
    return 'Replying to $username';
  }

  @override
  String get writeCommentHint => 'Write a comment…';

  @override
  String get reply => 'Reply';

  @override
  String get failedStartDiscussion => 'Failed to start discussion. Try again.';

  @override
  String get startDiscussionTitle => 'Start a Discussion';

  @override
  String get topicOptionalLabel => 'Topic (optional)';

  @override
  String get topicOptionalHint => 'e.g. Is the gelatin source specified?';

  @override
  String get startDiscussionButton => 'Start Discussion';

  @override
  String get linkedToChallenge => 'Linked to challenge';

  @override
  String get locked => 'Locked';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get noChallengesYet => 'No ingredient challenges yet.';

  @override
  String get noChallengesHint =>
      'Tap an ingredient in Deep Analysis to challenge its verdict.';

  @override
  String challengeBy(String username) {
    return 'by $username';
  }

  @override
  String get commentDeleted => '[deleted]';

  @override
  String get couldNotPostComment =>
      'Couldn\'t post your comment. Please try again.';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get aiApprovalHint =>
      'Approve to trigger AI ingredient lookup via Gemini/Claude. The product will be updated automatically.';

  @override
  String get refetchAiIngredients => 'Re-fetch AI Ingredients';

  @override
  String get approveAndFetch => 'Approve & Fetch';

  @override
  String get photoReplacement => 'replacement';

  @override
  String get photoCurrentLabel => 'Current';

  @override
  String get photoNewLabel => 'New';

  @override
  String get noPendingPhotoSubmissions => 'No pending photo submissions';

  @override
  String get noPendingIngredientContributions =>
      'No pending ingredient contributions';

  @override
  String get filterPending => 'Pending';

  @override
  String get filterApproved => 'Approved';

  @override
  String get filterRejected => 'Rejected';

  @override
  String get myContributions => 'My contributions';

  @override
  String get noPhotoContributions => 'No photo contributions yet.';

  @override
  String get filterAll => 'All';

  @override
  String get filterDone => 'Done';

  @override
  String get noPendingAiRequests => 'No pending AI ingredient requests';

  @override
  String get noApprovedAiRequests => 'No approved AI ingredient requests';

  @override
  String get adminBatchRequestFailed =>
      'Batch request failed — check Supabase logs';

  @override
  String adminBatchDoneSummary(int done, int skipped) {
    return 'Done: $done, skipped: $skipped';
  }

  @override
  String adminBatchDoneWithErrors(int done, int skipped, int errors) {
    return 'Done: $done, skipped: $skipped, failed: $errors — see logs';
  }

  @override
  String get challengeVerdictWas => 'was';

  @override
  String get challengeVerdictShouldBe => 'should be';

  @override
  String get noAnalysesYet => 'No analyses yet';

  @override
  String get filterNothingHere => 'Nothing here';

  @override
  String get runAll => 'Run all';

  @override
  String get runningLabel => 'Running…';

  @override
  String runSelectedCount(int count) {
    return 'Run $count';
  }

  @override
  String get selectAllPending => 'Select all pending';

  @override
  String get deselectAllPending => 'Deselect all';

  @override
  String get unknownProduct => 'Unknown product';

  @override
  String adminAiRefetching(String barcode) {
    return 'Re-fetching AI ingredients for $barcode…';
  }

  @override
  String get close => 'Close';

  @override
  String get barcodeLabel => 'Barcode';

  @override
  String barcodeWithValue(String barcode) {
    return 'Barcode: $barcode';
  }

  @override
  String localDbDebugTitle(String barcode) {
    return 'Local DB — $barcode';
  }

  @override
  String get localDbDebugTooltip => 'Local DB debug';

  @override
  String get debugCacheSection => '── SharedPreferences cache ──';

  @override
  String get debugRemoteDbSection => '── Remote DB (products table) ──';

  @override
  String get debugEmpty => '(empty)';

  @override
  String get debugNotFound => '(not found)';

  @override
  String get debugCacheCleared => 'Cache cleared';

  @override
  String get debugClearCache => 'Clear cache';

  @override
  String get showOriginal => 'Original';

  @override
  String get copyIngredientsTooltip => 'Copy ingredients';

  @override
  String get findIngredientsViaAi => 'Find ingredients via AI';

  @override
  String get aiLookupPendingHint =>
      'AI lookup requested — an admin will review and approve it shortly.';

  @override
  String get aiLookupRejectedHint => 'The AI request was rejected by an admin.';

  @override
  String get aiLookupPromptHint =>
      'Ask AI to search the web for this product\'s ingredient list.';

  @override
  String get aiWebIngredientLookupAlreadyRanTitle =>
      'AI ingredient lookup already ran';

  @override
  String get aiWebIngredientLookupAlreadyRanHint =>
      'Gemini web search already ran for this product name but no usable ingredient list was found. You can still contribute ingredients or improve data on Open Food Facts.';

  @override
  String get requestViaAi => 'Request via AI';

  @override
  String get requestAgain => 'Request again';

  @override
  String showAllIngredients(int count) {
    return 'Show all $count ingredients';
  }

  @override
  String get showLessIngredients => 'Show less';

  @override
  String get allergens => 'Allergens';

  @override
  String get additives => 'Additives';

  @override
  String get mayContain => 'May contain';

  @override
  String get findings => 'Findings';

  @override
  String get relatedGuides => 'Related guides';

  @override
  String get readGuide => 'Read guide';

  @override
  String get seeFullDetails => 'See full details';

  @override
  String get fullDetailsTitle => 'Full Details';
}
