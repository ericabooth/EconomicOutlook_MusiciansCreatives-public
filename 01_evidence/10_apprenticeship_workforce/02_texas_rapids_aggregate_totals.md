# Texas Registered Apprenticeship totals (RAPIDS), aggregate only

## What we have
Per Texas Workforce Commission (TWC) public statements citing DOL/RAPIDS data:
- **Active apprentices statewide: more than 37,000** (reported "at the start of 2025")
- **Registered apprenticeship programs statewide: 945** (as of November 18, 2024)
- **Active participants (as of Nov 2024 release): more than 35,500**
- TWC received **$8.8 million** in DOL Apprenticeship Expansion grant funding in 2024

Source: TWC news release, "TWC Celebrates Apprenticeship Week," published 2024-11-18.
https://www.twc.texas.gov/news/twc-celebrates-apprenticeship-week-0
(Note: two closely-timed figures appear in TWC messaging — "35,500 active participants" as of
the Nov-2024 release and "37,000+ active apprentices at the start of 2025" from a slightly
later restatement picked up in secondary coverage. Treat both as approximate; TWC did not
publish a single reconciled point-in-time figure with an exact as-of date in the material we
could access.)

## What we could NOT get: occupation-level or industry-level TX breakdown
Apprenticeship.gov's "Active Programs" and "Apprentices by State" pages (
https://www.apprenticeship.gov/data-and-statistics/active-programs and
https://www.apprenticeship.gov/data-and-statistics/apprentices-by-state-dashboard ) are
interactive Tableau-style dashboards with no static CSV/Excel export and no public API. We
confirmed via data.gov that the underlying RAPIDS microdata is **non-public** (contact: Alex
Jordan, jordan.alexander@dol.gov, or apprenticeship-public-data@dol.gov) —
https://catalog.data.gov/dataset/registered-apprenticeship-partners-information-database-system-rapids-dataset

We attempted to drive the live dashboard in-browser to filter Texas x arts/entertainment
occupations, but the embedded viz was unstable/slow to render in an automated browser session
and we could not reliably extract an occupation-level cross-tab within the time budget for this
sidebar task. This is a **blocker, not a null finding** — it means the "arts-related count for
Texas specifically" is unverified from primary DOL data, not confirmed-zero.

## Best available proxy: national apprenticeable-occupations list + absence of TX-specific hits
- We found no Texas-specific news release, TWC program list, or union apprenticeship page
  citing a registered program under MUSICIAN, RECORDING ENGINEER, SOUND MIXER, SOUND
  TECHNICIAN, AUDIO OPERATOR, or STAGE/LIGHT TECHNICIAN codes.
- Generic job-board postings (e.g., ZipRecruiter "Audio Engineer Apprenticeship Jobs in
  Texas") use "apprenticeship" informally for entry-level jobs; these are **not** DOL
  Registered Apprenticeships and should not be conflated with the RAPIDS universe.
- Given arts/entertainment/media occupations are ~1.1% of the 1,440-title national
  apprenticeable list (16 of 1,440; see national extract) and organized-labor apprenticeship
  activity in music/live-event work is concentrated in IATSE locals (see
  `03_precedent_iatse_stagehand.md`) rather than in Texas specifically, our working assumption
  — consistent with the task's own framing — is that Texas arts/music-related registered
  apprenticeship counts are **at or near zero**, but this should be labeled "likely zero,
  unconfirmed from primary microdata" rather than a hard count.

## Recommended next step if a firmer number is needed
Email apprenticeship-public-data@dol.gov (or jordan.alexander@dol.gov) requesting a
Texas state extract filtered to O*NET codes 27-2042.02, 27-4011.00, 27-4012.00, 27-4014.00,
27-2012.01, 27-4032.00, 49-2097.00. This is a data request, not something retrievable from the
public dashboards.

Retrieved: 2026-08-01.
