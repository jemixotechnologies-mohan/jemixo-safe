import 'package:flutter/material.dart';

/// Sensitive-permission taxonomy.
///
/// Android exposes hundreds of permissions; only a subset meaningfully changes
/// a user's privacy posture, so we group them into the categories the UI
/// presents. Anything unrecognised lands in [PermissionCategory.other] rather
/// than being silently dropped.
enum PermissionCategory {
  camera,
  microphone,
  location,
  contacts,
  phone,
  sms,
  notifications,
  photos,
  videos,
  files,
  calendar,
  nearbyDevices,
  sensors,
  other;

  String get label => switch (this) {
    PermissionCategory.camera => 'Camera',
    PermissionCategory.microphone => 'Microphone',
    PermissionCategory.location => 'Location',
    PermissionCategory.contacts => 'Contacts',
    PermissionCategory.phone => 'Phone',
    PermissionCategory.sms => 'SMS',
    PermissionCategory.notifications => 'Notifications',
    PermissionCategory.photos => 'Photos & Media',
    PermissionCategory.videos => 'Videos',
    PermissionCategory.files => 'Files & Storage',
    PermissionCategory.calendar => 'Calendar',
    PermissionCategory.nearbyDevices => 'Nearby Devices',
    PermissionCategory.sensors => 'Body & Sensors',
    PermissionCategory.other => 'Other',
  };

  IconData get icon => switch (this) {
    PermissionCategory.camera => Icons.photo_camera_outlined,
    PermissionCategory.microphone => Icons.mic_none_rounded,
    PermissionCategory.location => Icons.location_on_outlined,
    PermissionCategory.contacts => Icons.contacts_outlined,
    PermissionCategory.phone => Icons.call_outlined,
    PermissionCategory.sms => Icons.sms_outlined,
    PermissionCategory.notifications => Icons.notifications_none_rounded,
    PermissionCategory.photos => Icons.image_outlined,
    PermissionCategory.videos => Icons.videocam_outlined,
    PermissionCategory.files => Icons.folder_outlined,
    PermissionCategory.calendar => Icons.calendar_today_outlined,
    PermissionCategory.nearbyDevices => Icons.bluetooth_searching,
    PermissionCategory.sensors => Icons.monitor_heart_outlined,
    PermissionCategory.other => Icons.apps_rounded,
  };

  /// Weight used by the privacy score. Reading sensors and location is treated
  /// as more invasive than, say, posting a notification.
  int get sensitivityWeight => switch (this) {
    PermissionCategory.location => 3,
    PermissionCategory.sms => 3,
    PermissionCategory.phone => 3,
    PermissionCategory.contacts => 3,
    PermissionCategory.microphone => 2,
    PermissionCategory.camera => 2,
    PermissionCategory.nearbyDevices => 2,
    PermissionCategory.sensors => 2,
    PermissionCategory.photos => 1,
    PermissionCategory.videos => 1,
    PermissionCategory.files => 1,
    PermissionCategory.calendar => 1,
    PermissionCategory.notifications => 0,
    PermissionCategory.other => 0,
  };
}

class PermissionDefinition {
  const PermissionDefinition({
    required this.androidName,
    required this.category,
    required this.title,
    required this.why,
  });

  final String androidName;
  final PermissionCategory category;
  final String title;
  final String why;
}

