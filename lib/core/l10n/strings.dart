import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../state/settings_controller.dart';

/// Centralized strings for the entire app with full English and Hindi support.
class Strings {
  const Strings._(this.code);

  final String code;

  static const supported = {'en': 'English', 'hi': 'हिन्दी'};

  static Strings of(BuildContext context) {
    String code = 'en';
    try {
      code = context.watch<SettingsController>().language;
    } catch (_) {
      // Outside the provider tree (tests, share card rendering).
    }
    return Strings._(code);
  }

  static Strings forCode(String code) => Strings._(code);

  bool get isHindi => code == 'hi';

  String _t(String en, String hi) => isHindi ? hi : en;

  // App & Common
  String get appName => 'Jemixo Safe';
  String get tagline => _t(
    'Know Your Phone. Protect Your Privacy.',
    'अपने फ़ोन को जानें, अपनी प्राइवेसी सुरक्षित रखें।',
  );
  String get runsOnDevice => _t(
    'Runs entirely on this device',
    'पूरी तरह आपके फ़ोन पर ही चलता है',
  );
  String get disclaimerScore => _t(
    'This score is a Jemixo Safe risk indicator based on information this app can read on your device. It is not a guarantee that your phone is free of harmful apps.',
    'यह स्कोर एक सुरक्षा संकेतक है जो केवल इस फ़ोन पर उपलब्ध जानकारी पर आधारित है। यह हानिकारक ऐप्स की अनुपस्थिति की गारंटी नहीं है।',
  );
  String get disclaimerRisk => _t(
    'Risk levels are indicators, not proof of harmful behaviour. Review any flagged app before taking action.',
    'जोखिम स्तर केवल संकेतक हैं, किसी हानिकारक गतिविधि का पक्का सबूत नहीं। कोई भी कदम उठाने से पहले ऐप की समीक्षा करें।',
  );

  // Bottom Navigation
  String get tabHome => _t('Home', 'होम');
  String get tabSafety => _t('Safety', 'सुरक्षा');
  String get tabPrivacy => _t('Privacy', 'प्राइवेसी');
  String get tabClean => _t('Clean', 'क्लीनर');
  String get tabMore => _t('More', 'अन्य');

  // Common Actions
  String get scanNow => _t('Scan now', 'अभी स्कैन करें');
  String get scanning => _t('Scanning…', 'स्कैनिंग…');
  String get details => _t('Details', 'विवरण');
  String get review => _t('Review', 'जाँचें');
  String get reviewNow => _t('Review now', 'अभी जाँचें');
  String get clear => _t('Clear', 'हटाएं');
  String get delete => _t('Delete', 'डिलीट करें');
  String get cancel => _t('Cancel', 'रद्द करें');
  String get refresh => _t('Refresh', 'रिफ़्रेश करें');
  String get rescan => _t('Rescan', 'पुनः स्कैन करें');
  String get settings => _t('Settings', 'सेटिंग्स');
  String get tryAgain => _t('Try again', 'फिर कोशिश करें');
  String get allowAccess => _t('Allow access', 'अनुमति दें');
  String get selectAll => _t('Select all', 'सभी चुनें');
  String get selectAllShown => _t('Select all shown', 'दिखाए गए सभी चुनें');
  String get share => _t('Share', 'शेयर करें');
  String get copy => _t('Copy', 'कॉपी करें');
  String get copied => _t('Copied', 'कॉपी हो गया');
  String get paste => _t('Paste', 'पेस्ट करें');
  String get waiting => _t('Waiting…', 'प्रतीक्षा करें…');

  // Score Bands & Risk Levels
  String get excellent => _t('Excellent', 'शानदार');
  String get good => _t('Good', 'अच्छा');
  String get needsReview => _t('Needs Review', 'जाँच ज़रूरी');
  String get attentionRequired => _t('Attention Required', 'ध्यान दें');
  String get notScanned => _t('Not scanned', 'स्कैन नहीं हुआ');
  String get healthy => _t('Healthy', 'सामान्य');
  String get gettingLow => _t('Getting low', 'कम हो रही है');
  String get nearlyFull => _t('Nearly full', 'लगभग भरी हुई');

  String get riskSafe => _t('Safe', 'सुरक्षित');
  String get riskLow => _t('Low Risk', 'कम जोखिम');
  String get riskReview => _t('Review', 'समीक्षा');
  String get riskHigh => _t('High Risk', 'उच्च जोखिम');
  String get riskCritical => _t('Attention Required', 'अति संवेदनशील');

