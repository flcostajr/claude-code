---
name: de-slop-ui
description: Audit and rewrite a UI screen so it stops looking AI-generated ("slop") and reads like a deliberate, native-quality product. Use when the user says "de-slop", "unslop", "make this look less AI", "this UI looks generic", "polish this screen", or asks to make a frontend beautiful. Also use to turn a reference video or screenshots of a good UI into concrete design rules (scripts/extract_scenes.sh pulls frames from a video).
---

# de-slop UI

AI-generated UIs fail in the same predictable ways: everything gets a border, a
tint and a pill; spacing is whatever value came to mind; color is spent on
decoration instead of meaning; there's a sparkle "AI" banner nobody asked for.
This skill removes that in fixed passes, one measurable decision at a time.

The output is never "made it prettier". It is a **token table** plus a list of
**removed/changed elements**, each with a reason, then the code that applies
them, then a screenshot that proves it.

Reference material in `references/`:
- `before-after.png`: the chat list this skill was distilled from, before and after.
- `token-panels.png`: the exact token panels used for that pass.

## Workflow

1. **Capture the current state.** Render the screen (Playwright is fine:
   `chromium.launch()`, 390x844 viewport for mobile, 1440x900 for desktop) and
   save `before.png`. Read the code that produces it.
2. **Audit** against the slop checklist below. Write each hit down as
   `element → problem → fix`.
3. **Run the five passes in order** (see *The five passes*). Each pass sets
   tokens first, then applies them. Every value on the screen must come from a
   token. No one-off `mt-[13px]`.
4. **Verify.** Render `after.png` at the same viewport and look at both. Check
   that no information was lost (see *Don't over-correct*).
5. **Report** the filled token table, the change list, and before/after images.

## The five passes

The reference redesign applied these in this order. Order matters: spacing
and type set the skeleton; color, materials and imagery go on top.

### 1. Spacing

| Token  | Value | Rule |
|--------|-------|------|
| Gap    | 14 pt | between avatar and text, between title and subtitle. Snap odd values (13 → 14). |
| Gutter | 24 pt | left/right padding, shared by header, search, chips and rows: one left edge. |
| Rows   | 98 pt | fixed list row height. Generous rows replace divider lines. |
| Filler | 0 pt  | no spacer elements or padding outside the scale. |
| Chips  | 36 pt | filter chip height. |
| Radius | 22 pt | fields and cards; chips and buttons are fully round. |

### 2. Type

| Token | Value | Rule |
|-------|-------|------|
| Font  | SF Pro (system stack on web: `-apple-system, system-ui, …`) | one family. |
| Title | 27 pt, bold, left-aligned | big screen title, replaces a small centered nav title. |
| Names | 16 pt, semibold | the one thing in each row the eye should land on. |
| Body  | 14 pt, regular | previews, secondary text in a darker gray than the timestamp. |

Sentence case everywhere. Timestamps smaller and lighter than body.

### 3. Colour

| Token    | Value | Rule |
|----------|-------|------|
| Canvas   | light neutral gray (≈ #F2F2F4), not pure white | gives the glass surfaces something to sit on. |
| Dividers | 0 pt  | remove row dividers; spacing separates rows. |
| Filters  | neutral gray | chips are gray, never brand blue. Selected chip = slightly darker gray. |
| Unread   | one small blue dot | the only accent color left on the list. |

One accent hue total. No red unless something is actually wrong.

### 4. Glass (materials)

| Element | Treatment |
|---------|-----------|
| Search  | glass field, no colored border, magnifier icon + short placeholder |
| Filters | glass chips |
| Button  | glass circle with `+`, replacing the solid blue compose button |
| Icons   | plain line glyphs (search, plus), no filled colored circles |

On the web, glass is:

```css
.glass {
  background: rgb(255 255 255 / 0.6);
  backdrop-filter: blur(20px) saturate(180%);
  -webkit-backdrop-filter: blur(20px) saturate(180%);
  border: 0.5px solid rgb(255 255 255 / 0.7);
  box-shadow: 0 1px 2px rgb(0 0 0 / 0.06), inset 0 1px 0 rgb(255 255 255 / 0.8);
}
```

Use it on controls only (search, chips, buttons), never on list rows or text
blocks. On iOS 26+, use the system Liquid Glass material instead of faking it.

### 5. People (imagery)

| Token     | Value | Rule |
|-----------|-------|------|
| Portraits | Photos | real photos (or group/place images) instead of pastel initials circles. Small green dot for online. |
| Circle    | on | a horizontal row of top contacts ("Your circle") above search, with first names under each avatar. |

When there are no photos, fall back to one neutral tone for initials circles,
not a rainbow.

## Slop checklist

What the reference "before" screen had, and what generic AI UIs usually have.
Fix the ones present; don't invent problems.

- **AI feature banners** ("✨ AI smart replies" strip). Remove from the main
  surface; put the feature where it's used (e.g. inside the composer).
- **Small centered nav title** on a top-level screen. Use a large left-aligned title.
- **Solid brand-colored circular button** in the header. Neutral/glass button, simple glyph.
- **Search field with tint + colored border** at rest. One neutral fill, no border.
- **Blue filled + blue outlined chips.** Neutral chips; selected = darker neutral.
- **Pastel initials avatars** in random hues. Photos, or one neutral tone.
- **Red count badges** on every row. Quieter unread indicator (see below).
- **Full-width hairline dividers** plus row padding. Pick spacing; drop the lines.
- **Off-grid values** (13 pt next to 14 and 24). Snap to the scale.
- **Borders and background and shadow** on the same element. Pick one.
- **Cards inside cards.** One surface level per region.
- **Emoji/icons in every heading,** title-cased copy, wordy placeholders.
- **Gradients, glows, more than one accent color.**
- **`transition: all`** everywhere, or no pressed/focus states at all.
  Use 120–200 ms transitions on specific properties.
- **Missing empty, loading and error states.**

## Don't over-correct

Replies to the reference post called out real regressions. Avoid them:

- **Don't drop information for looks.** The redesign replaced unread *counts*
  with a dot. If the count matters to the user, keep it: a small neutral or
  accent pill with the number, not alarm red.
- **Don't duplicate content.** A "circle" row of contacts that are also the
  first rows of the list wastes space. Show it only if it holds something the
  list doesn't (pinned people, stories, online now).
- **Don't shrink the content area** just to add whitespace. Keep the 24 pt
  gutter and use the rest of the width.
- **"Use Apple's guidelines" isn't the whole job.** The value is in the specific
  tokens and removals. Write them down, apply them, and check them in the screenshot.

## Learning from a reference video

When the user gives a video of a good UI (or a before/after):

```bash
.claude/skills/de-slop-ui/scripts/extract_scenes.sh <video> <out_dir> [threshold] [fallback_fps]
```

It keeps the first frame and one frame per scene change (threshold default
0.25). Screen recordings of smooth UI animations have no hard cuts, so if
fewer than 3 frames pass, it falls back to sampling at `fallback_fps` (default
1/s). It writes `timestamps.txt` and `contact.png`. Look at the contact sheet
first, then crop the frames that matter at full resolution
(`ffmpeg -ss <t> -i video -frames:v 1 -vf crop=w:h:x:y out.png`), especially
any panels listing values. Turn what you see into concrete tokens and removals
in this file. No vague adjectives like "clean" or "modern".
