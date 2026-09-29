# Swahili handover — Ruaha 360

Generated 2026-09-29 from `src/i18n/en/common.json`. Do not edit by hand;
regenerate with `pnpm i18n:handover`.

## What this is

Every user-facing string in the application, with its Swahili **draft**,
for a **native Kiswahili reviewer** to correct. The string list is frozen:
every screen is built, so the keys will not move while the work is under
way.

**The Swahili here is an unreviewed draft.** It was written by Claude from
a sourced glossary (`docs/i18n-glossary.md`) and back-translated blind as a
cross-check. That catches some errors and not others, and a native reader
has not seen it. It ships so the demo is usable in Swahili, with the
status column recording honestly which strings a native reviewer has been
through. Where a draft is wrong, correct it: a wrong Swahili string is
worse than English, because English is visibly untranslated and a wrong
string is not.

## Priority

- **Required** — the farmer and officer surfaces, and the chrome both of
  them render. 599 strings. CLAUDE.md specifies these ship
  complete Swahili.
- **Optional** — Ops and Tower. 383 strings. These may ship
  English for the demo.

982 strings in total: 2 reviewed, 597 draft, 383 missing. 173 flagged for a closer look (see the Flag note).

## How to read the table

- **Status** is `draft` until a native reviewer has been through the
  string, `reviewed` once they have, and `missing` if there is no Swahili
  yet.
- `{{value}}` and its siblings are placeholders. They must appear in the
  translation exactly as written, or the string will render broken.
- The Notes column carries product requirements from CLAUDE.md, not style
  advice. "Estimate", "indicative" and "planned capacity" are claims about
  what the programme does and does not promise; a translation that
  strengthens them misrepresents it.
- A survey incentive is a fixed cash amount paid at the office. It is never
  earnings, a wallet, a balance or a payment.
- Terms marked `unverified` in `docs/i18n-glossary.md` had no Tanzanian
  source. Check those first.
- Flag anything whose meaning is unclear rather than guessing. A gap is a
  question; a wrong string is a defect nobody sees.

## Required — farmer and officer surfaces