  // Dashboard
  String get safetyScore => _t('Safety score', 'सुरक्षा स्कोर');
  String get runCheckToSeeScore => _t(
    'Run a check to see your safety score.',
    'अपना सुरक्षा स्कोर देखने के लिए जाँच शुरू करें।',
  );
  String get noAttentionNeeded => _t(
    'Nothing needs your attention right now.',
    'अभी किसी चीज़ पर ध्यान देने की ज़रूरत नहीं है। सब सुरक्षित है।',
  );
  String appsWorthLook(int count) => _t(
    '$count app${count == 1 ? '' : 's'} worth a look.',
    '$count ऐप${count == 1 ? '' : '्स'} की समीक्षा ज़रूरी है।',
  );
  String get firstScanTakesFewSeconds => _t(
    'Your first scan takes a few seconds.',
    'पहली जाँच में कुछ ही सेकंड लगते हैं।',
  );
  String lastCheckedRelative(String relative) => _t(
    'Last checked $relative',
    'पिछली जाँच $relative',
  );
  String get battery => _t('Battery', 'बैटरी');
  String get memory => _t('Memory', 'मेमोरी');
  String get storage => _t('Storage', 'स्टोरेज');
  String get checkBeforeYouAct => _t('Check before you act', 'कार्रवाई से पहले जाँचें');
  String get scamScannerTitle => _t('Scam message scanner', 'फ़्रॉड मैसेज स्कैनर');
  String get scamScannerSub => _t(
    'Paste a message, or share one from any app',
    'मैसेज पेस्ट करें, या किसी भी ऐप से यहाँ शेयर करें',
  );
  String get checkScreenshotTitle => _t('Check a screenshot', 'स्क्रीनशॉट जाँचें');
  String get checkScreenshotSubtitle => _t(
    'Text is read on the phone, in English and Hindi',
    'टेक्स्ट फ़ोन पर ही पढ़ा जाता है, पूरी तरह सुरक्षित',
  );
  String get checkPhoneTitle => _t('Check a phone number', 'फ़ोन नंबर जाँचें');
  String get checkPhoneSubtitle => _t(
    'Can a bank or the police really call from it?',
    'बैंक या पुलिस क्या वाकई इस नंबर से कॉल कर सकते हैं?',
  );
  String get checkUrlTitle => _t('URL safety checker', 'लिंक / वेबसाइट सुरक्षा');
  String get checkUrlSubtitle => _t(
    'Check a link for impersonation and insecure patterns',
    'फ़र्ज़ी और ख़तरनाक लिंक की पहचान करें',
  );
  String get checkQrTitle => _t('QR & UPI check', 'QR और UPI जाँचें');
  String get checkQrSubtitle => _t(
    'See who gets paid before you scan in your UPI app',
    'UPI ऐप में स्कैन करने से पहले देखें पैसा किसे जाएगा',
  );
  String get threatCallTitle => _t('Someone is threatening me on a call', 'कोई कॉल पर धमका रहा है (डिजिटल अरेस्ट)');
  String get threatCallSubtitle => _t(
    'Police, CBI, customs, bank: read this before you do anything',
    'पुलिस, CBI, कस्टम, बैंक: कुछ भी करने से पहले यह पढ़ें',
  );
  String get gotScammedTitle => _t('I think I got scammed', 'लगता है मेरे साथ ठगी हुई है');
  String get gotScammedSubtitle => _t(
    'Call 1930 and freeze the money in the first hour',
    '1930 पर तुरंत कॉल करें और पैसा रुकवाएँ',
  );
  String get yourApps => _t('Your apps', 'आपके ऐप्स');
  String get appsSpecialAccessTitle => _t('Apps with special access', 'विशेष अनुमति वाले ऐप्स');
  String get appsSpecialAccessSubtitle => _t(
    'Screen readers, notification access, device admin, hidden apps',
    'स्क्रीन रीडर, नोटिफ़िकेशन एक्सेस, डिवाइस एडमिन, छिपे हुए ऐप्स',
  );
  String get whatChangedTitle => _t('What changed since last check', 'पिछली जाँच के बाद क्या बदला');
  String get whatChangedSubtitle => _t(
    'New apps and permissions added by updates',
    'नए ऐप्स और अपडेट्स द्वारा जोड़ी गई अनुमतियाँ',
  );
  String get deviceSection => _t('Device', 'डिवाइस स्थिति');
  String get storageCleanupTitle => _t('Storage cleanup', 'स्टोरेज साफ़ करें');
  String get storageCleanupSubtitle => _t(
    'Large files, duplicates, screenshots, downloads',
    'बड़ी फ़ाइलें, डुप्लीकेट, स्क्रीनशॉट, डाउनलोड',
  );
  String get whatsappCleanerTitle => _t('WhatsApp cleaner', 'व्हाट्सएप क्लीनर');
  String get whatsappCleanerSubtitle => _t(
    'Free up space from old forwards and big videos',
    'पुराने फॉरवर्ड और बड़े वीडियो हटाकर जगह खाली करें',
  );
  String get deviceHealthTitle => _t('Device health', 'डिवाइस स्वास्थ्य');
  String get deviceHealthSubtitle => _t(
    'Battery, memory, storage pressure and security settings',
    'बैटरी, मेमोरी, स्टोरेज स्थिति और सुरक्षा सेटिंग्स',
  );
  String get networkTitle => _t('Network', 'नेटवर्क स्थिति');
  String get networkSubtitle => _t(
    'Connection type, validation and network settings',
    'कनेक्शन प्रकार, सुरक्षा और नेटवर्क सेटिंग्स',
  );
  String get allToolsTitle => _t('All tools', 'सभी टूल्स');
  String get allToolsSubtitle => _t(
    'Reports, history, hardware tests, QR scanner, settings',
    'रिपोर्ट, इतिहास, हार्डवेयर टेस्ट, QR स्कैनर, सेटिंग्स',
  );

