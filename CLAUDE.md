# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TestCaliNode is a SwiftUI iOS calisthenics training app that features:
- Interactive skill trees for different exercise categories (Pull, Push, Core, Legs) 
- Progress tracking with Firebase authentication and Firestore persistence
- Workout tracking system
- Quest system (placeholder implementation)
- User authentication via Google Sign-In and Apple Sign-In

## Development Commands

This is an Xcode project. Common development tasks:

### Building and Running
- Open `TestCaliNode.xcodeproj` in Xcode
- Build: `⌘+B` in Xcode or use Xcode's Product > Build menu
- Run: `⌘+R` in Xcode or use Xcode's Product > Run menu
- Test: `⌘+U` in Xcode (though no test targets are currently configured)

### Dependencies
The project uses Swift Package Manager for dependencies:
- Firebase (Auth, Firestore, Analytics)
- Google Sign-In
- FirebaseSignInWithApple (third-party)

Dependencies are defined in the Xcode project and resolved via Package.resolved.

## Architecture

### Core Components

**GlobalSkillManager** (`TestCaliNode/View/GlobalSkillManager.swift`)
- Central state manager for all skill unlocking and progress
- Handles Firebase/UserDefaults persistence 
- Manages XP system and level calculations
- ObservableObject for SwiftUI binding

**Skill Tree System**
- `EnhancedSkillTreeModel`: New hierarchical model with foundational/branch/master skills
- `SkillTreeModel`: Legacy flat model (backward compatibility)
- `SkillNode`: Individual skill representation with requirements and metadata
- Trees defined in `TestCaliNode/View/SkillTree/Skills/` directory

**Main Navigation**
- `MainTabView`: Tab-based navigation with 5 tabs (Skills, Workouts, Quests, Progress, Settings)
- `SkillTreeContainer`: Handles smooth scrolling between skill trees with TabView
- `SkillTreeLayoutContainer`: Layout management for individual trees

### UI Architecture

**Skill Tree Rendering**
- `SkillTreeCanvasView`: Main canvas for rendering skills with pan/zoom
- `SkillNodeView`: Individual skill circle with unlock states
- `SkillConnectionLines`: Draws requirement connections between skills
- `SkillTreeOverlays`: Handles selection dialogs and branch visibility

**Progress System**
- `ProgressDashboard`: Main analytics view with tree progress breakdowns
- XP-based leveling system with skill-type bonuses
- Tree completion percentages and statistics

### Data Models

**Enhanced Tree Structure:**
```
EnhancedSkillTreeModel
├── foundationalSkills: [SkillNode]  // Base skills
├── branches: [SkillBranch]          // Specialized skill paths  
└── masterSkills: [SkillNode]        // Advanced skills
```

**Skill Requirements:**
- Skills have `requires: [String]` arrays referencing prerequisite skill IDs
- GlobalSkillManager.canUnlock() validates all requirements are met

### Authentication & Persistence
- Firebase Auth with Google/Apple sign-in
- Firestore for cloud progress sync
- UserDefaults fallback for offline usage
- Progress data: user's unlocked skill IDs array

## Key Files to Understand

- `TestCaliNode/View/GlobalSkillManager.swift` - Core state management
- `TestCaliNode/View/Main/MainTabView.swift` - Main app navigation
- `TestCaliNode/View/SkillTree/SkillTreeContainer.swift` - Tree navigation and scrolling
- `TestCaliNode/View/SkillTree/Skills/EnhancedSkillTreeModel.swift` - Data models
- `TestCaliNode/View/SkillTree/Skills/AllSkills.swift` - Skill tree definitions
- `TestCaliNode/App/TestCaliNodeApp.swift` - App entry point with theme support

## Development Notes

### Skill Tree Data
- Trees are defined programmatically in Swift files, not external JSON
- Each tree has metadata (emoji, description) in `treeMetadata` arrays
- Positions for skills are defined as CGPoint dictionaries per tree/branch

### State Management
- Heavy use of `@ObservedObject` and `@StateObject` for SwiftUI reactivity
- GlobalSkillManager is the single source of truth for progress
- Settings use `@AppStorage` for persistence (e.g., dark mode toggle)

### Firebase Integration
- Requires GoogleService-Info.plist configuration
- Uses Firestore subcollection structure: users/{uid}/unlockedSkills
- Handles both authenticated and anonymous states gracefully

### Visual System
- Custom color schemes in `TestCaliNode/Visuals/`
- Skill difficulty represented by color coding
- Smooth animations for tree transitions and skill unlocks

## MCP Servers Configuration

This project has been configured with comprehensive MCP (Model Context Protocol) servers for enhanced development capabilities:

### Essential iOS Development MCPs
- **ios-simulator**: Control iOS simulators programmatically, take screenshots, simulate gestures
- **xcode-build**: Build and test Xcode projects, access build logs and compilation errors  
- **firebase**: Manage Firestore data, authentication, security rules (30+ tools)
- **swift-package-manager**: Automate Swift Package Manager operations

### Development & Testing MCPs
- **github**: Repository management, issues, PRs, code analysis
- **git**: Advanced Git repository operations and history management
- **filesystem**: Enhanced file operations with security controls
- **rest-api**: Test REST API endpoints with authentication support

### Database & Documentation MCPs  
- **firestore-db**: Direct Firestore database operations and queries
- **npm-packages**: NPM package information and version management
- **docs-generator**: Generate and maintain project documentation

### Image & Asset MCPs
- **image-processing**: Resize, compress, convert image formats in batches
- **ocr-vision**: OCR text extraction from images using RapidOCR
- **image-recognition**: Image analysis using Anthropic and OpenAI vision APIs

### MCP Status
Some MCPs may require initial setup or authentication:
- Working: ios-simulator, filesystem, image-processing
- May need auth: firebase (Google Cloud), github (GitHub token), firestore-db
- May need installation: xcode-build, swift-package-manager

### Using MCPs
MCPs provide additional tools beyond the standard Claude Code toolkit. They enable:
- Automated testing workflows with iOS simulator control
- Direct Firestore database management
- Advanced image processing for app assets
- Package dependency management
- Comprehensive project documentation generation