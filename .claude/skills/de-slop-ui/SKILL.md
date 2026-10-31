---
name: de-slop-ui
description: Audit and rewrite a UI screen so it stops looking AI-generated ("slop") and reads like a deliberate, native-quality product. Use when the user says "de-slop", "unslop", "make this look less AI", "this UI looks generic", "polish this screen", or asks to make a frontend beautiful. Also use to turn a reference video or screenshots of a good UI into concrete design rules (scripts/extract_scenes.sh pulls one frame per scene change).
---

# de-slop UI

AI-generated UIs fail in the same predictable ways: everything gets a border, a
tint, a shadow and a pill; spacing is whatever Tailwind default came to mind;
color is spent on decoration instead of meaning. This skill removes that, one
measurable decision at a time.

The output is never "made it prettier". It is a **token table** plus a list of
**removed/changed elements**, each with a reason, then the code that applies
them, then a screenshot that proves it.

## Workflow

1. **Capture the current state.** Render the screen (Playwright is fine:
   `chromium.launch()`, 390x844 viewport for mobile, 1440x900 for desktop) and
   save `before.png`. Read the code that produces it.
2. **Audit** against the slop checklist below. Write each hit down as
   `element → problem → fix`.
3. **Fix the system, not the instance.** Before touching components, write the
   spacing/type/radius/color token table (see *Tokens*). Every value used on the
   screen must come from it. No one-off `mt-[13px]`.
4. **Apply** the fixes. Prefer deleting over restyling.
5. **Verify.** Render `after.png` at the same viewport, look at both images,
   and check: does every element still earn its place? Is any information lost
   (unread counts, timestamps, states)? De-slopping that drops information is a
   regression, not a fix.
6. **Report** the token table, the change list, and before/after images.

## Slop checklist

Each item is a common tell. Fix the ones present; don't invent problems.

**Containers and chrome**
- Borders *and* background *and* shadow on the same element. Pick one way to
  separate a surface from its context (usually: background tint only).
- Cards inside cards. Flatten: one level of surface per region.
- Hairline dividers between every list row *and* generous row padding. Use
  one: either spacing or a divider inset to the text column, not both full-width.
- Search fields with a tinted fill plus a colored border plus a focus ring at
  rest. At rest: one neutral fill, no border.

**Pills, chips, badges**
- Outlined pill filters where only one is selected. Selected = filled; the
  rest = plain text or a neutral fill. No outline on unselected chips.
- Badges on everything. Count badges only where the number changes behavior
  (unread count). Keep the count — don't replace it with a dot if the number
  matters; do make it smaller and quieter (neutral or brand, not alarm red,
  unless it's actually urgent).
- Emoji or icon in every heading/button.

**Color**
- More than one accent hue. One brand/accent color, used for the primary
  action and selected state only. Everything else is neutral.
- Pastel avatar/initial circles in random hues. Use photos when available,
  otherwise one neutral tone with initials, or a deterministic palette of
  ≤ 6 muted hues with matched lightness.
- Gradient backgrounds, gradient text, glows. Remove.
- Gray text on tinted background with insufficient contrast. Secondary text
  must still hit 4.5:1.

**Type**
- More than ~3 sizes and 2 weights on a screen. Collapse to a scale.
- Bold used for emphasis everywhere. Bold is for the one thing per row the
  eye should land on (e.g. the contact name, or the name *and* preview when
  unread).
- Title-cased UI copy ("Find A Conversation"). Use sentence case.
- Placeholder copy that explains the obvious ("Search for a conversation…").
  Shorter: "Search".

**Spacing and layout**
- Values off any grid (13px, 17px, 22px next to 24px). Snap to the scale.
- Inconsistent gutters: the header, search field, chips and list rows must
  share the same left edge.
- Content squeezed into a narrow column with dead space on the sides — or the
  opposite, text running edge to edge. Keep the gutter, use the width.
- Floating action button *and* header compose button. One primary action.

**Motion and states**
- Missing pressed/hover/focus states, or a `transition: all 0.3s` on
  everything. Short (120–200 ms) transitions on specific properties only.
- No empty, loading, or error state.

## Tokens

Write this table before writing code, filled with the values you chose. The
reference example (a de-slopped iOS chat list) used:

| Token   | Value | Use |
|---------|-------|-----|
| Gap     | 14 pt | between avatar and text, between stacked lines |
| Gutter  | 24 pt | left/right screen padding, shared by every element |
| Rows    | 98 pt | list row height (fixed, so the list has rhythm) |
| Filler  | 0 pt  | no extra padding/spacers outside the scale |
| Chips   | 36 pt | filter chip height (also the minimum tap height used) |
| Radius  | 22 pt | one radius for fields/cards; chips are fully round |

Also fix: a type scale (e.g. 34 / 17 / 15 / 13), two weights (regular,
semibold), one accent color, two neutral text colors (primary, secondary), one
surface tint. On the web, express them as CSS custom properties or Tailwind
theme values, never inline literals.

Native platforms have good defaults — on iOS follow the Human Interface
Guidelines (SF Pro sizes, 44 pt minimum hit targets); on Android, Material 3.
Matching the platform is usually more "un-slop" than inventing a style.

## Learning from a reference video

When the user gives a video of a good UI (or a before/after):

```bash
.claude/skills/de-slop-ui/scripts/extract_scenes.sh <video.mp4> <out_dir> [threshold]
```

It keeps the first frame, one frame per scene change (default threshold 0.25;
lower it to 0.1–0.15 for subtle UI transitions, raise it if you get dozens of
near-duplicates), writes `timestamps.txt`, and builds `contact.png`. Look at
the contact sheet first, then the individual frames. For each frame, write
down concrete, measurable rules (sizes, spacing, what was removed) and add the
good ones to this skill's checklist or token table — not vague adjectives
like "clean" or "modern".