  // Security / Safety Tab
  String get safetyCheckTitle => _t('Safety check', 'सुरक्षा जाँच');
  String get startSafetyCheck => _t('Start safety check', 'सुरक्षा जाँच शुरू करें');
  String get whatWeChecked => _t('What we checked', 'हमने क्या जाँचा');
  String get fakeBankingTitle => _t('Fake bank & payment apps', 'नकली बैंक और पेमेंट ऐप्स');
  String get fakeBankingDetailSafe => _t(
    'No app borrows a bank, UPI or government brand name without being the official package.',
    'कोई भी ऐप बैंक, UPI या सरकारी ब्रांड का नाम चुराता हुआ नहीं पाया गया।',
  );
  String get sideloadedTitle => _t('Sideloaded apps', 'बाहर से इंस्टॉल किए गए ऐप्स');
  String get sideloadedDetailSafe => _t(
    'All installed apps came from Google Play or the device maker.',
    'सभी इंस्टॉल किए गए ऐप्स Google Play या फ़ोन निर्माता से आए हैं।',
  );
  String get specialAccessTitle => _t('Apps with special access', 'विशेष अनुमति वाले ऐप्स');
  String get devOptionsTitle => _t('Developer options & USB debugging', 'डेवलपर विकल्प और USB डीबगिंग');
  String get devOptionsDetailSafe => _t(
    'Developer mode and USB debugging are turned off.',
    'डेवलपर मोड और USB डीबगिंग बंद हैं।',
  );
  String userAppsReviewed(int count) => _t(
    '$count user apps reviewed',
    '$count ऐप्स की समीक्षा पूरी हुई',
  );
  String get safetyScoreCaption => _t('Safety score', 'सुरक्षा स्कोर');
  String get screenLock => _t('Screen lock', 'स्क्रीन लॉक');

  // Privacy Tab
  String get privacyTitle => _t('Privacy', 'प्राइवेसी');
  String get privacyScore => _t('Privacy score', 'प्राइवेसी स्कोर');
  String get privacyScoreHint => _t(
    'Higher means fewer sensitive permissions across your apps.',
    'स्कोर जितना अधिक होगा, संवेदनशील अनुमतियाँ उतनी ही कम होंगी।',
  );
  String get reviewInstalledApps => _t('Review installed apps', 'इंस्टॉल किए गए ऐप्स देखें');
  String get analyzers => _t('Analyzers', 'विश्लेषक टूल्स');
  String get installedAppAnalyzerTitle => _t('Installed app analyzer', 'इंस्टॉल किए गए ऐप का विश्लेषण');
  String get installedAppAnalyzerSubtitle => _t(
    'Sort by risk, size or date and inspect any app\'s permissions',
    'जोखिम, साइज़ या तारीख से क्रमबद्ध करें और अनुमतियाँ देखें',
  );
  String get apkAnalyzerTitle => _t('APK analyzer', 'APK फ़ाइल विश्लेषक');
  String get apkAnalyzerSubtitle => _t(
    'Inspect an APK file you have on your device before installing',
    'इंस्टॉल करने से पहले अपने फ़ोन में मौजूद APK फ़ाइल की जाँच करें',
  );
  String get permissionsByCategory => _t('Permissions by category', 'श्रेणी अनुसार अनुमतियाँ');

