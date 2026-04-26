---
layout: default
title: Surf Pick — Privacy Policy
---

# Surf Pick — Privacy Policy

**Effective date:** 27 April 2026

Surf Pick is designed to give you a useful answer with the smallest possible amount of data about you. This policy describes what is collected, what isn't, and what happens to it.

## Plain-English summary

- Surf Pick uses your location only to find the surf breaks nearest to you.
- Your location stays on your device. It is never sent to a server.
- Surf Pick has no accounts, no logins, no analytics, no advertising, and no tracking.
- The only network requests Surf Pick makes are to a free public weather API (Open-Meteo), and those requests do not include any identifier for you.

## What is collected

**Precise location.** When you tap Refresh or open the app, Surf Pick reads your current location using Apple's Core Location framework. This location is used on your device, in real time, to:

1. Compute distances to known surf breaks in the bundled dataset.
2. Fetch wave and wind conditions for the 10 nearest breaks from Open-Meteo.

Your location coordinates are never written to a remote server. The only network calls Surf Pick makes are to `https://api.open-meteo.com/` and `https://marine-api.open-meteo.com/`, and those calls send only a *spot's* latitude and longitude (not yours) to fetch its forecast. Open-Meteo therefore receives the coordinates of the surf breaks you are looking up, not your personal location.

A short-lived cache of your last fetched location is held in memory and on disk for up to one hour, only on your device, so the app opens with recent data when you reopen it. This cache is purged on next refresh.

## What is not collected

Surf Pick does **not** collect, store, transmit, or share:

- Your name, email, or any account information (there are no accounts)
- Your device identifier, advertising identifier, or IDFA
- Your browsing history, app usage, screen views, or session data
- Crash reports or analytics of any kind
- Your contacts, photos, microphone, or camera
- Anything else.

## Third parties

- **Open-Meteo** ([open-meteo.com](https://open-meteo.com/)) provides marine and weather forecast data. Surf Pick sends Open-Meteo only the latitude and longitude of surf breaks. See [Open-Meteo's terms](https://open-meteo.com/en/terms) for their data handling.
- **Apple** processes In-App Purchase transactions (the one-time Pro unlock) via StoreKit. Surf Pick does not receive your Apple ID or payment information; only a verified entitlement that says "this device has Pro." See [Apple's privacy policy](https://www.apple.com/legal/privacy/).

There are no other third parties. No analytics SDKs, no advertising networks, no crash reporters, no usage tracking.

## Children's privacy

Surf Pick is rated 4+ and is suitable for all ages. It does not knowingly collect data from anyone, including children.

## Reporting a bad spot location

If you tap **"Report wrong location"** in the app, the iOS Mail app opens with a pre-filled email containing the spot name, its claimed coordinates, and the app version. You add the correct coordinates and send it from your own email account. Surf Pick does not transmit anything itself — the email is composed in your Mail app and sent on your behalf if you choose to send it.

## Changes to this policy

If this policy ever changes materially, the **Effective date** at the top will be updated. Material changes will also be summarised in the app's release notes.

## Contact

Questions about privacy: **[qngo9871@gmail.com](mailto:qngo9871@gmail.com?subject=Surf%20Pick%20privacy)**

---

Surf Pick is built by Quyen Ngo.
