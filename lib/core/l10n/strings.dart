import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../state/settings_controller.dart';

/// Strings for the family-facing surfaces (simple mode, emergency screens,
/// verdict labels). The rest of the app stays English for now; these are the
/// screens a parent or grandparent actually sees.
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