  // Storage Tab & Scaffolding
  String get cleanTitle => _t('Clean', 'स्टोरेज क्लीनर');
  String get storageOverview => _t('Storage', 'स्टोरेज');
  String get used => _t('Used', 'प्रयुक्त');
  String get free => _t('Free', 'ख़ाली');
  String get whereSpaceGoes => _t('Where space goes', 'स्टोरेज कहाँ खर्च हो रही है');
  String get cleanupTools => _t('Cleanup tools', 'सफ़ाई टूल्स');
  String get largeFilesTitle => _t('Large files', 'बड़ी फ़ाइलें');
  String get largeFilesSubtitle => _t(
    'Big videos, photos and downloads, sorted by size',
    'साइज़ के आधार पर बड़े वीडियो, फ़ोटो और डाउनलोड',
  );
  String get duplicatesTitle => _t('Duplicates', 'एक जैसी फ़ाइलें (डुप्लीकेट)');
  String get duplicatesSubtitle => _t(
    'Identical copies found by content hash',
    'एक जैसी फ़ाइलें जो बेकार जगह घेर रही हैं',
  );
  String get similarPhotosTitle => _t('Similar photos', 'मिलती-जुलती फ़ोटो');
  String get similarPhotosSubtitle => _t(
    'Bursts and re-saved shots that look the same',
    'एक जैसी दिखने वाली तस्वीरें और बर्स्ट फ़ोटो',
  );
  String get screenshotsTitle => _t('Screenshots', 'स्क्रीनशॉट');
  String get screenshotsSubtitle => _t(
    'Screenshots and screen recordings',
    'पुराने स्क्रीनशॉट और स्क्रीन रिकॉर्डिंग',
  );
  String get downloadsTitle => _t('Downloads', 'डाउनलोड');
  String get downloadsSubtitle => _t(
    'Installers, archives and media',
    'डाउनलोड फ़ोल्डर की फ़ाइलें और दस्तावेज़',
  );
  String get whatsappMediaOnPhone => _t('WhatsApp media on this phone', 'इस फ़ोन पर व्हाट्सएप मीडिया');
  String get allTypes => _t('All types', 'सभी प्रकार');
  String get scanningStorage => _t('Scanning your storage…', 'स्टोरेज की जाँच हो रही है…');
  String get noDuplicatesFound => _t('No duplicate WhatsApp files found.', 'व्हाट्सएप की कोई डुप्लीकेट फ़ाइल नहीं मिली।');
  String get noMediaFound => _t('No WhatsApp media found', 'कोई व्हाट्सएप मीडिया नहीं मिला');
  String get noMediaFoundMsg => _t(
    'Either WhatsApp is not installed, media auto-download is off, or Android has not indexed the files yet.',
    'व्हाट्सएप इंस्टॉल नहीं है, ऑटो-डाउनलोड बंद है या फ़ाइलें अभी इंडेक्स नहीं हुई हैं।',
  );
  String deleteFilesConfirmTitle(int count) => _t(
    'Delete $count file${count == 1 ? '' : 's'}?',
    'क्या आप $count फ़ाइलें हटाना चाहते हैं?',
  );
  String deleteFilesConfirmMsg(String size) => _t(
    'This permanently removes $size and cannot be undone.',
    'यह हमेशा के लिए $size डेटा हटा देगा और इसे वापस नहीं लाया जा सकता।',
  );
  String deleteSuccess(int count) => _t(
    'Deleted $count file${count == 1 ? '' : 's'}.',
    '$count फ़ाइलें डिलीट कर दी गईं।',
  );
  String get deleteCancelled => _t('Delete cancelled.', 'डिलीट रद्द कर दिया गया।');
  String get filesSelected => _t('files selected', 'फ़ाइलें चुनी गईं');
  String get sentByYou => _t('Sent by you', 'आपके द्वारा भेजी गई');

