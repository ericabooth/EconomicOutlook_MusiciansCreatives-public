# Sources — Apprenticeship / structured workforce models for musicians

All retrieved 2026-08-01 unless noted. Retrieval method noted where it affects reliability
(WebFetch text-extraction vs. downloaded file vs. in-browser dashboard interaction).

## DOL / RAPIDS / apprenticeship.gov
1. **DOL list of apprenticeable occupations (source file for occupation-eligibility check and
   national arts-related extract)**
   https://www.dol.gov/sites/dolgov/files/ETA/apprenticeship/pdfs/Available_Occupations.xlsx
   - Vintage per file's own cover sheet: "Revised: March 2020." This is the file currently
     linked live from apprenticeship.gov as of 2026-08-01; DOL adds/updates individual
     occupations via numbered bulletins (e.g., 19-24 for Musician) without necessarily
     reissuing the cover-sheet date, so treat "March 2020" as the last full-document revision
     date, not evidence the list is stale on every row.
   - Saved locally as `DOL_Available_Occupations_full_list_20260801.xlsx` (1,441 rows across
     two sheets: Cover Sheet, Apprenticeable Occupations).
   - Filtered arts/entertainment/media/audio extract saved as
     `national_arts_related_occupations_extract.csv` (16 of 1,440 occupation titles).

2. **Apprenticeship.gov Data and Statistics landing page**
   https://www.apprenticeship.gov/data-and-statistics
   - Links to four interactive dashboards (Apprentices by State, Grants Performance, Active
     Programs, Completion Rate BETA). No static CSV/Excel export found on the page itself.

3. **Active Programs dashboard**
   https://www.apprenticeship.gov/data-and-statistics/active-programs
   - Text layer states data covers FY Oct-2014 through 7/15/2026. Underlying visualization is
     a heavy embedded (Tableau-style) dashboard; in-browser automation was unable to reliably
     scroll/render a Texas-by-occupation cross-tab within this session's time budget (renderer
     repeatedly went blank/unresponsive). Aggregate national/program-type tables (e.g.,
     "National Programs," "Non-continental States/Territories") were visible in screenshots but
     a clean Texas x arts-occupation table was not extracted. **Flagged as a blocker, not a
     zero-finding.**

4. **RAPIDS dataset listing (data.gov / catalog.data.gov)**
   https://catalog.data.gov/dataset/registered-apprenticeship-partners-information-database-system-rapids-dataset
   - Confirms access level "non-public." Contact: Alex Jordan, jordan.alexander@dol.gov.
   https://catalog.data.gov/dataset/apprenticeship-data-and-statistics
   - Same conclusion; no direct resource/download URLs for state x occupation microdata found
     on the catalog page. General contact: apprenticeship-public-data@dol.gov.

