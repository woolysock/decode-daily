# watchOS Support Setup Guide

This guide will help you add the watchOS target to your Decode! Daily project.

## What's Been Created

The following watchOS app files have been created in the `WatchApp/` folder:

- **DecodeDailyWatchApp.swift** - Main app entry point for watchOS
- **WatchContentView.swift** - Main navigation and game selection view
- **WatchDecodeGameView.swift** - watchOS version of the Decode game
- **WatchFlashdanceGameView.swift** - watchOS version of the Flashdance game
- **WatchAnagramsGameView.swift** - watchOS version of the Anagrams game
- **Info.plist** - watchOS app configuration

## Adding the watchOS Target in Xcode

Follow these steps to add the watchOS target to your project:

### Step 1: Open Your Project in Xcode

1. Open `DecoderGame.xcodeproj` in Xcode

### Step 2: Add a New watchOS Target

1. In Xcode, select the project in the Project Navigator (top item)
2. Click the "+" button at the bottom of the targets list
3. Select **watchOS** → **App** → **Watch App**
4. Click **Next**
5. Configure the new target:
   - **Product Name:** `DecodeDailyWatch`
   - **Bundle Identifier:** `com.megandonahue.DecoderGame.watchkitapp`
   - **Organization Name:** Your organization name
   - **Team:** Select your development team
   - **Language:** Swift
   - **Interface:** SwiftUI
6. Click **Finish**
7. When prompted about activating the scheme, click **Activate**

### Step 3: Replace Default Files

The wizard will create some default files. We'll replace these with our custom files:

1. In the Project Navigator, find the newly created `DecodeDailyWatch` folder
2. Delete the default app file (likely named `DecodeDailyWatchApp.swift`) - click "Move to Trash"
3. Delete the default `ContentView.swift` - click "Move to Trash"
4. Delete the default `Assets.xcassets` folder in the watchOS target

### Step 4: Add Your Custom watchOS Files

1. Drag the entire `WatchApp` folder from Finder into the watchOS target folder in Xcode
2. When the dialog appears:
   - ✅ Check "Copy items if needed"
   - ✅ Check "Create groups"
   - ✅ Select only the **DecodeDailyWatch** target
   - ❌ Do NOT select the iOS target
3. Click **Finish**

### Step 5: Configure Shared Code

The watchOS app needs access to the game logic and manager classes. Add these files to the watchOS target:

1. In Project Navigator, select `AnagramsGame.swift`
2. In the File Inspector (right panel), under **Target Membership**, check ✅ **DecodeDailyWatch**
3. Repeat for these files:
   - `DecodeGame.swift`
   - `FlashdanceGame.swift`
   - `GameProtocol.swift`
   - `GameCoordinator.swift`
   - `GameScoreManager.swift`
   - `DailyCheckManager.swift`
   - `DailyCodeSetManager.swift`
   - `DailyEquationManager.swift`
   - `DailyWordsetManager.swift`
   - `DailyWordset.swift`
   - `Extensions.swift`
   - `PaidTier.swift`
   - `StoreManager.swift`

### Step 6: Add Resource Files to watchOS Target

Add the data files to the watchOS target:

1. Select `DailyCodes.json`
2. In File Inspector, check ✅ **DecodeDailyWatch** under Target Membership
3. Repeat for:
   - `DailyEquations.json`
   - `DailyWordsets.json`
   - `MasterWordList.json`
   - `LuloOne.otf`
   - `LuloOne-Bold.otf`
   - `Sole-Light.otf`

### Step 7: Configure watchOS Build Settings

1. Select the project in Project Navigator
2. Select the **DecodeDailyWatch** target
3. Go to the **General** tab:
   - Set **Minimum Deployments** to **watchOS 9.0** or later
   - Verify **Bundle Identifier** is correct
   - Set **Version** to match your iOS app (1.0.4)
