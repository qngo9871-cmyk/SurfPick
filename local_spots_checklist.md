# Surf Pick — Local Spots Coordinate Checklist

Goal: replace AI-generated coordinates with your verified ones for spots within ~50km of Ballina.

## How to fill this in

For each spot, using the **Google Maps app** on your iPhone:

1. **Open Google Maps**
2. **Search for the spot** (e.g. "Flat Rock Ballina") OR **navigate to where you know the surf break is**
3. **Long-press** the actual surf break location on the map until a red pin drops
4. **At the bottom of the screen, the place card shows the coordinates** as `lat, lon` (e.g. "-28.84221, 153.60567"). If you don't see them, tap the place card to expand it — coordinates appear under the address.
5. **Tap the coordinates to copy** them
6. **Paste them in this file** next to the spot name

Format: `lat, lon` — e.g. `-28.84221, 153.60567`

**Tip:** if the surf break has a Google Maps marker already (like "Flat Rock Beach Surf Spot"), tap directly on that marker instead of long-pressing — the coords will be more accurate to where Google's community has placed it.

If a spot:
- Doesn't really exist as a break → write `SKIP` and a note
- Coords look fine to you already → write `OK` (and the current coord)
- Should have a different name than what's in the dataset → write the new name

---

## EXISTING SPOTS IN DATASET (verify or fix)

These are already in the dataset within 50km of you. The current coords are LLM-generated and need verification.

### 1. Ballina
- Current: `-28.862, 153.589` (idealWind 240°)
- This is a generic name — what break does this actually mean? Lighthouse Beach? South Wall? Town centre?
- **Your verified coord:** `_______________`
- **Better name (if any):** `_______________`

### 2. Shelly Beach (Ballina)
- Current: `-28.873, 153.591` (idealWind 270°)
- **Your verified coord:** `_(-28.8630907, 153.5944663)______________`

### 3. Flat Rock (Ballina) ⚠️ KNOWN WRONG
- Current: `-28.849, 153.596` (idealWind 270°) — points at Skennars Head residential area, ~1.4km from real spot
- **Your verified coord:** `__(-28.8418467, 153.6044347)_____________`

### 4. Skennars Head
- Current: `-28.829, 153.597` (idealWind 270°)
- **Your verified coord:** `__(-28.8140097, 153.6050758)_____________`

### 5. Sharpes Beach
- Current: `-28.816, 153.596` (idealWind 270°)
- **Your verified coord:** `__(-28.8335629, 153.6047308)_____________`

### 6. Lennox Head
- Current: `-28.791, 153.593` (idealWind 225°)
- This is a generic name — what break does this actually mean? The Point? Main Beach? Boulders?
- **Your verified coord:** `_(-28.8065666, 153.6040569)______________`
- **Better name (if any):** `_______________`

### 7. Seven Mile Beach (Lennox)
- Current: `-28.767, 153.604` (idealWind 270°)
- **Your verified coord:** `_(-28.7579957, 153.5991833)______________`

### 8. Byron Bay (Main Beach)
- Current: `-28.643, 153.627` (idealWind 225°)
- **Your verified coord:** `_(-28.6409512, 153.6167226)______________`

### 9. Byron Bay (The Pass)
- Current: `-28.6364, 153.638` (idealWind 225°)
- **Your verified coord:** `_(-28.6377099, 153.6282276)______________`

### 10. Evans Head
- Current: `-29.117, 153.433` (idealWind 270°)
- **Your verified coord:** `_(-29.1077845, 153.4345051)______________`

---

## POSSIBLY MISSING SPOTS (add if relevant)

These are well-known local breaks I think might be missing. Add coords for any that should be in the app, skip the ones that aren't really surf spots or are too obscure.

### 11. Wategos Beach (Byron Bay)
- Protected nook on the headland, important on big northerly swells
- **Coord:** `_(-29.1077845, 153.4345051)______________`
- **idealWindBearing:** `____` (degrees the offshore wind comes FROM — for a north-facing beach like Wategos this is roughly 180° / S)

### 12. Tallows Beach (Byron Bay)
- South-facing beach, popular when northerlies blow out the main beach
- **Coord:** `___(-28.6583962, 153.6251343)____________`
- **idealWindBearing:** `____`

### 13. Broken Head
- Between Suffolk Park and Lennox
- **Coord:** `_(-28.7023938, 153.6139525)______________`
- **idealWindBearing:** `____`

### 14. Boulder Beach
- Between Lennox and Ballina
- **Coord:** `_(-28.8190908, 153.6038597)______________`
- **idealWindBearing:** `____`

### 15. Lighthouse Beach (Ballina)
- South side of Ballina, separate from the generic "Ballina" entry
- **Coord:** `_(-28.8687109, 153.5919075)______________`
- **idealWindBearing:** `____`

### 16. South Wall (Ballina)
- Richmond River mouth, popular on big swells
- **Coord:** `__(-28.8766466, 153.5857236)_____________`
- **idealWindBearing:** `____`

### 17. Brunswick Heads
- ~40km north — just inside the radius, classic NSW break
- **Coord:** `___(-28.5387328, 153.5566364)____________`
- **idealWindBearing:** `____`

### 18. Suffolk Park (Tallow Beach south end)
- South of Byron Bay
- **Coord:** `___(-28.6875762, 153.6155589)____________`
- **idealWindBearing:** `____`

### 19. (Add any other local spot I missed)
- **Name:** `__Angels Beach Ballina_____________`
- **Coord:** `___(-28.8530661, 153.5996269)____________`
- **idealWindBearing:** `____`

### 20. (Add any other local spot I missed)
- **Name:** `__Ballina North Wall_____________`
- **Coord:** `__(-28.8735292, 153.5897252)_____________`
- **idealWindBearing:** `____`

---

## Notes on idealWindBearing

This is the compass direction (in degrees) that the **offshore wind** comes from for that break. Offshore wind = clean waves. It's the direction wind blows FROM, not TO.

Quick reference for east-coast Australia (most NSW breaks face east-ish):
- **East-facing beach** (faces straight out to ocean): offshore wind comes from W → `idealWindBearing: 270`
- **NE-facing beach**: offshore from SW → `idealWindBearing: 225`
- **SE-facing beach**: offshore from NW → `idealWindBearing: 315`
- **N-facing beach** (like Wategos): offshore from S → `idealWindBearing: 180`
- **S-facing beach** (like Tallows): offshore from N → `idealWindBearing: 0` or `360`

If unsure, leave it as the default for that direction or write `?` and we'll figure it out.

---

## Once you're done

Save the file. Tell me "checklist done" and I'll:
1. Parse your verified coordinates
2. Patch the existing spots in surf_spots.json
3. Add the new spots
4. Rebuild the SurfShared package
5. Verify in the app on your iPhone
