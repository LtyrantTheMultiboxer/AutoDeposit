# AutoDeposit
### by xLT69x — World of Warcraft 3.3.5 (WotLK) Addon
<img width="442" height="601" alt="AutoDeposit demo" src="https://github.com/user-attachments/assets/659af944-3412-487e-82dc-d4a03cd3d65b" />

> Scan your bags, pick your items, and deposit them straight into the Guild Bank — all from one clean futuristic window.

---

## Features

### Smart Bag Scanner
- Press **Bag Scan** to instantly scan all 5 bag slots (backpack + 4 bags).
- Only **depositable items** are shown — soulbound gear and quest items are automatically filtered out and hidden, so you never accidentally try to deposit something the bank won't accept.
- The item list is sorted alphabetically for easy browsing.
- Hovering over any item shows its full **in-game tooltip**.

### Checkbox Item Selection
- Each item row has a **checkbox** — tick the ones you want to deposit.
- **Select All** checks every item in the list in one click.
- **Deselect All** unchecks everything so you can start fresh.
- Your selections are **saved between sessions** — the addon remembers which item types you had checked even after logging out.

### Guild Bank Tab Selector
- A dropdown lets you choose **which Guild Bank tab** to deposit into.
- Tabs you don't have deposit permission for are shown greyed out and cannot be selected.
- The addon automatically refreshes the tab list when you open the Guild Bank.

### Queued Deposit System
- Clicking **Deposit** sends your selected items to the chosen Guild Bank tab one at a time, with a short delay between each — exactly like a reliable in-game macro but fully automated.
- A live progress indicator shows `Depositing X / Y...` in the status bar while the queue is running.
- Items are verified still in their slot before each deposit — if a slot changed, that entry is safely skipped.
- After the queue finishes, the item list automatically refreshes to reflect what is left in your bags.
- You cannot accidentally double-click Deposit mid-run — the button is guarded until the current queue completes.

### Live Status Bar
- Displays the number of depositable items found in your bags.
- Shows how many are currently selected in green.
- Updates in real-time as your bags change (looting, trading, etc.).

### Auto Bag Refresh
- The list silently refreshes whenever your bags change (via `BAG_UPDATE`), keeping it accurate without manual re-scanning.
- Auto-refresh is paused during an active deposit run so it does not interfere.

### Futuristic UI Theme
- Deep navy/black background with an **electric cyan glowing border**.
- Cyan-tinted header bar and accent lines.
- Colour-coded buttons: cyan for Bag Scan, green for Deposit, amber for Deselect All.
- Cyan hover highlight on every item row.
- Subtle dark-blue tinted scroll area.
- Author credit footer: **xLT69x**.

### Movable Window
- The frame can be **dragged anywhere** on screen by clicking and holding the title bar.
- Position resets to centre on next login (saved position coming in a future version).

### Slash Commands
| Command | Action |
|---|---|
| `/ad` | Toggle the AutoDeposit window open / closed |
| `/autodeposit` | Same as `/ad` |
| `/ad scan` | Scan bags and print the depositable item count to chat |
| `/ad version` | Print the current addon version to chat |
| `/ad help` | Print all available commands to chat |

---

## Installation

1. Download **AutoDeposit.zip**.
2. Extract the `AutoDeposit` folder.
3. Place the folder inside:
   ```
   World of Warcraft\Interface\AddOns\
   ```
   So the path looks like:
   ```
   Interface\AddOns\AutoDeposit\AutoDeposit.toc
   Interface\AddOns\AutoDeposit\AutoDeposit.lua
   ```
4. Launch (or reload) the game.
5. Enable **AutoDeposit** on the character selection AddOns screen.
6. Log in and type `/ad` in chat to open the window.

---

## How to Use

1. **Open the Guild Bank** by interacting with the Guild Banker NPC.
2. Type `/ad` (or `/autodeposit`) to open the AutoDeposit window.
3. Click **Bag Scan** — your depositable bag items will appear in the list.
4. **Tick the checkboxes** next to the items you want to send to the bank (or click **Select All**).
5. Use the **Guild Bank Tab** dropdown to choose which tab receives the items.
6. Click **Deposit** — items are sent one by one automatically.
7. Watch the status bar for live progress. The list refreshes when done.

---

## Notes

- You **must have the Guild Bank window open** before clicking Deposit. The addon will remind you if it is not open.
- Items you do not have deposit permission for on the selected tab will be rejected by the server — pick a tab you have access to.
- The 0.5-second delay between deposits is intentional and matches what the server allows for guild bank interactions.

---

## Saved Variables

The addon saves the following between sessions (stored in `WTF\Account\<name>\SavedVariables\AutoDepositDB.lua`):

| Variable | Description |
|---|---|
| `selectedItems` | The set of item IDs you last had checked |
| `guildTab` | The last Guild Bank tab you selected |

---

## Version History

| Version | Changes |
|---|---|
| 1.5.0 | Futuristic UI theme, cyan border, coloured buttons, author branding |
| 1.4.0 | Queued deposit system — all selected items now deposit reliably |
| 1.3.0 | Fixed deposit API: switched to `UseContainerItem` (correct WotLK method) |
| 1.2.0 | Depositable-only filter via tooltip scanner, layout overhaul |
| 1.1.0 | Frame layout rebuilt, deposit state tracking fixed |
| 1.0.1 | Fixed `UIPanelButtonTemplate`, removed crash from nil texture call |
| 1.0.0 | Initial release |

---

## Author

**xLT69x**
