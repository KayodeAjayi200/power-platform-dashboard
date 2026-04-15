# AGENT SKILL: Power Apps Canvas Apps

> **Reference for AI agents working with Power Apps Canvas Apps.**
> Use this when a user asks you to build, modify, debug, or explain a Canvas App,
> its controls, properties, components, or Power Fx formulas.

---

## Quick orientation

| Concept | What it is |
|---|---|
| **Canvas App** | A low-code app where you drag controls onto screens and write Power Fx formulas |
| **Screen** | Top-level container; apps have one or more screens; navigate between them with `Navigate()` |
| **Control** | A UI element (Button, Gallery, Label, etc.) placed on a screen |
| **Property** | A setting on a control (position, color, data, behavior) set via Power Fx formulas |
| **Power Fx** | The Excel-like formula language used for all logic in Canvas Apps |
| **Component** | A reusable custom control built from other controls, with Input/Output properties |
| **Collection** | An in-memory table created and managed inside the app |
| **Data Source** | An external table connected to the app (SharePoint, Dataverse, SQL, etc.) |

---

## Controls — Complete Reference

### Input & Selection

| Control | Key Properties | Notes |
|---|---|---|
| **Button** | `Text`, `OnSelect`, `DisplayMode` | Primary action trigger |
| **Text Input** | `Default`, `Text`, `Mode` (SingleLine/MultiLine/Password), `DelayOutput`, `Placeholder` | `Text` is read-only output; set `Default` to pre-fill |
| **Dropdown** | `Items`, `Selected`, `SelectedText`, `Default` | `Selected` returns the whole record; use `.Value` for the display field |
| **Combo Box** | `Items`, `SelectMultiple`, `SelectedItems`, `DefaultSelectedItems` | Use when multi-select or search is needed |
| **List Box** | `Items`, `Selected`, `SelectedItems` | Always-visible list, supports multi-select |
| **Check Box** | `Default` (bool), `Value`, `Text`, `OnCheck`, `OnUncheck`, `CheckmarkFill` | `Value` = current state |
| **Radio** | `Items`, `Selected` | Single-choice button group |
| **Toggle** | `Default` (bool), `Value`, `TrueText`, `FalseText` | Sliding on/off switch |
| **Slider** | `Min`, `Max`, `Default`, `Value`, `Step`, `ThumbFill` | `Value` is the current number |
| **Rating** | `Min`, `Max`, `Default`, `Value` | Star-based rating input |
| **Date Picker** | `SelectedDate`, `DefaultDate`, `Format` | Date only (no time); time via separate Text Input |
| **Pen Input** | `Image`, `OnSelect` | Captures freehand ink/signature as image |
| **Rich Text Editor** | `HtmlText`, `Default` | Output is HTML; full formatting controls for user |
| **Attachments** | `Items`, `AddAttachmentText`, `MaxAttachments` | Used in forms linked to SharePoint/Dataverse |

### Display

| Control | Key Properties | Notes |
|---|---|---|
| **Label** | `Text`, `Color`, `Size`, `Align`, `VerticalAlign`, `Wrap` | Most common display control |
| **HTML Text** | `HtmlText` | Renders HTML — hyperlinks, formatting, etc. |
| **Data Table** | `Items`, `HeadingFill`, `NoDataText` | Read-only tabular grid; good for simple lists |
| **Display Form** | `DataSource`, `Item`, `DefaultMode` (View) | Shows one record read-only |
| **Edit Form** | `DataSource`, `Item`, `DefaultMode` (Edit/New), `OnSuccess`, `OnFailure`, `LastSubmit` | Shows one record for editing or creating |
| **Card** | `DataField`, `Default`, `Update`, `Required` | Auto-generated inside forms; one per field |
| **Gallery** | `Items`, `Selected`, `TemplateSize`, `TemplatePadding`, `Layout` | Repeating list of records; template defines per-item look |

### Media

