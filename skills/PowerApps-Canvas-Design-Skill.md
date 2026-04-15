---
name: powerapps-canvas-design
description: Power Apps Canvas Apps UI/UX design guide — containers, responsive layouts, modern Fluent UI controls, gallery designs, filter panels, and navigation patterns. Use this skill when designing or improving the look, layout, or user experience of a Canvas App.
license: MIT
metadata:
  author: KayodeAjayi200
  version: "1.0.0"
  organization: Veldarr
  date: April 2026
  abstract: >
    Best practices for building beautiful, well-designed Power Apps Canvas Apps. Covers structured
    layouts with containers, responsive design with breakpoints, modern Fluent UI controls and
    theming, gallery and card designs (list vs grid, multi-view toggle, filter panels), and
    navigation patterns (collapsible side menu, tab bar, hover/feedback micro-interactions).
    Based on Tolu Victor's Power Apps UI/UX tutorial series.
---

# Power Apps Canvas Apps — UI/UX Design Best Practices

> Use this skill when a user asks about improving their app's look, creating better layouts,
> making an app responsive, designing galleries, adding a nav menu, or anything visual/UX.

---

## 1. Structured Layouts with Containers

**Rule: Never use absolute X/Y positioning. Always use containers.**

Horizontal and Vertical Container controls form the backbone of every well-designed canvas app. They group controls and manage arrangement automatically — no manual pixel-pushing.

### Container types

| Container | When to use |
|---|---|
| **Vertical Container** | Stack content top-to-bottom (header → content → footer) |
| **Horizontal Container** | Place items side-by-side (icon + label, nav bar icons, two-column layout) |
| **Grid Container** (Preview) | Precise row/column grid placement for dashboards |

### How to structure a screen

```
Screen (Vertical Container)
├── Header (Horizontal Container)
│   ├── Logo / Title (Label)
│   └── Nav Icons (Horizontal Container)
├── Body (Horizontal Container)
│   ├── Side Nav (Vertical Container)  ← optional
│   └── Main Content (Vertical Container)
│       ├── Filter Bar (Horizontal Container)
│       └── Gallery / Form
└── Footer (Horizontal Container)      ← optional
```

### Container properties to know

| Property | What it does |
|---|---|
| `LayoutMode` | Auto (children flow) vs Manual |
| `AlignInContainer` | Stretch / Start / End / Center |
| `FlexibleWidth` / `FlexibleHeight` | Lets container grow to fill available space |
| `Gap` | Spacing between children |
| `Padding` | Inner spacing on all sides |
| `Wrap` | Allows children to wrap to next row |

### Key rules
- **Group related controls** in a container so you can hide/move the whole group at once
- **Nest containers** for complex layouts — a horizontal container can contain vertical ones
- Containers make maintenance trivial: need to hide a section? `Container.Visible = false`

---

## 2. Responsive Design

**Rule: Design for the devices your users actually use. Make it work everywhere, make it perfect for the primary device.**

### Enable responsiveness

Turn off fixed canvas scaling in **Settings → Display**. This enables percentage-based sizing and makes containers flexible.

### Fluid sizing formulas

```powerfx
// 50% width of parent
Width = Parent.Width * 0.5

// Fill remaining height
Height = Parent.Height - HeaderContainer.Height

// Responsive padding
Padding = If(App.Width < 600, 8, 16)
```

### Breakpoints pattern

```powerfx
// Define once as named formula (App.Formulas):
IsPhone  = App.Width < 600
IsTablet = App.Width >= 600 && App.Width < 1024
IsDesktop = App.Width >= 1024
```

Then use throughout:
```powerfx
// Hide sidebar on phone
SideNavContainer.Visible = !IsPhone

// Show hamburger menu only on phone
btnHamburger.Visible = IsPhone

// Adjust columns in a form
EditForm1.Columns = If(IsPhone, 1, 2)

// Adapt gallery template size
Gallery1.TemplateSize = If(IsPhone, 80, 120)
```

### Responsive navigation pattern

| Screen size | Navigation style |
|---|---|
| Desktop | Persistent side menu with icons + labels |
| Tablet | Side menu icons only (collapsed) |
| Phone | Hidden menu, hamburger ☰ button opens overlay |