  // WhatsApp Filters & Kinds
  String get filterAll => _t('All', 'सभी');
  String get filterOld => _t('Older than 90 days', '90 दिन से पुराने');
  String get filterLarge => _t('Over 20 MB', '20 MB से बड़े');
  String get filterReceived => _t('Received', 'प्राप्त हुए');
  String get filterSent => _t('Sent', 'भेजे गए');
  String get filterDuplicates => _t('Duplicates', 'एक जैसे');

  String get kindPhotos => _t('Photos', 'फ़ोटो');
  String get kindVideos => _t('Videos', 'वीडियो');
  String get kindGifs => _t('GIFs', 'GIFs');
  String get kindVoiceNotes => _t('Voice notes', 'वॉयस नोट्स');
  String get kindAudio => _t('Audio', 'ऑडियो');
  String get kindDocuments => _t('Documents', 'दस्तावेज़');
  String get kindStickers => _t('Stickers', 'स्टिकर्स');
  String get kindStatuses => _t('Viewed statuses', 'देखे गए स्टेटस');
  String get kindOther => _t('Other', 'अन्य');

  // More Tab
  String get moreTitle => _t('More', 'अन्य टूल्स');
  String get scamProtectionSection => _t('Scam protection', 'ठगी से सुरक्षा');
  String get financeAppsTitle => _t('Bank & loan app check', 'बैंक और लोन ऐप जाँच');
  String get financeAppsSubtitle => _t(
    'Fake banking apps and unregulated lenders on this phone',
    'फ़ोन में नकली बैंकिंग ऐप्स और गैर-कानूनी लोन ऐप्स की पहचान',
  );
  String get toolsSection => _t('Tools', 'टूल्स');
  String get reportsTitle => _t('Reports', 'सुरक्षा रिपोर्ट');
  String get reportsSubtitle => _t(
    'Full breakdown of your security and privacy position',
    'आपकी सुरक्षा और प्राइवेसी स्थिति का पूरा विवरण',
  );
  String get historyTitle => _t('Scan history', 'स्कैन इतिहास');
  String get historySubtitle => _t(
    'Past scans, stored only on this device',
    'पिछली जाँचों का रिकॉर्ड, सिर्फ़ आपके फ़ोन पर',
  );
  String get qrScannerTitle => _t('QR scanner', 'QR स्कैनर');
  String get qrScannerSubtitle => _t(
    'Read a code and check what it points to',
    'QR कोड स्कैन करके देखें वह सुरक्षित है या नहीं',
  );
  String get hardwareTestsTitle => _t('Hardware tests', 'हार्डवेयर टेस्ट');
  String get hardwareTestsSubtitle => _t(
    'Sensor, proximity, compass and torch checks',
    'सेंसर, कंपास, टॉर्च और स्क्रीन टेस्ट',
  );
  String get storageShortcutsSection => _t('Storage shortcuts', 'स्टोरेज शॉर्टकट');
  String get appSection => _t('App', 'ऐप');
  String get privacyPolicyTitle => _t('Privacy policy', 'प्राइवेसी पॉलिसी');
  String get privacyPolicySubtitle => _t(
    'Readable offline; published copy linked inside',
    'ऑफ़लाइन पढ़ें; डेटा हमेशा आपके फ़ोन पर सुरक्षित',
  );

