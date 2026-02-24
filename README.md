# Ingenes iOS App

Native iOS app for Ingenes management system built with Swift and SwiftUI.

## Requirements

- macOS Sonoma 14.0+ or Ventura 13.0+
- Xcode 15.0+
- iOS 15.0+ deployment target
- Apple Developer account (for device testing)

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. File → New → Project
3. Select: iOS → App
4. Configure:
   - **Product Name:** Ingenes
   - **Bundle Identifier:** mx.itgroup.ingenes
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Include Tests:** Yes (both Unit and UI)
5. Save to this directory

### 2. Add Source Files

After creating the Xcode project:

1. Delete the auto-generated ContentView.swift and IngenesApp.swift
2. Drag the following folders into your Xcode project:
   - `App/`
   - `Core/`
   - `Domain/`
   - `Services/`
   - `Features/`
   - `SharedUI/`
   - `Resources/`

3. Ensure "Copy items if needed" is **unchecked**
4. Ensure "Create groups" is **selected**

### 3. Add Dependencies

1. File → Add Package Dependencies
2. Add: `https://github.com/kishikawakatsumi/KeychainAccess`
3. Version: Up to Next Major (4.2.0)

### 4. Add Assets

1. In Xcode, go to Assets.xcassets
2. Drag `Resources/logo.png` to create an image set named "logo"
3. Add color sets for:
   - `PrimaryGreen` (#2E7D32)

4. Copy `Resources/Audio/greatjob.mp3` to your project

### 5. Configure FileMaker Credentials

Create `Debug.xcconfig` in project root:

```
FILEMAKER_BASE_URL = https://your-filemaker-server.com/fmi/data/v1/databases/YourDB
FILEMAKER_USERNAME = your_username
FILEMAKER_PASSWORD = your_password
```

Then in Xcode:
1. Project → Info tab
2. Configurations section
3. Set Debug configuration to use Debug.xcconfig

### 6. Update Info.plist

Add these keys:
- `FILEMAKER_BASE_URL` = $(FILEMAKER_BASE_URL)
- `FILEMAKER_USERNAME` = $(FILEMAKER_USERNAME)
- `FILEMAKER_PASSWORD` = $(FILEMAKER_PASSWORD)

### 7. Build & Run

1. Select a simulator (iPhone 15 recommended)
2. Press Cmd+R to build and run

## Project Structure

```
Ingenes/
├── App/                    # App entry point
│   ├── IngenesApp.swift
│   ├── AppDelegate.swift
│   ├── AppState.swift
│   └── ContentView.swift
├── Core/                   # Core infrastructure
│   ├── Constants/
│   ├── Network/
│   ├── Storage/
│   └── Utilities/
├── Domain/                 # Business models
│   └── Models/
├── Services/               # API services
│   ├── FileMakerService.swift
│   └── AudioService.swift
├── Features/               # Feature modules
│   ├── Authentication/
│   ├── Dashboard/
│   └── SubmitWinners/
├── SharedUI/               # Shared components
│   ├── Components/
│   └── Theme/
└── Resources/              # Assets
    ├── logo.png
    └── Audio/
```

## Features (MVP)

- **Authentication:** Sign in, forgot password, multi-location support
- **Dashboard:** Welcome screen, quick actions, recent winners
- **Submit Winners:** Award selection, winner form, confetti celebration

## Future Features

- History & winner details
- FedEx package tracking
- Training & audiobook
- Badges system
- Push notifications

## Architecture

- **MVVM + Clean Architecture**
- **SwiftUI** for UI
- **Combine** for reactive programming
- **Actor-based services** for thread safety
- **Keychain** for secure storage

## Testing

Run tests with: Cmd+U

Or from command line:
```bash
xcodebuild test \
  -project ingenes.xcodeproj \
  -scheme ingenes \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Version

- App Version: 1.0.0
- Minimum iOS: 15.0
- Swift: 5.9+
