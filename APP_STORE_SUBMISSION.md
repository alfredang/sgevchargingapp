# App Store Submission Notes

## Current Build Artifacts

- Archive: `/tmp/SGEVCharging.xcarchive`
- IPA: `/tmp/sgevcharging-export/SGEVCharging.ipa`
- iPhone 6.9 screenshot: `/tmp/sgevcharging-screenshots/iphone_69_1290x2796.png`
- iPhone 6.5 screenshot: `/tmp/sgevcharging-screenshots/iphone_65_1242x2688.png`
- iPad 13 screenshot: `/tmp/sgevcharging-screenshots/ipad_13_2064x2752.png`
- Metadata copy: `AppStoreMetadata/en-US/`
- Review notes: `AppStoreMetadata/review_notes.txt`

## App Identity

- App name: `SG EV Charging`
- Bundle ID: `com.alfredang.sgevcharging`
- SKU suggestion: `sgevcharging-2026`
- Version/build: `1.0` / `1`
- Team ID: `GU9WTSTX9M`
- Category suggestion: `Navigation`
- Local build config: `Config.xcconfig` must be present and passed to `xcodebuild`
  so `LTA_DATAMALL_ACCOUNT_KEY` is embedded in `Info.plist`.

## Local App Store Prep Completed

- Release archive and App Store Connect IPA export succeeded.
- Explicit Bundle ID was created in Apple Developer resources.
- App Store provisioning profile was created and installed:
  `SG EV Charging App Store Distribution`
- 1024x1024 no-alpha app icon was added.
- `PrivacyInfo.xcprivacy` was added.
- `ITSAppUsesNonExemptEncryption` is set to `false`.
- iPhone and iPad orientations are explicitly declared.
- Location permission copy is present.
- App Store metadata copy and review notes are prepared under `AppStoreMetadata/`.

## Current Blocker

App Store Connect does not yet have an app record for `com.alfredang.sgevcharging`.

Evidence:

```text
altool: Cannot determine the Apple ID from Bundle ID 'com.alfredang.sgevcharging' and platform 'IOS'.
```

The installed App Store Connect API key can read apps, bundle IDs, certificates, and profiles,
but Apple returned `403 FORBIDDEN_ERROR` for `POST /v1/apps`, so the app record must be created
manually in App Store Connect or with an account/API capability that can create apps.

## Required Portal Step

In App Store Connect:

1. Go to `My Apps`.
2. Create a new iOS app.
3. Use bundle ID `com.alfredang.sgevcharging`.
4. Use name `SG EV Charging`.
5. Use SKU `sgevcharging-2026`.
6. Set primary language to English.
7. Complete App Privacy, age rating, and content rights declarations.

After the app record exists, validate/upload:

```sh
set -a; source /Users/alfredang/projects/mobile/iOS/fractalapp/.env; set +a
xcodegen generate
xcodebuild -project SGEVCharging.xcodeproj -scheme SGEVCharging -configuration Release \
  -destination 'generic/platform=iOS' -archivePath /tmp/SGEVCharging.xcarchive \
  -xcconfig Config.xcconfig archive \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_PRIVATE_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"
xcodebuild -exportArchive -archivePath /tmp/SGEVCharging.xcarchive \
  -exportPath /tmp/sgevcharging-export -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates \
  -authenticationKeyPath "$ASC_PRIVATE_KEY_PATH" \
  -authenticationKeyID "$ASC_KEY_ID" \
  -authenticationKeyIssuerID "$ASC_ISSUER_ID"
xcrun altool --validate-app -f /tmp/sgevcharging-export/SGEVCharging.ipa -t ios --api-key "$ASC_KEY_ID" --api-issuer "$ASC_ISSUER_ID"
xcrun altool --upload-app -f /tmp/sgevcharging-export/SGEVCharging.ipa -t ios --api-key "$ASC_KEY_ID" --api-issuer "$ASC_ISSUER_ID"
```

## Suggested App Privacy Answers

The app does not create accounts and does not collect personal data in its own backend.
It requests location permission to find nearby charging points, but the location is used on
device for the immediate app feature and is not stored by this app.

In App Store Connect, use the App Privacy UI to declare the actual behavior. If no additional
analytics, ads, crash reporting, or backend logging is added, the expected declaration is:

- Data collected: No data collected.
- Tracking: No.

## Suggested Age Rating / Content Rights

- Age rating: suitable for all ages, assuming no additional content is added.
- Content rights: the app uses LTA DataMall public API data and Apple Maps; no third-party
  copyrighted media is included beyond platform-provided maps.