4. Go to the **Build Settings** tab:
   - Search for "fonts"
   - Under **Info.plist Values**, add these fonts to **Fonts provided by application**:
     - `LuloOne.otf`
     - `LuloOne-Bold.otf`
     - `Sole-Light.otf`

### Step 8: Add watchOS App Icon

1. Create a watchOS App Icon asset:
   - In the watchOS target's Assets.xcassets, add a new **watchOS** App Icon
   - The watchOS app icon needs these sizes:
     - 48x48pt (96x96px @2x)
     - 55x55pt (110x110px @2x)
     - 87x87pt (174x174px @2x)
     - 58x58pt (116x116px @2x)
     - 29x29pt (58x58px @2x)
     - 40x40pt (80x80px @2x)
     - 44x44pt (88x88px @2x, 132x132px @3x)
     - 50x50pt (100x100px @2x)

2. You can create simplified versions of your iOS app icon for watchOS

### Step 9: Configure Package Dependencies

The watchOS app needs the Mixpanel SDK:

1. Select the project in Project Navigator
2. Select the **DecodeDailyWatch** target
3. Go to **General** → **Frameworks, Libraries, and Embedded Content**
4. Click the "+" button
5. Select **Mixpanel** and click **Add**

### Step 10: Build and Test

1. Select the **DecodeDailyWatch** scheme at the top of Xcode
2. Choose a watchOS Simulator (e.g., "Apple Watch Series 9 (45mm)")
3. Press **Cmd+B** to build
4. If successful, press **Cmd+R** to run
5. The app should launch in the watchOS Simulator

## Troubleshooting

### Build Errors

**"Cannot find type 'DecodeGame' in scope"**
- Make sure you added all the shared Swift files to the watchOS target (Step 5)

**"Could not find resource file"**
- Make sure you added all JSON and font files to the watchOS target (Step 6)

**"Missing app icon"**
- Add a watchOS app icon to the Assets.xcassets (Step 8)

### Runtime Issues

**"Game doesn't load data"**
- Verify the JSON files are in the watchOS target's Copy Bundle Resources build phase
- Check that the file names match exactly (case-sensitive)

**"Fonts look wrong"**
- Make sure you added the font files to Info.plist under "Fonts provided by application"
- Verify the font files are included in the watchOS target

## watchOS App Features

The watchOS app includes:

### Decode Game
- Color code-cracking game adapted for small screen
- Shows last 3 attempts for easier viewing
- Touch-based color picker
- Full 7 attempts with scoring

### Flashdance Game
- 30-second timed math challenge
- Large equation display
- Simple button-based answer selection
- Score tracking with correct/incorrect counts

### Anagrams Game
- 60-second word scramble
- Letter selection interface
- Submit, clear, and skip controls
- Score and progress tracking

### Scores View
- View today's scores for all games
- Integrated with GameScoreManager
- Synced data with iOS app (via shared container or iCloud)

## Next Steps

After setting up the watchOS target:

1. **Test all three games** on a watchOS Simulator
2. **Add watchOS app icons** to make it look polished
3. **Consider adding complications** for quick access from watch faces
4. **Test on a physical Apple Watch** if available
5. **Update your App Store listing** to mention watchOS support

## Architecture Notes

The watchOS app:
- **Shares all game logic** with the iOS app (DecodeGame, FlashdanceGame, AnagramsGame)
- **Uses the same managers** for data and scoring (GameScoreManager, etc.)
- **Has watchOS-specific views** optimized for the smaller screen
- **Works independently** but can sync data with the iOS app
- **Uses SwiftUI throughout** for modern, declarative UI

## Future Enhancements

Consider adding:
- **Watch Complications** - Show daily streak or quick game launch
- **Watch Connectivity** - Real-time sync with iPhone app
- **Haptic Feedback** - Vibrations for correct/incorrect answers
- **Shorter Game Modes** - 15-second versions for quick play
- **Widgets** - Show today's scores on watch face
