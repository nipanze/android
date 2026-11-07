# Prompt: Add button on the Home tab row (categories as tabs)

Design source: the canvas "Home: filters follow my services", boards "Home: no services yet" and "Home: many services, Add stays pinned". Match them, using the app's existing theme, components and routes. The tabs in the live app are the person's provider categories (for example Finance, Business), so wherever the boards say "service tab", use "category tab".

## What it is

The Home tab row is: [For You] [category tabs...] then the Add button, then the filter button. The Add button has two forms:

1. NO CATEGORIES YET: a full dashed chip with a label: "+ Add service". It sits right after "For You". It is big enough to read and tap, because there is room.
2. HAS CATEGORIES: a compact 44px dashed square with only a "+" icon, pinned between the scrolling tabs and the filter button. It never scrolls away, even when there are many tabs. The tabs scroll sideways under a soft fade on the right edge.

Both are dashed purple (the provider colour), so they look like "something to add", not like a real tab. Both open Provider Services.

## Prompt for the coding agent

```
You are working in the Nipanze Flutter + Supabase app. Change ONLY the Home horizontal tab row. Do not change the cards, the feed, the filter sheet or the other tabs' behaviour.

FIRST: inspect and report, then WAIT for my OK. Tell me:
- which file builds the Home tab row (For You, category tabs, filter button) and where the tabs come from;
- how a person's provider categories are loaded and when the list is empty or still loading;
- the Provider Services route and how "add a service" starts today;
- the files you will edit and any conflict with this spec.

WHAT TO BUILD
1. Row layout, left to right: [scrolling tabs area, takes the remaining width] [Add button] [filter button]. The filter button is unchanged.
2. Scrolling tabs area: "For You" first, then one tab per category. It scrolls horizontally. Add a soft fade (about 36px) on its right edge when there is more to scroll, so people can tell. No visible scrollbar.
3. Add button, state A, the person has NO categories (the category list is loaded and empty):
   - a full chip with a dashed purple border (1.5px), a "+" icon and the label "Add service", placed inside the tabs area right after "For You";
   - height 40px (the same as the tabs), a 44px minimum tap area, white background, purple text and icon;
   - in this state the pinned compact button is NOT shown.
4. Add button, state B, the person has one or more categories:
   - a 44x44 square with a dashed purple border (1.5px), rounded about 12px, white background, and a purple "+" icon only;
   - pinned between the tabs area and the filter button. It does not scroll;
   - screen reader label "Add service".
5. While categories are loading, show neither form (no flicker), then show the right one.
6. Tap on either form: open Provider Services at the category picker. Do not create a service here.
7. If the person has reached their service limit for their plan, tap shows the existing "limit reached" message instead. The limit is enforced on the server; the button only reflects it.
8. Colours: the existing provider purple token (#6D4AFF). The active tab stays the app blue. Do not make the Add button look like a tab.

RULES
- Everything is behind capability_profiles_enabled. With the flag off, the row is unchanged.
- No SQL changes. If you think one is needed, stop and tell me; use only a NEW standalone patch file, never modify patch.sql or merged.sql, and do not run anything against production.
- 44px minimum tap targets. Status is not shown by colour alone. Respect the selected language and light and dark theme.
- Long tab names do not wrap; they stay on one line and the row scrolls.

DONE WHEN
Show the diff, the files changed, and 390px screenshots of: no categories (full "+ Add service" chip), two categories (compact "+" pinned), many categories (tabs scrolling, "+" still visible, fade on the right edge), and loading. Confirm that nothing else on Home changed and that nothing is outside capability_profiles_enabled.
```
