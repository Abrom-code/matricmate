# MatricET Privacy Policy

*Effective Date: September 2026*

> **Disclaimer:** MatricET is an independent educational examination preparation platform developed by Abopia. It is **not** an official government application and is **not** affiliated with, endorsed by, or operated by the Ministry of Education of Ethiopia, the Educational Assessment and Examinations Service (EAES), or any governmental authority. All educational references and examination curricula are based on publicly available educational curricula.

---

## 1. Introduction
This Privacy Policy describes how **Abopia** ("we", "us", or "our") collects, uses, and safeguards information when you use the **MatricET** mobile application (Android Package ID: `com.abopia.matricet`).

---

## 2. Information We Collect

| Category | Specific Data | Purpose |
|---|---|---|
| **Account Information** | Name (First & Last), Email Address, Password (hashed securely) | User authentication, account recovery, profile display. |
| **Educational Stream** | Stream preference (Natural Science / Social Science) | Filtering relevant subjects, tests, and entrance exams. |
| **Device & Session Identifier** | App-generated UUID (randomly generated, not a hardware IMEI) | Single-device session security and preventing unauthorized account takeover. |
| **Push Notifications** | Firebase Cloud Messaging (FCM) registration token | Delivering study announcements, challenge updates, and payment status alerts. |
| **Academic Progress** | Test answers, scores, bookmarks, timer remaining, completion status | Local and remote test result reviews, analytics, and resume-in-progress features. |
| **Payment Verification Proof** | User-uploaded transaction receipt screenshots, payment method name | Manual verification of bank/mobile money subscriptions by administrators. |

---

## 3. Information We Do NOT Collect
MatricET does **not** collect:
- Precise or approximate GPS location.
- Device hardware serial numbers, IMEI, or MAC address.
- Contact lists, phone logs, or SMS content.
- Microphone or camera recordings.
- Advertising identifiers (no advertising SDKs or third-party ad networks are used).

---

## 4. How Information is Processed & Third-Party Services
We do not sell, rent, or trade your personal data. Data is processed securely through trusted infrastructure providers:
- **Supabase Inc. (Backend & Authentication):** Stores user accounts, encrypted passwords, relational test data, and receipt files over encrypted HTTPS/TLS connections.
- **Google Firebase Cloud Messaging (FCM):** Delivers encrypted push notifications to your device. No user profile data or test scores are shared with Firebase.

---

## 5. Data Retention & Deletion
We retain your personal data for as long as your account is active. You have the right to permanently delete your account and all associated data at any time:
- **In-App Deletion:** Open MatricET → Profile → Settings → Delete Account. Deletion is instantaneous and cascades through all database records.
- **Web Deletion:** You can submit a deletion request via our Account Deletion page (`docs/account_deletion.html`) or by contacting `[INSERT_YOUR_SUPPORT_EMAIL_HERE]`.

---

## 6. Children & Student Privacy
MatricET is designed for Ethiopian secondary school students (typically Grade 9 through 12, ages 14 to 18) preparing for university entrance examinations. We do not knowingly collect personal data from children under the age of 13.

---

## 7. Security of Your Information
All communication between the MatricET app and backend servers is encrypted in transit using Transport Layer Security (TLS 1.3/HTTPS). Row-Level Security (RLS) policies restrict database queries so users can only access their own educational data.

---

## 8. Contact Us
If you have questions about this Privacy Policy or your data, please contact:

**Abopia Software**  
Email: `[INSERT_YOUR_SUPPORT_EMAIL_HERE]`  
Website: `[INSERT_YOUR_WEBSITE_URL_HERE]`  
Application: **MatricET** (`com.abopia.matricet`)
