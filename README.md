# AutoDeposit
### by xLT69x — World of Warcraft 3.3.5 (WotLK) Addon — v1.5.5
<img width="1024" height="1024" alt="AutoDeposit Logo" src="https://github.com/user-attachments/assets/d4193030-e321-4608-928b-334a02d91626" />

### by xLT69x — World of Warcraft 3.3.5 (WotLK) Addon
<img width="442" height="601" alt="AutoDeposit demo" src="https://github.com/user-attachments/assets/659af944-3412-487e-82dc-d4a03cd3d65b" />

> Scan your bags, pick your items, and deposit them straight into the Guild Bank **or your Personal Bank** — all from one clean futuristic window.

---

## What's New in v1.5.5

| # | Feature |
|---|---------|
| 1 | **Version number** displayed in the top-right corner of the addon frame |
| 2 | **Minimap button** — shows the AutoDeposit logo (bundled `logo.tga`) on the minimap; click to open/close, drag to reposition |
| 3 | **Interface > AddOns panel** — open AutoDeposit settings via the standard WoW Interface screen |
| 4 | **Personal Bank support** — deposit directly to your character's own bank (added in v1.5.0, now stable) |
| 5 | **Auto-close window** — the window now closes automatically when you close the Guild Bank or Personal Bank |
| 6 | Version bumped to **1.5.5** in both `AutoDeposit.lua` and `AutoDeposit.toc` |

### Fixes in this build

- **Minimap button & Interface panel now actually appear.** Both were silently failing because the WoW 3.3.5 checkbox label uses the global `<name>Text` element, not the retail-era `.Text` property — the error aborted panel creation and blocked the minimap button. Both are now created on `PLAYER_LOGIN` for reliable initialization.
- **Minimap button resized and corrected.** The logo is now a small circular icon (cropped with `SetTexCoord`) framed by the standard minimap tracking border, instead of an oversized icon spilling past the ring.
- **Custom logo bundled as `logo.tga`** so it loads correctly on WoW 3.3.5 (which cannot read `.png`).

---

## Features

### Smart Bag Scanner
- Press **Bag Scan** to instantly scan all 5 bag slots (backpack + 4 bags).
- Only **depositable items** are shown — soulbound gear and quest items are automatically filtered out.
- The item list is sorted alphabetically for easy browsing.
- Hovering over any item shows its full **in-game tooltip**.

### Checkbox Item Selection
- Each item row has a **checkbox** — tick the ones you want to deposit.
- **Select All** checks every item in the list in one click.
- **Deselect All** unchecks everything so you can start fresh.
- Your selections are **saved between sessions**.

### Deposit Mode — Guild Bank or Personal Bank
- A **Deposit to:** row lets you switch between **Guild Bank** and **Personal Bank** with one click.
- In **Guild Bank** mode a tab dropdown lets you pick which bank tab receives the items.
- In **Personal Bank** mode items go straight to your character's bank — no tab required.
- Opening a Guild Bank or Personal Bank **automatically switches the mode** for you when auto-open is enabled.

### Queued Deposit System
- Items are sent one at a time with a safe 0.5 s gap — identical to a reliable macro but fully automated.
- Live progress indicator: `Depositing X / Y...` in the status bar.
- Slots are verified before each deposit; changed slots are safely skipped.
- The list auto-refreshes after the queue finishes.
- Double-click protection: the Deposit button is guarded until the current run completes.

### Minimap Button *(new in v1.5.5)*
- A circular button using the **AutoDeposit logo** sits on the edge of the minimap.
- The logo is shown as a small circular icon framed by the standard minimap ring — correctly sized, no longer oversized.
- **Left-click** to open or close the addon window.
- **Drag** to reposition the button anywhere around the minimap edge; position is saved between sessions.
- Hover shows a tooltip: *"Left-click to open / close — Drag to reposition"*.
- Can be hidden from **Interface > AddOns > AutoDeposit**.

> **Logo texture:** The logo ships as `logo.tga`, which WoW 3.3.5 loads natively (the client cannot read `.png`). No conversion needed — it just works.

### Interface > AddOns Panel *(new in v1.5.5)*
- Open via **Game Menu → Interface → AddOns → AutoDeposit**.
- Settings available in the panel:
  - ☑ **Auto-open at Bank / Guild Bank** — toggle the auto-open behaviour.
  - ☑ **Show Minimap Button** — hide or show the minimap button.
  - **Open AutoDeposit** button — launches the main window and closes the Interface panel.

