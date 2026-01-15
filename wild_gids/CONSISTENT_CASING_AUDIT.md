# Consistent Casing Audit

This audit reviews user‑visible strings across the app to assess capitalization consistency. Recommended convention: sentence case for all UI text (capitalize only the first word and proper nouns/acronyms). This follows Material Design guidance. Exceptions: brand names, legal terms, and domain‑specific acronyms should preserve their official casing.

## Summary

- Overall: Mixed usage of sentence case, lowercase placeholders, and occasional English strings within Dutch UI.
- Primary inconsistencies:
  - Mixed language in tooltips/buttons (Dutch vs English).
  - Lowercase placeholders/hints alongside capitalized ones.
  - A few camelCase words embedded in user messages.
  - Ellipsis style inconsistencies (`...` vs `…`).

## Notable Findings (by file)

- Animals screen
  - [lib/screens/waarneming/animals_screen.dart#L64](lib/screens/waarneming/animals_screen.dart#L64): "Geen actieve animalSighting gevonden" — mixed language and camelCase.
  - [lib/screens/waarneming/animals_screen.dart#L287](lib/screens/waarneming/animals_screen.dart#L287): `hintText: 'zoeken'` — lowercase; consider "Zoeken" for sentence case.

- Location
  - [lib/widgets/location/location_data_card.dart#L45](lib/widgets/location/location_data_card.dart#L45): "Adres gekopieerd" — OK (sentence case).
  - [lib/widgets/location/location_data_card.dart#L62](lib/widgets/location/location_data_card.dart#L62): "Locatie wordt geladen..." — ellipsis style; prefer single character `…`.
  - [lib/widgets/location/location_data_card.dart#L116](lib/widgets/location/location_data_card.dart#L116): `tooltip: 'Kopieer adres'` — OK.
  - [lib/widgets/location/custom_location_map_widget.dart#L149](lib/widgets/location/custom_location_map_widget.dart#L149): "Tik op de kaart om een locatie te selecteren" — OK.
  - [lib/widgets/location/custom_location_map_widget.dart#L367](lib/widgets/location/custom_location_map_widget.dart#L367): "Annuleren" — OK.
  - [lib/widgets/location/custom_location_map_widget.dart#L379](lib/widgets/location/custom_location_map_widget.dart#L379): "Bevestigen" — OK.
  - [lib/screens/location/kaart_overview_screen.dart#L1124](lib/screens/location/kaart_overview_screen.dart#L1124): AppBar title "Kaart" — OK.
  - [lib/screens/location/kaart_overview_screen.dart#L1942](lib/screens/location/kaart_overview_screen.dart#L1942): `tooltip: 'Reset map rotation'` — English within Dutch UI.
  - [lib/screens/location/kaart_overview_screen.dart#L2014](lib/screens/location/kaart_overview_screen.dart#L2014): `tooltip: 'Center on me'` — English within Dutch UI.
  - [lib/screens/location/kaart_overview_screen.dart#L2054](lib/screens/location/kaart_overview_screen.dart#L2054): "Zoeken naar je locatie…" — OK (uses `…`).

- Belonging (schade)
  - [lib/widgets/belonging/belonging_crops_details.dart#L591](lib/widgets/belonging/belonging_crops_details.dart#L591): `label: Text('Bedrag in €')` — OK.
  - [lib/widgets/belonging/belonging_crops_details.dart#L666](lib/widgets/belonging/belonging_crops_details.dart#L666): `label: Text('Bedrag in €')` — OK.
  - [lib/widgets/belonging/belonging_crops_details.dart#L200](lib/widgets/belonging/belonging_crops_details.dart#L200): `hintText: 'Typ hier...'` — OK sentence case; ellipsis style.
  - [lib/widgets/belonging/belonging_crops_details.dart#L516](lib/widgets/belonging/belonging_crops_details.dart#L516): `hintText: 'Voer aantal in...'` — OK; ellipsis style.
  - [lib/screens/belonging/area_selection_map.dart#L580](lib/screens/belonging/area_selection_map.dart#L580): `label: Text('Ongedaan maken')` — OK.
  - [lib/screens/belonging/area_selection_map.dart#L596](lib/screens/belonging/area_selection_map.dart#L596): `label: Text('Wissen')` — OK.
  - [lib/screens/belonging/area_selection_map.dart#L633](lib/screens/belonging/area_selection_map.dart#L633): `label: Text('Gebied bevestigen')` — OK.
  - [lib/screens/belonging/area_selection_map.dart#L708](lib/screens/belonging/area_selection_map.dart#L708): Title "Prijs per m²" — OK.
  - [lib/screens/belonging/area_selection_map.dart#L714](lib/screens/belonging/area_selection_map.dart#L714): `hintText: 'bijv. 2,50'` — lowercase "bijv."; could be "Bijv." for sentence case.

- Filtering/Dropdowns
  - [lib/managers/filtering_system/dropdown_manager.dart#L105](lib/managers/filtering_system/dropdown_manager.dart#L105): `label: Text('Zoek een dier...')` — OK; ellipsis style.
  - [lib/managers/filtering_system/dropdown_manager.dart#L138](lib/managers/filtering_system/dropdown_manager.dart#L138): "Deze functie komt binnenkort beschikbaar" — OK.
  - [lib/widgets/animals/animal_list_table.dart#L555](lib/widgets/animals/animal_list_table.dart#L555): `label: Text('type..')` — lowercase and double-dot; suggest "Type…".
  - [lib/widgets/animals/animal_list_table.dart#L634](lib/widgets/animals/animal_list_table.dart#L634): `label: Text('typ hier...')` — lowercase; suggest "Typ hier…".

- Auth/Terms
  - [lib/widgets/login/verification_code_input.dart#L369](lib/widgets/login/verification_code_input.dart#L369): "Verificatiecode opnieuw verzonden" — OK.
  - [lib/widgets/login/verification_code_input.dart#L377](lib/widgets/login/verification_code_input.dart#L377): "Kon code niet verzenden. Probeer het later opnieuw." — OK.
  - [lib/screens/terms/terms_screen.dart#L105](lib/screens/terms/terms_screen.dart#L105): "Kon voorwaarden niet accepteren: ..." — OK.
  - [lib/screens/terms/terms_screen.dart#L148](lib/screens/terms/terms_screen.dart#L148): `hintText: 'Voer uw weergavenaam in'` — OK.
  - [lib/screens/login/login_screen.dart#L242](lib/screens/login/login_screen.dart#L242): `hintText: 'e-mailadres'` — acceptable Dutch hyphenation/casing; optional "E-mailadres" for sentence case.

- Questionnaire
  - [lib/widgets/questionnaire/questionnaire_open_response.dart#L311](lib/widgets/questionnaire/questionnaire_open_response.dart#L311): `hintText: 'Schrijf hier uw antwoord...'` — OK; ellipsis style.
  - [lib/widgets/questionnaire/questionnaire_multiple_choice.dart#L285](lib/widgets/questionnaire/questionnaire_multiple_choice.dart#L285): `labelText: 'Toelichting'` — OK.
  - [lib/widgets/questionnaire/questionnaire_home.dart#L167](lib/widgets/questionnaire/questionnaire_home.dart#L167): `tooltip: 'Overslaan'` — OK.

- Logbook/History
  - [lib/screens/logbook/waarneming_history_screen.dart#L274](lib/screens/logbook/waarneming_history_screen.dart#L274): Title "Details" — OK.
  - Several labels starting with uppercase ("Beschrijving:", "Locatie:") — OK.
  - [lib/screens/logbook/verkeersongeval_history_screen.dart#L284](lib/screens/logbook/verkeersongeval_history_screen.dart#L284): Title "Details" — OK.

## Recommendations

1. Adopt sentence case across the app for:
   - AppBar titles, buttons, labels, SnackBars, dialogs, tooltips, hints/placeholders.
2. Normalize ellipses to a single glyph `…` for consistency.
3. Unify language to Dutch in the UI (replace remaining English strings unless intentionally bilingual).
4. Replace any camelCase internal words in user-facing text with Dutch equivalents (e.g., "animalSighting" → "waarneming"/"dierwaarneming").

## Next Steps (upon approval)

- I can apply fixes to flagged lines to enforce the chosen convention without changing functionality, in a focused PR.
