# Prompt: floating "Add service" edge button on the "What do you need?" screen

Design source: the new canvas "Home: filters follow my services", board "What do you need? with a floating Add service button". Match it, using the app's existing theme, components and routes.

## What it is (plain description)

A small purple tab with a white "+" that sits on the right edge of the screen, just above the bottom bar. It is flat on the right and rounded on the left, and part of it is always off the screen edge, like the new-message button in Instagram. It is tilted a little, about 9 degrees, so it looks like it is leaning into the edge. It is thin: about 64px wide and 44px tall.

It moves with the person's scrolling:
- Resting: most of the tab shows, with the "+" visible.
- Scrolling down: it slides further into the edge. Only a small part with the "+" peeks out, so it never covers a card.
- Scrolling up, or when scrolling stops for about a second: it slides back out.
- Tap: opens Provider Services so the person can add a service they offer.

It is purple (the provider colour), not blue, so it is not mistaken for a request card or for the blue "+" in the bottom bar, which means "post a request".

## Prompt for the coding agent

```
You are working in the Nipanze Flutter + Supabase app. Add ONE floating edge button to the "What do you need?" screen (route /needs/create). Change nothing else on that screen, and do not touch the cards, search, drafts or the Something else row.

FIRST: inspect and report, then WAIT for my OK. Tell me:
- which file builds the "What do you need?" screen and its scroll view;
- where the Provider Services route is, and how "add a service" is started today;
- whether there is a shared floating-button or overlay widget I should reuse;
- the files you will edit and any conflict with this spec.

WHAT TO BUILD
1. A small floating tab, on the right edge of the screen, above the bottom navigation bar (about 88px above the bottom of the screen). It overlays the screen content and does not push the layout.
2. Look:
   - colour: the provider purple already used in the app (#6D4AFF or the existing token);
   - about 64px wide and 44px tall; rounded only on the left corners (radius about 18px), flat on the right;
   - a white "+" icon (about 22px, stroke about 2.4) near the left of the tab;
   - tilted about 9 degrees anticlockwise (rotate -9deg), with a soft shadow;
   - no text label.
3. Resting position: shifted about 10px past the right edge, so most of the tab is visible.
4. Scrolling down (offset increases by more than a few pixels): animate the tab about 28px further past the right edge, so only a small part with the "+" shows. Keep the "+" visible.
5. Scrolling up, or no scroll for about 900ms: animate back to the resting position.
6. Animation: about 280ms, ease-out. If the system "reduce motion" setting is on, change position with no animation.
7. Tap: open Provider Services (the existing route). Do not create a service here.
8. The tap area must be at least 44x44 logical pixels, even if the drawn tab is smaller. Give the tab a screen reader label "Add service" and the role of a button. The "+" icon is decorative.
9. Hide it while the keyboard is open (the search box is focused) and when a sheet or dialog is open.
10. Hide it, and show the existing "service limit reached" message on tap instead, if the person has reached their service limit for their plan. The limit is enforced on the server; the button only reflects it.

RULES
- Everything is behind capability_profiles_enabled. Existing behaviour with the flag off is unchanged.
- No SQL changes. If you think one is needed, stop and tell me; use only a NEW standalone patch file, never modify patch.sql or merged.sql, and do not run anything against production.
- Use the existing theme colours and widgets. No new packages for this.
- Respect the selected language for the screen reader label. Works in light and dark theme.
- Do not change the blue "+" in the bottom bar or any other screen.

DONE WHEN
Show the diff, the files changed, and screenshots at 390px width for: resting, tucked while scrolling down, with the keyboard open (hidden), and reduce motion on. Confirm that nothing else on the screen changed and that nothing is outside capability_profiles_enabled.
```
