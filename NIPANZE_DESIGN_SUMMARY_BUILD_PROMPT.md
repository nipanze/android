# Prompt: build the Provider Services, Account and Plans changes (summary of the design)

Design source: the "Provider Type Screen" canvas (Design artifact). Boards are named below. Match the canvas, but use the app's existing theme, components and routes.

```
You are working in the Nipanze Flutter + Supabase app (Uganda marketplace). Implement the changes below in PARTS. Do them one part at a time.

FIRST: inspect the code and report back, then WAIT for my OK before editing. For each part tell me: which files you will edit, what already exists, and any conflict with this spec. After my OK, edit only that part's screens.

STANDING RULES (apply to every part)
- Home and the Marketplace feed do not change (additive only).
- Everything new is behind capability_profiles_enabled.
- SQL goes only in NEW standalone, descriptive patch files. Do not modify patch.sql or merged.sql.
- Never run anything against production without my explicit approval. Never print secrets.
- Non-custodial. Loans and Forex behaviour is unchanged. No paid verification APIs.
- Verification never transfers between identities, categories or roles. A plan never grants verification.
- Per-capability verification policies stay: open / optional_proof / required_proof.
- No "Self-declared" labels. Do not show a switch or save as successful until the database call succeeds.
- Enforce all limits and rules on the server, concurrency-safe. The UI is not enough.
- 44px minimum tap targets. Status is shown with icon + text, not colour alone. Sheets scroll with the main button fixed at the bottom.

PART 1 · EACH CATEGORY STANDS ALONE (canvas note "Each category stands alone")
- There is no shared Work Profile screen or row. Remove the Work Profile row from Provider Services (Individual and Company).
- Roles, specialties, qualifications, proofs, years of experience, availability, languages and expected pay are saved PER CATEGORY. Nothing is copied or prefilled between categories. A person can be a Foreman in one category and a freelancer in another.
- Provider Services shows only service cards and role cards.

PART 2 · B2 "Who is offering?" (boards: B2 first time, B2 Company selected, B2 saved identity)
- Selection only. No inputs. Two cards: Individual, Company / Organization.
- A read-only PREVIEW (icon, name, category) extends ONLY on the selected card. One expanded at a time.
  - Individual: profile name, hint "Name and photo come from your Profile".
  - Company, none saved: "Your company name" in muted grey, hint "You add it in step 2". Saved: the company name, hint "Edit in step 2".
- Continue is always enabled. Keep the "Current" tag, the switching notice and the "does not verify you" note.
- Individual continues to roles. Company continues to services and roles. A changed identity goes through the existing confirm and review steps.

PART 3 · COMPANY DETAILS, step 2 (board: Company details and verification)
- Top section "How should you be shown?":
  - Company logo (optional): add, change, remove. JPG or PNG, up to 2 MB. Empty state is a dashed "+ Logo" button. Added state shows the logo, "Logo added", Change and Remove. Store in a private bucket with progress and retry. Show initials as the fallback.
  - Company name: required, the ONLY place it is edited.
  - Representative switch. When on, show a READ-ONLY card: the user's profile name and photo, a "Synced" tag and a "Change in Profile" link. Not editable here.
  - A live PREVIEW card.
- Below: registration number, team size, years in business, areas, Company verification, "Save company profile".
- Presentation is stored in provider_identity_presentations (display_mode company or company_with_representative).

PART 4 · SWITCH CONFIRM, S2 (board: S2 Confirm switch)
- Calm sheet "Switch to Company / Organization?" with an Individual -> Company chip row.
- Green "Kept safe" card (service info, accepted deals, reviews, history, personal job roles stay active). Blue "What changes" card (old services become inactive and restorable, new offers use the new identity, verification may be asked again and does not carry over).
- Continue / Cancel fixed at the bottom. The switch is atomic (switch_provider_identity RPC). Keep S4 consistent in tone and direction.

PART 5 · INDIVIDUAL ROLES, MULTI-SELECT AND UNTICK (boards: Roles untick, Qualifications untick)
- Ticking several roles shows ALL their details together through step 2 (role details) and step 3 (qualifications and proof). Unticking removes that role's questions.
- Unticking is never blocked or greyed out.
  - Nothing pending or approved: untick right away.
  - Pending proof: confirm sheet ("Withdraw this proof?"). Main button "Keep". Outlined red "Withdraw and untick". Withdrawing removes it from the review queue.
  - Approved proof: confirm sheet. Unticking removes the Nipanze badge.
  - Whole role with proof: sheet "Remove <role>?" listing what goes (specialties and qualifications hidden, proofs withdrawn, badges removed) and "Your answers are kept. Tick the role again to restore them." Buttons "Keep role" / "Remove role".
- Untick and withdraw happen as ONE server action. If Nipanze decides while a sheet is open, show the new state instead.

PART 6 · ROLES THAT NEED PROOF (boards: Step 1 roles, Step 3 required proof)
- Add requires_proof (boolean) and allowed proof types to the role catalogue. Do NOT hard-code role names. Examples: Security Specialist, Cybersecurity Specialist, Travel Consultant.
- Step 1: a small amber "Needs proof" tag at the right of the role card. Nothing else is added. Other roles look normal and can show the normal "approved proof" badge.
- Step 3: the required proof is its own block at the top, marked Required, with an upload button. The main button stays disabled ("Upload required proof to continue") until the proof is uploaded, then reads "Save and submit for review". Optional items stay optional.
- After upload the role is Pending Review. It is not shown to employers and cannot take offers until approved. Other roles are not affected. If rejected, the role goes back to proof needed with the reason and the user can upload again.
- Server rule: a role with requires_proof can never become Active without an approved proof.

PART 7 · PROFILE & VERIFICATION (board: Profile & Verification)
- Merge Edit Profile and Identity verification into one Account screen (dark theme).
- Order: photo with "Change profile picture", then ONE green KYC card (KYC Approved, divider, "Marketplace access unlocked" with the "5 of 5" pill and its chips), then Full name / Phone (locked) / District, then Additional Verification last. "Save changes" fixed at the bottom.
- Dropped: the separate Profile Picture card, "Identity verified" and its expiry line.

PART 8 · PLANS & PRICING (board: Plans & pricing)
- Loans and Needs are merged into REQUESTS. One shared active-requests counter per account across loans and Needs (decide with me whether Forex counts). Each request still shows its Loan or Need tag.
- Free: browse loans, Forex and Needs; 3 active requests; accept offers and responses.
- Provider 690 KES / month: everything in Free; 8 active requests; respond to Needs with full terms; alerts for new Needs in your categories; up to 10 active responses.
- Pro 1,790 KES / month: everything in Provider; 20 active requests; unlimited active responses; your response shown first to the requester; advanced filters for loans and Needs; response insights (seen, shortlisted, won); preferred loan terms and Forex rate; advanced trust insights.
- These limits (3 / 8 / 20 and 10 responses) are a starting guess. Put them in config or a table, not in code.
- Prices show "/ month". Use the word "requests" in Plans, limit messages ("3 of 3 active requests"), Activity and the Post button.
- Verification is NOT part of any plan. Never sell the Verified badge. A note on the screen says so.
- Gate limits and Pro features on the server by plan.

PART 9 · ADVANCED FILTERS, Pro (board: Advanced Filters)
- Top switch: All, Loans, Forex, Needs (same as the Home chips). Reset at the top. The main button shows the filter count ("Show results · 3 filters").
- Shared (All, and added to each type): Amount range (brackets only), Location, Verified requester toggle.
- Loans: your existing loan filters (employment type, monthly income range, suggested terms, institution matches).
- Forex: currency pair and buy or sell.
- Needs: Need type, urgency, has a clear budget, be among the first, matches my categories and roles.
- Filters only narrow results. Never reveal requester names, exact amounts or exact income. Existing loan filter behaviour stays as it is.

BUILD ORDER
1 Part 1 and Part 2 (identity chooser). 2 Part 3 and Part 4 (company path and switching). 3 Part 5 and Part 6 (roles and proof). 4 Part 7 (account). 5 Part 8 and Part 9 (plans and filters). Finish and show each part before the next.

DONE WHEN, for each part
Show the diff, the list of files changed, and screenshots at 390px width for each state on the canvas board. Confirm that Home and the Marketplace feed are unchanged, that nothing sits outside capability_profiles_enabled, and list every new SQL patch file by name (do not run them).
```
