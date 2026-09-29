# Play Console submission pack — Jemixo Safe 1.1.0

Everything below is ready to paste. Replace the two placeholders (privacy
policy URL, contact email) before submitting.

## App details

- **App name:** Jemixo Safe – Scam & Fraud Check
- **Category:** Tools (alternative: Finance is not appropriate; Tools keeps the "device security" framing)
- **Contact email:** `<your email>`
- **Privacy policy URL:** `<https://…/privacy-policy.html>` (publish `docs/privacy-policy.html`)
- **Ads:** No ads
- **Content rating:** IARC questionnaire → no violence, no user interaction, no data sharing → "Everyone"

## Short description (80 chars)

EN: `Check scam messages, links, QR codes, calls & fake bank apps. Offline. Free.`

HI: `स्कैम मैसेज, लिंक, QR, कॉल और नकली बैंक ऐप जाँचें। ऑफ़लाइन, मुफ़्त।`

## Full description

```
Jemixo Safe checks the things scammers send you — before you reply, click or pay.

MESSAGE & SCREENSHOT CHECK
• Paste an SMS or WhatsApp text, or share a screenshot. Text is read on your phone (English + Hindi) and matched against 350+ scam patterns: KYC, "digital arrest", lottery, job, electricity-bill and OTP tricks.
• Sender check: real banks send from registered IDs (AX-SBIINB). A 10-digit or foreign number claiming to be a bank is flagged instantly.
• "Check with Jemixo Safe" appears when you select text in any app.

LINK & QR CHECK
• Link checker spots look-alike domains, shortened links, punycode and brand impersonation, and shows a "Verified official domain" badge for 200+ real bank, government, courier and utility sites.
• Reveal where a short link goes without opening it.
• Scan a payment QR and see plainly: "You would PAY ₹500 to …". No QR ever gives you money.

FAKE BANK & LOAN APP DETECTOR
• Finds apps that use a bank, UPI or government name without being the official package.
• Flags loan apps that are not run by RBI-regulated lenders.
• Shows every app that can read your screen (accessibility), read your notifications or act as device admin — the access banking trojans depend on — plus hidden apps with spying-type permissions.
• Optional alert when a new sideloaded app asks for SMS or contacts.

WHEN IT IS ALREADY HAPPENING
• "Scam call?" card: the four things to do while they are still talking.
• "I got scammed": dial 1930, bank and UPI helplines, first-hour checklist. In Hindi too.

FOR PARENTS
• Simple mode: large text, big buttons, Hindi.

ALSO
• Phone safety check with plain-language risk indicators (not an antivirus).
• Clean up large videos, duplicates and old screenshots.
• Battery, storage and network health. PDF report.

PRIVACY
No account. No server. No ads. Nothing is uploaded. Scam patterns and official-site lists update weekly from a static file; the request carries no device data.

Jemixo Safe shows risk indicators based on what Android exposes. It does not claim to detect malware and it never deletes or uninstalls anything without your confirmation.
```

## Permissions declarations

### QUERY_ALL_PACKAGES (Sensitive permission declaration)

- **Core purpose:** Device security / anti-fraud. The app's primary function
  is to review installed apps for fake bank/payment apps (brand name on a
  non-official package), unregulated loan apps, hidden apps with spying-type
  permissions and risky permission combinations. This requires the full
  package list; the launcher-visible subset would hide exactly the apps that
  matter (background-only spyware).
- **Video:** record 30–45 s showing: Home → Safety check runs → "Apps with
  special access" screen → "Bank & loan app check" screen → tap a flagged app
  → details with the indicators. Show that no data leaves the device
  (Settings → Privacy section).
- **Fallback if refused:** delete the permission line from
  `AndroidManifest.xml`; the scanner merges the launcher query and the UI
  states that only apps with an icon were checked.

### Photos and videos (READ_MEDIA_IMAGES / VIDEO)

Used only when the user opens Clean (large files, duplicates, screenshots)
or "Check a screenshot". Requested in context, never at launch.

### POST_NOTIFICATIONS

Only when the user enables "New app alerts" in Settings.

### CAMERA

QR scanner only.

## Data safety form

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | N/A (no collection) |
| Do you provide a way for users to request that their data is deleted? | N/A; all data is local and removed on uninstall (also "Delete all" in Settings) |
| Independent security review | No |

Note for reviewers (optional text): "The app performs all analysis on the
device. Its only network request is a weekly GET of a static JSON file
(scam phrases / official-site list) with no identifiers."

## Store assets checklist

- Icon 512×512 (existing launcher icon, no shield-with-virus imagery).
- Feature graphic 1024×500: phone with "Scam message? Check it first." and the
  four buttons of simple mode.
- Screenshots (phone, 6–8): Home with Safety score and Scam Radar · Message
  check with matched phrases · Screenshot check grid · UPI QR "You would PAY"
  · Bank & loan app check · Apps with special access · Scam call card (Hindi)
  · Simple mode.
- Do not use the words "antivirus", "virus", "malware" anywhere in the listing.

## Release notes (1.1.0)

```
New: screenshot check (on-device OCR, English + Hindi), fake bank/loan app detector, apps with special access, caller-number check, scam-call card, "I got scammed" flow, share result cards, text-selection action, home widget, simple mode in Hindi.
Improved: safety scan runs in the background, no all-files access needed, faster storage lists.
```

## Build

```bash
flutter build appbundle --release
# upload build/app/outputs/bundle/release/app-release.aab
```