```powerfx
// Side menu width — collapses on narrow screens
SideNavContainer.Width = If(IsPhone, 0, If(varMenuCollapsed, 48, 200))
SideNavContainer.Visible = !IsPhone || varMenuOpen

// Label visibility in nav items
navLabel.Visible = !varMenuCollapsed && !IsPhone
```

### Responsive forms

```powerfx
// Number of form columns
EditForm1.Columns = If(App.Width < 700, 1, 2)
```

### Responsive galleries

```powerfx
// Gallery fills remaining content area
Gallery1.Height = Parent.Height - SearchBar.Height - FilterBar.Height
Gallery1.Width = Parent.Width

// Template size adapts to screen
Gallery1.TemplateSize = If(IsPhone, 72, 96)
```

---

## 3. Modern Fluent UI Controls & Theming

**Rule: Use modern controls for new apps. Apply a theme. Don't style things manually that the theme handles for you.**

### Enabling modern controls

**Settings → Updates → Modern controls and themes** → turn on.

Modern controls include: Button, Text Input, Dropdown, Combo Box, Checkbox, Toggle, Date Picker, Slider, Radio Group, Badge, Progress Bar, Spinner.

### Why modern controls

- Consistent Fluent Design aesthetic out of the box
- Automatically inherit the app theme (colors, fonts)
- Built-in hover/focus/press states — no manual HoverFill needed
- Better accessibility (focus rings, ARIA attributes)
- Icon support built into Button

### Applying a theme

**Settings → Themes** → choose a preset or create a custom theme.

Custom theme approach:
```powerfx
// Define colors as named formulas for consistency
BrandColor    = ColorValue("#0078D4")
SurfaceColor  = ColorValue("#F3F2F1")
TextPrimary   = ColorValue("#201F1E")
TextSecondary = ColorValue("#605E5C")
SuccessColor  = ColorValue("#107C10")
ErrorColor    = ColorValue("#A4262C")
```

Use these everywhere instead of hardcoded hex values.

### Modern Button with icon

```powerfx
// Icon property — use built-in icon names
btnSave.Icon = Icon.Save
btnDelete.Icon = Icon.Trash
btnAdd.Icon = Icon.Add

// Icon position
btnSave.IconPosition = IconPosition.Leading   // icon left of text
```

### SVG icons with theme colors

To make custom SVG icons follow the app theme:
```powerfx
// In an Image control's Image property:
"data:image/svg+xml;utf8," &
EncodeUrl("<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'>
  <path fill='" & RGBA(0,120,212,1) & "' d='M12 2...'/>
</svg>")
```

Replace the hardcoded color with your named formula:
```powerfx
"data:image/svg+xml;utf8," &
EncodeUrl("<svg ...><path fill='" & Text(BrandColor) & "' .../></svg>")
```

### Drop shadows (workaround)

Power Apps doesn't have a native shadow property on containers. Use an HTML Text control placed *behind* your card:

```powerfx
// HtmlText property:
"<div style='
  width: 100%;
  height: 100%;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.12);
  background: white;
'></div>"
```

Match its Width/Height/X/Y to the card container.

### Rounded corners and card style

```powerfx
// On containers/rectangles:
BorderRadius = 8     // subtle rounding
Fill = White
BorderColor = RGBA(0,0,0,0.08)   // very subtle border
BorderThickness = 1
```

---

## 4. Gallery & List Design

### List vs Grid — when to use each

| View | Best for |
|---|---|
| **List** | Text-heavy records, many details per item, task/ticket lists |
| **Grid** | Visual/image-rich content, quick scanning, catalogs, dashboards |

**Best UX: offer both and let users toggle.**

### Multi-view toggle

```powerfx
// Toggle button OnSelect:
Set(varGalleryView, If(varGalleryView = "Grid", "List", "Grid"))

// Show/hide galleries:
galleryList.Visible = varGalleryView = "List"
galleryGrid.Visible = varGalleryView = "Grid"

// Or: toggle button icon
btnToggleView.Icon = If(varGalleryView = "Grid", Icon.DetailList, Icon.Waffle)
```

### Card-style gallery item template

Build each gallery item as a styled card:

