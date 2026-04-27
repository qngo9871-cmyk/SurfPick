# Surf Pick — App Store Connect Submission Packet

Everything you need to paste into App Store Connect, in the order ASC presents the fields. Generated 2026-04-27.

**Version**: 1.0 | **Build**: 1 | **Bundle ID**: `com.quyenngo.surfpick`

---

## 0. Pre-flight (do once, in Apple Developer portal)

Your Xcode wildcard signing won't work for ASC — you need explicit App IDs.

Go to https://developer.apple.com/account → Certificates, Identifiers & Profiles → Identifiers → `+`:

1. **Main app**
   - Description: `Surf Pick`
   - Bundle ID: **Explicit** → `com.quyenngo.surfpick`
   - Capabilities: enable **In-App Purchase**

2. **Widget extension**
   - Description: `Surf Pick Widget`
   - Bundle ID: **Explicit** → `com.quyenngo.surfpick.SurfPickWidget`
   - Capabilities: none required

After both exist, the ASC "Create New App" dropdown will show them.

---

## 1. Create New App (ASC → My Apps → `+` → New App)

| Field | Value |
|---|---|
| Platforms | **iOS** (only — Surf Pick is iPhone-only) |
| Name | `Surf Pick` |
| Primary Language | **English (Australia)** |
| Bundle ID | `com.quyenngo.surfpick — Surf Pick` |
| SKU | `com.quyenngo.surfpick` |
| User Access | **Full Access** |

---

## 2. App Information page

### General Information
| Field | Value |
|---|---|
| App Name (Version page) | `Surf Pick: Wave Forecast` *(24/30 chars — adds searchable "Wave" + "Forecast")* |
| Subtitle | `Live tide, swell & wind` *(23/30 chars — indexes "live", "tide", "swell", "wind")* |
| Privacy Policy URL | `https://qngo9871-cmyk.github.io/SurfPick/privacy` *(verify the actual published URL — check what `/Users/user/SurfPick/privacy.md` resolves to on Pages)* |
| Category — Primary | **Weather** |
| Category — Secondary | **Sports** |

### Content Rights
- "Does your app contain, display, or access third-party content?" → **Yes**
- "Do you have all necessary rights to that third-party content?" → **Yes**
  - *(Open-Meteo marine + forecast data is licensed CC BY 4.0; attribution is in the in-app Info screen and privacy policy.)*

### Age Rating → Edit → answer the questionnaire

Every answer is **None** / **No** / **No** — Surf Pick is a 4+ utility app.

| Question | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| Horror/Fear Themes | None |
| Medical/Treatment Information | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Sexual Content or Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Gambling | None |
| Contests | None |
| Unrestricted Web Access | **No** *(no in-app browser)* |
| Made for Kids | **No** *(general-audience utility)* |

→ Resulting rating: **4+**

---

## 3. Pricing and Availability

### Base app
| Field | Value |
|---|---|
| Price | **USD 0.00 (Free)** |
| Availability | **All countries and regions** |
| Pre-order | Off |
| Make available on Apple Vision Pro | **Off (untick)** |
| Make available on Mac (Apple Silicon) | **Off (untick)** |

*(Both off because Surf Pick is iPhone-only — CoreLocation flow, CarPlay widget, and portrait UI are not designed for visionOS or macOS. Apple may flag mismatches if you leave them ticked.)*

### IAP (Surf Pick Pro) — set during IAP creation in §5
| Field | Value |
|---|---|
| Base price | **USD $4.99** |
| Base country | United States |
| Tax category | App Store Software |
| Availability start | Today (date of submission) |
| Availability end | No end date |
| Availability scope | All countries and regions |
| Family Sharing | On |

Apple auto-converts the USD base to ~175 storefronts. Sample preview:

| Storefront | Auto-converted price |
|---|---|
| 🇺🇸 USA | $4.99 |
| 🇦🇺 Australia | A$7.99 |
| 🇬🇧 United Kingdom | £4.99 |
| 🇪🇺 Eurozone | €5.49 |
| 🇨🇦 Canada | C$6.99 |
| 🇳🇿 New Zealand | NZ$8.99 |
| 🇯🇵 Japan | ¥800 |