  // Settings
  String get settingsTitle => _t('Settings', 'सेटिंग्स');
  String get forFamilySection => _t('App & Family', 'ऐप और परिवार');
  String get appLanguageTitle => _t('App language', 'ऐप की भाषा');
  String get appLanguageSubtitle => _t(
    'Choose between English and हिन्दी for the entire app',
    'पूरे ऐप के लिए अंग्रेज़ी या हिन्दी चुनें',
  );
  String get simpleModeTitle => _t('Simple mode', 'सरल मोड');
  String get simpleModeSubtitle => _t(
    'Large text and four big buttons. Good for parents and grandparents.',
    'बड़े अक्षर और चार बड़े बटन। माता-पिता और बुजुर्गों के लिए बहुत आसान।',
  );
  String get installAlertsTitle => _t('New app alerts', 'नए ऐप की चेतावनी');
  String get installAlertsSubtitle => _t(
    'Check for newly installed apps and warn when one asks for sensitive access.',
    'नए इंस्टॉल हुए ऐप्स की जाँच करें और संवेदनशील अनुमति मांगने पर चेतावनी दें।',
  );
  String get scamDataSection => _t('Scam data', 'फ़्रॉड डेटा');
  String get checkForUpdatesNow => _t('Check for updates now', 'अपडेट की जाँच करें');
  String get appearanceSection => _t('Appearance', 'थीम और दिखावट');
  String get themeTitle => _t('Theme', 'थीम');
  String get themeSubtitle => _t(
    'Dark mode follows your system setting by default.',
    'डार्क मोड डिफ़ॉल्ट रूप से सिस्टम सेटिंग के अनुसार रहता है।',
  );
  String get themeSystem => _t('System', 'सिस्टम');
  String get themeLight => _t('Light', 'लाइट');
  String get themeDark => _t('Dark', 'डार्क');
  String get scanOptionsSection => _t('Scan options', 'स्कैन विकल्प');
  String get saveHistoryTitle => _t('Save scan history', 'स्कैन इतिहास सुरक्षित रखें');
  String get saveHistorySubtitle => _t(
    'Keeps a local record of each scan.',
    'प्रत्येक जाँच का रिकॉर्ड स्थानीय रूप से सुरक्षित रखता है।',
  );
  String get hapticsTitle => _t('Haptic feedback', 'कंपन (हैप्टिक)');
  String get hapticsSubtitle => _t(
    'A short vibration when a scan or cleanup completes.',
    'स्कैन या सफ़ाई पूरी होने पर हल्का कंपन।',
  );
  String get flagDebuggableTitle => _t('Flag debuggable builds', 'डीबग ऐप्स को चिन्हित करें');
  String get largeFileThresholdSection => _t('Large file threshold', 'बड़ी फ़ाइल सीमा');
  String get flagFilesAbove => _t('Flag files above', 'इससे बड़ी फ़ाइलों को दिखाएं');
  String get privacySection => _t('Privacy', 'प्राइवेसी');
  String get noCloudTitle => _t('No account, no cloud', 'न कोई अकाउंट, न कोई क्लाउड');
  String get noCloudBody => _t(
    'Jemixo Safe has no sign-in, no server and no analytics. Scans, scores, reports and history are all produced and stored on this device. Uninstalling the app removes all of it.',
    'Jemixo Safe में कोई लॉगिन, कोई सर्वर और कोई ट्रैकिंग नहीं है। सभी स्कैन, स्कोर और इतिहास सिर्फ़ आपके फ़ोन पर बनते और रहते हैं। ऐप हटाने पर सब कुछ हट जाता है।',
  );
  String get yourDataSection => _t('Your data', 'आपका डेटा');
  String get storedOnDeviceTitle => _t('Stored on this device', 'इस फ़ोन पर सुरक्षित');
  String get storedOnDeviceSubtitle => _t(
    'You can remove any of it at any time.',
    'आप कभी भी इसे हटा सकते हैं।',
  );
  String get clearHistoryBtn => _t('Clear history', 'इतिहास साफ़ करें');
  String get deleteAllBtn => _t('Delete all', 'सब कुछ हटाएं');
  String get clearHistoryConfirmTitle => _t('Clear scan history?', 'स्कैन इतिहास साफ़ करें?');
  String get clearHistoryConfirmMsg => _t('Past scan records will be removed from this device.', 'पिछली जाँचों का रिकॉर्ड इस डिवाइस से हटा दिया जाएगा।');
  String get clearHistoryDone => _t('History cleared.', 'इतिहास साफ़ कर दिया गया।');
  String get deleteAllConfirmTitle => _t('Delete all app data?', 'ऐप का सारा डेटा हटाएं?');
  String get deleteAllConfirmMsg => _t(
    'Scan history, preferences and every other setting will be erased and the welcome screen will show again. This cannot be undone.',
    'स्कैन इतिहास, प्राथमिकताएँ और सभी सेटिंग्स हटा दी जाएँगी और शुरुआत वाली स्क्रीन दिखेगी। इसे वापस नहीं लाया जा सकता।',
  );
  String get deleteEverythingBtn => _t('Delete everything', 'सब कुछ हटाएं');
  String get listVersionLabel => _t('List version', 'लिस्ट वर्ज़न');
  String get lastCheckedLabel => _t('Last checked', 'पिछली जाँच');
  String get contentsLabel => _t('Contents', 'सामग्री');
  String get neverLabel => _t('Never', 'कभी नहीं');
  String get packageLabel => _t('Package', 'पैकेज');
  String get versionLabel => _t('Version', 'वर्ज़न');
  String get appLabel => _t('App', 'ऐप');
  String get aboutSection => _t('About', 'जानकारी');