```
Gallery Item (Vertical Container)
├── BorderRadius: 8, Fill: White, Shadow: (HTML workaround)
├── Padding: 12
├── Image (thumbnail/avatar)          — optional
├── Title Label    — FontWeight: Bold, Size: 14
├── Subtitle Label — Color: TextSecondary, Size: 12
├── Status Badge   — colored pill
└── Action Row (Horizontal Container)
    └── Action buttons (icon-only)
```

### Status badge / pill pattern

```powerfx
// Rectangle used as badge background:
badgeBg.Fill = Switch(ThisItem.Status,
    "Active",   RGBA(16, 124, 16, 0.1),
    "Pending",  RGBA(255, 140, 0, 0.1),
    "Closed",   RGBA(100, 100, 100, 0.1)
)

// Badge label:
badgeLabel.Color = Switch(ThisItem.Status,
    "Active",   ColorValue("#107C10"),
    "Pending",  ColorValue("#FF8C00"),
    "Closed",   ColorValue("#646464")
)
```

### Search bar pattern

```
Search Container (Horizontal Container)
├── Search Icon (Icon.Search) — color: TextSecondary
├── Text Input — Placeholder: "Search...", BorderNone, Fill: Transparent
└── Clear Button (Icon.Cancel) — Visible: !IsBlank(txtSearch.Text)
                                — OnSelect: Reset(txtSearch)
```

Gallery Items filtered:
```powerfx
Gallery1.Items = Search(DataSource, txtSearch.Text, "Title", "Description", "AssignedTo")
```

---

## 5. Modern Filter UI

### Filter panel structure

```
Filter Panel (Vertical Container) — slides in from side or drops from top
├── Header Row: "Filters" + Clear All button
├── Section: Status
│   └── Toggle buttons for each status value
├── Section: Date Range
│   └── Date Picker start + end
├── Section: Assigned To
│   └── Combo Box (multi-select)
└── Footer: Apply / Close
```

### Active filter counter

```powerfx
// Count how many filters are active:
varActiveFilters = 
    (If(!IsBlank(cboStatus.SelectedItems), CountRows(cboStatus.SelectedItems), 0)) +
    (If(!IsBlank(dtpFrom.SelectedDate), 1, 0)) +
    (If(!IsBlank(dtpTo.SelectedDate), 1, 0))

// Show in button:
btnFilter.Text = "Filters" & If(varActiveFilters > 0, " (" & varActiveFilters & ")", "")
btnFilter.Fill = If(varActiveFilters > 0, BrandColor, SurfaceColor)
```

### Filter chips / pill toggles

```powerfx
// Gallery of status options used as filter chips:
galleryFilterChips.Items = ["All", "Active", "Pending", "Closed"]

// Each item background (active = brand color, inactive = surface):
chipBg.Fill = If(ThisItem.Value = varSelectedStatus, BrandColor, SurfaceColor)
chipLabel.Color = If(ThisItem.Value = varSelectedStatus, White, TextPrimary)

// Chip OnSelect:
Set(varSelectedStatus, ThisItem.Value)
```

### Applying multiple filters to a gallery

```powerfx
Gallery1.Items = Filter(
    DataSource,
    // Text search
    (IsBlank(txtSearch.Text) || StartsWith(Title, txtSearch.Text)),
    // Status filter
    (varSelectedStatus = "All" || Status = varSelectedStatus),
    // Date filter
    (IsBlank(dtpFrom.SelectedDate) || Created >= dtpFrom.SelectedDate),
    (IsBlank(dtpTo.SelectedDate)   || Created <= dtpTo.SelectedDate)
)
```

### Responsive filter layout

```powerfx
// Wide screen: filter panel as sidebar
filterPanel.Visible = !IsPhone
filterPanel.Width = 240

// Phone: filter behind a modal overlay
filterOverlay.Visible = IsPhone && varShowFilters
btnOpenFilters.Visible = IsPhone
```

---

## 6. Navigation Patterns

### Collapsible side menu