You can override individual markets if needed, but auto-conversion is fine for v1.

---

## 4. App Privacy (the Nutrition Label)

→ "Get Started" → answer **No** to "Do you or your third-party partners collect data from this app?"

Reasoning to keep handy:
- Location is processed on-device only — never transmitted to your server.
- The only outbound data sent to Open-Meteo is the *spot's* lat/lon, not the user's.
- StoreKit purchases are handled by Apple — receipt verification doesn't constitute data collection by you.
- No analytics, no crash reporting SDK, no IDFA, no accounts.

Result: **"Data Not Collected"** label on the App Store.

If ASC pushes back on the location point: location used **on-device only and not stored** doesn't count as "collection." This is consistent with your privacy policy.

---

## 5. In-App Purchases & Subscriptions → Manage → `+`

Type: **Non-Consumable**

| Field | Value |
|---|---|
| Reference Name | `Surf Pick Pro` |
| Product ID | `com.quyenngo.surfpick.pro` |
| Price | **USD $4.99** *(Tier 5 in legacy pricing)* |
| Availability | All countries |
| Family Sharing | **On** *(non-consumables that unlock features should support Family Sharing — Apple favours this)* |

### IAP localization (Display Name ≤35 / Description ≤55)

Both fields are capped — there is no separate long-form description for IAPs. Add one localization per English locale you support.

| Locale | Display Name | Description |
|---|---|---|
| English (U.S.) | `Surf Pick Pro` | `10 nearest spots + widget. One-time, no subscription.` |
| English (U.K.) | `Surf Pick Pro` | `10 nearest spots + widget. One-time, no subscription.` |
| English (Australia) | `Surf Pick Pro` | `10 nearest spots + widget. One-time, no subscription.` |

### Review Information
- **Screenshot**: upload `Simulator Screenshot - iPhone 17 Pro Max - 2026-04-27 at 14.33.32_1284x2778.png` *(the paywall card with the "Unlock for $4.99" button)*
- **Review notes**:
  ```
  Surf Pick Pro is a one-time non-consumable IAP that unlocks the full ranked list (10 spots
  instead of 3), the home-screen widget, and the CarPlay widget. Tap "Unlock 7 more spots" on
  the main list, or open Settings → "Surf Pick Pro" to reach the paywall. Use any sandbox
  tester to confirm the unlock flow.
  ```

---

## 6. Version 1.0 — fill out the listing

### Promotional Text *(170 char max — editable without resubmit)*
```
Just shipped — Surf Pick checks the 10 nearest breaks and tells you exactly where to drive right now. Free shows the top 3, Pro unlocks the rest. Tap and go.
```
*(155 chars)*

### Description *(4000 char max)*
```
You've got an hour. Where do you go?

Surf Pick is a live surf forecast app that ranks the 10 nearest breaks near you right now. No graphs. No browsing. Just the spot — the one to drive to.

Built for surfers who want to spend the hour in the water, not on a forecast site comparing six tabs.

HOW IT WORKS

Open the app. It finds your location, pulls live wave height, period, wind and tide for the closest breaks, and ranks them by quality. Green means go. Amber means maybe. Red means sit this one out. Tap any spot for full conditions, or tap Get Directions to drive there in Google Maps or Apple Maps.

FREE

• The top 3 nearest spots, ranked by quality
• Traffic-light rating — green, amber, or red at a glance
• One-tap directions to whichever spot wins
• Live wave reports and tide charts from Open-Meteo's marine forecast
• Tap-through detail screen with 24-hour tide chart and full swell data

PRO — $4.99 one-time

• All 10 nearest spots, not just the top 3
• Home-screen widget showing today's pick
• Auto-CarPlay widget on iOS 26 — your pick on the dashboard
• One-time payment. No subscription. Yours forever.

WHY THIS APP EXISTS

Most surf forecast apps give you data and make you decide. Surf Pick decides. The #1 spot on the list is the one you should drive to. The whole point of the app is removing the comparison step.

WORLDWIDE COVERAGE

600+ surf spots are bundled in the app, from Bondi to Pipeline to Praia do Norte. If a local spot is missing or in the wrong place, tap Report on the detail screen and the developer fixes it in the next update.

PRIVACY

No accounts. No logins. No analytics. No ads. No tracking.

Your location is used on your device only and is never sent to a server. The only network calls Surf Pick makes are to Open-Meteo's free public weather API, and those calls only contain the coordinates of the surf spots being looked up — not yours.

Built independently in Australia. Weather data by Open-Meteo (CC BY 4.0).
```