| Control | Key Properties | Notes |
|---|---|---|
| **Image** | `Image`, `ImagePosition` (Fill/Fit/Center/Tile/Stretch) | Displays image from URL, collection, or data |
| **Camera** | `Camera` (0=rear, 1=front), `Photo`, `OnSelect` | `Photo` holds last captured image |
| **Microphone** | `Audio`, `OnStop` | Records audio |
| **Audio** | `Media`, `Start`, `Pause`, `Volume` | Plays audio from URL or media resource |
| **Video** | `Media`, `Start`, `Volume`, `ShowControls` | Supports YouTube URLs and local media |
| **PDF Viewer** | `Document`, `CurrentPage`, `Page` | Experimental; displays PDF from URL |
| **Add Picture** | `Image`, `Media`, `OnChange` | Lets user load image from device |

### Charts

| Control | Items schema needed | Notes |
|---|---|---|
| **Column Chart** | Table with category + value columns | Vertical bars |
| **Line Chart** | Table with series data | Trend lines |
| **Pie Chart** | Table with `Labels` and `Values` columns | Proportional slices |

### Layout & Containers

| Control | Notes |
|---|---|
| **Container** | Groups controls; no visual output itself |
| **Horizontal Container** | Auto-arranges children left-to-right; enables responsive layout |
| **Vertical Container** | Auto-arranges children top-to-bottom |
| **Screen** | Top-level container; has `OnVisible`, `OnHidden`, `Fill`, `BackgroundImage` |

### Maps & Mixed Reality

| Control | Notes |
|---|---|
| **Map** | Plots locations; properties: `Items`, `Latitude`, `Longitude`, `Zoom` |
| **3D Object** | Renders GLB 3D model |
| **View in MR** | Places 3D content in real world via AR camera |
| **Measuring Camera** | Measures distance/area/volume via device camera |

### AI Builder Components

| Component | What it does | Key output properties |
|---|---|---|
| **Business Card Reader** | Extracts contact info from photo | `FullName`, `Email`, `Phone`, `Company` |
| **Form Processor** | Extracts fields from a scanned form/invoice | Per-field text outputs |
| **Object Detector** | Identifies objects in an image | `Results` (table: Tag, Score, BoundingBox) |
| **Text Recognizer** | OCR — extracts text from images | `Results` (table of text regions) |

---

## Control Properties — Common Reference

### Position & Size
| Property | Type | Description |
|---|---|---|
| `X` | Number | Left edge position in pixels |
| `Y` | Number | Top edge position in pixels |
| `Width` | Number | Width in pixels |
| `Height` | Number | Height in pixels |
| `ZIndex` | Number | Layer order (higher = in front) |

### Visibility & Interaction
| Property | Type | Description |
|---|---|---|
| `Visible` | Boolean | Show/hide the control |
| `DisplayMode` | Enum | `DisplayMode.Edit`, `DisplayMode.View`, `DisplayMode.Disabled` |
| `TabIndex` | Number | Keyboard nav order; -1 = excluded |
| `Tooltip` | Text | Hover text |
| `AccessibleLabel` | Text | Screen-reader label |

### Color & Style
| Property | Type | Description |
|---|---|---|
| `Fill` | Color | Background fill |
| `Color` | Color | Text/icon foreground color |
| `BorderColor` | Color | Border color |
| `BorderThickness` | Number | Border width in pixels |
| `BorderStyle` | Enum | `Solid`, `Dashed`, `Dotted`, `None` |
| `HoverFill` | Color | Background on mouse hover |
| `PressedFill` | Color | Background when pressed |
| `DisabledFill` | Color | Background when disabled |

**Setting colors:**
```powerfx
// 3 ways to set a color value:
Color.Blue                     // built-in enum
ColorValue("#0078D4")          // hex string
RGBA(0, 120, 212, 1)          // red, green, blue, alpha(0-1)
ColorFade(Color.Blue, -20%)    // darken by 20%
```

### Typography
| Property | Type | Description |
|---|---|---|
| `Font` | Text | Font family name |
| `Size` | Number | Font size in points |
| `FontWeight` | Enum | `Bold`, `Semibold`, `Normal`, `Lighter` |
| `Italic` | Boolean | Italic text |
| `Underline` | Boolean | Underlined text |
| `Align` | Enum | `Left`, `Center`, `Right`, `Justify` |
| `VerticalAlign` | Enum | `Top`, `Middle`, `Bottom` |