/// Curated list of permissions worth surfacing to a non-technical user.
const kSensitivePermissions = <PermissionDefinition>[
  PermissionDefinition(
    androidName: 'android.permission.CAMERA',
    category: PermissionCategory.camera,
    title: 'Camera',
    why: 'Can take photos and record video.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.RECORD_AUDIO',
    category: PermissionCategory.microphone,
    title: 'Microphone',
    why: 'Can record audio, including calls in some versions.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.ACCESS_FINE_LOCATION',
    category: PermissionCategory.location,
    title: 'Precise location',
    why: 'Can see your exact position.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.ACCESS_COARSE_LOCATION',
    category: PermissionCategory.location,
    title: 'Approximate location',
    why: 'Can see your approximate position.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.ACCESS_BACKGROUND_LOCATION',
    category: PermissionCategory.location,
    title: 'Background location',
    why: 'Can keep tracking location while closed.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.READ_CONTACTS',
    category: PermissionCategory.contacts,
    title: 'Read contacts',
    why: 'Can read your contact list.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.WRITE_CONTACTS',
    category: PermissionCategory.contacts,
    title: 'Modify contacts',
    why: 'Can add, change or delete contacts.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.GET_ACCOUNTS',
    category: PermissionCategory.contacts,
    title: 'Device accounts',
    why: 'Can list the accounts signed in on this phone.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.READ_CALL_LOG',
    category: PermissionCategory.phone,
    title: 'Call history',
    why: 'Can read your call log.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.WRITE_CALL_LOG',
    category: PermissionCategory.phone,
    title: 'Modify call history',
    why: 'Can change or delete entries in your call log.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.READ_PHONE_STATE',
    category: PermissionCategory.phone,
    title: 'Phone & device identity',
    why: 'Can read phone number, carrier and device identifiers.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.READ_PHONE_NUMBERS',
    category: PermissionCategory.phone,
    title: 'Phone number',
    why: 'Can read the phone numbers on this device.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.CALL_PHONE',
    category: PermissionCategory.phone,
    title: 'Make calls',
    why: 'Can place calls without you tapping.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.ANSWER_PHONE_CALLS',
    category: PermissionCategory.phone,
    title: 'Answer calls',
    why: 'Can answer incoming calls.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.READ_SMS',
    category: PermissionCategory.sms,
    title: 'Read SMS',
    why: 'Can read your text messages.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.RECEIVE_SMS',
    category: PermissionCategory.sms,
    title: 'Receive SMS',
    why: 'Can read incoming text messages before you see them.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.SEND_SMS',
    category: PermissionCategory.sms,
    title: 'Send SMS',
    why: 'Can send text messages, which may cost money.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.RECEIVE_MMS',
    category: PermissionCategory.sms,
    title: 'Receive MMS',
    why: 'Can read incoming picture messages.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.POST_NOTIFICATIONS',
    category: PermissionCategory.notifications,
    title: 'Notifications',
    why: 'Can show notifications on your screen.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.READ_MEDIA_IMAGES',
    category: PermissionCategory.photos,
    title: 'Read photos',
    why: 'Can read the photos saved on your phone.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.READ_MEDIA_VIDEO',
    category: PermissionCategory.videos,
    title: 'Read videos',
    why: 'Can read the videos saved on your phone.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.READ_MEDIA_AUDIO',
    category: PermissionCategory.photos,
    title: 'Read audio files',
    why: 'Can read music and recordings saved on your phone.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.READ_EXTERNAL_STORAGE',
    category: PermissionCategory.files,
    title: 'Read files',
    why: 'Can read files in shared storage.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.WRITE_EXTERNAL_STORAGE',
    category: PermissionCategory.files,
    title: 'Modify files',
    why: 'Can create and change files in shared storage.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.MANAGE_EXTERNAL_STORAGE',
    category: PermissionCategory.files,
    title: 'All files access',
    why: 'Can read, change and delete any file on your phone.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.READ_CALENDAR',
    category: PermissionCategory.calendar,
    title: 'Read calendar',
    why: 'Can read your calendar events.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.WRITE_CALENDAR',
    category: PermissionCategory.calendar,
    title: 'Modify calendar',
    why: 'Can add or change calendar events.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.BLUETOOTH_CONNECT',
    category: PermissionCategory.nearbyDevices,
    title: 'Connect to Bluetooth',
    why: 'Can communicate with nearby Bluetooth devices.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.BLUETOOTH_SCAN',
    category: PermissionCategory.nearbyDevices,
    title: 'Scan for Bluetooth',
    why: 'Can discover nearby Bluetooth devices.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.NEARBY_WIFI_DEVICES',
    category: PermissionCategory.nearbyDevices,
    title: 'Nearby Wi-Fi',
    why: 'Can detect nearby Wi-Fi networks.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.BODY_SENSORS',
    category: PermissionCategory.sensors,
    title: 'Body sensors',
    why: 'Can read heart rate and similar body data.',
  ),
  PermissionDefinition(
    androidName: 'android.permission.ACTIVITY_RECOGNITION',
    category: PermissionCategory.sensors,
    title: 'Physical activity',
    why: 'Can tell whether you are moving.',
  ),
];

final _permissionIndex = {
  for (final p in kSensitivePermissions) p.androidName: p,
};

/// Resolves an Android permission string into a curated definition, or null
/// when it is not privacy-relevant enough to show.
PermissionDefinition? resolvePermission(String androidName) =>
    _permissionIndex[androidName];

PermissionCategory categoryFor(String androidName) =>
    _permissionIndex[androidName]?.category ?? PermissionCategory.other;

String permissionTitle(String androidName) =>
    _permissionIndex[androidName]?.title ?? _humanisePermission(androidName);

/// Turns `android.permission.READ_SMS` into `Read sms` for permissions outside
/// the curated list, so nothing displays as a raw constant.
String _humanisePermission(String androidName) {
  final short = androidName
      .split('.')
      .last
      .replaceAll('_', ' ')
      .toLowerCase()
      .trim();
  if (short.isEmpty) return androidName;
  return short[0].toUpperCase() + short.substring(1);
}

/// Permissions that grant powerful capabilities on their own.
const kElevatedPermissions = <String>{
  'android.permission.BIND_ACCESSIBILITY_SERVICE',
  'android.permission.BIND_DEVICE_ADMIN',
  'android.permission.SYSTEM_ALERT_WINDOW',
  'android.permission.BIND_NOTIFICATION_LISTENER_SERVICE',
  'android.permission.REQUEST_INSTALL_PACKAGES',
  'android.permission.PACKAGE_USAGE_STATS',
  'android.permission.QUERY_ALL_PACKAGES',
  'android.permission.BIND_VPN_SERVICE',
  'android.permission.READ_LOGS',
};

bool isElevatedPermission(String androidName) =>
    kElevatedPermissions.contains(androidName);

/// Short human title for an elevated permission.
String elevatedPermissionTitle(String androidName) => switch (androidName) {
  'android.permission.BIND_ACCESSIBILITY_SERVICE' => 'accessibility service',
  'android.permission.BIND_DEVICE_ADMIN' => 'device administrator',
  'android.permission.SYSTEM_ALERT_WINDOW' => 'draw over other apps',
  'android.permission.BIND_NOTIFICATION_LISTENER_SERVICE' =>
    'notification access',
  'android.permission.REQUEST_INSTALL_PACKAGES' => 'install other apps',
  'android.permission.PACKAGE_USAGE_STATS' => 'usage access',
  'android.permission.QUERY_ALL_PACKAGES' => 'see all installed apps',
  'android.permission.BIND_VPN_SERVICE' => 'VPN service',
  'android.permission.READ_LOGS' => 'read system logs',
  _ => _humanisePermission(androidName).toLowerCase(),
};