### Version Label *(new in v1.5.5)*
- The current version number is shown in the **top-right corner** of the addon frame in cyan, so you always know which version is running.

### Auto-Open at Bank
- When enabled (default: on), the addon window automatically pops up whenever you open a **Guild Bank** or **Personal Bank**.
- The mode (Guild Bank / Personal Bank) is automatically set to match the bank you just opened.
- Toggle with the **Auto-open at Guild Bank** checkbox in the main window footer, or in the Interface panel.

### Auto-Close at Bank *(new in v1.5.5)*
- The addon window **automatically closes** when you close the Guild Bank or Personal Bank — no leftover window cluttering the screen.
- A deposit run in progress is never interrupted; the window only closes when no deposit is active.

### Live Status Bar
- Shows how many depositable items are in your bags and how many are selected.
- Updates in real-time as bags change (looting, trading, etc.).

### Futuristic UI Theme
- Deep navy/black background with an **electric cyan glowing border**.
- Colour-coded buttons: cyan for Bag Scan, green for Deposit, amber for Deselect All.
- Cyan hover highlight on every item row.
- Author credit footer: **xLT69x**.

### Movable Window
- Drag the title bar to move the window anywhere on screen.

---

## Installation

1. Download **AutoDeposit.zip** and extract it.
2. Place the `AutoDeposit` folder inside:
   ```
   World of Warcraft\Interface\AddOns\AutoDeposit\
   ```
3. Launch (or `/reload`) the game and enable **AutoDeposit** on the character select AddOns screen.
4. Type `/ad` in chat or click the **minimap button** to open the window.

> The minimap logo (`logo.tga`) is already included and loads natively on WoW 3.3.5 — no conversion needed.

---

## How to Use

### Guild Bank Deposit
1. Open the **Guild Bank** (talk to the Guild Banker NPC) — the window opens automatically.
2. Make sure **Guild Bank** is selected in the *Deposit to:* row.
3. Choose a tab from the **Guild Bank Tab** dropdown.
4. Tick items and click **Deposit**.

### Personal Bank Deposit
1. Open your **Bank** (talk to a Banker NPC) — the window opens automatically.
2. Make sure **Personal Bank** is selected in the *Deposit to:* row.
3. Tick items and click **Deposit**.

---

## Slash Commands

| Command | Action |
|---|---|
| `/ad` | Toggle the AutoDeposit window open / closed |
| `/autodeposit` | Same as `/ad` |
| `/ad scan` | Scan bags and print the depositable item count to chat |
| `/ad version` | Print the current addon version to chat |
| `/ad help` | Print all available commands to chat |

---

## Settings (Interface > AddOns)

Open via **Game Menu → Interface → AddOns → AutoDeposit**:

| Setting | Default | Description |
|---|---|---|
| Auto-open at Bank / Guild Bank | ✅ On | Auto-shows the window when you visit a bank |
| Show Minimap Button | ✅ On | Toggles the minimap logo button |

---

## Saved Variables

Stored in `WTF\Account\<name>\SavedVariables\AutoDepositDB.lua`:

| Variable | Description |
|---|---|
| `selectedItems` | Item IDs last checked in the list |
| `guildTab` | Last selected Guild Bank tab |
| `depositMode` | Last deposit mode (`"guild"` or `"bank"`) |
| `autoOpen` | Whether auto-open is enabled |
| `showMinimapBtn` | Whether the minimap button is visible |
| `minimapAngle` | Saved position of the minimap button (radians) |

---

## Version History

| Version | Changes |
|---|---|
| **1.5.5** | Version label in frame top-right; minimap button with bundled TGA logo (circular, correctly sized); Interface > AddOns panel; auto-close window when bank/guild bank closes; fixed checkbox `.Text` crash that blocked the panel & minimap button; both now created on `PLAYER_LOGIN`; version sync across .lua and .toc |
| 1.5.0 | Personal Bank deposit mode; auto-open at bank; futuristic UI theme; author branding |
| 1.4.0 | Queued deposit system — all selected items now deposit reliably |
| 1.3.0 | Fixed deposit API: switched to `UseContainerItem` (correct WotLK method) |
| 1.2.0 | Depositable-only filter via tooltip scanner, layout overhaul |
| 1.1.0 | Frame layout rebuilt, deposit state tracking fixed |
| 1.0.1 | Fixed `UIPanelButtonTemplate`, removed crash from nil texture call |
| 1.0.0 | Initial release |

---

## Author

**xLT69x** — WoW 3.3.5 private server enthusiast.