### Keywords *(100 char max, comma-separated, no spaces)*
```
buoy,carplay,widget,nearby,break,beach,nearest,spot,ocean,report,conditions,marine,offshore
```
*(91 chars — zero overlap with title or subtitle; drops generics like "best"/"session"/"paddle" that don't move rank; adds differentiators "carplay"/"widget" and surf-vocabulary "buoy"/"marine"/"offshore")*

### Support URL
```
https://qngo9871-cmyk.github.io/SurfPick/support
```
*(verify the published URL of `/Users/user/SurfPick/support.md`)*

### Marketing URL
**Leave blank.** A broken marketing URL is a rejection; an empty one is fine.

### Version-specific Privacy Policy URL
**Leave blank.** ASC inherits the App-level Privacy Policy URL set in section 2.

### Screenshots — iPhone 6.9" Display (required)
Upload these in this order from `/Users/user/Downloads/`:

1. `Simulator Screenshot - iPhone 17 Pro Max - 2026-04-27 at 14.34.00_1284x2778.png` — **main ranked list (Pro view, 10 spots)**
2. `Simulator Screenshot - iPhone 17 Pro Max - 2026-04-27 at 14.21.38_1284x2778.png` — **free tier with locked state**
3. `Simulator Screenshot - iPhone 17 Pro Max - 2026-04-27 at 14.22.03_1284x2778.png` — **paywall (4-feature card, Unlock for $4.99)**
4. `Simulator Screenshot - iPhone 17 Pro Max - 2026-04-27 at 14.34.17_1284x2778.png` — **Get Directions → Apple Maps**
5. `Simulator Screenshot - iPhone 17 Pro Max - 2026-04-27 at 14.33.32_1284x2778.png` — **StoreKit purchase prompt**
6. `Simulator Screenshot - iPhone 17 Pro Max - 2026-04-27 at 14.33.48_1284x2778.png` — **purchase success**

### iPhone 6.5" Display
ASC will accept the 6.9" screenshots scaled down. You can leave 6.5" empty if 6.9" is filled.

### iPad
**No iPad screenshots needed.** Surf Pick is iPhone-only (`LSRequiresIPhoneOS=true` in Info.plist).

### App Preview Videos
**Skip for v1.0.** Add later if conversion needs a boost.

### General App Information
| Field | Value |
|---|---|
| Copyright | `© 2026 Quyen Ngo` |
| Routing App Coverage File | (none — not a maps app) |

### Build
After you Archive in Xcode and **Window → Organizer → Distribute App → App Store Connect → Upload**, the build appears here within ~10–30 minutes. Select build **1.0 (1)** when it appears.

### App Review Information
| Field | Value |
|---|---|
| Sign-In Required | **No** *(no accounts)* |
| Contact First Name | `Quyen` |
| Contact Last Name | `Ngo` |
| Contact Phone | `+61 425 409 937` |
| Contact Email | `qngo@icloud.com` *(use the iCloud one for App Review — not the gmail)* |
| Notes | *(see below)* |

**Review notes** (paste into the Notes field):
```
Surf Pick is the iPhone companion to my existing watchOS app Surf Near Me (bundle ID: com.quyenngo.surfnearme). The two apps target different platforms with intentionally different UX, and are companion products rather than duplicates:

• Surf Near Me (Apple Watch only) — glance complication, shows one surf spot at a time, sorted geographically for Digital Crown scrolling, no directions.

• Surf Pick (iPhone only) — decision tool, shows the 10 nearest spots ranked by surf quality with the best one prominent, includes Get Directions (Google Maps + Apple Maps), and a home-screen widget that auto-appears as a CarPlay widget on iOS 26.

Both apps share a forecast data layer (Open-Meteo), but the interaction model, ranking logic, feature set, and platform are distinct.

Sandbox testing notes: the Pro upgrade is a one-time non-consumable IAP at $4.99 (com.quyenngo.surfpick.pro). No login or test account is required — location permission is the only prerequisite to see the ranked list.
```

---

## 6.5 App Store Localizations

ASC → My Apps → Surf Pick → primary language dropdown (top right) → **Add Language**.

### Recommended for v1 — English variants (shared copy, market-tuned keywords)

| Locale | Status | Notes |
|---|---|---|
| English (Australia) | **Primary** | All copy as written above |
| English (U.S.) | **Add** | Mirror copy; swap keywords below |
| English (U.K.) | **Add** | Mirror copy; swap keywords below |

For each English locale, paste the same Subtitle / Promotional Text / Description as the Australia primary. Only the **Keywords** field changes per market.

**Keywords — English (Australia)** *(primary)*:
```
buoy,carplay,widget,nearby,break,beach,nearest,spot,ocean,report,conditions,marine,offshore
```

**Keywords — English (U.S.)** *(swap "ocean" → "coast")*:
```
buoy,carplay,widget,nearby,break,beach,nearest,spot,coast,report,conditions,marine,offshore
```

**Keywords — English (U.K.)** *(swap "nearest" → "cornwall" — #1 UK surf region)*:
```
buoy,carplay,widget,nearby,break,beach,cornwall,spot,ocean,report,conditions,marine,offshore
```

### Future v1.x localizations (full translation work, defer)

| Locale | Why high-value |
|---|---|
| Portuguese (Brazil) | Massive surf scene, large App Store, low English-only competition |
| Spanish (Mexico) | Surf coast + huge LATAM App Store reach |
| French (France) | Hossegor / Biarritz — strong surf market |
| Japanese (Japan) | Active surf scene + top-5 App Store revenue market |

Skip for v1 — add in v1.1 once initial submission is approved.

---

## 7. Version Release

| Field | Recommended |
|---|---|
| Release | **Manually release this version** *(so you can hit publish at a moment that suits you)* |
| Phased Release | **Off for v1.0** *(phased release is for established apps managing crash regression risk; first release just ship)* |

---

## 8. Final pre-submit checks

Before clicking **Add for Review** → **Submit to App Review**:

- [ ] All Sections show green ticks in the left sidebar
- [ ] Build 1.0 (1) selected
- [ ] All 6 screenshots uploaded in order
- [ ] Privacy Policy URL pings 200 (`curl -I https://qngo9871-cmyk.github.io/SurfPick/privacy`)
- [ ] Support URL pings 200 (`curl -I https://qngo9871-cmyk.github.io/SurfPick/support`)
- [ ] IAP "Surf Pick Pro" is in **Ready to Submit** state and attached to this version
- [ ] No "lorem", "TODO", "TBD" in any text field

---

## 9. After submission

- Apple usually responds in 24–48h.
- If you get an "Information Needed" message, it's a clarification, not a rejection — answer within 7 days.
- Don't push another build while in review (cancels and restarts the queue).
- Watch your iCloud email — App Review correspondence goes to the contact email you set above.

---

## Build-side TODO before you Archive

Quick verification in Xcode before the upload:

1. **Scheme is set to Release** (Product → Scheme → Edit Scheme → Run → Build Configuration = Release for the archive)
2. **Signing**: SurfPick target → Signing & Capabilities → Team is set, Provisioning Profile is "Automatic"
3. **TARGETED_DEVICE_FAMILY = 1** (iPhone only) — verify in Build Settings
4. **Archive**: Product → Destination = "Any iOS Device (arm64)" → Product → Archive
5. **Validate** the archive in Organizer first (catches signing/entitlement issues before upload)
6. **Distribute** → App Store Connect → Upload

Once the build appears in ASC (10–30 min, you'll get an email when it's processed), come back to section 6 → Build → select it → Submit.