  // Emergency & Scam Scanner tools
  String get gotScammedHourSub => _t('What to do in the first hour', 'पहले 1 घंटे में क्या करें');
  String get call1930Now => _t('Call 1930 now', '1930 पर तुरंत कॉल करें');
  String get dial1930 => _t('Dial 1930', '1930 डायल करें');
  String get enterMessageHint => _t(
    'Paste an SMS, WhatsApp message or telegram text here…',
    'यहाँ SMS, WhatsApp या कोई भी संदिग्ध मैसेज पेस्ट करें…',
  );
  String get senderLabel => _t('Sender / Header (optional)', 'भेजने वाला / हेडर (वैकल्पिक)');
  String get senderHint => _t('e.g. VK-SBIINB or a phone number', 'उदा. VK-SBIINB या फ़ोन नंबर');
  String get checkPhoneSubtitleTop => _t('Who can really be calling from it?', 'इस नंबर से कौन कॉल कर सकता है?');
  String get screenshotOcrSubtitle => _t(
    'Text is read on the phone, never uploaded',
    'टेक्स्ट फ़ोन पर ही पढ़ा जाता है, कहीं अपलोड नहीं होता',
  );

  // Simple mode
  String get simpleTitle => _t(
    'Got a message, link or QR code you are not sure about?',
    'कोई मैसेज, लिंक या QR कोड जिस पर शक है?',
  );
  String get simpleSubtitle => _t(
    'Check it here before you reply, pay or click. Nothing leaves your phone.',
    'जवाब देने, पैसे भेजने या क्लिक करने से पहले यहाँ जाँचें। कुछ भी फ़ोन से बाहर नहीं जाता।',
  );
  String get checkMessage => _t('Check a message', 'मैसेज जाँचें');
  String get checkMessageSub => _t('Paste an SMS or WhatsApp text', 'SMS या WhatsApp का टेक्स्ट पेस्ट करें');
  String get checkScreenshot => _t('Check a screenshot', 'स्क्रीनशॉट जाँचें');
  String get checkScreenshotSub => _t('Pick a screenshot; the text is read on the phone', 'स्क्रीनशॉट चुनें; टेक्स्ट फ़ोन पर ही पढ़ा जाता है');
  String get checkLink => _t('Check a link', 'लिंक जाँचें');
  String get checkLinkSub => _t('Before you tap it', 'क्लिक करने से पहले');
  String get checkQr => _t('Check a QR code', 'QR कोड जाँचें');
  String get checkQrSub => _t('See who gets paid before you scan in your UPI app', 'UPI ऐप में स्कैन करने से पहले देखें पैसा किसे जाएगा');
  String get checkCaller => _t('Check a phone number', 'फ़ोन नंबर जाँचें');
  String get checkCallerSub => _t('Bank, police or courier? See if the number fits', 'बैंक, पुलिस या कूरियर? देखें नंबर सही है या नहीं');
  String get checkClipboard => _t('Check what I just copied', 'जो अभी कॉपी किया, उसे जाँचें');
  String get checkClipboardSub => _t('Uses the last text on your clipboard', 'क्लिपबोर्ड का आखिरी टेक्स्ट इस्तेमाल होगा');
  String get scamCallNow => _t('Someone is calling and threatening me', 'कोई कॉल पर धमका रहा है');
  String get scamCallNowSub => _t('Police, CBI, customs, bank… read this first', 'पुलिस, CBI, कस्टम, बैंक… पहले यह पढ़ें');
  String get gotScammed => _t('I think I got scammed', 'लगता है मेरे साथ ठगी हुई है');
  String get gotScammedSub => _t('Call 1930 and freeze the money', '1930 पर कॉल करें और पैसा रुकवाएँ');
  String get fullApp => _t('Full app', 'पूरा ऐप');
  String get threeRulesTitle => _t('Three rules that stop most scams', 'तीन नियम जो ज़्यादातर ठगी रोक देते हैं');
  String get rule1 => _t(
    '1. Nobody genuine ever asks for your OTP or PIN.',
    '1. कोई भी असली संस्था कभी OTP या PIN नहीं माँगती।',
  );
  String get rule2 => _t(
    '2. Scanning a QR or approving a request only sends money out.',
    '2. QR स्कैन करने या रिक्वेस्ट मंज़ूर करने से पैसा सिर्फ़ जाता है, आता नहीं।',
  );
  String get rule3 => _t(
    '3. Police, banks and courier companies do not threaten you on the phone. Hang up and call them back on the official number.',
    '3. पुलिस, बैंक और कूरियर कंपनियाँ फ़ोन पर धमकाती नहीं। कॉल काटें और आधिकारिक नंबर पर खुद कॉल करें।',
  );
  String get nothingCopied => _t(
    'Nothing is copied right now. Copy the message first.',
    'अभी कुछ कॉपी नहीं है। पहले मैसेज कॉपी करें।',
  );