```
SideMenu (Vertical Container)
├── Width: If(varMenuCollapsed, 48, 200)
├── Toggle Button — OnSelect: Set(varMenuCollapsed, !varMenuCollapsed)
└── Menu Gallery
    ├── Items: [
    │     {Icon: Icon.Home,    Label: "Home",     Screen: HomeScreen},
    │     {Icon: Icon.People,  Label: "Contacts", Screen: ContactsScreen},
    │     {Icon: Icon.Document,Label: "Reports",  Screen: ReportsScreen}
    │   ]
    ├── Item Template (Horizontal Container):
    │   ├── Icon Control — ThisItem.Icon
    │   └── Label — Visible: !varMenuCollapsed
    └── Selected highlight:
        itemBg.Fill = If(ThisItem.Screen = varCurrentScreen, BrandColor, Transparent)
```

Track current screen:
```powerfx
// On each screen's OnVisible:
Set(varCurrentScreen, HomeScreen)   // or use App.ActiveScreen
```

Navigate on item select:
```powerfx
Navigate(ThisItem.Screen, ScreenTransition.None)
```

### Top navigation bar

```
TopNav (Horizontal Container, full width, Height: 48)
├── App Logo/Title (left)
├── Spacer (FlexibleWidth: true)
└── Nav Icons (right — Horizontal Container)
    ├── Notifications icon
    ├── Search icon
    └── User avatar (Circle image)
```

### Hamburger menu for mobile

```powerfx
// Hamburger button (phone only):
btnHamburger.Visible = IsPhone
btnHamburger.OnSelect = Set(varMenuOpen, !varMenuOpen)

// Full-screen overlay menu:
menuOverlay.Visible = IsPhone && varMenuOpen
menuOverlay.ZIndex = 100  // above everything
```

---

## 7. Micro-interactions & Feedback

### Loading states

```powerfx
// Show spinner while data loads:
Spinner1.Visible = varLoading

// In OnSelect before async operation:
Set(varLoading, true);
Refresh(DataSource);
Set(varLoading, false)
```

### Success / error notifications

```powerfx
// Using built-in Notify:
Notify("Record saved!", NotificationType.Success)
Notify("Failed to save. Try again.", NotificationType.Error)

// Or: custom toast (label that auto-hides with a timer)
Set(varToast, "Saved ✓");
Set(varShowToast, true);
// Timer Duration=2000 AutoStart=true OnTimerEnd: Set(varShowToast, false)
```

### Button states

```powerfx
// Disable button while saving:
btnSave.DisplayMode = If(varSaving, DisplayMode.Disabled, DisplayMode.Edit)

// Change text during save:
btnSave.Text = If(varSaving, "Saving...", "Save")
```

---

## 8. Design Checklist

Before publishing, verify:

- [ ] All screens use containers (no manually positioned controls floating)
- [ ] App tested on smallest target device — nothing cut off
- [ ] Modern controls enabled and theme applied
- [ ] Color palette consistent (use named formulas, not hardcoded hex)
- [ ] All galleries have a `NoDataText` or empty state UI
- [ ] Search + filter tested with empty results
- [ ] Loading/saving states handled — no "frozen" buttons
- [ ] Navigation highlights current section
- [ ] Touch targets ≥ 44px (add padding to small buttons)
- [ ] Sufficient color contrast (WCAG AA minimum)
- [ ] No single screen overwhelmed with information — break into sections

---

## Quick Patterns Reference

### Responsive 2-column layout that stacks on phone
```powerfx
// Outer container: Horizontal, Wrap: true
// Each column: FlexibleWidth, MinWidth: If(IsPhone, Parent.Width, 300)
```

### Image aspect ratio lock
```powerfx
img.Width  = Parent.Width
img.Height = img.Width * 0.5625   // 16:9
img.ImagePosition = ImagePosition.Fill
```

### Scrollable section
```powerfx
// Use a Vertical Gallery with a single item (a container) or
// use Scroll property on a container (modern containers support scrolling)
scrollContainer.OverflowY = Overflow.Scroll
```

### Section with expand/collapse
```powerfx
sectionContent.Visible = varSectionExpanded
chevronIcon.Icon = If(varSectionExpanded, Icon.ChevronUp, Icon.ChevronDown)
// Header OnSelect: Set(varSectionExpanded, !varSectionExpanded)
```

### Zebra-striped list rows
```powerfx
rowBg.Fill = If(Mod(ThisItem.ItemNumber, 2) = 0, SurfaceColor, White)
```
