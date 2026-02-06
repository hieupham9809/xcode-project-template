# Design Specifications

## 1. Overview
The goal is to update the Home Screen for both iOS and macOS applications to match the provided design screenshots. The design features a clean, modern aesthetic with a focus on subscription tracking, utilizing a deep blue branding color and card-based layout.

## 2. Color Palette
- **Primary Gradient**: Deep Blue to Lighter Blue/White.
  - Top: `#1A57DB` (Estimated Deep Blue)
  - Bottom: `#F2F4F7` (Light Gray/White fade) or Transparent.
- **Accent Blue**: `#007AFF` (System Blue or similar for buttons/icons).
- **Text Primary**: `#000000` (Black).
- **Text Secondary**: `#8A8A8E` (Gray).
- **Background**: `#F2F4F7` (Light Gray) for the main content area background.
- **Card Background**: `#FFFFFF` (White).
- **Positive/Green**: `#34C759` (For "Active" or similar indicators if needed).
- **Negative/Red**: `#FF3B30` (For delete actions).

## 3. iOS Home Screen (`HomeDashboardView`)

### Layout Structure
- **Container**: `ZStack` or `VStack` with a custom background header.
- **Header**:
  - **Background**: A generic view with the Primary Gradient, covering the top safe area and extending down (~200pt).
  - **Content**:
    - **Title**: "Subscriptions", Large Title font (e.g., 34pt Bold), White color.
    - **Add Button**: "+" Icon, White, Top Trailing.
    - **Segmented Control**:
      - Labels: "Monthly", "Yearly".
      - Background: Translucent Dark Blue or `Material`.
      - Selection: Lighter Blue/Gray highlight.
      - Text Color: White (Unselected), Blue/Black (Selected).

- **Summary Card**:
  - **Position**: Overlapping the bottom of the header gradient.
  - **Style**: Rounded Rect (Corner Radius ~16-20), White Background, Shadow.
  - **Content**:
    - Text: "Total $54.97/month" (Centered, Bold, Black).

- **Subscription List**:
  - **Style**: Vertical ScrollView.
  - **Items**: `SubscriptionRow` / `SubscriptionCard`.
  - **Item Style**:
    - Background: White.
    - Corner Radius: ~16.
    - Shadow: Soft, low opacity.
    - **Layout**:
      - **Leading**: Service Icon (Image), size ~40x40.
      - **Center**:
        - Top: Name (e.g., "Spotify"), Bold, Black.
        - Bottom: Plan/Description (e.g., "Premium Individual"), Regular, Gray.
      - **Trailing**:
        - Price (e.g., "$9.99"), Bold, Black.

### Bottom Tab Bar
- **Items**:
  - "Subscriptions" (Selected, Blue).
  - "Analytics" (Gray).
  - "Settings" (Gray).

## 4. macOS / iPadOS Home Screen

### Layout Structure
- **Navigation**: `NavigationSplitView` (Sidebar + Detail).
- **Sidebar**:
  - Background: Dark Gray / Black (`#1C1C1E`).
  - Items:
    - "Home" (Icon: House).
    - "Analytics" (Icon: Pie Chart).
    - "Settings" (Icon: Gear).
  - Selection Style: Rounded Rectangle with Darker Gray highlight.

- **Main Content (Home)**:
  - **Background**: Light Gray / White.
  - **Header**:
    - Title: "Subscriptions" (Large, Black).
    - Controls (Top Right):
      - Segmented Control ("Monthly", "Yearly").
      - Add Button ("+" in Blue Circle).
  - **List**:
    - Style: Wide Cards.
    - **Card Layout**:
      - Leading: Icon.
      - Title/Subtitle: Name (Bold), Plan (Gray).
      - Trailing:
        - Date (e.g., "May 25").
        - Price (e.g., "$7.99").
        - Chevron Right Icon (`>`).