  // Scam call panic card
  String get panicTitle => _t('Scam call? Read this now.', 'ठगी की कॉल? अभी यह पढ़ें।');
  String get panicHangUp => _t('Hang up. Right now.', 'कॉल काट दें। अभी।');
  String get panicHangUpBody => _t(
    'No police, CBI, customs, court or bank arrests or fines anyone over a phone or video call. "Digital arrest" does not exist in law. Ending the call is always safe.',
    'कोई पुलिस, CBI, कस्टम, कोर्ट या बैंक फ़ोन या वीडियो कॉल पर गिरफ़्तार या जुर्माना नहीं करता। "डिजिटल अरेस्ट" कानून में है ही नहीं। कॉल काटना हमेशा सुरक्षित है।',
  );
  String get panicNoPay => _t('Do not pay, do not share, do not install', 'न पैसा भेजें, न कुछ बताएँ, न कुछ इंस्टॉल करें');
  String get panicNoPayBody => _t(
    'No OTP, PIN, Aadhaar, card number or "verification deposit". No AnyDesk, TeamViewer or any app they send. Money sent to "verify" or "release a parcel" is gone.',
    'OTP, PIN, आधार, कार्ड नंबर या "वेरिफ़िकेशन डिपॉज़िट" कुछ नहीं। AnyDesk, TeamViewer या उनका भेजा कोई ऐप नहीं। "वेरिफ़ाई" या "पार्सल छुड़ाने" के लिए भेजा पैसा वापस नहीं आता।',
  );
  String get panicTell => _t('Tell someone', 'किसी को बताएँ');
  String get panicTellBody => _t(
    'Scammers insist on secrecy because one phone call to a family member ends the scam. Speak to someone before doing anything.',
    'ठग गोपनीयता पर ज़ोर देते हैं क्योंकि घर के किसी एक को फ़ोन करते ही ठगी खत्म हो जाती है। कुछ भी करने से पहले किसी से बात करें।',
  );
  String get panicVerify => _t('Verify on your own', 'खुद जाँचें');
  String get panicVerifyBody => _t(
    'Look up the organisation\'s number yourself (bank card, official website) and call it. Never call back the number that called you.',
    'संस्था का नंबर खुद खोजें (बैंक कार्ड, आधिकारिक वेबसाइट) और वहाँ कॉल करें। जिस नंबर से कॉल आई, उस पर कभी वापस कॉल न करें।',
  );
  String get panicDial => _t('Dial 1930 (Cyber Crime Helpline)', '1930 डायल करें (साइबर क्राइम हेल्पलाइन)');
  String get panicAlreadyPaid => _t('Already sent money? Open "I got scammed"', 'पैसा भेज चुके हैं? "मेरे साथ ठगी हुई" खोलें');
  String get panicShare => _t('Share this card with family', 'यह कार्ड परिवार को भेजें');
  String get panicScripts => _t('Lines scammers use', 'ठग जो लाइनें बोलते हैं');
  List<String> get panicScriptLines => isHindi
      ? const [
          '"आपके नाम का पार्सल पकड़ा गया है, उसमें ड्रग्स हैं।"',
          '"आपका आधार मनी लॉन्ड्रिंग में इस्तेमाल हुआ है।"',
          '"वीडियो कॉल पर रहें, वरना गिरफ़्तारी होगी।"',
          '"पैसा सुरक्षित खाते में ट्रांसफ़र करें, जाँच के बाद वापस मिलेगा।"',
          '"यह गोपनीय है, किसी को मत बताना।"',
        ]
      : const [
          '"A parcel in your name was caught with drugs."',
          '"Your Aadhaar was used for money laundering."',
          '"Stay on the video call or you will be arrested."',
          '"Transfer the money to a safe account; it will be returned after verification."',
          '"This is confidential, do not tell anyone."',
        ];
}
