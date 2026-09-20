# GitHub Actions secrets (Nordi Production)

Create a **Production** environment on `OmiSU-Dev/OmiSU` and add:

| Name | Value |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 android/app/release.jks` from the machine that signs Wi‑Fi deploys |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key password |

Optional (NeoStation workflow only): `SCREENSCRAPER_DEV_ID`, `SCREENSCRAPER_DEV_PASSWORD`.

The **Nordi Android (main)** workflow fails fast if the keystore secret is missing. OTA installs on the N30 will fail signature checks if CI uses a different key than the APK already on the device.