5. **Apprenticeship Occupations / Occupation Finder landing page**
   https://www.apprenticeship.gov/apprenticeship-occupations
   - Describes an "Occupation Finder" tool; page text itself lists no example occupations, so
     the DOL Excel file (#1 above) was used as the authoritative source instead.

## Texas Workforce Commission (TWC)
6. **TWC news release — "TWC Celebrates Apprenticeship Week"** (2024-11-18)
   https://www.twc.texas.gov/news/twc-celebrates-apprenticeship-week-0
   - Source for TX totals: 945 registered programs, 35,500+ active participants (as of
     release date), $8.8M DOL Apprenticeship Expansion grant funding in 2024. A secondary,
     slightly higher figure ("37,000+ active apprentices at the start of 2025") appears in
     aggregated search-result summarization of related TWC messaging; we did not independently
     verify a single TWC document containing that exact figure with an as-of date, so it is
     presented as approximate in the findings.
7. TWC Apprenticeship program pages (general program description, no occupation-sector
   detail found for arts/music):
   https://www.twc.texas.gov/programs/apprenticeship
   https://www.twc.texas.gov/programs/apprenticeship/employers
   https://www.twc.texas.gov/sites/default/files/wf/docs/apprenticeship-101-twc.pdf
   https://www.twc.texas.gov/sites/default/files/wf/docs/2025-apprenticeship-cost-study-twc.pdf
   https://www.twc.texas.gov/sites/default/files/wf/docs/fy26-apprenticeship-program-timeline-final-twc.pdf

## Austin / Workforce Solutions Capital Area / local creative-sector nonprofits
8. Workforce Solutions Capital Area homepage: https://wfscapitalarea.com/
   - No creative-industries- or music-specific training program found on the site itself.
9. Austin economic-development planning document ("Positioning Workforce Development
   Programs to Drive Economic Prosperity"), referenced via search results as discussing
   exploratory higher-ed partnerships for music/creative-industry certificate programs:
   https://services.austintexas.gov/edims/document.cfm?id=417634
   - **Could not verify directly** — WebFetch returned the document as unreadable
     binary/encoded PDF content in this session. Treat any claim sourced to this document as
     unverified pending a direct read (e.g., via the PDF skill) or a call to Austin Economic
     Development.
10. Health Alliance for Austin Musicians (HAAM): https://www.myhaam.org/ — healthcare access,
    not workforce training.
11. Austin Texas Musicians (ATXM) education/programming page:
    https://www.austintexasmusicians.org/programs-education — business-of-music workshops,
    self-reported "1,500+ musicians trained annually"; not a registered apprenticeship or
    credentialed workforce pipeline.

## Precedents — IATSE (stagehand/entertainment-technician apprenticeships)
12. IATSE Local One Apprenticeship Program: https://www.iatselocaloneapprenticeship.com/
    - 2-3 year program; trades include lighting, sound, rigging, carpentry. Registration
      status (DOL/NY State) not stated on the page itself — unconfirmed.
13. IATSE Local 122 (San Diego) application/pre-apprentice info:
    https://www.iatse122.org/online-application-form/
14. IATSE Local 38 join/apprenticeship info: https://www.iatse38.org/?zone=/unionactive/view_page.cfm&page=How20To20Join
15. California Division of Apprenticeship Standards — "Theatrical Training Corp" standard
    (lead only, not directly verified in this session — link returned an error on re-fetch):
    https://dir.ca.gov/das/standards/101291_SD_Theatrical_Training_Corp_Standards.pdf

## Precedents — private schools / mentorship (negative case: NOT registered apprenticeships)
16. The Blackbird Academy (Nashville): https://theblackbirdacademy.com/ ,
    program detail https://theblackbirdacademy.com/program/studio-engineering/
17. GRAMMY U Mentorship Program: https://www.grammy.com/membership/grammy-u/ ,
    https://www.grammy.com/news/grammy-u-mentorship-program-2025-2026/

## Precedents — UK apprenticeship standards (international contrast)
18. Assistant Recording Technician (ST0944), Level 4, approved 27 May 2021:
    https://skillsengland.education.gov.uk/apprenticeship-standards/assistant-recording-technician
    (redirected from instituteforapprenticeships.org — IfATE functions are transferring to
    Skills England)
19. UK Music apprenticeship-development page:
    https://www.ukmusic.org/education-skills/apprenticeship-development/ ,
    https://www.ukmusic.org/news/uk-music-welcomes-success-of-first-assistant-recording-technician-apprentice/
20. Creative Industries Production Technician (ST1297), Level 3, successor to Live Event
    Technician (ST0255, retired 25 Jan 2024) and Creative Venue Technician (ST0106):
    https://skillsengland.education.gov.uk/media/7199/st1297-creative-industries-production-technician-l3-standard.pdf

## Known gaps / blockers (see also individual notes)
- No static, downloadable Texas x occupation RAPIDS cross-tab was obtainable from public DOL
  sources in the time budgeted for this sidebar; the dashboards are JS/Tableau-rendered with
  no export and the raw RAPIDS microdata is officially non-public.
- The Austin economic-development PDF (#9) needs direct verification before citing.
- IATSE registration status (DOL/state-registered vs. purely CBA/union-internal) is unconfirmed
  for the specific locals checked.