### Events (Behavior Properties)
| Property | When it fires |
|---|---|
| `OnSelect` | User taps/clicks the control |
| `OnChange` | Control value changes |
| `OnVisible` (Screen) | Screen becomes active |
| `OnHidden` (Screen) | Screen is navigated away from |
| `OnSuccess` (Form) | Form submitted successfully |
| `OnFailure` (Form) | Form submission failed |
| `OnTimerEnd` (Timer) | Timer duration elapsed |

---

## Components — Reusable Custom Controls

### Creating a component
1. Open **Tree View → Components → New component**
2. Add controls inside (they form the component's UI)
3. Define **custom properties** (Data → New custom property)

### Custom property types
| Type | Direction | Usage |
|---|---|---|
| **Input** | App → Component | Data the parent sends in (Text, Number, Boolean, Record, Table, Color, etc.) |
| **Output** | Component → App | Data the component exposes out (e.g. `MyComponent.SelectedValue`) |
| **Behavior** (experimental) | App → Component | Event handler the parent provides (called by the component) |

### Using a component
```powerfx
// Parent sets input property:
MyHeaderComponent.Title = "Expenses App"

// Parent reads output property:
If(MyMenuComponent.SelectedPage = "Settings", Navigate(SettingsScreen))
```

### Component Libraries
- Create in a **Component Library** app (separate from your main app)
- Publish the library, then import components into any canvas app
- Updates propagate: apps get an "Update available" prompt when library changes

---

## Power Fx Functions — Complete Reference

### 🎨 Color
| Function | Example | Returns |
|---|---|---|
| `RGBA(r,g,b,a)` | `RGBA(255,0,0,1)` | Color (solid red) |
| `ColorValue(str)` | `ColorValue("#FF0000")` | Color |
| `ColorFade(color, pct)` | `ColorFade(Color.Blue, -20%)` | Darker blue |
| `Color.*` | `Color.Red` | Color enum constant |

### 📦 Data — Read & Query
| Function | Example | Returns |
|---|---|---|
| `Filter(table, condition)` | `Filter(Orders, Status="Open")` | Table |
| `LookUp(table, condition)` | `LookUp(Employees, ID=42)` | Record |
| `Search(table, term, col1, col2)` | `Search(Customers, txtSearch.Text, "Name", "City")` | Table |
| `Sort(table, expr, order)` | `Sort(Products, Price, Ascending)` | Table |
| `SortByColumns(table, col, order)` | `SortByColumns(Employees, "Name", Ascending)` | Table |
| `First(table)` | `First(Orders)` | Record |
| `Last(table)` | `Last(Orders)` | Record |
| `FirstN(table, n)` | `FirstN(Orders, 5)` | Table |
| `LastN(table, n)` | `LastN(Orders, 5)` | Table |
| `Index(table, n)` | `Index(MyTable, 3)` | Record |
| `Distinct(table, expr)` | `Distinct(Orders, Region)` | Single-col table |
| `GroupBy(table, col, name)` | `GroupBy(Orders, "Region", "Items")` | Table with nested tables |
| `Ungroup(table, col)` | `Ungroup(Grouped, "Items")` | Flat table |
| `AddColumns(table, name, expr)` | `AddColumns(Products, "Total", Price*Qty)` | Table with extra col |
| `DropColumns(table, col)` | `DropColumns(T, "TempCol")` | Table without that col |
| `ShowColumns(table, col1, ...)` | `ShowColumns(Employees, "Name", "Email")` | Slim table |
| `RenameColumns(table, old, new)` | `RenameColumns(T, "Author", "Owner")` | Table with renamed col |
| `ForAll(table, expr)` | `ForAll(Orders, Patch(Orders, ThisRecord, {Done:true}))` | Table of results or side-effects |

### ✏️ Data — Write
| Function | Example | Notes |
|---|---|---|
| `Patch(ds, record, changes)` | `Patch(Orders, ThisItem, {Status:"Done"})` | Update existing record |
| `Patch(ds, Defaults(ds), fields)` | `Patch(Orders, Defaults(Orders), {Title:"New"})` | Create new record |
| `Collect(collection, record)` | `Collect(MyList, {Name:"Jane"})` | Add to collection |
| `ClearCollect(collection, table)` | `ClearCollect(MyList, Filter(DS, Active))` | Replace entire collection |
| `Clear(collection)` | `Clear(TempList)` | Empty a collection |
| `Remove(ds, record)` | `Remove(Employees, ThisItem)` | Delete a record |
| `RemoveIf(ds, condition)` | `RemoveIf(Employees, Status="Inactive")` | Delete matching records |
| `UpdateIf(ds, condition, changes)` | `UpdateIf(Orders, Region="West", {Tax: 0.1})` | Batch update |
| `Relate(table.rel, record)` | `Relate(Account.Contacts, contact)` | Link records (Dataverse) |
| `Unrelate(table.rel, record)` | `Unrelate(Account.Contacts, contact)` | Unlink records |
| `Refresh(datasource)` | `Refresh(OrdersList)` | Reload from server |

### 🔢 Math & Aggregates
| Function | Example | Returns |
|---|---|---|
| `Sum(table, expr)` | `Sum(Orders, Amount)` | Number |
| `Average(table, expr)` | `Average(Scores, Value)` | Number |
| `Min(table, expr)` | `Min(Orders, Price)` | Number |
| `Max(table, expr)` | `Max(Orders, Price)` | Number |
| `CountRows(table)` | `CountRows(Orders)` | Number |
| `CountIf(table, condition)` | `CountIf(Tasks, Done=true)` | Number |
| `Round(n, decimals)` | `Round(3.456, 2)` → 3.46 | Number |
| `RoundDown(n, d)` | `RoundDown(3.9, 0)` → 3 | Number |
| `RoundUp(n, d)` | `RoundUp(3.1, 0)` → 4 | Number |
| `Abs(n)` | `Abs(-5)` → 5 | Number |
| `Mod(n, d)` | `Mod(17, 5)` → 2 | Number |
| `Sqrt(n)` | `Sqrt(16)` → 4 | Number |
| `Power(base, exp)` | `Power(2,3)` → 8 | Number |
| `Int(n)` | `Int(4.9)` → 4 | Number |
| `Trunc(n)` | `Trunc(-4.9)` → -4 | Number |
| `Log(n, base)` | `Log(100, 10)` → 2 | Number |
| `Pi()` | `Pi()` → 3.14159… | Number |

### 📝 Text
| Function | Example | Returns |
|---|---|---|
| `Text(value, format)` | `Text(Today(), "dd/mm/yyyy")` | Text |
| `Value(text)` | `Value("42")` → 42 | Number |
| `Len(text)` | `Len("Hello")` → 5 | Number |
| `Upper(text)` | `Upper("hello")` → "HELLO" | Text |
| `Lower(text)` | `Lower("HELLO")` → "hello" | Text |
| `Proper(text)` | `Proper("john doe")` → "John Doe" | Text |
| `Trim(text)` | `Trim("  hi  ")` → "hi" | Text |
| `TrimEnds(text)` | `TrimEnds("  hi  ")` → "hi" (preserves internal spaces) | Text |
| `Left(text, n)` | `Left("abcdef", 3)` → "abc" | Text |
| `Right(text, n)` | `Right("abcdef", 2)` → "ef" | Text |
| `Mid(text, start, len)` | `Mid("abcdef", 2, 3)` → "bcd" | Text |
| `Find(needle, haystack)` | `Find("or", "World")` → 2 | Number |
| `StartsWith(text, prefix)` | `StartsWith("Hello", "He")` → true | Boolean |
| `EndsWith(text, suffix)` | `EndsWith("Hello", "lo")` → true | Boolean |
| `Replace(text, start, len, new)` | `Replace("Hello World", 7, 5, "!")` → "Hello !" | Text |
| `Substitute(text, old, new)` | `Substitute("a-b-c", "-", "/")` → "a/b/c" | Text |
| `Concat(table, expr, sep)` | `Concat(Items, Name, ", ")` → "A, B, C" | Text |
| `Concatenate(t1, t2, ...)` | `Concatenate("Hi", " ", name)` — same as `"Hi " & name` | Text |
| `Split(text, sep)` | `Split("a,b,c", ",")` → table of 3 rows | Single-col table |
| `Char(code)` | `Char(65)` → "A" | Text |
| `GUID()` | `GUID()` → "d4e3ac…" | Text |
| `IsMatch(text, pattern)` | `IsMatch(email, ".+@.+\..+")` | Boolean |
| `Match(text, pattern)` | `Match("AB12", "[A-Z]+")` → {FullMatch:"AB"} | Record |
| `MatchAll(text, pattern)` | `MatchAll("12 and 34", "\d+")` → table of matches | Table |

**Common `Text()` formats:**
```powerfx
Text(Today(), "dd mmm yyyy")          // "15 Apr 2026"
Text(Today(), "dddd")                  // "Wednesday"
Text(1234.5, "[$-en-US]$#,###.00")   // "$1,234.50"
Text(0.752, "0%")                      // "75%"
```

### 📅 Date & Time
| Function | Example | Returns |
|---|---|---|
| `Today()` | `Today()` | Date (no time) |
| `Now()` | `Now()` | DateTime |
| `UTCNow()` | `UTCNow()` | DateTime in UTC |
| `Date(y, m, d)` | `Date(2026, 4, 15)` | Date |
| `DateValue(str)` | `DateValue("15 Apr 2026")` | Date |
| `DateTimeValue(str)` | `DateTimeValue("15/04/2026 10:30")` | DateTime |
| `DateAdd(date, n, unit)` | `DateAdd(Today(), 30, Days)` | Date |
| `DateDiff(d1, d2, unit)` | `DateDiff(Start, End, Days)` | Number |
| `EDate(date, months)` | `EDate(Today(), 3)` | Date (3 months later) |
| `EOMonth(date, months)` | `EOMonth(Today(), 0)` | Last day of this month |
| `Year(date)` | `Year(Now())` → 2026 | Number |
| `Month(date)` | `Month(Today())` → 4 | Number |
| `Day(date)` | `Day(Today())` → 15 | Number |
| `Hour(dt)` | `Hour(Now())` | Number |
| `Minute(dt)` | `Minute(Now())` | Number |
| `Weekday(date)` | `Weekday(Today())` | Number (1=Sun by default) |
| `WeekNum(date)` | `WeekNum(Today())` | Number |
| `TimeZoneOffset()` | `TimeZoneOffset()` | Minutes offset from UTC |

**Unit enum values for DateAdd/DateDiff:**
`Days`, `Hours`, `Minutes`, `Months`, `Quarters`, `Years`, `Seconds`, `Milliseconds`

### ✅ Logic & Conditionals
| Function | Example |
|---|---|
| `If(cond, t, f)` | `If(x > 10, "High", "Low")` |
| `If(c1, r1, c2, r2, default)` | Multi-branch (no nesting needed) |
| `Switch(expr, v1, r1, v2, r2, def)` | `Switch(color, "R", Color.Red, "G", Color.Green, Color.Gray)` |
| `And(a, b)` / `a && b` | Both must be true |
| `Or(a, b)` / `a \|\| b` | Either must be true |
| `Not(a)` / `!a` | Inverts boolean |
| `IsBlank(value)` | True if null/empty |
| `IsEmpty(table)` | True if table has 0 rows |
| `IsError(value)` | True if value is an error |
| `IsBlankOrError(value)` | True if blank or error |
| `IfError(expr, fallback)` | Returns fallback if expr errors |
| `Coalesce(v1, v2, ...)` | First non-blank value |
| `Blank()` | Produces null/empty value |

### 🧭 Navigation & App
| Function | Syntax | Notes |
|---|---|---|
| `Navigate(screen, transition)` | `Navigate(HomeScreen, ScreenTransition.Fade)` | Switch screen |
| `Navigate(screen, tr, context)` | `Navigate(Detail, None, {item: ThisItem})` | Pass context variables |
| `Back()` | `Back()` | Go to previous screen |
| `Exit()` | `Exit()` | Close the app |
| `Launch(url)` | `Launch("https://example.com")` | Open URL or another app |
| `Param(name)` | `Param("id")` | Get URL parameter |

**ScreenTransition values:** `None`, `Fade`, `Cover`, `UnCover`, `CoverRight`, `UnCoverRight`

### 📋 Forms
| Function | Usage |
|---|---|
| `SubmitForm(form)` | Saves form data to data source |
| `ResetForm(form)` | Reverts form to original values |
| `NewForm(form)` | Sets form to create a new record |
| `EditForm(form)` | Sets form to edit existing record |
| `ViewForm(form)` | Sets form to read-only view |

### 🔔 Notifications & UI
| Function | Example |
|---|---|
| `Notify(msg, type)` | `Notify("Saved!", NotificationType.Success)` |
| `Reset(control)` | `Reset(TextInput1)` — revert to default |
| `SetFocus(control)` | `SetFocus(SearchBox)` — move cursor |
| `Select(control)` | `Select(Button1)` — simulate a click |
| `RequestHide()` | Close SharePoint custom form dialog |

**NotificationType values:** `Information`, `Warning`, `Error`, `Success`

### 💾 Variables
| Function | Scope | Example |
|---|---|---|
| `Set(name, value)` | Global (whole app) | `Set(currentUser, User().Email)` |
| `UpdateContext({name: val})` | Screen-local | `UpdateContext({showModal: true})` |
| `Navigate(screen, tr, {var: val})` | Passes to target screen as context | — |

> **Rule:** Use context variables (`UpdateContext`) for screen-local state (show/hide panels, toggle modes). Use global variables (`Set`) for data shared across screens. Avoid overusing globals — prefer named formulas or passing context through Navigate.

### 💾 Offline & Local Storage
| Function | Example |
|---|---|
| `SaveData(collection, key)` | `SaveData(MyCache, "CachedOrders")` |
| `LoadData(collection, key, ignoreErrors)` | `LoadData(MyCache, "CachedOrders", true)` |
| `ClearData(key)` | `ClearData("CachedOrders")` |

### 🌐 Environment & Signals
| Signal / Function | What it returns |
|---|---|
| `User().FullName` | Current user's display name |
| `User().Email` | Current user's email |
| `User().Image` | Current user's profile picture URI |
| `Connection.Connected` | Boolean — is there a network connection? |
| `Connection.Metered` | Boolean — is connection metered (mobile data)? |
| `Location.Latitude` | Number — device GPS latitude |
| `Location.Longitude` | Number — device GPS longitude |
| `App.Width` / `App.Height` | App canvas dimensions |
| `App.ActiveScreen` | Currently visible screen |

### 🤖 AI Functions (AI Builder)
| Function | What it does |
|---|---|
| `AISentiment(text)` | Returns sentiment (positive/negative/neutral) |
| `AISummarize(text)` | Returns a shorter summary |
| `AITranslate(text, lang)` | Translates text to target language |
| `AIClassify(modelId, text)` | Classifies text using a trained model |
| `AIExtract(modelId, text)` | Extracts entities from text |
| `AIReply(modelId, text)` | Generates a suggested reply |

> AI functions require AI Builder capacity in the tenant. Prebuilt functions (Sentiment, Summarize, Translate) don't need a custom model.

### 🧪 Debugging
| Function | Usage |
|---|---|
| `Trace(msg, severity, data)` | Sends to Monitor tool — not visible to users |
| `IfError(expr, fallback)` | Inline error catching |
| `Errors(datasource)` | Table of errors from last data operation |
| `IsError(value)` | Check if a value is in error state |

---

## Common Patterns

### Filter a gallery from a search box
```powerfx
// Gallery.Items:
Search(Orders, txtSearch.Text, "Title", "CustomerName")
```

### Conditional visibility
```powerfx
// Show a panel only when toggle is on:
pnlDetails.Visible = tglShowDetails.Value
```

### Create a new record
```powerfx
// Button OnSelect:
Patch(Orders, Defaults(Orders), {
    Title:   txtTitle.Text,
    Amount:  Value(txtAmount.Text),
    Status:  "Open",
    Created: Now()
});
Notify("Order created!", NotificationType.Success);
Reset(txtTitle); Reset(txtAmount)
```

### Delete selected gallery item
```powerfx
// Delete button OnSelect:
Remove(Orders, Gallery1.Selected);
Notify("Deleted", NotificationType.Warning)
```

### Navigate and pass context
```powerfx
// Gallery item OnSelect:
Navigate(DetailScreen, ScreenTransition.Cover, { selectedOrder: ThisItem })

// On DetailScreen, form Item:
selectedOrder
```

### Offline-first save
```powerfx
// Save button OnSelect:
If(
    Connection.Connected,
    Patch(Orders, Defaults(Orders), {Title: txtTitle.Text});
        Notify("Saved online"),
    Collect(PendingOrders, {Title: txtTitle.Text});
        SaveData(PendingOrders, "PendingOrders");
        Notify("Saved offline — will sync when online", NotificationType.Warning)
)
```

### Sync pending offline records on startup
```powerfx
// App.OnStart or screen OnVisible:
LoadData(PendingOrders, "PendingOrders", true);
If(
    Connection.Connected && !IsEmpty(PendingOrders),
    ForAll(PendingOrders, Patch(Orders, Defaults(Orders), ThisRecord));
    Clear(PendingOrders);
    ClearData("PendingOrders");
    Notify("Offline changes synced!")
)
```

### Dynamic color based on data
```powerfx
// Label Fill:
If(ThisItem.Status = "Overdue", RGBA(255,0,0,0.2),
   ThisItem.Status = "Done",    RGBA(0,200,0,0.2),
                                RGBA(200,200,200,0.1))
```

### Aggregate in a label
```powerfx
// Show total of filtered items:
"Total: " & Text(Sum(Filter(Orders, Region = ddRegion.Selected.Value), Amount), "$#,###")
```

### Validate before submitting
```powerfx
// Submit button OnSelect:
If(
    IsBlank(txtName.Text) || IsBlank(txtEmail.Text),
    Notify("Please fill all required fields", NotificationType.Error),
    !IsMatch(txtEmail.Text, ".+@.+\..+"),
    Notify("Invalid email format", NotificationType.Error),
    SubmitForm(EditForm1)
)
```

---

## Property Type Quick Reference

| Needs a... | Use this |
|---|---|
| Color | `Color.Red` / `ColorValue("#hex")` / `RGBA(r,g,b,a)` |
| Boolean | `true` / `false` / a condition expression |
| Number | A numeric literal or formula returning a number |
| Text | A string in quotes `"hello"` or formula returning text |
| Table | `Filter(...)`, `Search(...)`, a collection name, or `Table(...)` |
| Record | `LookUp(...)`, `First(...)`, `Gallery.Selected`, or `{Field: value}` |
| Enum | Use the enum name: `DisplayMode.Edit`, `ScreenTransition.Fade` |
| Date/DateTime | `Today()`, `Now()`, `Date(y,m,d)`, `DateValue("str")` |
| Image | A URL string, a camera's `.Photo` property, or `User().Image` |

> ⚠️ Never quote numbers or booleans. `Visible = "true"` is a type error — use `Visible = true`.

---

## Named Formulas (App-level)

Define in the App object's `Formulas` section — auto-recompute, no `Set()` needed:
```powerfx
TotalRevenue      = Sum(Orders, Amount)
ActiveUserCount   = CountRows(Filter(Users, Active = true))
CurrentUserOrders = Filter(Orders, Owner = User().Email)
```

---

## Delegation Warning

Delegation = data source processes the query server-side (handles large data).

- ✅ **Delegable:** `Filter`, `Sort`, `Search` on supported columns for SharePoint/Dataverse/SQL
- ❌ **Not delegable:** `CountRows` on Dataverse, `ForAll`, most text functions inside `Filter`, `GroupBy`

When not delegable, Power Apps fetches up to **500 records** (max 2000 via setting) locally. For large data, check the blue delegation warning in the formula bar and redesign the query or use server-side views.

---

## AI Code Generation — Canvas App Authoring MCP

> **Preview feature** (as of 2025). Lets AI tools like GitHub Copilot CLI and Claude Code create and edit canvas apps by generating `.pa.yaml` files and syncing them to a live Power Apps Studio coauthoring session.
>
> Official docs: https://learn.microsoft.com/en-us/power-apps/maker/canvas-apps/create-canvas-external-tools

### Prerequisites

| Requirement | Minimum | How to install |
|---|---|---|
| .NET SDK | **10.0** | `winget install --id Microsoft.DotNet.SDK.10 --silent` |
| GitHub Copilot CLI / Claude Code | Latest | `gh extension install github/gh-copilot` |
| Power Apps Studio | Any | Open app with **coauthoring enabled** (Settings → Updates → Coauthoring) |

### Install the Canvas Apps Plugin

Run these two commands inside GitHub Copilot CLI or Claude Code:

```
/plugin marketplace add microsoft/power-platform-skills
/plugin install canvas-apps@power-platform-skills
```

### Configure the Canvas MCP Server

1. Open your canvas app in Power Apps Studio — enable coauthoring if not already on.
2. Copy the full URL from the browser address bar.
3. In your AI tool, run:
   ```
   /configure-canvas-mcp
   ```
4. Paste the Power Apps Studio URL when prompted. The tool auto-extracts environment ID, app ID, and cluster.

### Available Skills / Commands

| Command | What it does |
|---|---|
| `/generate-canvas-app` | Create a new canvas app from a natural language description |
| `/edit-canvas-app` | Edit an existing app; syncs current state from coauthoring session first |
| `/configure-canvas-mcp` | Register the canvas app authoring MCP server with your AI tool |

### Create a New App — Workflow

1. **Describe** what you want:
   - "Create a canvas app for tracking inventory with a searchable list and detail view"
   - "Build a multi-step employee onboarding form with approval workflow"
   - "Make a dashboard showing sales metrics with charts and KPIs"
   - Attach an image or mockup to guide theming/layout
2. **Answer clarifying questions** — the AI discovers available controls and data sources via MCP.
3. **Review** — the AI generates `.pa.yaml` files per screen and validates them automatically.
4. **Test in Studio** — open Power Apps Studio; changes sync via the coauthoring session.
5. **Iterate** — describe further changes in natural language; repeat.

### Edit an Existing App — Workflow

1. Say: `"I want to edit my expense tracking canvas app"` — the tool syncs all current screens.
2. Describe changes:
   - "Add a filter to show only pending expenses"
   - "Change the home screen to a card-based grid layout"
   - "Add a new screen for expense history with charts"
3. AI generates updated `.pa.yaml` files, validates, and syncs.

### Revert Changes

If recent AI-generated changes break the app:
```
"The recent changes broke the app. Please revert to the last working version."
```
The AI syncs current state → identifies your changes → restores previous code → validates and resyncs.

### Troubleshooting

| Problem | Fix |
|---|---|
| Changes don't appear in Studio | Verify MCP connection (ask AI to list available controls); ensure coauthoring is on |
| MCP server not responding | Run `dotnet --version` — must be 10.0+; re-run `/configure-canvas-mcp` with fresh URL |
| Plugin install fails | Ensure you are inside GitHub Copilot CLI or Claude Code session |

### Best Practices

- **Start simple** — build basic structure first, then iterate to add complexity
- **Be specific** — detailed natural language prompts produce better initial code
- **Test frequently** — preview in Studio after each significant change
- **Bold design choices** — describe visual style and layout direction explicitly; don't accept generic defaults
- **Validate generated code** — always review `.pa.yaml` files for org compliance before publishing

> ⚠️ AI code generation makes a best-effort attempt at production-ready, accessible, secure code — but **you are responsible** for final review and validation.