| Key | English | Swahili | Status | Notes |
| --- | --- | --- | --- | --- |
| `a11y.breadcrumb` | Breadcrumb | Njia ya kurasa | draft | Flag: Drafter: 'Njia ya kurasa' composed; no glossary term for breadcrumb (screen-reader label only). |
| `a11y.language` | Language | Lugha | draft | Flag: Drafter: 'Lugha' unverified as UI label. |
| `a11y.primaryNav` | Primary navigation | Urambazaji mkuu | draft |  |
| `a11y.skipToContent` | Skip to content | Ruka hadi kwenye maudhui | draft | Flag: Drafter: 'Ruka hadi kwenye maudhui' composed; 'Ruka' unverified. |
| `auditTrail.blocked` | Could not redeem: {{reason}} | Haikuweza kukabidhiwa: {{reason}} | draft | Keep {{reason}} Flag: Drafter: 'Could not redeem' -> 'Haikuweza kukabidhiwa' (redeem = kabidhi, glossary UNVERIFIED). Subject concord assumes 'vocha/motisha' unspecified; may need adjusting. |
| `auditTrail.empty` | Nothing recorded yet. | Bado hakuna kilichorekodiwa. | draft |  |
| `auditTrail.heldForAudit` | Held for an in-person audit | Imeshikiliwa kwa ukaguzi wa ana kwa ana | draft | Flag: Drafter: 'in-person audit' -> 'ukaguzi wa ana kwa ana' (composed; 'ukaguzi' UNVERIFIED). |
| `auditTrail.idSeen` | ID checked: {{type}} | Kitambulisho kilichokaguliwa: {{type}} | draft | Keep {{type}} |
| `auditTrail.idType.driving_licence` | Driving licence | Leseni ya udereva | draft | Flag: Drafter: 'Leseni ya udereva' UNVERIFIED in glossary. |
| `auditTrail.idType.nida` | NIDA card | Kitambulisho cha Taifa (NIDA) | draft |  |
| `auditTrail.idType.village_letter` | Village letter | Barua ya kijiji | draft | Flag: Drafter: 'Barua ya kijiji' is a composed name for the ID-substitute document; exact Tanzanian name unknown. |
| `auditTrail.idType.voter` | Voter card | Kadi ya mpiga kura | draft |  |
| `auditTrail.kind.answered` | Survey answered | Dodoso limejibiwa | draft |  |
| `auditTrail.kind.household_registered` | Household registered | Kaya imesajiliwa | draft |  |
| `auditTrail.kind.household_verified` | Household verified | Kaya imehakikiwa | draft |  |
| `auditTrail.kind.issued` | Voucher issued | Vocha imetolewa | draft |  |
| `auditTrail.kind.login_initial` | App login created | Akaunti ya programu imeundwa | draft |  |
| `auditTrail.kind.login_reset` | App password reset | Neno la siri la programu limerudishwa | draft |  |
| `auditTrail.kind.redeemed` | Incentive handed over | Motisha imekabidhiwa | draft |  |
| `auditTrail.kind.refused` | Scan refused | Skani imekataliwa | draft | Flag: Drafter: 'Scan refused' -> 'Skani imekataliwa'; glossary suggests 'imezuiwa' for policy blocks. Chose imekataliwa to match 'refused'. |
| `auditTrail.kind.scanned` | Voucher scanned | Vocha imeskaniwa | draft | Flag: Drafter: 'imeskaniwa' passive of loan 'skani'; unattested. |
| `auditTrail.kind.survey_published` | Survey published | Dodoso limechapishwa | draft | Flag: Drafter: 'published' -> 'limechapishwa'; 'kuchapisha' is print/publish, may read as printed. Alternative 'limetolewa'. Cross-check (natural): 'limechapishwa' back-translates as 'printed/issued'; for a survey made live in the app it may read as printed on paper (drafter also flagged). |
| `auditTrail.kind.voided` | Voucher cancelled | Vocha imeghairiwa | draft |  |
| `auditTrail.reason` | Reason: {{reason}} | Sababu: {{reason}} | draft | Keep {{reason}} |
| `auditTrail.role.admin` | Admin | Msimamizi | draft | Flag: Drafter: 'Msimamizi' (glossary UNVERIFIED). |
| `auditTrail.role.farmer` | Farmer | Mkulima | draft |  |
| `auditTrail.role.field_officer` | Field officer | Afisa wa uwandani | draft | Flag: Drafter: 'Afisa wa uwandani' per glossary decision (composed, unverified). |
| `auditTrail.role.ops` | Ops | Uendeshaji | draft | Flag: Drafter: 'Ops' role -> 'Uendeshaji' (glossary UNVERIFIED, means 'operations'). |
| `auditTrail.role.unknown` | Unknown role | Jukumu halijulikani | draft |  |
| `auditTrail.title` | Audit trail | Kumbukumbu za ukaguzi | draft | Flag: Drafter: 'Audit trail' = 'Kumbukumbu za ukaguzi' (glossary UNVERIFIED). Cross-check (natural): 'Kumbukumbu za ukaguzi' back-translates as 'audit records (records of checking)'; it reads as a list of inspections rather than a who-did-what trail. Glossary-locked, so only for the native reviewer. |
| `capacityBasis.nameplate` | Nameplate | Kibao cha mashine | draft | Capacity is PLANNED or NAMEPLATE, never measured. Always shown with its basis. Flag: Drafter: 'Kibao cha mashine' (machine plate) is a short label; glossary only has a long unverified phrase. Must stay distinct from 'Uliopangwa' and never read as measured. Cross-check (meaning): 'Kibao cha mashine' (back: 'Machine plate') names the object, not a rated/nameplate figure, and 'kibao' alone can mean signboard or tablet; it may not read as a stated rating that is not measured. Native/energy reviewer should confirm. |
| `capacityBasis.planned` | Planned | Uliopangwa | draft | Capacity is PLANNED or NAMEPLATE, never measured. Always shown with its basis. Flag: Drafter: 'Uliopangwa' agrees with 'uwezo' (capacity), since this label sits next to a capacity figure. May need a different class agreement if used beside another noun. |
| `common.back` | Back | Rudi nyuma | draft |  |
| `common.close` | Close | Funga | draft |  |
| `common.loading` | Loading… | Inapakia… | draft | Flag: Drafter: 'Inapakia…' unverified per glossary. |
| `common.no` | No | Hapana | draft |  |
| `common.optional` | optional | si lazima | draft | Flag: Drafter: 'si lazima' unverified per glossary (alt 'hiari'). |
| `common.yes` | Yes | Ndiyo | draft |  |
| `confidence.high` | High | Juu | draft | Confidence level recorded with a figure. Low / medium / high. |
| `confidence.low` | Low | Chini | draft | Confidence level recorded with a figure. Low / medium / high. Flag: Drafter: 'Chini/Wastani/Juu' scale words not attested for confidence. |
| `confidence.medium` | Medium | Wastani | draft | Confidence level recorded with a figure. Low / medium / high. |
| `cycleDetail.harvests` | Harvest figures | Kiasi cha mavuno | draft |  |
| `cycleDetail.measure` | Planted | Kiasi kilichopandwa | draft | Flag: Drafter: Label 'Planted' whose value is area, tree count or unit count; 'Kilichopandwa' composed. Cross-check (meaning): "Kilichopandwa" reads as "What was planted", which a farmer may take to mean the crop name, but the value is a quantity (area, trees or units). |
| `cycleDetail.noHarvestsDetail` | Nobody has recorded an expected or actual figure for this cycle. | Hakuna aliyerekodi kiasi kinachotarajiwa wala halisi kwa msimu huu wa zao. | draft | Flag: Drafter: 'cycle' = 'msimu wa zao' (glossary UNVERIFIED). |
| `cycleDetail.noHarvestsTitle` | No harvest figure yet | Bado hakuna kiasi cha mavuno | draft |  |
| `cycleDetail.notFoundDetail` | It may not exist, or it may be outside your villages. | Huenda haupo, au uko nje ya vijiji vyako. | draft |  |
| `cycleDetail.notFoundTitle` | Crop cycle not found | Msimu wa zao haukupatikana | draft |  |
| `cycleDetail.season` | Season | Msimu | draft | Flag: Drafter: 'Season' = 'Msimu'; free-text value from officer, taxonomy open (S22). |
| `cycleDetail.seriesNote` | A harvest figure is a series. A revised estimate does not erase the one it replaced. | Kiasi cha mavuno ni mfululizo wa rekodi. Makadirio yaliyorekebishwa hayafuti yale ya awali. | draft |  |
| `cycleDetail.status` | Status | Hali | draft |  |
| `cycleDetail.superseded` | superseded | imebadilishwa na mpya | draft | Flag: Replaced after the cross-check. Meaning: this figure was replaced by a newer one and is excluded from totals. Drafter: 'imepitwa na mpya' (overtaken by a newer one) is my composition; agreement varies with the noun. Cross-check (meaning): "imepitwa na mpya" was read as "overtaken by a new one"; it does not clearly say the figure was replaced and is excluded from totals (superseded), and the agreement is fixed to one noun class. |
| `cycleDetail.trees_one` | 1 tree | mti 1 | draft |  |
| `cycleDetail.trees_other` | {{count}} trees | miti {{count}} | draft | Keep {{count}} |
| `cycleDetail.units_one` | 1 unit | kitengo 1 | draft | Flag: Drafter: 'Unit' as a crop count (not equipment) rendered 'kitengo'/'vitengo'; unsure what the unit is (e.g. hives, beds). Also unused in source. |
| `cycleDetail.units_other` | {{count}} units | vitengo {{count}} | draft | Keep {{count}} |
| `cycleDetail.window` | Harvest window | Kipindi cha kuvuna | draft |  |
| `cycleStatus.abandoned` | Abandoned | Imeachwa | draft | Flag: Drafter: 'Imeachwa' for Abandoned cycle; plain word, not in glossary. |
| `cycleStatus.growing` | Growing | Inakua | draft |  |
| `cycleStatus.harvested` | Harvested | Imevunwa | draft |  |
| `cycleStatus.planned` | Planned | Imepangwa | draft |  |
| `dbError.addPhoneFirst` | Add a phone number before issuing a login. | Ongeza namba ya simu kabla ya kutoa akaunti ya kuingia. | draft | Flag: Drafter: 'Login' (issuing a login) rendered 'akaunti ya kuingia' (composed); consistent across personHasLogin, phoneHasLogin. Glossary has 'kadi ya kuingia' for the printed card. |
| `dbError.choosePasswordFirst` | Choose a new password first. | Chagua neno la siri jipya kwanza. | draft |  |
| `dbError.confirmIdName` | Confirm that the name on the ID matches the household. | Thibitisha kwamba jina kwenye kitambulisho linalingana na kaya. | draft |  |
| `dbError.cropNeedsArea` | This crop is measured by area, so the planted area is required. | Zao hili hupimwa kwa eneo, kwa hiyo eneo lililopandwa linahitajika. | draft |  |
| `dbError.cropNeedsTrees` | This crop is measured by tree count, so the number of trees is required. | Zao hili hupimwa kwa idadi ya miti, kwa hiyo idadi ya miti inahitajika. | draft |  |
| `dbError.cropNeedsUnits` | This crop is measured by unit count, so the number of units is required. | Zao hili hupimwa kwa idadi ya vitengo, kwa hiyo idadi ya vitengo inahitajika. | draft | Flag: Drafter: 'Unit count' rendered 'idadi ya vitengo' (composed). |
| `dbError.farmLocationRequired` | The farm location is required: capture the GPS position before saving. | Mahali shamba lilipo panahitajika: rekodi mahali kwa kutumia GPS kabla ya kuhifadhi. | draft | Flag: Drafter: 'Capture the GPS position' rendered 'chukua nafasi ya GPS' (composed; 'nafasi' = position/space). Reviewer to check. |
| `dbError.householdNeedsChecking` | Your household record needs checking by an officer. | Rekodi ya kaya yako inahitaji kukaguliwa na afisa. | draft | Flag: Drafter: 'Checking' rendered 'kukaguliwa' (not 'kuhakikiwa') to keep it distinct from formal verification; reviewer may prefer hakiki. |
| `dbError.householdNeedsSecondVerifier` | Your household must be verified by a second staff member. | Kaya yako lazima ihakikiwe na mfanyakazi wa pili. | draft | Flag: Drafter: 'Staff member' rendered 'mfanyakazi' (not in glossary). Also used in voucher and staffPasswordNotHere strings. |
| `dbError.householdNotVerified` | Your household has not been verified yet. | Kaya yako bado haijahakikiwa. | draft |  |
| `dbError.notAwaitingVerification` | That record is not awaiting verification. | Rekodi hiyo haisubiri kuhakikiwa. | draft |  |
| `dbError.notLinkedToFarmer` | Your account is not linked to a registered farmer. | Akaunti yako haijaunganishwa na mkulima aliyesajiliwa. | draft |  |
| `dbError.personNotFound` | That person was not found, or is outside your villages. | Mtu huyo hakupatikana, au yuko nje ya vijiji vyako. | draft |  |
| `dbError.phoneFormat` | The phone number must be a Tanzanian mobile number, for example +255 712 345 678. | Namba ya simu lazima iwe namba ya simu ya mkononi ya Tanzania, kwa mfano +255 712 345 678. | draft |  |
| `dbError.phoneHasLogin` | This phone number already has an app login. | Namba hii ya simu tayari ina akaunti ya kuingia kwenye programu. | draft |  |
| `dbError.phoneRequired` | A phone number is required so the farmer can sign in. | Namba ya simu inahitajika ili mkulima aweze kuingia. | draft |  |
| `dbError.questionChooseOne` | Question {{position}}: choose one of the listed options. | Swali {{position}}: chagua mojawapo ya chaguo zilizoorodheshwa. | draft | Keep {{position}} |
| `dbError.questionChooseSome` | Question {{position}}: choose from the listed options. | Swali {{position}}: chagua kutoka kwenye chaguo zilizoorodheshwa. | draft | Keep {{position}} |
| `dbError.questionEnterNumber` | Question {{position}}: enter a number. | Swali {{position}}: andika namba. | draft | Keep {{position}} |
| `dbError.questionRequired` | Question {{position}} is required. | Swali {{position}} ni lazima. | draft | Keep {{position}} |
| `dbError.questionTooLong` | Question {{position}}: answer in at most 2000 characters. | Swali {{position}}: jibu lisizidi herufi 2000. | draft | Keep {{position}} |
| `dbError.questionYesNo` | Question {{position}}: answer yes or no. | Swali {{position}}: jibu ndiyo au hapana. | draft | Keep {{position}} |
| `dbError.recordIdDocument` | Record which ID document you checked. | Andika aina ya kitambulisho ulichokagua. | draft |  |
| `dbError.recordNotFound` | That record was not found, or it is outside your villages. | Rekodi hiyo haikupatikana, au iko nje ya vijiji vyako. | draft |  |
| `dbError.redeemOwnHousehold` | You cannot redeem a voucher for your own household. | Huwezi kukabidhi vocha ya kaya yako mwenyewe. | draft |  |
| `dbError.redeemOwnRegistration` | You registered this household, so another staff member must redeem this voucher. | Ulisajili kaya hii, kwa hiyo mfanyakazi mwingine lazima akabidhi vocha hii. | draft |  |
| `dbError.redeemOwnVerification` | You verified this household, so another staff member must redeem this voucher. | Ulihakiki kaya hii, kwa hiyo mfanyakazi mwingine lazima akabidhi vocha hii. | draft |  |
| `dbError.setOwnPasswordFirst` | Set your own password before answering surveys. | Weka neno la siri lako mwenyewe kabla ya kujibu madodoso. | draft |  |
| `dbError.signInFirst` | Sign in first. | Ingia kwanza. | draft |  |
| `dbError.staffPasswordNotHere` | This person signs in as staff, so their password cannot be reset here. | Mtu huyu huingia kama mfanyakazi, kwa hiyo neno lake la siri haliwezi kurudishwa hapa. | draft | Flag: Cross-check (natural): 'kurudishwa' alone reads as 'returned', not 'reset' (back-translation lost 'reset'); follows the glossary 'Rudisha neno la siri' but is ambiguous in a sentence. |
| `dbError.surveyClosed` | This survey is closed. | Dodoso hili limefungwa. | draft |  |
| `dbError.surveyLimitReached` | This survey has reached its limit. | Dodoso hili limefikia kikomo chake. | draft |  |
| `dbError.surveyNotFound` | This survey could not be found. | Dodoso hili halikupatikana. | draft |  |
| `dbError.surveyNotInVillage` | This survey is not open in your village. | Dodoso hili halijafunguliwa katika kijiji chako. | draft |  |
| `dbError.surveyOpenedBeforeRegistration` | This survey opened before your household was registered. | Dodoso hili lilifunguliwa kabla kaya yako haijasajiliwa. | draft |  |
| `dbError.verifyOtherOfficer` | A household must be verified by someone other than the officer who registered it. | Kaya lazima ihakikiwe na mtu mwingine, si afisa aliyeisajili. | draft |  |
| `dbError.voucherAlreadyRedeemed` | This voucher was already redeemed on {{date}} by {{name}}. | Motisha ya vocha hii ilishakabidhiwa tarehe {{date}} na {{name}}. | draft | Keep {{date}} {{name}} Flag: Drafter: 'Redeemed' rendered 'imekabidhiwa' (handed over) for officer-facing errors; farmer-facing status elsewhere is 'imechukuliwa'. Confirm which wording the reviewer wants across the app. Applies also to ...ByOther, redeemOwn*, voucherHeldForAudit. Cross-check (meaning): 'Redeemed' is rendered 'kabidhiwa' (handed over), so the back-translation reads as the voucher itself being handed over rather than redeemed for cash; the same verb is used for ByOther, redeemOwnRegistration, redeemOwnVerification, redeemOwnHousehold, voucherHeldForAudit and tour.officer.redeemBody, and differs from the farmer-facing 'imechukuliwa'. |
| `dbError.voucherAlreadyRedeemedByOther` | This voucher was already redeemed on {{date}} by another staff member. | Motisha ya vocha hii ilishakabidhiwa tarehe {{date}} na mfanyakazi mwingine. | draft | Keep {{date}} Flag: Changed after the cross-check; unreviewed. |
| `dbError.voucherExpired` | This voucher expired on {{date}}. | Vocha hii iliisha muda wake tarehe {{date}}. | draft | Keep {{date}} Flag: Drafter: 'iliisha muda wake' from glossary 'imeisha muda wake' [UNVERIFIED]. |
| `dbError.voucherHeldForAudit` | This voucher is held for an audit: ops or admin must redeem it in person. | Vocha hii imeshikiliwa kwa ukaguzi: mtu wa uendeshaji au msimamizi lazima aikabidhi ana kwa ana. | draft |  |
| `dbError.voucherNotFound` | Voucher not found. | Vocha haikupatikana. | draft |  |
| `dbError.voucherVoided` | This voucher was voided: {{reason}} | Vocha hii imebatilishwa: {{reason}} | draft | Keep {{reason}} Flag: Drafter: 'Voided' rendered 'imebatilishwa' (cancelled/annulled); not in glossary. |
| `demoBanner.detail` | Every figure here is invented. Nothing is a measured Ruaha result. | Kila takwimu hapa ni ya kubuni. Hakuna hata moja ambayo ni matokeo yaliyopimwa ya Ruaha. | draft | Flag: Drafter: Reworded to 'takwimu ... ya kubuni' (invented figures); native check that 'ya kubuni' reads as fictitious and not 'creative'. 'Si matokeo yaliyopimwa' keeps the not-measured meaning. |
| `demoBanner.label` | Demo data | Taarifa za majaribio | draft | Flag: Drafter: 'Taarifa za majaribio' unverified per glossary. |
| `draft.earlierVersionSaved` | An earlier version of this form was already saved. Open it from the list to check it. | Toleo la awali la fomu hii lilishahifadhiwa. Lifungue kutoka kwenye orodha ili kulikagua. | draft | Flag: Changed after the cross-check; unreviewed. |
| `draft.notSubmitted` | Not yet submitted | Haijawasilishwa bado | draft | Flag: Drafter: 'Haijawasilishwa bado' from glossary, unsourced. |
| `draft.storageError` | Could not save this draft on this device. Keep this page open until you submit. | Rasimu hii haikuweza kuhifadhiwa kwenye kifaa hiki. Acha ukurasa huu wazi hadi uwasilishe. | draft | Flag: Drafter: 'Rasimu' (draft) and 'kifaa' (device) ; 'Acha ukurasa huu wazi' for 'Keep this page open' composed. |
| `empty.noAccessDetail` | You may not have access to these records, or there are none yet. | Huenda huna ruhusa ya kuona rekodi hizi, au bado hakuna. | draft |  |
| `empty.noAccessToThis` | Nothing to show | Hakuna cha kuonyesha | draft |  |
| `equipment.days` | Days per week | Siku kwa wiki | draft |  |
| `equipment.daysDecimals` | Use at most 1 decimal place. | Tumia desimali isiyozidi 1. | draft |  |
| `equipment.daysRange` | Days per week run from 0 to 7. | Siku kwa wiki ni kuanzia 0 hadi 7. | draft |  |
| `equipment.estimateBlockedDetail` | Fill in how many, hours per day and days per week, and the estimate appears here. | Jaza idadi, saa kwa siku na siku kwa wiki, na makadirio yataonekana hapa. | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `equipment.estimateBlockedTitle` | No estimate yet | Bado hakuna makadirio | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `equipment.estimateImpossibleDetail` | One of the figures above is outside what is possible, so no estimate is shown for it. Correct it and the estimate returns. | Moja ya namba zilizo hapo juu iko nje ya kinachowezekana, kwa hiyo hakuna makadirio yanayoonyeshwa kwake. Irekebishe, na makadirio yatarudi. | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. Flag: Drafter: Idiom 'nje ya kinachowezekana' for 'outside what is possible' is composed; check naturalness. |
| `equipment.estimateImpossibleTitle` | This cannot be estimated | Hili haliwezi kukadiriwa | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `equipment.hours` | Hours per day | Saa kwa siku | draft |  |
| `equipment.hoursDecimals` | Use at most 2 decimal places. | Tumia desimali zisizozidi 2. | draft |  |
| `equipment.hoursRange` | Hours per day run from 0 to 24. | Saa kwa siku ni kuanzia 0 hadi 24. | draft |  |
| `equipment.indicative` | Indicative | Ya makadirio | draft | Prices are INDICATIVE, never quotations. Must not read as a firm offer. |
| `equipment.indicativePrice` | Indicative price | Bei ya makadirio | draft | Prices are INDICATIVE, never quotations. Must not read as a firm offer. |
| `equipment.intro` | Powered equipment available through the programme. | Vifaa vya umeme vinavyopatikana kupitia mradi. | draft | Flag: Drafter: 'Programme' = 'programu' also means 'app' in Tanzanian Swahili; reviewer to choose 'mpango' or 'programu'. Also 'powered equipment' = 'vifaa vya umeme' (assumed electric). Cross-check (natural): "programu" also means "app" in Tanzanian Swahili (the back-translator flagged both readings), and "vifaa vya umeme" narrows "powered equipment" to electric. The same applies to "programu" in equipment.noneDetail. |
| `equipment.moreThanZero` | This must be more than zero. | Hii lazima iwe zaidi ya sifuri. | draft |  |
| `equipment.noneDetail` | Equipment appears here once the programme adds it. | Vifaa vitaonekana hapa mradi utakapoviongeza. | draft | Flag: Cross-check (natural): "programu itakapoviongeza" can read as "when the app adds them". |
| `equipment.noneTitle` | No equipment listed yet | Bado hakuna vifaa vilivyoorodheshwa | draft |  |
| `equipment.notANumber` | Enter a number. | Weka namba. | draft |  |
| `equipment.notAQuotation` | Prices are indicative, not quotations. | Bei ni ya makadirio, si nukuu ya bei. | draft | Flag: Drafter: Kept 'si nukuu ya bei' per glossary; 'Bei ni ya makadirio' number agreement is generic. |
| `equipment.notFoundDetail` | It may no longer be listed, or you may not have access to it. | Huenda hakiorodheshwi tena, au huna ruhusa ya kukifikia. | draft |  |
| `equipment.notFoundTitle` | Equipment not found | Kifaa hakikupatikana | draft |  |
| `equipment.price` | Price | Bei ya makadirio | draft | Prices are INDICATIVE, never quotations. Must not read as a firm offer. Flag: Drafter: Labelled 'Bei ya makadirio' (glossary decision) because the note requires indicative wording; English label is just 'Price'. |
| `equipment.purpose` | What will you use it for? | Utakitumia kwa ajili ya nini? | draft | Flag: Drafter: Assumes equipment noun class 7 ('kifaa' -> 'Utakitumia'). |
| `equipment.quantity` | How many | Idadi | draft |  |
| `equipment.ratedPower` | Rated power | Nguvu iliyoandikwa | draft | Flag: Cross-check (glossary): Same as estimate.ratedPower: shortened nameplate term "nguvu iliyoandikwa" is ambiguous, and "iliyoandikwa iliyorekodiwa" in requests.noEstimateDetail is clumsy. |
| `equipment.requestThis` | Request this | Omba kifaa hiki | draft |  |
| `equipment.required` | This is required. | Ni lazima. | draft | Flag: Drafter: 'Ni lazima.' short form; the English 'This is required.' has no clear subject. |
| `equipment.submit` | Submit request | Wasilisha ombi | draft | Flag: Drafter: Submit vs send: 'Wasilisha ombi' here (matches status 'Imewasilishwa') but 'Tuma ombi hili' for requests.action.submit and 'haijatumwa' in draftNote, following glossary Tuma=send. Reviewer to unify. |
| `equipment.submitting` | Submitting… | Inawasilisha… | draft |  |
| `equipment.successDetail` | Ops will review it. You can follow it under Requests. | Timu ya uendeshaji italipitia. Unaweza kulifuatilia chini ya Maombi. | draft | Flag: Drafter: 'Ops' rendered 'Timu ya uendeshaji' (glossary 'Uendeshaji' role UNVERIFIED). |
| `equipment.successTitle` | Request submitted | Ombi limewasilishwa | draft |  |
| `equipment.title` | Equipment | Vifaa | draft |  |
| `equipment.viewRequest` | View the request | Tazama ombi | draft |  |
| `equipment.wholeNumber` | Enter a whole number. | Weka namba nzima. | draft |  |
| `error.accountUnreadable` | Your account could not be read. Try again. | Akaunti yako haikuweza kusomwa. Jaribu tena. | draft |  |
| `error.badId` | That record reference is not valid. | Rejea ya rekodi hiyo si sahihi. | draft |  |
| `error.badReference` | That refers to a record that does not exist. | Hiyo inarejelea rekodi ambayo haipo. | draft |  |
| `error.contributionPositive` | A contribution must be more than zero. | Kiasi kinachochangiwa lazima kiwe zaidi ya sifuri. | draft | Flag: Drafter: 'Contribution' (quantity attached from a harvest figure to an opportunity) rendered 'kiasi kinachochangiwa' (composed). |
| `error.daysRange` | Days per week must be between 0 and 7. | Siku kwa wiki lazima ziwe kati ya 0 na 7. | draft |  |
| `error.duplicate` | That record already exists. | Rekodi hiyo tayari ipo. | draft |  |
| `error.duplicateBuyer` | A buyer with that name already exists in this project. | Mnunuzi mwenye jina hilo tayari yupo katika mradi huu. | draft |  |
| `error.duplicateEquipmentCode` | That equipment code is already in use in this project. | Msimbo huo wa kifaa tayari unatumika katika mradi huu. | draft |  |
| `error.duplicateSupply` | That harvest figure is already attached to this opportunity. | Kiasi hicho cha mavuno tayari kimeambatishwa kwenye fursa hii. | draft |  |
| `error.hoursRange` | Hours per day must be between 0 and 24. | Saa kwa siku lazima ziwe kati ya 0 na 24. | draft |  |
| `error.invalidValue` | One of the values is not allowed here. Check the form and try again. | Moja ya thamani haikubaliki hapa. Angalia fomu kisha ujaribu tena. | draft |  |
| `error.missingValue` | A required value is missing. | Thamani inayohitajika haipo. | draft |  |
| `error.network` | Could not reach the server. Check your connection and try again. | Imeshindwa kuwasiliana na seva. Angalia mtandao wako kisha ujaribu tena. | draft |  |
| `error.notAllowed` | You do not have permission to do that. | Huna ruhusa ya kufanya hivyo. | draft |  |
| `error.numericOverflow` | One of the numbers is too large for the field it was typed into. Check the figures and try again. | Moja ya namba ni kubwa mno kwa kisanduku ulichoiandikia. Angalia namba kisha ujaribu tena. | draft |  |
| `error.oneCurrentHarvest` | A crop cycle can only have one current harvest figure. Supersede the existing one instead. | Msimu wa zao unaweza kuwa na kiasi kimoja tu cha sasa cha mavuno. Badala yake, weka kiasi kipya kuchukua nafasi ya kilichopo. | draft | Flag: Drafter: 'Supersede' rendered 'chukua nafasi ya kilichopo kwa kiasi kipya' (replace the existing with a new figure); no glossary term. |
| `error.personHasLogin` | This person already has an app login. | Mtu huyu tayari ana akaunti ya kuingia kwenye programu. | draft |  |
| `error.quantityNotNegative` | The quantity cannot be negative. | Idadi haiwezi kuwa chini ya sifuri. | draft |  |
| `error.quantityPositive` | The quantity must be more than zero. | Idadi lazima iwe zaidi ya sifuri. | draft |  |
| `error.retry` | Try again | Jaribu tena | draft |  |
| `error.surveyAlreadyAnswered` | Your household has already answered this survey. | Kaya yako tayari imejibu dodoso hili. | draft |  |
| `error.title` | Something went wrong | Kuna tatizo | draft | Flag: Drafter: 'Kuna tatizo' [UNVERIFIED glossary term]; 'error.retry' uses 'Jaribu tena' [UNVERIFIED]. |
| `error.unexpected` | Something went wrong that should not have. Try again, and tell the programme team if it keeps happening. | Kumetokea hitilafu isiyotarajiwa. Jaribu tena, na uiambie timu ya mradi ikiendelea kutokea. | draft | Flag: Drafter: 'Programme team' rendered 'timu ya programu'; sentence composed [UNVERIFIED like 'Kuna tatizo' glossary row]. |
| `error.windowBackwards` | The window must end on or after it starts. | Kipindi lazima kiishe siku ile ile kinapoanza au baada yake. | draft | Flag: Drafter: 'Window' rendered 'kipindi' (glossary: harvest window = kipindi cha kuvuna); the error does not say which kind of window, so check context. |
| `estimate.aDay` | a day | kwa siku | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `estimate.aWeek` | a week | kwa wiki | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `estimate.basis` | Calculated from rated power and the operating assumptions below (Level 1). | Imekokotolewa kutokana na nguvu iliyoandikwa na dhana za matumizi zilizo hapa chini (Kiwango cha 1). | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. Flag: Drafter: 'operating assumptions' = 'dhana za matumizi', 'Level 1' = 'Kiwango cha 1'; both composed. 'Rated power' = 'nguvu iliyoandikwa' (nameplate, glossary UNVERIFIED). |
| `estimate.days` | Days per week | Siku kwa wiki | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `estimate.daysAWeek` | days a week | siku kwa wiki | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `estimate.hours` | Hours per day | Saa kwa siku | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `estimate.hoursADay` | hours a day | saa kwa siku | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `estimate.isEstimate` | This is an estimate, not a measurement. | Haya ni makadirio, si kipimo. | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `estimate.peak` | Estimated peak | Kilele kilichokadiriwa | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. Flag: Drafter: 'Kilele kilichokadiriwa' composed (glossary UNVERIFIED); estimate.peakNote uses 'nguvu ya juu zaidi' for peak power, also UNVERIFIED. |
| `estimate.peakNote` | Peak power does not change with hours of use. | Nguvu ya juu zaidi haibadiliki kulingana na saa za matumizi. | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `estimate.perDay` | Estimated per day | Makadirio kwa siku | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `estimate.perWeek` | Estimated per week | Makadirio kwa wiki | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `estimate.quantity` | Quantity | Idadi | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `estimate.rated` | rated | iliyoandikwa | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. Flag: Drafter: Appears as a unit label after a kW figure ('15 kW iliyoandikwa'); glossary nameplate wording shortened. Needs energy reviewer. |
| `estimate.ratedPower` | Rated power | Nguvu iliyoandikwa | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. Flag: Cross-check (glossary): The glossary nameplate wording "nguvu iliyoandikwa kwenye kibao cha mashine" was cut to "nguvu iliyoandikwa", which the blind translator read as "written-down (rated) power" and which loses the idea of the manufacturer rating on the equipment. The same short form is used in estimate.basis and estimate.rated. |
| `estimate.tag` | Estimate | Makadirio | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `estimate.title` | Energy estimate | Makadirio ya nishati | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `estimate.units_one` | unit | kifaa | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. Flag: Drafter: Unit noun for equipment items ('kifaa'/'vifaa'). Unused in source (usedIn empty); appears after a number in the equation. |
| `estimate.units_other` | units | vifaa | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `farmDetail.gps` | GPS point | Alama ya GPS | draft |  |
| `farmDetail.noGps` | Not captured | Haijarekodiwa | draft | Flag: Drafter: 'Haijachukuliwa' (not captured); could read as 'not taken'. Alternative 'Haijarekodiwa'. |
| `farmDetail.noPlotsDetail` | This farm has no plots yet. | Shamba hili bado halina vipande vya shamba. | draft |  |
| `farmDetail.noPlotsTitle` | No plots recorded | Hakuna kipande cha shamba kilichorekodiwa | draft |  |
| `farmDetail.notFoundDetail` | It may not exist, or it may be outside your villages. | Huenda halipo, au liko nje ya vijiji vyako. | draft |  |
| `farmDetail.notFoundTitle` | Farm not found | Shamba halikupatikana | draft |  |
| `farmDetail.plotCount` | Plots | Vipande vya shamba | draft |  |
| `farmDetail.plots` | Plots | Vipande vya shamba | draft |  |
| `farmerLogin.cancel` | Cancel | Ghairi | draft | Flag: Drafter: 'Ghairi' is UNVERIFIED in glossary; also used in voucherStatus.void 'Imeghairiwa' and voucher.voided/auditTrail.kind.voided. |
| `farmerLogin.detail` | Give these to the farmer. They sign in with their phone number and must choose their own password straight away. | Mpe mkulima taarifa hizi. Ataingia kwa namba yake ya simu na lazima achague neno lake la siri papo hapo. | draft | Flag: Changed after the cross-check; unreviewed. |
| `farmerLogin.done` | Done | Maliza | draft | Flag: Drafter: 'Done' button rendered 'Maliza' (glossary UNVERIFIED). |
| `farmerLogin.failed` | The farmer is registered, but the app login could not be created. | Mkulima amesajiliwa, lakini akaunti ya programu haikuweza kuundwa. | draft |  |
| `farmerLogin.historyInitial` | Login created by {{name}} | Akaunti iliundwa na {{name}} | draft | Keep {{name}} |
| `farmerLogin.historyNone` | No app login yet. | Bado hakuna akaunti ya programu. | draft |  |
| `farmerLogin.historyReset` | Password reset by {{name}} | Neno la siri lilirudishwa na {{name}} | draft | Keep {{name}} |
| `farmerLogin.historyTitle` | App login | Akaunti ya programu | draft |  |
| `farmerLogin.issue` | Create app login | Unda akaunti ya programu | draft |  |
| `farmerLogin.issuing` | Creating login… | Inaunda akaunti… | draft |  |
| `farmerLogin.mustChange` | Waiting for the farmer to choose their own password. | Inasubiri mkulima achague neno lake la siri mwenyewe. | draft |  |
| `farmerLogin.password` | Temporary password | Neno la siri la muda | draft |  |
| `farmerLogin.phone` | Phone number | Namba ya simu | draft |  |
| `farmerLogin.reset` | Reset app password | Rudisha neno la siri la programu | draft |  |
| `farmerLogin.resetConfirm` | Reset password | Rudisha neno la siri | draft |  |
| `farmerLogin.resetConfirmDetail` | Their current password stops working and anyone signed in with it is signed out. You will get a new temporary password to give them. | Neno lake la siri la sasa litaacha kufanya kazi, na yeyote aliyeingia nalo atatolewa kwenye programu. Utapata neno la siri la muda jipya la kumpa. | draft | Flag: Drafter: 'new temporary password' written 'neno jipya la siri la muda' (jipya agrees with neno). Glossary 'neno la siri jipya' agrees with the closer noun; reviewer to settle agreement. |
| `farmerLogin.resetConfirmTitle` | Reset this farmer's app password? | Rudisha neno la siri la programu la mkulima huyu? | draft |  |
| `farmerLogin.resetting` | Resetting… | Inarudisha… | draft |  |
| `farmerLogin.retry` | Try again | Jaribu tena | draft |  |
| `farmerLogin.shownOnce` | Shown once. Write it down for the farmer now; it cannot be shown again. | Huonyeshwa mara moja. Liandike sasa kwa ajili ya mkulima; haliwezi kuonyeshwa tena. | draft | Flag: Drafter: Object concord 'li-' refers to 'neno la siri'; check reads naturally to a farmer/officer. |
| `farmerLogin.title` | App login for the farmer | Akaunti ya programu ya mkulima | draft | Flag: Drafter: 'App login' rendered as 'Akaunti ya programu' (app account). 'login' as a noun has no glossary term; also affects issue/history/audit strings. 'programu' for 'app' is common but unverified. |
| `farmerOpportunities.buyerWithOps` | Your field officer holds the buyer details. | Afisa wako wa uwandani ana taarifa za mnunuzi. | draft |  |
| `farmerOpportunities.noneDetail` | None of your harvest has been put forward to a buyer yet. | Bado hakuna mavuno yako yaliyopendekezwa kwa mnunuzi. | draft |  |
| `farmerOpportunities.noneTitle` | No opportunities yet | Bado hakuna fursa | draft |  |
| `farmerOpportunities.notASale` | An opportunity is not a sale, a delivery or a payment. It records that your harvest has been put forward to a buyer. Nothing has moved and nothing is owed. | Fursa si mauzo, si uwasilishaji wa mazao wala si malipo. Inaonyesha kwamba mavuno yako yamependekezwa kwa mnunuzi. Hakuna kilichohamishwa na hakuna deni lolote. | draft | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. Flag: Drafter: Glossary bans 'mauzo' for the opportunity itself, but the negation 'not a sale' needs a word for sale; 'mauzo' used only inside the negation. 'delivery' rendered 'uwasilishaji wa mazao' (collides with 'wasilisha'=submit). 'Nothing is owed' = 'hakuna anayedaiwa chochote' unverified. Same in farmHome.notASale. |
| `farmerOpportunities.opportunityTotal` | Opportunity total | Jumla katika fursa hii | draft | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. Flag: Cross-check (meaning): "Jumla ya fursa" can be read as the total number of opportunities, not the total quantity within this one opportunity. |
| `farmerOpportunities.title` | Opportunities | Fursa | draft |  |
| `farmerOpportunities.yourShare` | Your share | Sehemu yako | draft |  |
| `farmHome.browseEquipment` | Browse equipment | Angalia vifaa | draft |  |
| `farmHome.cycles` | Crops growing | Mazao yanayokua | draft |  |
| `farmHome.farms` | Farms | Mashamba | draft |  |
| `farmHome.latestRequest` | Latest equipment request | Ombi la karibuni la vifaa | draft |  |
| `farmHome.noFarmDetail` | Your field officer has not registered your farm yet. Ask them to add it. | Afisa wako wa uwandani bado hajasajili shamba lako. Mwombe alisajili. | draft |  |
| `farmHome.noFarmTitle` | No farm recorded yet | Bado hakuna shamba lililorekodiwa | draft |  |
| `farmHome.noOpportunities` | None of your harvest has been put forward to a buyer yet. | Bado hakuna mavuno yako yaliyopendekezwa kwa mnunuzi. | draft |  |
| `farmHome.noRequests` | You have not asked for any equipment yet. | Bado hujaomba kifaa chochote. | draft |  |
| `farmHome.notASale` | An opportunity is not a sale, a delivery or a payment. | Fursa si mauzo, si uwasilishaji wa mazao wala si malipo. | draft | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. Flag: Drafter: Same as farmerOpportunities.notASale: 'mauzo' appears only in the negation. |
| `farmHome.openMyFarm` | See my records | Tazama taarifa zangu | draft |  |
| `farmHome.openOpportunities` | See opportunities | Tazama fursa | draft |  |
| `farmHome.opportunities` | Opportunities | Fursa | draft |  |
| `farmHome.opportunityCount_one` | Your harvest is in 1 opportunity. | Mavuno yako yamo katika fursa 1. | draft | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `farmHome.opportunityCount_other` | Your harvest is in {{count}} opportunities. | Mavuno yako yamo katika fursa {{count}}. | draft | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. Keep {{count}} |
| `farmHome.plots` | Plots | Vipande vya shamba | draft |  |
| `farmHome.title` | My farm | Shamba langu | draft |  |
| `harvestKind.actual` | Actual | Halisi | draft |  |
| `harvestKind.expected` | Expected | Yanayotarajiwa | draft |  |
| `language.en` | English | Kiingereza | reviewed |  |
| `language.notSaved` | Language changed for now, but could not be saved. | Lugha imebadilishwa kwa sasa, lakini haikuweza kuhifadhiwa. | draft |  |
| `language.sw` | Kiswahili | Kiswahili | reviewed |  |
| `login.email` | Phone number or email | Namba ya simu au barua pepe | draft | Flag: Drafter: Key name says email but string is 'phone number or email'; 'barua pepe' is standard for email. |
| `login.emailInvalid` | Enter a Tanzanian mobile number, for example 0712 345 678, or an email address. | Weka namba ya simu ya mkononi ya Tanzania, kwa mfano 0712 345 678, au anwani ya barua pepe. | draft | Flag: Drafter: Example number 0712 345 678 kept as is. |
| `login.emailRequired` | Enter your phone number or email address. | Weka namba yako ya simu au anwani ya barua pepe. | draft |  |
| `login.invalid` | That phone number or email and password do not match an account. | Namba ya simu au barua pepe na neno la siri havilingani na akaunti yoyote. | draft |  |
| `login.network` | Could not reach the server. Check your connection and try again. | Seva haikupatikana. Angalia mtandao wako kisha ujaribu tena. | draft |  |
| `login.password` | Password | Neno la siri | draft |  |
| `login.passwordRequired` | Enter your password. | Weka neno lako la siri. | draft |  |
| `login.submit` | Sign in | Ingia | draft |  |
| `login.submitting` | Signing in… | Inaingia… | draft |  |
| `login.title` | Sign in | Ingia | draft |  |
| `login.unexpected` | Something went wrong signing in. | Kuna tatizo wakati wa kuingia. | draft |  |
| `myFarm.expected` | Expected harvest | Mavuno yanayotarajiwa | draft |  |
| `myFarm.noCycles` | No crops recorded on this plot yet | Bado hakuna zao lililorekodiwa katika kipande hiki | draft |  |
| `myFarm.noFarmDetail` | A field officer will register your farm and it will appear here. | Afisa wa uwandani atasajili shamba lako na litaonekana hapa. | draft |  |
| `myFarm.noFarmTitle` | No farm recorded yet | Bado hakuna shamba lililorekodiwa | draft |  |
| `myFarm.noPlots` | No plots recorded on this farm yet | Bado hakuna kipande cha shamba kilichorekodiwa katika shamba hili | draft |  |
| `myFarm.plots` | Plots | Vipande vya shamba | draft | Flag: Drafter: 'Kipande cha shamba' for plot is glossary UNVERIFIED; used throughout. |
| `myFarm.readOnly` | This is a record of what has been registered. Ask your field officer to change anything. | Hizi ni taarifa za kile kilichosajiliwa. Mwombe afisa wako wa uwandani abadilishe chochote. | draft |  |
| `myFarm.title` | My farm | Shamba langu | draft |  |
| `myFarm.window` | Harvest window | Kipindi cha kuvuna | draft |  |
| `nav.buyers` | Buyers | Wanunuzi | draft |  |
| `nav.catalogue` | Catalogue | Katalogi | draft | Flag: Drafter: 'Katalogi' unverified; alternative 'Orodha ya vifaa'. |
| `nav.demand` | Demand | Mahitaji | draft |  |
| `nav.equipment` | Equipment | Vifaa | draft |  |
| `nav.myFarm` | My farm | Shamba langu | draft |  |
| `nav.opportunities` | Opportunities | Fursa | draft |  |
| `nav.people` | People | Watu | draft |  |
| `nav.redeem` | Redeem | Kabidhi | draft | Flag: Drafter: 'Kabidhi' (hand over) per glossary for the officer redeem action; unverified, sense is handing cash over at the office. Cross-check (meaning): 'Kabidhi' back-translates to 'Hand over', dropping the voucher/redeem sense; as a bare nav label it does not say what is being handed over or that it is a voucher claim at the office. |
| `nav.register` | Register | Sajili | draft |  |
| `nav.requests` | Requests | Maombi | draft |  |
| `nav.signingOut` | Signing out… | Inatoka… | draft | Flag: Drafter: 'Inatoka…' follows 'Toka'; could read as 'is leaving'. Alternative 'Inakutoa…' is not natural. |
| `nav.signOut` | Sign out | Toka | draft | Flag: Drafter: 'Toka' chosen, unverified (alt 'Ondoka'). |
| `nav.surveys` | Surveys | Madodoso | draft | Flag: Drafter: 'Madodoso' (plural of dodoso, questionnaire) used as the nav label; alternative 'Tafiti'. |
| `nav.tower` | Control Tower | Control Tower | draft | Flag: Drafter: Kept 'Control Tower' in English as a product/screen name; no glossary term. Reviewer may prefer a Swahili name. |
| `nav.userMenu` | Account menu | Menyu ya akaunti | draft |  |
| `nav.verify` | Verify | Hakiki | draft |  |
| `nav.villages` | Villages | Vijiji | draft |  |
| `noAccess.detail` | Your account is not attached to a project yet. Ask your programme manager to add you. | Akaunti yako bado haijaunganishwa na mradi. Muulize meneja wa mradi akuongeze. | draft | Flag: Changed after the cross-check; unreviewed. |
| `noAccess.nothingDetail` | This is a real screen with a next step — never a blank page, and never an error. | Hii ni skrini halisi yenye hatua inayofuata — kamwe si ukurasa mtupu, wala hitilafu. | draft | Flag: Drafter: Meta/developer-style English sentence; translated faithfully, native reviewer may simplify. |
| `noAccess.nothingTitle` | Nothing to show yet | Bado hakuna cha kuonyesha | draft |  |
| `noAccess.signOut` | Sign out | Toka | draft |  |
| `noAccess.title` | No access yet | Bado huna ufikiaji | draft | Flag: Drafter: 'ufikiaji' for 'access' not in glossary; plain wording. Alternative 'ruhusa'. |
| `notFound.detail` | The link may be out of date. | Huenda kiungo hicho kimepitwa na wakati. | draft |  |
| `notFound.home` | Go to your home screen | Nenda kwenye skrini yako ya mwanzo | draft |  |
| `notFound.title` | That page does not exist | Ukurasa huo haupo | draft |  |
| `officerEdit.action` | Edit | Hariri | draft | Flag: Drafter: 'Hariri' UNVERIFIED (MS guide only). 'Rekebisha' used for 'Correct harvest figure' per glossary. |
| `officerEdit.cancel` | Cancel | Ghairi | draft |  |
| `officerEdit.fields.confidence` | Confidence | Kiwango cha uhakika | draft | Confidence level recorded with a figure. Low / medium / high. |
| `officerEdit.fields.crop_id` | Crop | Zao | draft |  |
| `officerEdit.fields.cycle_area_ha` | Planted area (ha) | Eneo lililopandwa (ha) | draft | Flag: Same open question as register.cycleArea. Cross-check (glossary): The same English 'Planted area (ha)' (register.cycleArea, person.plantedArea) is 'Jumla ya eneo lililopandwa katika mazao yote' elsewhere but the short 'Eneo lililopandwa (ha)' here, so the across-cycles qualifier is dropped in the edit form and the same field has two labels. |
| `officerEdit.fields.family_name` | Family name | Jina la ukoo | draft |  |
| `officerEdit.fields.farm_label` | Farm name | Jina la shamba | draft |  |
| `officerEdit.fields.given_name` | First name | Jina la kwanza | draft |  |
| `officerEdit.fields.harvest_end` | Harvest window ends | Mwisho wa kipindi cha kuvuna | draft |  |
| `officerEdit.fields.harvest_start` | Harvest window starts | Mwanzo wa kipindi cha kuvuna | draft |  |
| `officerEdit.fields.household_label` | Household name | Jina la kaya | draft |  |
| `officerEdit.fields.latitude` | Latitude | Latitudo | draft |  |
| `officerEdit.fields.longitude` | Longitude | Longitudo | draft |  |
| `officerEdit.fields.phone` | Phone | Namba ya simu | draft |  |
| `officerEdit.fields.planted_on` | Planted on | Tarehe ya kupanda | draft |  |
| `officerEdit.fields.plot_area_ha` | Plot area (ha) | Eneo la kipande cha shamba (ha) | draft |  |
| `officerEdit.fields.plot_label` | Plot name | Jina la kipande cha shamba | draft |  |
| `officerEdit.fields.quantity_kg` | Quantity (kg) | Kiasi (kg) | draft | Flag: Drafter: 'Kiasi (kg)' per glossary for amounts. |
| `officerEdit.fields.reported_for` | Reported for | Taarifa kwa tarehe | draft | Flag: Cross-check said the first draft meant "date of the report". Replacement is not confident. Field means the date or period the figure applies to. Drafter: Field is a date; rendered 'Tarehe ya taarifa' (date of the report). Literal 'reported for' has no clean equivalent. Cross-check (meaning): 'Reported for' names the date or period the figure applies to. 'Tarehe ya taarifa' (date of the report) reads as the date the report was made, which is a different fact. |
| `officerEdit.fields.season_label` | Season | Msimu | draft | Flag: Drafter: 'Msimu' (season). Free-text field; season taxonomy open under S22. Cross-check (meaning): 'Season' is 'Msimu' while 'Crop cycle' is 'Msimu wa zao' (and 'Misimu ya mazao'). In the same crop-cycle edit form the two different fields end up with near-identical names, which is confusing. The glossary locks the cycle term, so this needs a native decision. |
| `officerEdit.fields.status` | Status | Hali | draft |  |
| `officerEdit.fields.tree_count` | Number of trees | Idadi ya miti | draft |  |
| `officerEdit.fields.unit_count` | Number of units | Idadi ya vitengo | draft |  |
| `officerEdit.save` | Save changes | Hifadhi mabadiliko | draft |  |
| `officerEdit.saving` | Saving… | Inahifadhi… | draft |  |
| `officerEdit.titles.crop_cycle` | Edit crop cycle | Hariri msimu wa zao | draft |  |
| `officerEdit.titles.farm` | Edit farm details | Hariri taarifa za shamba | draft |  |
| `officerEdit.titles.harvest_report` | Correct harvest figure | Rekebisha kiasi cha mavuno | draft |  |
| `officerEdit.titles.household` | Edit household details | Hariri taarifa za kaya | draft |  |
| `officerEdit.titles.person` | Edit farmer details | Hariri taarifa za mkulima | draft |  |
| `officerEdit.titles.plot` | Edit plot details | Hariri taarifa za kipande cha shamba | draft |  |
| `officerHome.farms` | Farms | Mashamba | draft |  |
| `officerHome.nothingOutstanding` | Every record in your villages is verified. | Rekodi zote katika vijiji vyako zimehakikiwa. | draft |  |
| `officerHome.noVillagesDetail` | Your account is on the project but not yet attached to a village. Ask your programme manager to assign one. | Akaunti yako iko kwenye mradi lakini bado haijaunganishwa na kijiji. Muulize meneja wa mradi akupangie kimoja. | draft | Flag: Changed after the cross-check; unreviewed. |
| `officerHome.noVillagesTitle` | No village assigned yet | Bado hujapangiwa kijiji | draft |  |
| `officerHome.openVerifyQueue` | Open the verify queue | Fungua orodha ya kuhakiki | draft |  |
| `officerHome.outstanding_one` | 1 record still needs verifying. | Rekodi 1 bado inahitaji kuhakikiwa. | draft | Flag: Drafter: Plural pairs: '1' form uses class 9 'Rekodi 1 ... inahitaji', other uses 'zinahitaji'. 'Rekodi' is invariable so both read correctly. |
| `officerHome.outstanding_other` | {{count}} records still need verifying. | Rekodi {{count}} bado zinahitaji kuhakikiwa. | draft | Keep {{count}} |
| `officerHome.people` | People | Watu | draft |  |
| `officerHome.register` | Register a farmer | Sajili mkulima | draft |  |
| `officerHome.requests` | Equipment requests | Maombi ya vifaa | draft |  |
| `officerHome.title` | Your villages | Vijiji vyako | draft |  |
| `officerHome.villageOutstanding_one` | 1 record here still needs verifying | Rekodi 1 hapa bado inahitaji kuhakikiwa | draft |  |
| `officerHome.villageOutstanding_other` | {{count}} records here still need verifying | Rekodi {{count}} hapa bado zinahitaji kuhakikiwa | draft | Keep {{count}} |
| `officerHome.villages` | Assigned villages | Vijiji ulivyopangiwa | draft | Flag: Drafter: 'Vijiji ulivyopangiwa' (villages you were assigned to). |
| `opportunityStatus.accepted` | Accepted | Imekubaliwa | draft | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunityStatus.declined` | Declined | Mnunuzi amekataa | draft | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunityStatus.lapsed` | Lapsed | Imeisha muda wake | draft | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. Flag: Drafter: 'Imeisha muda wake' glossary UNVERIFIED. |
| `opportunityStatus.proposed` | Proposed | Imependekezwa | draft | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunityStatus.shared` | Shared | Imeshirikishwa | draft | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. Flag: Drafter: 'Imeshirikishwa' (shared with buyer) composed; not in glossary. |
| `people.allVerifications` | All | Wote | draft |  |
| `people.colName` | Name | Jina | draft |  |
| `people.colPhone` | Phone | Simu | draft |  |
| `people.colProvenance` | Provenance | Chanzo cha taarifa | draft | Flag: Drafter: 'Chanzo cha taarifa' unverified per glossary. |
| `people.colVillage` | Village | Kijiji | draft |  |
| `people.filterVerification` | Verification | Uhakiki | draft | Flag: Drafter: 'Uhakiki' (noun for verification) derived from 'hakiki'. |
| `people.noneDetail` | Try a different name or clear the verification filter. | Jaribu jina lingine au ondoa kichujio cha uhakiki. | draft |  |
| `people.noneTitle` | No people match | Hakuna watu wanaolingana | draft |  |
| `people.search` | Search by name | Tafuta kwa jina | draft |  |
| `people.searchPlaceholder` | Given or family name | Jina la kwanza au la ukoo | draft | Flag: Drafter: 'Jina la kwanza au la ukoo' for 'Given or family name'. |
| `people.title` | People | Watu | draft |  |
| `person.actual` | Actual | Halisi | draft |  |
| `person.allVerified` | Every record here is verified | Kila rekodi hapa imehakikiwa | draft |  |
| `person.cycles` | Crop cycles | Misimu ya mazao | draft | Flag: Drafter: 'Misimu ya mazao' plural of composed term 'msimu wa zao'. |
| `person.expected` | Expected | Inatarajiwa | draft |  |
| `person.farms` | Farms | Mashamba | draft |  |
| `person.harvests` | Harvest figures | Kiasi cha mavuno | draft |  |
| `person.households` | Households | Kaya | draft |  |
| `person.members` | Members | Wanakaya | draft | Flag: Drafter: 'Wanakaya' (household members, glossary 'mwanakaya'). |
| `person.noFarms` | No farms recorded yet | Bado hakuna shamba lililorekodiwa | draft |  |
| `person.noFarmsDetail` | Farms appear here once one is registered. | Mashamba yataonekana hapa baada ya shamba kusajiliwa. | draft |  |
| `person.noHouseholds` | No household recorded | Hakuna kaya iliyorekodiwa | draft |  |
| `person.notFoundDetail` | This record may not exist, or you may not have access to it. | Rekodi hii huenda haipo, au huenda huna ruhusa ya kuiona. | draft | Flag: Changed after the cross-check; unreviewed. |
| `person.notFoundTitle` | Person not found | Mtu hajapatikana | draft |  |
| `person.plantedArea` | Planted area | Eneo lililopandwa | draft | This is planted area ACROSS CYCLES, never "land area": intercropping means it can exceed the village’s hectares. Flag: Same open question as register.cycleArea: on this screen the figure may be summed across cycles. Drafter: Glossary across-cycles phrase (UNVERIFIED); shortened form used in the edit field for the same concept. |
| `person.plots` | Plots | Vipande vya shamba | draft |  |
| `person.superseded` | Superseded | Imebadilishwa na mpya | draft | Flag: Drafter: 'Imebadilishwa na mpya' (replaced by a newer one); shown in parentheses after a harvest figure. No glossary term; could be confused with 'edited'. |
| `person.trees` | Trees | Miti | draft |  |
| `person.units` | Units | Vitengo | draft |  |
| `person.unverifiedCount_one` | {{count}} record still needs verifying | Rekodi {{count}} bado haijahakikiwa | draft | Keep {{count}} |
| `person.unverifiedCount_other` | {{count}} records still need verifying | Rekodi {{count}} bado hazijahakikiwa | draft | Keep {{count}} Flag: Drafter: Plural agreement 'rekodi ... hazijahakikiwa' vs singular 'haijahakikiwa' (rekodi class 9/10); 'haijahakikiwa' UNVERIFIED in glossary. Chose 'bado haijahakikiwa' over 'bado inahitaji kuhakikiwa' for brevity; reviewer decide. |
| `person.verified` | Verified | Imehakikiwa | draft |  |
| `person.verify` | Verify | Hakiki | draft |  |
| `person.verifying` | Verifying… | Inahakiki… | draft |  |
| `person.window` | Harvest window | Kipindi cha kuvuna | draft | Flag: Drafter: 'Kipindi cha kuvuna' UNVERIFIED composition. Date-field labels use 'Mwanzo/Mwisho wa kipindi cha kuvuna' (my construction). |
| `provenance.capturedAt` | Captured | Ilikusanywa | draft | Provenance wording: where a record came from, and who verified it. Flag: Drafter: 'Ilikusanywa' (was collected) for 'Captured'; alternative 'Ilirekodiwa' (was recorded). Shown next to a date and 'na' + name. |
| `provenance.capturedBy` | by | na | draft | Provenance wording: where a record came from, and who verified it. Flag: Drafter: Bare 'na' (by) reads oddly alone but works between a date and a name. |
| `provenance.confidenceLabel` | Confidence | Kiwango cha uhakika | draft | Provenance wording: where a record came from, and who verified it. Flag: Drafter: 'Kiwango cha uhakika' unverified per glossary. |
| `redeem.amount` | Incentive to hand over | Motisha ya kukabidhi | draft |  |
| `redeem.another` | Redeem another | Kabidhi nyingine | draft | Flag: Drafter: 'Redeem another' shortened to 'Vocha nyingine' (another voucher) for button length; reviewer may want a full verb. |
| `redeem.cameraUnavailable` | The camera is not available on this device. Type the code instead. | Kamera haipatikani kwenye kifaa hiki. Andika namba ya vocha badala yake. | draft |  |
| `redeem.cannotRedeem` | You cannot redeem this voucher | Huwezi kukabidhi vocha hii | draft |  |
| `redeem.code` | Voucher code | Namba ya vocha | draft |  |
| `redeem.confirm` | Confirm and hand over {{amount}} | Thibitisha na ukabidhi {{amount}} | draft | Keep {{amount}} Flag: Drafter: Uses 'Thibitisha' (Confirm) per glossary; fine since verify=hakiki is a different concept. |
| `redeem.confirming` | Redeeming… | Inakabidhi… | draft |  |
| `redeem.done` | Redeemed | Imekabidhiwa | draft |  |
| `redeem.doneDetail` | {{amount}} handed over. This voucher cannot be used again. | {{amount}} imekabidhiwa. Vocha hii haiwezi kutumika tena. | draft | Keep {{amount}} |
| `redeem.expires` | Valid until {{date}} | Inatumika hadi {{date}} | draft | Keep {{date}} |
| `redeem.head` | Head of household | Mkuu wa kaya | draft |  |
| `redeem.household` | Household | Kaya | draft |  |
| `redeem.idType` | ID document you checked | Kitambulisho ulichokagua | draft |  |
| `redeem.idTypePlaceholder` | Choose the document | Chagua kitambulisho | draft |  |
| `redeem.intro` | Scan the farmer's QR code, or type the code printed under it. | Skani msimbo wa QR wa mkulima, au andika namba iliyochapishwa chini yake. | draft |  |
| `redeem.lookingUp` | Looking up… | Inatafuta… | draft |  |
| `redeem.lookUp` | Look up | Tafuta | draft |  |
| `redeem.nameConfirm` | The name on the ID matches the household above | Jina kwenye kitambulisho linalingana na kaya iliyo hapo juu | draft | Flag: Drafter: Checkbox text; 'linalingana na' (matches) composed. |
| `redeem.needsOps` | Held for audit: ops or admin must redeem this voucher in person. | Imeshikiliwa kwa ukaguzi: mfanyakazi wa uendeshaji au msimamizi lazima akabidhi vocha hii ana kwa ana. | draft | Flag: Drafter: 'ops or admin' -> 'timu ya uendeshaji au msimamizi' (composed); 'Held for audit' UNVERIFIED in glossary. |
| `redeem.notAVoucher` | That is not a Ruaha voucher code. | Hiyo si namba ya vocha ya Ruaha. | draft |  |
| `redeem.notFound` | No voucher with this code in your villages. | Hakuna vocha yenye namba hii katika vijiji vyako. | draft |  |
| `redeem.respondent` | Answered by | Imejibiwa na | draft | Flag: Drafter: 'Answered by' -> 'Imejibiwa na' (class 9 concord for a label; may need 'Alijibu' if it names a person). |
| `redeem.scan` | Scan QR code | Skani msimbo wa QR | draft |  |
| `redeem.stopScan` | Stop camera | Zima kamera | draft |  |
| `redeem.survey` | Survey | Dodoso | draft |  |
| `redeem.title` | Redeem a voucher | Kabidhi motisha ya vocha | draft | Flag: Drafter: 'Redeem a voucher' has no Tanzanian term. Rendered 'Kabidhi motisha ya vocha' (hand over the voucher's incentive); glossary options kabidhi/chukua are UNVERIFIED. Also drives redeem.confirm, done, doneDetail, cannotRedeem. |
| `register.chooseCrop` | Choose a crop | Chagua zao | draft |  |
| `register.confidence` | Confidence | Kiwango cha uhakika | draft | Confidence level recorded with a figure. Low / medium / high. Flag: Drafter: 'Kiwango cha uhakika' UNVERIFIED (glossary). Low/medium/high option strings are in another batch. |
| `register.crop` | Crop | Zao | draft |  |
| `register.cycleArea` | Planted area (ha) | Eneo lililopandwa (ha) | draft | This is planted area ACROSS CYCLES, never "land area": intercropping means it can exceed the village’s hectares. Flag: Wording changed after the cross-check to the short, English-faithful label. Open question: this field is planted area for one crop cycle, and business-rules says it is never "land area". Reviewer to confirm the label and whether "across cycles" belongs here. Drafter: Note requires 'planted area across cycles'; used the glossary full phrase (UNVERIFIED). But this is a single-cycle form field, so 'katika mazao yote' (across all crops) may read oddly; reviewer decide. officerEdit.fields.cycle_area_ha (no note) uses the short 'Eneo lililopandwa (ha)'. Cross-check (rule): The locked phrase says 'total area planted across all the crops' but this field records ONE crop cycle's area; an officer may enter a sum over all crops, and 'across crops' is not the same as the note's 'across cycles'. Also 49 characters for a 17-character English label. Needs native decision, not a silent change. |
| `register.familyName` | Family name | Jina la ukoo | draft |  |
| `register.farmLabel` | Farm name | Jina la shamba | draft |  |
| `register.givenName` | First name | Jina la kwanza | draft |  |
| `register.gpsDenied` | Location access was declined. Enter the coordinates yourself, or | Ruhusa ya kupata mahali ilikataliwa. Andika viwianishi mwenyewe, au | draft | Flag: Drafter: Sentence ends with 'au' because a 'Jaribu tena' button follows; 'viwianishi' (coordinates) is my word choice, not in glossary. Same for gpsUnsupported and gpsError. |
| `register.gpsDetecting` | Finding this farm's location… | Inatafuta mahali lilipo shamba hili… | draft |  |
| `register.gpsError` | Couldn't get a location just now. Enter the coordinates yourself, or | Imeshindwa kupata mahali kwa sasa. Andika viwianishi mwenyewe, au | draft |  |
| `register.gpsNote` | The farm's position is required. It comes from this phone's GPS; if GPS is not available, type it in. | Mahali pa shamba ni lazima. Hupatikana kupitia GPS ya simu hii; ikiwa GPS haipatikani, paandike mwenyewe. | draft | Flag: Drafter: 'Mahali pa shamba' (location of farm) used for 'position'; class-16 agreement 'paandike' is natural but check. |
| `register.gpsRetry` | Try again | Jaribu tena | draft |  |
| `register.gpsUnsupported` | This browser can't detect location. Enter the coordinates yourself, or | Kivinjari hiki hakiwezi kutambua mahali. Andika viwianishi mwenyewe, au | draft |  |
| `register.groupsComplete` | {{done}} of {{total}} groups complete · saved on this phone only | Makundi {{done}} kati ya {{total}} yamekamilika · yamehifadhiwa kwenye simu hii pekee | draft | Keep {{done}} {{total}} Flag: Drafter: 'Makundi' for 'groups' (form sections); 'kwenye simu hii pekee' composed. |
| `register.harvestEnd` | Harvest window ends | Mwisho wa kipindi cha kuvuna | draft |  |
| `register.harvestKg` | Expected harvest (kg) | Mavuno yanayotarajiwa (kg) | draft |  |
| `register.harvestStart` | Harvest window starts | Mwanzo wa kipindi cha kuvuna | draft |  |
| `register.householdLabel` | Household name | Jina la kaya | draft |  |
| `register.intro` | One page, one submit. Everything below is created together. | Ukurasa mmoja, uwasilishaji mmoja. Kila kitu kilicho hapa chini kinaundwa pamoja. | draft |  |
| `register.isHead` | This person heads the household | Mtu huyu ni mkuu wa kaya | draft |  |
| `register.latitude` | Latitude | Latitudo | draft | Flag: Drafter: 'Latitudo'/'Longitudo' are standard loanwords I chose; no glossary entry. Not verified for Tanzanian usage. |
| `register.latitudeRange` | Latitude runs from -90 to 90. | Latitudo ni kati ya -90 na 90. | draft |  |
| `register.longitude` | Longitude | Longitudo | draft |  |
| `register.longitudeRange` | Longitude runs from -180 to 180. | Longitudo ni kati ya -180 na 180. | draft |  |
| `register.measuredBy` | {{crop}} is measured this way | {{crop}} hupimwa kwa njia hii | draft | Keep {{crop}} Flag: Drafter: Hint under area/trees/units meaning 'this crop is counted by this measure'. Meaning is my reading of the screen; wording 'hupimwa kwa njia hii' may be unclear. |
| `register.notANumber` | Enter a number. | Andika namba. | draft |  |
| `register.notNegative` | This cannot be negative. | Hii haiwezi kuwa chini ya sifuri. | draft |  |
| `register.noVillage` | No village to register into | Hakuna kijiji cha kusajili | draft |  |
| `register.noVillageDetail` | Registration needs a village assignment. Ask your programme manager. | Ili kusajili, unahitaji kupangiwa kijiji. Muulize meneja wako wa mradi. | draft | Flag: Drafter: 'Usajili unahitaji ugawiwe kijiji' (assigned a village) is composed; 'meneja wa programu' not in glossary. |
| `register.phone` | Phone | Namba ya simu | draft |  |
| `register.phoneHint` | Include the country code, for example +255700000101. | Weka msimbo wa nchi, kwa mfano +255700000101. | draft |  |
| `register.plantedOn` | Planted on | Tarehe ya kupanda | draft | Flag: Drafter: Used 'Tarehe ya kupanda' rather than 'Ilipopandwa'; glossary notes sources disagree on kupanda vs kuotesha. |
| `register.plotArea` | Plot area (ha) | Eneo la kipande cha shamba (ha) | draft |  |
| `register.plotLabel` | Plot name | Jina la kipande cha shamba | draft |  |
| `register.provenanceNote` | Recorded as field-verified, captured by you. This is not a choice. | Itarekodiwa kama imehakikiwa shambani, na imeingizwa nawe. Hili si chaguo. | draft | Provenance wording: where a record came from, and who verified it. Flag: Drafter: 'Field-verified' rendered 'imehakikiwa shambani' (UNVERIFIED glossary); 'imeingizwa nawe' for 'captured by you'; 'Hili si chaguo' for 'This is not a choice'. |
| `register.registerAnother` | Register another | Sajili mwingine | draft |  |
| `register.required` | This is required. | Hii ni lazima. | draft | Flag: Drafter: Used 'Sehemu hii ni lazima.' (glossary gives 'ni lazima'; sentence form composed). |
| `register.roundedNote` | This will be stored as {{value}}. | Itahifadhiwa kama {{value}}. | draft | Keep {{value}} |
| `register.sections.cycle` | Crop cycle | Msimu wa zao | draft | Flag: Drafter: Crop cycle = 'msimu wa zao' (UNVERIFIED, composed). |
| `register.sections.farm` | Farm | Shamba | draft |  |
| `register.sections.harvest` | Expected harvest | Mavuno yanayotarajiwa | draft | Flag: Drafter: 'Mavuno yanayotarajiwa' UNVERIFIED (glossary). person.expected uses 'Inatarajiwa' for the short column label; person.actual 'Halisi' unchecked. |
| `register.sections.household` | Household | Kaya | draft |  |
| `register.sections.person` | Person | Mtu | draft |  |
| `register.sections.plot` | Plot | Kipande | draft | Flag: Drafter: Plot = 'kipande cha shamba' (UNVERIFIED, glossary). Used in full everywhere; long for a wizard rail label, may want 'Kipande'. |
| `register.submit` | Register | Sajili | draft | Flag: Drafter: 'Sajili' as imperative for registering someone else (glossary). registerAnother 'Sajili mwingine' assumes 'mkulima' understood. |
| `register.submitting` | Registering… | Inasajili… | draft |  |
| `register.successDetail` | The records were created together. | Rekodi zimeundwa pamoja. | draft |  |
| `register.successTitle` | Registered | Imesajiliwa | draft |  |
| `register.title` | Register a farmer | Sajili mkulima | draft |  |
| `register.tooLarge` | This number is too large for the field. | Namba hii ni kubwa mno kwa sehemu hii. | draft |  |
| `register.treeCount` | Number of trees | Idadi ya miti | draft |  |
| `register.unitCount` | Number of units | Idadi ya vitengo | draft | Flag: Drafter: 'Vitengo' for 'units' (generic counted units); not in glossary. Also person.units and officerEdit.fields.unit_count. |
| `register.viewPerson` | Open the record | Fungua rekodi | draft |  |
| `register.wholeNumber` | Enter a whole number. | Andika namba nzima. | draft |  |
| `register.windowBackwards` | The harvest window must end on or after it starts. | Kipindi cha kuvuna lazima kiishe siku kinapoanza au baada yake. | draft | Flag: Drafter: Long composed validation sentence; check grammar and naturalness. |
| `requests.action.submit` | Send this request | Tuma ombi hili | draft |  |
| `requests.action.withdraw` | Withdraw | Ondoa ombi | draft | Flag: Cross-check: "Ondoa ombi" may read as deleting the request. Withdraw means the farmer takes it back and the record remains. Drafter: 'Withdraw' = 'Ondoa ombi' (glossary 'remove'); may read as delete rather than withdraw. Cross-check (meaning): "Ondoa ombi" back-translates as "Remove request", which reads like deleting; English Withdraw means the farmer takes the request back but the record remains. |
| `requests.assumptions` | Assumptions | Dhana | draft |  |
| `requests.decision` | Decision | Uamuzi | draft |  |
| `requests.draftNote` | This request has not been sent yet. Nobody is reviewing it until you send it. | Ombi hili bado halijatumwa. Hakuna anayelipitia hadi utakapolituma. | draft |  |
| `requests.frozen` | A submitted request cannot be changed. Ask your field officer if something needs correcting. | Ombi lililowasilishwa haliwezi kubadilishwa. Mwombe afisa wako wa uwandani ikiwa kuna kitu cha kurekebisha. | draft |  |
| `requests.noEstimate` | No estimate stored for this request | Hakuna makadirio yaliyohifadhiwa kwa ombi hili | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `requests.noEstimateDetail` | This equipment has no rated power recorded, so no estimate could be calculated. | Kifaa hiki hakina nguvu iliyoandikwa iliyorekodiwa, kwa hiyo makadirio hayakuweza kukokotolewa. | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `requests.noneDetail` | Requests you submit will appear here. | Maombi utakayowasilisha yataonekana hapa. | draft |  |
| `requests.noneTitle` | No requests yet | Bado hakuna maombi | draft |  |
| `requests.notFoundDetail` | It may not exist, or you may not have access to it. | Huenda halipo, au huna ruhusa ya kulifikia. | draft |  |
| `requests.notFoundTitle` | Request not found | Ombi halikupatikana | draft |  |
| `requests.storedEstimate` | Stored estimate | Makadirio yaliyohifadhiwa | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `requests.submittedOn` | Submitted | Imewasilishwa | draft |  |
| `requests.title` | My requests | Maombi yangu | draft |  |
| `requestStatus.approved` | Approved | Imeidhinishwa | draft |  |
| `requestStatus.draft` | Draft | Rasimu | draft |  |
| `requestStatus.rejected` | Rejected | Imekataliwa | draft |  |
| `requestStatus.submitted` | Submitted | Imewasilishwa | draft |  |
| `requestStatus.under_review` | Under review | Inapitiwa | draft | Flag: Drafter: 'Inapitiwa' glossary UNVERIFIED. |
| `requestStatus.withdrawn` | Withdrawn | Imeondolewa | draft | Flag: Cross-check: "Imeondolewa" may read as removed or deleted, and does not say who withdrew it. Drafter: 'Imeondolewa' (removed) for Withdrawn; unverified, could read as deleted. Cross-check (meaning): "Imeondolewa" back-translates as "Removed", which does not say who withdrew it and may read as deleted or taken away by ops. |
| `role.admin` | Administrator | Msimamizi | draft | Flag: Drafter: 'Msimamizi' unverified role label. |
| `role.farmer` | Farmer | Mkulima | draft |  |
| `role.field_officer` | Field officer | Afisa wa uwandani | draft | Flag: Drafter: 'Afisa wa uwandani' composed, unverified; avoids 'Afisa Ugani'. |
| `role.ops` | Operations | Uendeshaji | draft | Flag: Drafter: 'Uendeshaji' unverified role label. |
| `selectRole.continue` | Continue | Endelea | draft |  |
| `selectRole.detail` | You hold more than one role. Pick the one you want to work in. | Una majukumu zaidi ya moja. Chagua unalotaka kufanyia kazi. | draft |  |
| `selectRole.noneDetail` | Your access may have changed. Ask your programme manager. | Ufikiaji wako huenda umebadilika. Muulize meneja wa mradi. | draft | Flag: Drafter: 'meneja wa programu' for 'programme manager' is not in glossary; also used in noAccess.detail and officerHome.noVillagesDetail. |
| `selectRole.noneTitle` | No roles to choose from | Hakuna majukumu ya kuchagua | draft |  |
| `selectRole.title` | Choose a role | Chagua jukumu | draft | Flag: Drafter: 'Jukumu' used for 'role'; not in glossary. |
| `selectRole.wholeProject` | Whole project | Mradi mzima | draft |  |
| `setPassword.confirm` | Type it again | Liandike tena | draft |  |
| `setPassword.detail` | You signed in with a temporary password from your officer. Choose a new one that only you know. | Uliingia kwa neno la siri la muda kutoka kwa afisa wako. Chagua neno la siri jipya ambalo unalijua wewe tu. | draft | Flag: Drafter: 'wewe tu' used for emphasis (only you know it); acceptable per tone rule but reviewer may prefer 'ambalo ni wewe pekee unalijua'. |
| `setPassword.mismatch` | The two passwords are not the same. | Maneno mawili ya siri hayafanani. | draft |  |
| `setPassword.password` | New password | Neno la siri jipya | draft |  |
| `setPassword.required` | Enter a new password. | Weka neno la siri jipya. | draft |  |
| `setPassword.submit` | Save password | Hifadhi neno la siri | draft |  |
| `setPassword.submitting` | Saving… | Inahifadhi… | draft |  |
| `setPassword.title` | Choose your own password | Chagua neno lako la siri mwenyewe | draft | Flag: Changed after the cross-check; unreviewed. |
| `setPassword.unexpected` | Something went wrong saving your password. | Kuna tatizo katika kuhifadhi neno lako la siri. | draft |  |
| `source.farmer_reported` | Farmer reported | Imeripotiwa na mkulima | draft | Provenance wording: where a record came from, and who verified it. |
| `source.field_verified` | Field verified | Imehakikiwa shambani | draft | Provenance wording: where a record came from, and who verified it. |
| `source.model_estimated` | Estimated | Imekadiriwa | draft | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `source.sensor_derived` | Sensor measured | Imepimwa na kihisi | draft | Provenance wording: where a record came from, and who verified it. Flag: Drafter: 'Imepimwa na kihisi' composed; 'kihisi' (sensor) not in glossary. |
| `source.transaction_derived` | From a transaction | Kutoka kwenye muamala | draft | Provenance wording: where a record came from, and who verified it. Flag: Drafter: 'Kutoka kwenye muamala' composed; 'muamala' (transaction) used by Airtel per glossary but not a glossary row. |
| `surveys.answered` | Answered | Limejibiwa | draft | Flag: Drafter: 'Limejibiwa' (class 5 agreement with dodoso), not attested; 'Answered' may also label a card on a survey. Same for 'Halipatikani' (Not available). |
| `surveys.badge_one` | {{count}} new survey | dodoso jipya {{count}} | draft | Keep {{count}} Flag: Drafter: 'dodoso jipya {{count}}' / 'madodoso mapya {{count}}': agreement chosen by me. |
| `surveys.badge_other` | {{count}} new surveys | madodoso mapya {{count}} | draft | Keep {{count}} |
| `surveys.closes` | Closes {{date}} | Linafungwa {{date}} | draft | Keep {{date}} |
| `surveys.emptyDetail` | New surveys will appear here. | Madodoso mapya yataonekana hapa. | draft |  |
| `surveys.emptyTitle` | No surveys right now | Hakuna madodoso kwa sasa | draft |  |
| `surveys.incentive` | Incentive | Motisha | draft |  |
| `surveys.incentiveNote` | Paid in cash at the Ruaha office | Hukabidhiwa kwa fedha taslimu katika ofisi ya Ruaha | draft | Flag: Drafter: 'Paid in cash' -> 'Hukabidhiwa kwa fedha taslimu' (handed over in cash) deliberately, to avoid payment vocabulary. |
| `surveys.intro` | Answer a survey and your household receives a fixed cash incentive, once per survey, paid at the Ruaha office. | Jibu dodoso na kaya yako itapokea motisha ya kiasi maalum cha fedha taslimu, mara moja kwa kila dodoso, inayokabidhiwa katika ofisi ya Ruaha. | draft | Flag: Drafter: Incentive expressed as 'motisha ya kiasi maalum cha fedha taslimu' (glossary; 'kiasi maalum' UNVERIFIED). Avoided 'kulipwa' entirely; 'kukabidhiwa' (handed over) used for 'paid at the office'. |
| `surveys.new` | New | Jipya | draft | Flag: Drafter: 'New' is the badge on a survey (dodoso, class 5): 'Jipya' agrees with dodoso; if used for other nouns it would need to change. |
| `surveys.no` | No | Hapana | draft |  |
| `surveys.notAvailable` | Not available | Halipatikani | draft |  |
| `surveys.notFound` | This survey is not available. | Dodoso hili halipatikani. | draft |  |
| `surveys.onceNote` | Your household can answer this survey once. Check your answers before you submit. | Kaya yako inaweza kujibu dodoso hili mara moja. Kagua majibu yako kabla ya kuwasilisha. | draft |  |
| `surveys.open` | Answer survey | Jibu dodoso | draft |  |
| `surveys.optional` | Optional | Si lazima | draft | Flag: Drafter: 'Si lazima' UNVERIFIED in glossary; 'hiari' alternative. |
| `surveys.questionCount_one` | {{count}} question | swali {{count}} | draft | Keep {{count}} Flag: Drafter: Number placed after noun ('swali {{count}}') to work for count=1 and !=1; reviewer may prefer 'Swali {{count}}'. |
| `surveys.questionCount_other` | {{count}} questions | maswali {{count}} | draft | Keep {{count}} |
| `surveys.required` | Required | Lazima | draft |  |
| `surveys.submit` | Submit answers | Wasilisha majibu | draft |  |
| `surveys.submitting` | Submitting… | Inawasilisha… | draft |  |
| `surveys.title` | Surveys | Madodoso | draft | Flag: Drafter: 'Surveys' as 'Madodoso' (dodoso = questionnaire, glossary). 'Utafiti' considered but means research. |
| `surveys.view` | View voucher | Angalia vocha | draft |  |
| `surveys.yes` | Yes | Ndiyo | draft |  |
| `surveyStatus.closed` | Closed | Limefungwa | draft | Flag: Changed after the cross-check; unreviewed. |
| `surveyStatus.draft` | Draft | Rasimu | draft |  |
| `surveyStatus.live` | Live | Linaendelea | draft | Flag: Drafter: 'Live' for a survey: 'Inaendelea' (ongoing) is my choice; not in glossary. Reviewer to confirm. |
| `table.emptyDetail` | No records match. | Hakuna rekodi zinazolingana. | draft |  |
| `table.emptyTitle` | Nothing to show | Hakuna cha kuonyesha | draft |  |
| `tour.back` | Back | Rudi nyuma | draft |  |
| `tour.close` | Done | Maliza | draft | Flag: Drafter: 'Maliza' [UNVERIFIED] for Done; alternative 'Funga'. |
| `tour.farmer.equipmentBody` | Browse what is available and what it would cost to run. Every price here is indicative — it is a guide, not a quotation, and nothing is ordered from this screen. | Angalia vifaa vilivyopo na gharama ya kuviendesha. Kila bei hapa ni bei ya makadirio — ni mwongozo tu, si nukuu ya bei, na hakuna kinachoagizwa kutoka skrini hii. | draft |  |
| `tour.farmer.equipmentTitle` | Equipment you can ask for | Vifaa unavyoweza kuomba | draft |  |
| `tour.farmer.opportunitiesBody` | An opportunity is a buyer looking for a crop, matched to what your village expects to harvest. It is not a sale, a delivery or a payment — nothing is owed either way. | Fursa ni mnunuzi anayetafuta zao, aliyelinganishwa na mavuno ambayo kijiji chako kinatarajia. Si uuzaji, si uwasilishaji wala malipo — hakuna anayedaiwa upande wowote. | draft | Flag: Drafter: Must say 'not a sale, a delivery or a payment'. Used 'uuzaji' for sale (avoiding mauzo/mkataba per glossary), 'uwasilishaji' for delivery, 'malipo' for payment. Native reviewer to confirm wording; 'malipo' is fine here (not an incentive string) but check any test scanning the whole file. |
| `tour.farmer.opportunitiesTitle` | Opportunities near you | Fursa karibu nawe | draft |  |
| `tour.farmer.recordsBody` | Each record carries a badge saying who recorded it and whether an officer has verified it. Unverified does not mean wrong; it means nobody has checked it yet. | Kila rekodi ina lebo inayoonyesha nani aliiandika na kama afisa ameihakiki. Haijahakikiwa haimaanishi si sahihi; inamaanisha bado hakuna aliyeikagua. | draft | Flag: Drafter: 'Badge' rendered as 'lebo' (my choice, not in glossary); glossary's ProvenanceBadge wording is 'chanzo cha taarifa'. 'Haijahakikiwa' [UNVERIFIED]. |
| `tour.farmer.recordsTitle` | Your farm, in detail | Shamba lako kwa undani | draft |  |
| `tour.farmer.requestsBody` | Every request you send appears here with its current status, so you can see whether it is waiting, under review, approved or turned down — and why. | Kila ombi unalotuma linaonekana hapa likiwa na hali yake ya sasa, ili uone kama linasubiri, linapitiwa, limeidhinishwa au limekataliwa — na kwa nini. | draft |  |
| `tour.farmer.requestsTitle` | What you have asked for | Ulichoomba | draft |  |
| `tour.farmer.summaryBody` | Your farm, your plots and what you expect to harvest. If something here is wrong, tell your field officer — they are the one who can correct it. | Shamba lako, vipande vya shamba lako na mavuno yanayotarajiwa. Kama kuna kitu kisicho sahihi hapa, mwambie afisa wako wa uwandani — ndiye anayeweza kukirekebisha. | draft |  |
| `tour.farmer.summaryTitle` | What is on file for you | Kilichoandikwa kukuhusu | draft |  |
| `tour.farmer.surveysBody` | Answer a survey and your household receives a fixed cash incentive, once per survey. You get a voucher code; show it at the Ruaha office to collect the cash. The number on this tab is how many surveys are waiting for you. | Jibu dodoso na kaya yako itapokea motisha ya kiasi maalum cha fedha taslimu, mara moja kwa kila dodoso. Utapata namba ya vocha; ionyeshe kwenye ofisi ya Ruaha ili uchukue fedha hizo. Namba iliyo kwenye kichupo hiki ni idadi ya madodoso yanayokusubiri. | draft | Flag: Drafter: Incentive string: motisha, vocha, kiasi maalum cha fedha taslimu used; none of the banned words present. 'Namba ya vocha' and 'kichupo' (tab) are composed [UNVERIFIED]. |
| `tour.farmer.surveysTitle` | Surveys, and the incentive for answering | Madodoso, na motisha ya kujibu | draft |  |
| `tour.farmer.welcomeBody` | This is your own record. Everything here was written by a field officer who visited your farm, and every figure shows where it came from. The tour button in the header (the person icon on a phone) shows you any part of the app whenever you want. | Hii ni rekodi yako mwenyewe. Kila kitu hapa kiliandikwa na afisa wa uwandani aliyetembelea shamba lako, na kila kiasi kinaonyesha chanzo chake. Hatua saba fupi. | draft |  |
| `tour.farmer.welcomeTitle` | Welcome to Ruaha 360 | Karibu Ruaha 360 | draft |  |
| `tour.next` | Next | Endelea | draft | Flag: Changed to the imperative "Endelea" (also "Continue"). Reviewer may prefer another word for "Next". Drafter: Glossary gives 'Inayofuata' [UNVERIFIED]; it is not a bare imperative. 'Endelea' (continue) is the attested alternative. Cross-check (glossary): 'Inayofuata' is not a bare imperative (back-translation 'The next one'), against the editorial decision that buttons are bare imperatives; drafter also flagged it. |
| `tour.officer.oneSubmitBody` | Press this once. If the signal drops the form stays saved on this phone, and pressing it again after a failure replays the same registration rather than creating a second farmer. | Bonyeza kitufe hiki mara moja. Mtandao ukikatika, fomu inabaki imehifadhiwa kwenye simu hii, na ukibonyeza tena baada ya kushindwa, usajili ule ule unarudiwa badala ya kuunda mkulima wa pili. | draft |  |
| `tour.officer.oneSubmitTitle` | Registering creates all six records | Kusajili kunaunda rekodi zote sita | draft |  |
| `tour.officer.outstandingBody` | Everything you record starts unverified. This counts what is waiting for you. Verify only what you have seen yourself — it cannot be undone. | Kila unachorekodi huanza kikiwa hakijahakikiwa. Namba hii inaonyesha kinachokusubiri. Hakiki tu ulichokiona mwenyewe — haiwezi kutenduliwa. | draft |  |
| `tour.officer.outstandingTitle` | What still needs verifying | Kinachosubiri kuhakikiwa | draft |  |
| `tour.officer.peopleBody` | Search by name or phone, or filter by whether records are verified. Opening a person shows every record attached to them and who recorded each one. | Tafuta kwa jina au namba ya simu, au chuja kulingana na kama rekodi zimehakikiwa. Ukifungua mtu, unaona kila rekodi iliyoambatishwa kwake na nani aliyeirekodi. | draft |  |
| `tour.officer.peopleTitle` | Everyone you have registered | Wote uliowasajili | draft |  |
| `tour.officer.redeemBody` | Scan the farmer's voucher, check their ID and hand over the cash. You cannot redeem a voucher for a household you registered or verified, and some vouchers are held for ops to redeem in person. Every scan is recorded with your name. | Skani vocha ya mkulima, angalia kitambulisho chake kisha kabidhi fedha taslimu. Huwezi kukabidhi vocha ya kaya uliyoisajili au kuihakiki, na baadhi ya vocha zimeshikiliwa ili uendeshaji uzikabidhi ana kwa ana. Kila skani inarekodiwa pamoja na jina lako. | draft | Flag: Drafter: Officer-side redeem rendered as 'kabidhi' (hand over) per glossary; 'ops' rendered 'uendeshaji' [UNVERIFIED role label]. 'Skani' per glossary. |
| `tour.officer.redeemTitle` | Hand over a survey incentive | Kabidhi motisha ya dodoso | draft |  |
| `tour.officer.registerBody` | Six groups — person, household, farm, plot, crop cycle, expected harvest — created together in a single step. These chips show which groups you have filled in. | Makundi sita — mtu, kaya, shamba, kipande cha shamba, msimu wa zao, mavuno yanayotarajiwa — yanaundwa pamoja kwa kuwasilisha mara moja. Alama hizi zinaonyesha makundi uliyojaza. | draft | Flag: Drafter: 'Chips' rendered as 'alama' (marks); six group names composed from glossary terms (msimu wa zao, kipande cha shamba, mavuno yanayotarajiwa are all [UNVERIFIED]). |
| `tour.officer.registerTitle` | One page, one submit | Ukurasa mmoja, kuwasilisha mara moja | draft |  |
| `tour.officer.verifyBody` | Everything awaiting verification, in one list. Verifying says you have seen the record yourself. There is no way to un-verify, so leave anything you are unsure of. | Kila kinachosubiri kuhakikiwa, kwenye orodha moja. Kuhakiki kunamaanisha umeiona rekodi mwenyewe. Hakuna njia ya kubatilisha, kwa hiyo acha chochote ambacho huna uhakika nacho. | draft |  |
| `tour.officer.verifyTitle` | The verify queue | Foleni ya kuhakiki | draft | Flag: Drafter: 'Foleni' (queue) is my choice; alternative 'Orodha ya kuhakiki'. |
| `tour.officer.welcomeBody` | This is the field officer's surface. You register farmers, verify what you recorded, and hand over survey incentives. The tour button in the header (the person icon on a phone) shows you any part of it again whenever you want. | Hii ni sehemu ya afisa wa uwandani. Unasajili wakulima, unahakiki ulichorekodi, na unakabidhi motisha za madodoso. Hatua saba fupi, na unaweza kurudia ziara hii wakati wowote. | draft |  |
| `tour.officer.welcomeTitle` | Welcome to Ruaha 360 | Karibu Ruaha 360 | draft |  |
| `tour.progress` | Step {{step}} of {{total}} | Hatua {{step}} kati ya {{total}} | draft | Keep {{step}} {{total}} |
| `tour.restart` | Take the tour again | Rudia ziara | draft | Flag: Changed after the cross-check; unreviewed. |
| `tour.skip` | Skip the tour | Ruka ziara | draft |  |
| `tour.start` | Take the tour | Anza ziara | draft | Flag: Drafter: Uses glossary 'ziara ya mwongozo' [UNVERIFIED] for tour; longer than English button. Also tour.restart and tour.skip ('Ruka' [UNVERIFIED]). |
| `verification.disputed` | Disputed | Imepingwa | draft | Provenance wording: where a record came from, and who verified it. Flag: Drafter: 'Imepingwa' (contested) is not in glossary; plain wording chosen. Alternative 'Ina mgogoro'. |
| `verification.pending` | Pending | Inasubiri | draft | Provenance wording: where a record came from, and who verified it. Flag: Drafter: 'Inasubiri' unverified per glossary. |
| `verification.unverified` | Unverified | Haijahakikiwa | draft | Provenance wording: where a record came from, and who verified it. Flag: Drafter: 'Haijahakikiwa' unverified per glossary. |
| `verification.verified` | Verified | Imehakikiwa | draft | Provenance wording: where a record came from, and who verified it. |
| `verifyDialog.cancel` | Cancel | Ghairi | draft | Flag: Drafter: 'Ghairi' UNVERIFIED (glossary). Same for officerEdit.cancel. |
| `verifyDialog.confirm` | Verify record | Hakiki rekodi | draft |  |
| `verifyDialog.detail` | You are confirming {{record}}. Your name will be attached, and this action cannot be undone. | Unahakiki {{record}}. Jina lako litaambatishwa, na kitendo hiki hakiwezi kutenguliwa. | draft | Keep {{record}} Flag: Drafter: 'Jina lako litaambatishwa' and 'hakiwezi kutenguliwa' composed; check natural phrasing for 'cannot be undone'. Cross-check (glossary): English says 'confirming' (Thibitisha in the glossary) but Swahili uses 'Unahakiki' (Hakiki = verify). This keeps the dialog consistent with its Verify title and button, but breaks the locked Hakiki/Thibitisha split, so the product owner should decide deliberately. |
| `verifyDialog.title` | Verify this record? | Hakiki rekodi hii? | draft |  |
| `verifyQueue.householdNeedsSecondStaff` | You registered this household, so another staff member must verify it. | Ulisajili kaya hii, kwa hiyo mfanyakazi mwingine lazima aihakiki. | draft | Flag: Drafter: 'Mfanyakazi' used for 'staff member'; alternative 'mwenzako wa kazi'. Avoided 'wewe' via verb prefix. |
| `verifyQueue.intro` | Records captured in your villages that nobody has checked yet. Verifying attaches your name to the record. | Rekodi zilizokusanywa katika vijiji vyako ambazo bado hakuna aliyezikagua. Kuhakiki kunaambatisha jina lako kwenye rekodi. | draft | Flag: Drafter: 'Kuhakiki kunaambatisha jina lako' composed; 'ambatisha' (attach) not in glossary. |
| `verifyQueue.noneDetail` | Every record in your villages has been checked. | Rekodi zote katika vijiji vyako zimekaguliwa. | draft |  |
| `verifyQueue.noneTitle` | Nothing waiting to be verified | Hakuna kinachosubiri kuhakikiwa | draft |  |
| `verifyQueue.outstanding_one` | 1 record waiting | Rekodi 1 inasubiri | draft |  |
| `verifyQueue.outstanding_other` | {{count}} records waiting | Rekodi {{count}} zinasubiri | draft | Keep {{count}} |
| `verifyQueue.table.crop_cycle` | Crop cycle | Msimu wa zao | draft | Flag: Drafter: 'Msimu wa zao' unverified per glossary. |
| `verifyQueue.table.farm` | Farm | Shamba | draft |  |
| `verifyQueue.table.harvest_report` | Harvest figure | Kiasi cha mavuno | draft |  |
| `verifyQueue.table.household` | Household | Kaya | draft |  |
| `verifyQueue.table.person` | Person | Mtu | draft |  |
| `verifyQueue.table.plot` | Plot | Kipande | draft | Flag: Drafter: 'Kipande cha shamba' unverified per glossary. |
| `verifyQueue.title` | Verify | Hakiki | draft |  |
| `voucher.amount` | Incentive | Motisha | draft |  |
| `voucher.code` | Voucher code | Namba ya vocha | draft |  |
| `voucher.expired` | This voucher expired on {{date}}. | Vocha hii iliisha muda wake tarehe {{date}}. | draft | Keep {{date}} Flag: Drafter: 'expired' phrasing 'iliisha muda wake' UNVERIFIED in glossary. |
| `voucher.expires` | Valid until {{date}} | Inatumika hadi {{date}} | draft | Keep {{date}} Flag: Drafter: 'Valid until' -> 'Inatumika hadi' (usable until); composed. |
| `voucher.qrLabel` | QR code for voucher {{code}} | Msimbo wa QR wa vocha {{code}} | draft | Keep {{code}} |
| `voucher.redeemedBy` | Collected {{date}} · handed over by {{name}} | Imechukuliwa {{date}} · imekabidhiwa na {{name}} | draft | Keep {{date}} {{name}} Flag: Drafter: 'Collected' = 'Imechukuliwa' (glossary UNVERIFIED) paired with 'imekabidhiwa' (handed over) for the officer; 'Collected/handed over' distinction mirrors English. |
| `voucher.showAtOffice` | Show this code at the Ruaha office. A staff member scans it and hands over the incentive. It can be used once. | Onyesha msimbo huu katika ofisi ya Ruaha. Mfanyakazi ataskani na kukukabidhi motisha. Vocha hii inaweza kutumika mara moja. | draft | Flag: Drafter: 'staff member' -> 'Mfanyakazi' (no glossary term); 'ataskani' verb form from loan 'skani' unattested. 'Vocha hii inaweza kutumika mara moja' used for 'It can be used once'. |
| `voucher.title` | Your incentive voucher | Vocha yako ya motisha | draft |  |
| `voucher.voided` | Cancelled: {{reason}} | Imeghairiwa: {{reason}} | draft | Keep {{reason}} |
| `voucherStatus.expired` | Expired | Imeisha muda wake | draft |  |
| `voucherStatus.issued` | Not yet collected | Haijachukuliwa bado | draft |  |
| `voucherStatus.redeemed` | Collected | Imechukuliwa | draft |  |
| `voucherStatus.void` | Cancelled | Imeghairiwa | draft |  |

## Optional — ops and tower surfaces

| Key | English | Swahili | Status | Notes |
| --- | --- | --- | --- | --- |
| `buyers.channel.afm` | AFM |  | missing |  |
| `buyers.channel.direct` | Direct |  | missing |  |
| `buyers.channel.other` | Other |  | missing |  |
| `buyers.channelNote` | Channel is a label describing how the buyer was reached. 'AFM' records that origin only — there is no integration and no partnership implied. |  | missing |  |
| `buyers.colActive` | Active |  | missing |  |
| `buyers.colChannel` | Channel |  | missing |  |
| `buyers.colContact` | Contact note |  | missing |  |
| `buyers.colName` | Buyer |  | missing |  |
| `buyers.create` | Add buyer |  | missing |  |
| `buyers.createTitle` | Add a buyer |  | missing |  |
| `buyers.creating` | Adding… |  | missing |  |
| `buyers.nameRequired` | A buyer needs a name. |  | missing |  |
| `buyers.noneDetail` | Add the first buyer to record demand against them. |  | missing |  |
| `buyers.noneTitle` | No buyers yet |  | missing |  |
| `buyers.title` | Buyers |  | missing |  |
| `catalogue.colCategory` | Category |  | missing |  |
| `catalogue.colDays` | Typical days/week |  | missing |  |
| `catalogue.colHours` | Typical h/day |  | missing |  |
| `catalogue.colName` | Equipment |  | missing |  |
| `catalogue.colPower` | Rated power |  | missing |  |
| `catalogue.colPrice` | Indicative price |  | missing | Prices are INDICATIVE, never quotations. Must not read as a firm offer. |
| `catalogue.title` | Equipment catalogue |  | missing |  |
| `coverage.available` | Available |  | missing |  |
| `coverage.availableNow` | Available now |  | missing |  |
| `coverage.committed` | Already committed |  | missing |  |
| `coverage.committedNote` | Committed supply is promised to a live opportunity and is not available again. |  | missing |  |
| `coverage.coverageOf` | Coverage of {{total}} |  | missing | Keep {{total}} |
| `coverage.demand` | Demand |  | missing |  |
| `coverage.label` | Coverage |  | missing |  |
| `coverage.notCoveredOf` | Not covered of {{total}} |  | missing | Keep {{total}} |
| `demand.buyer` | Buyer |  | missing |  |
| `demand.chooseBuyer` | Choose a buyer |  | missing |  |
| `demand.chooseCrop` | Choose a crop |  | missing |  |
| `demand.colAvailable` | Available |  | missing |  |
| `demand.colBuyer` | Buyer |  | missing |  |
| `demand.colCoverable` | Coverable |  | missing |  |
| `demand.colCoverage` | Coverage |  | missing |  |
| `demand.colCrop` | Crop |  | missing |  |
| `demand.colOpportunity` | Opportunity |  | missing |  |
| `demand.colPrice` | Indicative price/kg |  | missing | Prices are INDICATIVE, never quotations. Must not read as a firm offer. |
| `demand.colQuantity` | Quantity |  | missing |  |
| `demand.colStatus` | Status |  | missing |  |
| `demand.colVillage` | Village |  | missing |  |
| `demand.colWindow` | Window |  | missing |  |
| `demand.create` | Record demand |  | missing |  |
| `demand.createOpportunity` | Create opportunity |  | missing |  |
| `demand.createTitle` | Record a demand |  | missing |  |
| `demand.creating` | Recording… |  | missing |  |
| `demand.creatingOpportunity` | Creating… |  | missing |  |
| `demand.crop` | Crop |  | missing |  |
| `demand.deliveryPoint` | Delivery point |  | missing |  |
| `demand.matches` | Villages that could supply this |  | missing |  |
| `demand.noneDetail` | Record a buyer requirement above and it will appear here. |  | missing |  |
| `demand.noneTitle` | No demand recorded yet |  | missing |  |
| `demand.noSupplyDetail` | No village has available supply of this crop in this window. That is an honest zero, not a missing row. |  | missing |  |
| `demand.noSupplyTitle` | No matching supply |  | missing |  |
| `demand.notANumber` | Enter a number. |  | missing |  |
| `demand.notASale` | An opportunity is not a sale, a delivery or a payment. It records that a village could supply a buyer. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `demand.notFoundDetail` | It may not exist, or you may not have access to it. |  | missing |  |
| `demand.notFoundTitle` | Demand not found |  | missing |  |
| `demand.priceNotANumber` | Enter a number, using a point for decimals (for example 12.5). |  | missing | Prices are INDICATIVE, never quotations. Must not read as a firm offer. |
| `demand.pricePerKg` | Indicative price per kg |  | missing | Prices are INDICATIVE, never quotations. Must not read as a firm offer. |
| `demand.qualityNote` | Quality note |  | missing |  |
| `demand.quantity` | Quantity (kg) |  | missing |  |
| `demand.required` | This is required. |  | missing |  |
| `demand.title` | Buyer demand |  | missing |  |
| `demand.twoDecimals` | Use at most 2 decimal places. |  | missing |  |
| `demand.window` | Window |  | missing |  |
| `demand.windowEnd` | Window ends |  | missing |  |
| `demand.windowStart` | Window starts |  | missing |  |
| `demandStatus.cancelled` | Cancelled |  | missing |  |
| `demandStatus.closed` | Closed |  | missing |  |
| `demandStatus.matched` | Matched |  | missing |  |
| `demandStatus.open` | Open |  | missing |  |
| `opportunity.actionAccept` | Buyer accepted |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.actionDecline` | Buyer declined |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.actionLapse` | Mark lapsed |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.actionShare` | Share with buyer |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.attach` | Attach |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.attachClosedDetail` | This opportunity is closed, so its supply no longer counts as committed. A line attached here would record a commitment against nothing. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.attachClosedTitle` | Nothing more can be attached |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.attachHarvest` | Available harvest |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.attaching` | Attaching… |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.attachKg` | Contribute (kg) |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.attachTitle` | Attach supply |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.chooseHarvest` | Choose a harvest figure |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.chooseHarvestRequired` | Choose a harvest figure to attach. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.colContributed` | Contributed |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.colCycle` | Crop cycle |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.colFarmer` | Farmer |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.colPlot` | Plot |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.demandQuantity` | Buyer's demand |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.harvestOption` | {{expected}} expected · {{available}} available |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. Keep {{expected}} {{available}} |
| `opportunity.kgDecimals` | Use at most 2 decimal places. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.kgMoreThanZero` | A contribution has to be more than zero. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.kgNotANumber` | Enter a number. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.kgRequired` | Enter how many kilograms. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.kgTooLarge` | This number is too large for the field. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.moving` | Saving… |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.noneAvailableDetail` | Every current harvest figure for this village, crop and window is already committed. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.noneAvailableTitle` | Nothing available to attach |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.noSupplyDetail` | Attach available harvest figures below. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.noSupplyTitle` | No supply attached yet |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.notASale` | An opportunity is not a sale, a delivery or a payment. Accepted means both sides agreed to keep talking; nothing has moved. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.notFoundDetail` | It may not exist, or you may not have access to it. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.notFoundTitle` | Opportunity not found |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.offered` | Offered |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.offeredNote` | This total is re-summed by the database from the supply lines below. It cannot drift from them. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.releaseDetail` | {{kg}} returns to available supply for this village, and the buyer's coverage falls. This cannot be undone: a declined or lapsed opportunity cannot be reopened. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. Keep {{kg}} |
| `opportunity.releasedNote` | Closed. Its {{kg}} has gone back to available supply for this village. The supply lines below stay on the record — nothing was deleted. |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. Keep {{kg}} |
| `opportunity.releaseNo` | Cancel |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.releaseTitle` | Release the committed supply? |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.releaseYes` | Yes, release the supply |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.supplyLines` | Supply |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `opportunity.title` | Opportunity |  | missing | An opportunity is NOT a sale, a delivery or a payment. "Accepted" means both sides agreed to keep talking. |
| `ops.allStatuses` | All statuses |  | missing |  |
| `ops.allVillages` | All villages |  | missing |  |
| `ops.applicant` | Applicant |  | missing |  |
| `ops.approve` | Approve |  | missing |  |
| `ops.approvedPeak` | Approved peak |  | missing |  |
| `ops.capacity` | Planned capacity |  | missing | Capacity is PLANNED or NAMEPLATE, never measured. Always shown with its basis. |
| `ops.capacityBasis` | Basis |  | missing | Capacity is PLANNED or NAMEPLATE, never measured. Always shown with its basis. |
| `ops.colApplicant` | Applicant |  | missing |  |
| `ops.colEquipment` | Equipment |  | missing |  |
| `ops.colEstKw` | Est. kW |  | missing |  |
| `ops.colStatus` | Status |  | missing |  |
| `ops.colSubmitted` | Submitted |  | missing |  |
| `ops.colVillage` | Village |  | missing |  |
| `ops.decisionNote` | Decision note |  | missing |  |
| `ops.decisionNoteRequired` | A decision needs a note explaining it. |  | missing |  |
| `ops.farm` | Farm |  | missing |  |
| `ops.filterStatus` | Status |  | missing |  |
| `ops.filterVillage` | Village |  | missing |  |
| `ops.headroom` | Village headroom |  | missing |  |
| `ops.neverSummed` | Prospective and approved demand are separate figures and are never added together. |  | missing |  |
| `ops.noActions` | No actions are available in this state. |  | missing |  |
| `ops.noHeadroom` | No capacity recorded for this village |  | missing |  |
| `ops.noHeadroomDetail` | A current village_capacity row is needed before headroom can be shown. |  | missing |  |
| `ops.noRequestsDetail` | Try a different status or village. |  | missing |  |
| `ops.noRequestsTitle` | No requests match |  | missing |  |
| `ops.notFoundDetail` | It may not exist, or you may not have access to it. |  | missing |  |
| `ops.notFoundTitle` | Request not found |  | missing |  |
| `ops.prospectivePeak` | Prospective peak |  | missing | Prospective and approved demand are separate figures and are NEVER summed. |
| `ops.reject` | Reject |  | missing |  |
| `ops.requestsTitle` | Request pipeline |  | missing |  |
| `ops.reviewTitle` | Review request |  | missing |  |
| `ops.simultaneity` | Simultaneity factor |  | missing |  |
| `ops.snapshotted` | Snapshotted inputs |  | missing |  |
| `ops.snapshottedNote` | These are the assumptions as they were when the estimate was calculated. |  | missing |  |
| `ops.startReview` | Start review |  | missing |  |
| `ops.village` | Village |  | missing |  |
| `ops.working` | Working… |  | missing |  |
| `opsHome.awaitingReview` | Requests awaiting review |  | missing |  |
| `opsHome.awaitingReviewDetail` | Submitted or under review |  | missing |  |
| `opsHome.lead` | Three queues. Every figure is a link, because a count nobody can act on is a statistic. |  | missing |  |
| `opsHome.openDemands` | Open buyer demands |  | missing |  |
| `opsHome.openDemandsDetail` | Still looking for supply |  | missing |  |
| `opsHome.openOrderBook` | Open the order book |  | missing |  |
| `opsHome.openPipeline` | Open the pipeline |  | missing |  |
| `opsHome.openVerifyQueue` | Open the verify queue |  | missing |  |
| `opsHome.outstandingRecords` | Records to verify |  | missing |  |
| `opsHome.outstandingRecordsDetail` | Captured but not yet checked |  | missing |  |
| `opsHome.title` | Today |  | missing |  |
| `surveyAdmin.addQuestion` | Add question |  | missing |  |
| `surveyAdmin.adminOnly` | Only an admin can author surveys. |  | missing |  |
| `surveyAdmin.answerCount_one` | {{count}} answer |  | missing | Keep {{count}} |
| `surveyAdmin.answerCount_other` | {{count}} answers |  | missing | Keep {{count}} |
| `surveyAdmin.auditNote` | A random share of vouchers can only be redeemed by ops or admin, face to face. Nobody can tell in advance which. |  | missing |  |
| `surveyAdmin.auditRate` | Vouchers held for audit |  | missing |  |
| `surveyAdmin.average` | Average {{value}} |  | missing | Keep {{value}} |
| `surveyAdmin.close` | Close survey |  | missing |  |
| `surveyAdmin.closeDetail` | Farmers can no longer answer it. Vouchers already issued stay valid until they expire. |  | missing |  |
| `surveyAdmin.closesOn` | Closes on |  | missing |  |
| `surveyAdmin.closeTitle` | Close this survey? |  | missing |  |
| `surveyAdmin.columns.outstanding` | Not yet collected |  | missing |  |
| `surveyAdmin.columns.redeemed` | Collected |  | missing |  |
| `surveyAdmin.columns.responses` | Households |  | missing |  |
| `surveyAdmin.columns.reward` | Incentive |  | missing |  |
| `surveyAdmin.columns.status` | Status |  | missing |  |
| `surveyAdmin.columns.title` | Survey |  | missing |  |
| `surveyAdmin.createdBy` | Created by {{name}} |  | missing | Keep {{name}} |
| `surveyAdmin.empty` | No surveys yet. |  | missing |  |
| `surveyAdmin.fields.audit_rate` | Vouchers held for audit (%) |  | missing |  |
| `surveyAdmin.fields.closes_at` | Closes on (optional) |  | missing |  |
| `surveyAdmin.fields.description_en` | Description (English) |  | missing |  |
| `surveyAdmin.fields.description_sw` | Description (Swahili) |  | missing |  |
| `surveyAdmin.fields.max_households` | Most households (optional) |  | missing |  |
| `surveyAdmin.fields.reward_amount` | Incentive per household (TZS) |  | missing |  |
| `surveyAdmin.fields.title_en` | Title (English) |  | missing |  |
| `surveyAdmin.fields.title_sw` | Title (Swahili) |  | missing |  |
| `surveyAdmin.from` | From |  | missing |  |
| `surveyAdmin.goBack` | Go back |  | missing |  |
| `surveyAdmin.held` | Held |  | missing |  |
| `surveyAdmin.highest` | Highest {{value}} |  | missing | Keep {{value}} |
| `surveyAdmin.intro` | Surveys for farmers. Each household can answer a survey once and collects the incentive in cash at the office. |  | missing |  |
| `surveyAdmin.kinds.multi_choice` | Several choices |  | missing |  |
| `surveyAdmin.kinds.number` | A number |  | missing |  |
| `surveyAdmin.kinds.single_choice` | One choice |  | missing |  |
| `surveyAdmin.kinds.text` | Free text |  | missing |  |
| `surveyAdmin.kinds.yes_no` | Yes or no |  | missing |  |
| `surveyAdmin.logColumns.amount` | Incentive |  | missing |  |
| `surveyAdmin.logColumns.household` | Household |  | missing |  |
| `surveyAdmin.logColumns.idType` | ID checked |  | missing |  |
| `surveyAdmin.logColumns.officer` | Handed over by |  | missing |  |
| `surveyAdmin.logColumns.survey` | Survey |  | missing |  |
| `surveyAdmin.logColumns.village` | Village |  | missing |  |
| `surveyAdmin.logColumns.when` | When |  | missing |  |
| `surveyAdmin.lowest` | Lowest {{value}} |  | missing | Keep {{value}} |
| `surveyAdmin.maxHouseholds` | Most households |  | missing |  |
| `surveyAdmin.new` | New survey |  | missing |  |
| `surveyAdmin.noQuestions` | No questions yet. |  | missing |  |
| `surveyAdmin.noRedemptions` | Nothing handed over in these dates |  | missing |  |
| `surveyAdmin.noRedemptionsDetail` | Try a wider date range. |  | missing |  |
| `surveyAdmin.noVouchers` | No vouchers yet |  | missing |  |
| `surveyAdmin.noVouchersDetail` | A voucher is issued when a household answers this survey. |  | missing |  |
| `surveyAdmin.publish` | Publish |  | missing |  |
| `surveyAdmin.publishDetail` | Farmers see it straight away. Once published, the questions and the incentive cannot be changed. |  | missing |  |
| `surveyAdmin.publishedBy` | Published {{date}} by {{name}} |  | missing | Keep {{date}} {{name}} |
| `surveyAdmin.publishTitle` | Publish this survey? |  | missing |  |
| `surveyAdmin.question.addOption` | Add option |  | missing |  |
| `surveyAdmin.question.kind` | Answer type |  | missing |  |
| `surveyAdmin.question.moveDown` | Move down |  | missing |  |
| `surveyAdmin.question.moveUp` | Move up |  | missing |  |
| `surveyAdmin.question.optionLabel` | Option (English) |  | missing |  |
| `surveyAdmin.question.optionLabelSw` | Option (Swahili) |  | missing |  |
| `surveyAdmin.question.options` | Options |  | missing |  |
| `surveyAdmin.question.prompt_en` | Question (English) |  | missing |  |
| `surveyAdmin.question.prompt_sw` | Question (Swahili) |  | missing |  |
| `surveyAdmin.question.remove` | Remove |  | missing |  |
| `surveyAdmin.question.required` | Required |  | missing |  |
| `surveyAdmin.questions` | Questions |  | missing |  |
| `surveyAdmin.redemptions` | Redemptions |  | missing |  |
| `surveyAdmin.redemptionsIntro` | Every incentive handed over, for reconciling cash each day. |  | missing |  |
| `surveyAdmin.results` | Results |  | missing |  |
| `surveyAdmin.save` | Save draft |  | missing |  |
| `surveyAdmin.saved` | Saved |  | missing |  |
| `surveyAdmin.saving` | Saving… |  | missing |  |
| `surveyAdmin.selectVoucher` | Choose a voucher to see its audit trail. |  | missing |  |
| `surveyAdmin.summary.expired` | Expired |  | missing |  |
| `surveyAdmin.summary.issued` | Issued |  | missing |  |
| `surveyAdmin.summary.outstanding` | Not yet collected |  | missing |  |
| `surveyAdmin.summary.redeemed` | Collected |  | missing |  |
| `surveyAdmin.summary.responses` | Households answered |  | missing |  |
| `surveyAdmin.summary.void` | Cancelled |  | missing |  |
| `surveyAdmin.swahiliNote` | Swahili text needs a native reviewer before farmers see it. Leave it blank to show English. |  | missing |  |
| `surveyAdmin.tally` | Answers |  | missing |  |
| `surveyAdmin.textNotTallied` | Free-text answers are not counted here. |  | missing |  |
| `surveyAdmin.title` | Surveys |  | missing |  |
| `surveyAdmin.to` | To |  | missing |  |
| `surveyAdmin.totals` | Per officer per day |  | missing |  |
| `surveyAdmin.totalsColumns.amount` | Total |  | missing |  |
| `surveyAdmin.totalsColumns.day` | Day |  | missing |  |
| `surveyAdmin.totalsColumns.officer` | Handed over by |  | missing |  |
| `surveyAdmin.totalsColumns.vouchers` | Vouchers |  | missing |  |
| `surveyAdmin.void` | Cancel voucher |  | missing |  |
| `surveyAdmin.voidConfirm` | Cancel voucher |  | missing |  |
| `surveyAdmin.voidDetail` | The household will not be able to collect this incentive. The reason is kept on the audit trail. |  | missing |  |
| `surveyAdmin.voidReason` | Reason |  | missing |  |
| `surveyAdmin.voidTitle` | Cancel this voucher? |  | missing |  |
| `surveyAdmin.voucherColumns.amount` | Incentive |  | missing |  |
| `surveyAdmin.voucherColumns.audit` | Audit |  | missing |  |
| `surveyAdmin.voucherColumns.household` | Household |  | missing |  |
| `surveyAdmin.voucherColumns.redeemedBy` | Handed over by |  | missing |  |
| `surveyAdmin.voucherColumns.respondent` | Answered by |  | missing |  |
| `surveyAdmin.voucherColumns.status` | Status |  | missing |  |
| `surveyAdmin.voucherColumns.submitted` | Answered |  | missing |  |
| `surveyAdmin.voucherFor` | Voucher for {{household}} |  | missing | Keep {{household}} |
| `surveyAdmin.vouchers` | Vouchers |  | missing |  |
| `tour.ops.demandBody` | What buyers are asking for, and how much of it a village could cover. Prices are indicative throughout. Creating an opportunity records a match — it is not a sale. |  | missing |  |
| `tour.ops.demandTitle` | Buyer demand |  | missing |  |
| `tour.ops.queueBody` | Each tile counts one queue and opens it. They are counts of work, not performance figures. |  | missing |  |
| `tour.ops.queueTitle` | What is waiting for you |  | missing |  |
| `tour.ops.requestsBody` | Every equipment request, filterable by status and village. Opening one shows the farmer's own words, the energy estimate and the decision controls. |  | missing |  |
| `tour.ops.requestsTitle` | The request pipeline |  | missing |  |
| `tour.ops.surveysBody` | Admin writes and publishes surveys here. Each household answers once and collects a fixed cash incentive at the office. You see who answered, which vouchers are collected, and the full trail of names behind each one; Redemptions totals the cash handed over per officer per day. |  | missing |  |
| `tour.ops.surveysTitle` | Surveys and their incentives |  | missing |  |
| `tour.ops.towerBody` | Production, energy, market and data quality for one village. Every figure is read from the database and drills down to the record it came from. |  | missing |  |
| `tour.ops.towerTitle` | The Control Tower |  | missing |  |
| `tour.ops.towerVillageBody` | The Tower is always about one village. Capacity here is planned and always shown with its basis — never measured — and prospective and approved demand are separate figures that are never added together. |  | missing |  |
| `tour.ops.towerVillageTitle` | Pick a village first |  | missing |  |
| `tour.ops.welcomeBody` | This is the programme surface: requests, buyer demand, surveys and the Control Tower. The tour button in the header lets you pick any part of it to be shown at any time. |  | missing |  |
| `tour.ops.welcomeTitle` | Welcome to Ruaha 360 |  | missing |  |
| `tower.actual` | Actual |  | missing |  |
| `tower.approvedNote` | Decided yes. Still not measured consumption. |  | missing |  |
| `tower.approvedPeak` | Approved peak |  | missing |  |
| `tower.approvedPerWeek` | Approved, estimated per week |  | missing |  |
| `tower.available` | Available |  | missing |  |
| `tower.backToTower` | Back to the Tower |  | missing |  |
| `tower.basis` | Basis |  | missing | Capacity is PLANNED or NAMEPLATE, never measured. Always shown with its basis. |
| `tower.capacity` | Planned capacity |  | missing | Capacity is PLANNED or NAMEPLATE, never measured. Always shown with its basis. |
| `tower.chooseVillage` | Choose a village |  | missing |  |
| `tower.colActual` | Actual |  | missing |  |
| `tower.colActualKg` | Actual kg |  | missing |  |
| `tower.colApplicant` | Applicant |  | missing |  |
| `tower.colApplicantEquipment` | Applicant · equipment |  | missing |  |
| `tower.colAvailable` | Available |  | missing |  |
| `tower.colBuyer` | Buyer |  | missing |  |
| `tower.colBuyerCrop` | Buyer · crop |  | missing |  |
| `tower.colCoverage` | Coverage |  | missing |  |
| `tower.colCrop` | Crop |  | missing |  |
| `tower.colCropFarmerPlot` | Crop · farmer · plot |  | missing |  |
| `tower.colCropWindow` | Crop · window |  | missing |  |
| `tower.colCycles` | Cycles |  | missing |  |
| `tower.colDemand` | Demand |  | missing |  |
| `tower.colEquipment` | Equipment |  | missing |  |
| `tower.colExpected` | Expected |  | missing |  |
| `tower.colExpectedKg` | Expected kg |  | missing |  |
| `tower.colOpportunity` | Opportunity |  | missing |  |
| `tower.colPeak` | Est. peak |  | missing |  |
| `tower.colPlanted` | Planted |  | missing |  |
| `tower.colStatus` | Status |  | missing |  |
| `tower.colVerified` | Verified cycles |  | missing |  |
| `tower.colWindow` | Window |  | missing |  |
| `tower.coverage` | Coverage |  | missing |  |
| `tower.cycles` | Cycles |  | missing |  |
| `tower.cyclesWithEstimate` | Cycles with an estimate |  | missing | Always labelled an ESTIMATE. Not a measurement, not a commitment. |
| `tower.drill` | See the records |  | missing |  |
| `tower.energy` | Energy |  | missing |  |
| `tower.energyDrill` | Requests behind the energy figures |  | missing |  |
| `tower.excludedFromFigures_one` | 1 more request in this village is draft, rejected or withdrawn. It feeds neither figure — the equipment pipeline tile counts every status. |  | missing |  |
| `tower.excludedFromFigures_other` | {{count}} more requests in this village are draft, rejected or withdrawn. They feed neither figure — the equipment pipeline tile counts every status. |  | missing | Keep {{count}} |
| `tower.expected` | Expected |  | missing |  |
| `tower.expectedWeightFor` | Expected weight, {{crop}} · {{window}} |  | missing | Keep {{crop}} {{window}} |
| `tower.farmsWithGps` | Farms with GPS |  | missing |  |
| `tower.figureOnTile` | {{crop}}, {{window}} — the figure on the tile |  | missing | Keep {{crop}} {{window}} |
| `tower.headroom` | Headroom |  | missing |  |
| `tower.headroomLeft` | Headroom left |  | missing |  |
| `tower.headroomNote` | Approved peak against planned capacity. Prospective requests are not on this bar; they are not a load. |  | missing |  |
| `tower.indicativeValue` | Indicative value |  | missing | Prices are INDICATIVE, never quotations. Must not read as a firm offer. |
| `tower.indicativeValueNote` | Indicative catalogue value: price times quantity. Not financed value and not a loan book. |  | missing | Prices are INDICATIVE, never quotations. Must not read as a firm offer. |
| `tower.lead` | Every headline here drills to the records underneath it. |  | missing |  |
| `tower.market` | Market |  | missing |  |
| `tower.marketDrill` | Demand against available supply |  | missing |  |
| `tower.marketNote` | Open demand against supply that is still available. |  | missing |  |
| `tower.neverSummed` | Prospective and approved are separate figures and are never added together. |  | missing |  |
| `tower.noCapacityDetail` | A current village_capacity row is needed before energy figures can be shown. |  | missing | Capacity is PLANNED or NAMEPLATE, never measured. Always shown with its basis. |
| `tower.noCapacityTitle` | No capacity recorded |  | missing | Capacity is PLANNED or NAMEPLATE, never measured. Always shown with its basis. |
| `tower.noDataDetail` | This tile fills in as records are created. |  | missing |  |
| `tower.noDataTitle` | Nothing recorded yet |  | missing |  |
| `tower.noneInFigure` | No requests in this figure. |  | missing |  |
| `tower.noVillageDetail` | The Tower reports on one village at a time. |  | missing |  |
| `tower.noVillageTitle` | Choose a village |  | missing |  |
| `tower.openDemand` | Open demand |  | missing |  |
| `tower.personsVerified` | Persons verified |  | missing |  |
| `tower.plantedArea` | Planted area across cycles |  | missing | This is planted area ACROSS CYCLES, never "land area": intercropping means it can exceed the village’s hectares. |
| `tower.plantedAreaNote` | The sum of cycle areas. Intercropping means several cycles share a plot, so this can exceed the village’s hectares. It is not land area. |  | missing | This is planted area ACROSS CYCLES, never "land area": intercropping means it can exceed the village’s hectares. |
| `tower.production` | Production |  | missing |  |
| `tower.productionDrill` | Production by crop and window |  | missing |  |
| `tower.productionNote` | Expected and actual harvest by crop and window. |  | missing |  |
| `tower.prospectiveNote` | Requests submitted or under review. An application, not a load. |  | missing | Prospective and approved demand are separate figures and are NEVER summed. |
| `tower.prospectivePeak` | Prospective peak |  | missing | Prospective and approved demand are separate figures and are NEVER summed. |
| `tower.pue` | Equipment pipeline |  | missing |  |
| `tower.pueNote` | Requests by status, with the catalogue value they represent. |  | missing |  |
| `tower.quality` | Data quality |  | missing |  |
| `tower.qualityCounted` | Counted |  | missing |  |
| `tower.qualityDrill` | Records behind data quality |  | missing |  |
| `tower.qualityMetrics` | Data quality measures |  | missing |  |
| `tower.qualityMissing` | Not counted |  | missing |  |
| `tower.qualityNote` | How much of what has been recorded has been checked. |  | missing |  |
| `tower.qualityRecord` | Record |  | missing |  |
| `tower.qualityState` | In measure |  | missing |  |
| `tower.requestCount_one` | 1 request |  | missing |  |
| `tower.requestCount_other` | {{count}} requests |  | missing | Keep {{count}} |
| `tower.requests` | Requests |  | missing |  |
| `tower.simultaneity` | Simultaneity factor |  | missing |  |
| `tower.simultaneityNote` | Applied to the peaks above. Village peak is not the sum of rated power. |  | missing |  |
| `tower.stillFree` | Still free |  | missing |  |
| `tower.sumOfPeaks` | Sum of estimated peaks |  | missing |  |
| `tower.timesFactor` | × {{factor}} simultaneity = |  | missing | Keep {{factor}} |
| `tower.title` | Control Tower |  | missing |  |
| `tower.trees` | Trees |  | missing |  |
| `tower.village` | Village |  | missing |  |
| `villages.colBasis` | Basis |  | missing |  |
| `villages.colCapacity` | Planned capacity |  | missing | Capacity is PLANNED or NAMEPLATE, never measured. Always shown with its basis. |
| `villages.colCode` | Code |  | missing |  |
| `villages.colEffectiveFrom` | Effective from |  | missing |  |
| `villages.colName` | Village |  | missing |  |
| `villages.colSimultaneity` | Simultaneity factor |  | missing |  |
| `villages.noneDetail` | No villages are visible for this project. |  | missing |  |
| `villages.noneTitle` | No villages |  | missing |  |
| `villages.plannedNote` | Capacity is planned, never measured. Every figure is shown with the basis it was planned on. |  | missing |  |
| `villages.simultaneityNote` | The simultaneity factor is applied to village peaks. Village peak is not the sum of rated power. |  | missing |  |
| `villages.title` | Villages |  | missing |  |

