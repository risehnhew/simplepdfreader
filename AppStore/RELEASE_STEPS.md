# Release Steps

These steps assume you have an active Apple Developer Program membership and access to App Store Connect.

## 1. Create App Store Connect Records

Xcode has already created the explicit Bundle ID/App ID and an App Store provisioning profile for `com.weihe.simplepdfreader` under Team ID `8777RK2R8M`.

Create a new app in App Store Connect using:

- Platform: iOS
- Name: `SimpPDF Reader`
- Primary language: English (U.S.)
- Bundle ID: `com.weihe.simplepdfreader`
- SKU: `simplepdf-reader-ios`
- User access: Full Access

After the app record exists, add the category, age rating, support URL, privacy policy URL, screenshots, and metadata from `AppStore/APP_STORE_METADATA.md`.

### Apple Developer Bundle ID Path

1. Go to `https://developer.apple.com/account/resources/identifiers/list`.
2. Click the add button.
3. Select App IDs.
4. Select App.
5. Description: `SimpPDF Reader`.
6. Bundle ID type: Explicit.
7. Bundle ID: `com.weihe.simplepdfreader`.
8. Do not enable extra capabilities for v1.
9. Register.

## 1.5 Publish Privacy and Support Pages

Fast GitHub Pages path:

1. Create a public GitHub repository named `simplepdfreader`.
2. Push this local repository to GitHub.
3. In GitHub, open Settings > Pages.
4. Source: Deploy from a branch.
5. Branch: `main`.
6. Folder: `/docs`.
7. Save.

After GitHub Pages is live, use:

- Privacy Policy URL: `https://risehnhew.github.io/simplepdfreader/privacy.html`
- Support URL: `https://risehnhew.github.io/simplepdfreader/support.html`

These pages are already live on GitHub Pages.

## 2. Configure Signing

Open `SimplePDFReader.xcodeproj` in Xcode and set:

- Team: your Apple Developer team
- Current local Team ID: `8777RK2R8M` (`Wei He`)
- Bundle Identifier: `com.weihe.simplepdfreader`
- Version: `1.0`
- Build: increment for every upload

## 3. Validate Locally

```bash
xcodebuild -project SimplePDFReader.xcodeproj -scheme SimplePDFReader -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4' test
xcodebuild -project SimplePDFReader.xcodeproj -scheme SimplePDFReader -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

## 4. Archive

Use Xcode:

1. Select `Any iOS Device`.
2. Choose Product > Archive.
3. In Organizer, choose Validate App.
4. Fix any signing, metadata, or entitlement issues.
5. Choose Distribute App > App Store Connect > Upload.

Or use command line after signing is configured:

```bash
xcodebuild -project SimplePDFReader.xcodeproj \
  -scheme SimplePDFReader \
  -destination 'generic/platform=iOS' \
  -archivePath build/SimplePDFReader.xcarchive \
  archive
```

Upload through Xcode Organizer or Apple’s current upload tool.

If command-line export stalls at `codesign`, approve the local macOS Keychain prompt for the Apple Distribution certificate or use Xcode Organizer, which surfaces the same approval flow in the UI.

## 5. TestFlight

1. Wait for processing in App Store Connect.
2. Add the build to TestFlight.
3. Test import, reader, search, bookmarks, sharing, delete, reset, iPhone, and iPad layouts.
4. Fix any crash or review-blocking issue before App Review submission.

## 6. Submit for Review

1. Attach the tested build to the app version.
2. Complete privacy, export-compliance, content-rights, and review-contact sections.
3. Submit for App Review.
