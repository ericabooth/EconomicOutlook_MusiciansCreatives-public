# Findings — Do registered apprenticeships exist for musicians / music-industry work?

Retrieved 2026-08-01. See `_sources.md` for full citations and caveats.

- **"Musician" is officially on DOL's apprenticeable-occupations list** (RAPIDS code 2080CB,
  O*NET-SOC 27-2042.02, competency-based training, added via Bulletin 19-24). So the model is
  not categorically inapplicable by DOL rule — but eligibility on paper has not translated into
  visible uptake.

- **No evidence any registered "Musician" apprenticeship program (Texas or national) actually
  exists in practice.** We found no sponsor, news release, or program listing anywhere citing
  an active registered apprenticeship under the Musician occupation code.

- **Adjacent technical occupations are also apprenticeable and more plausibly relevant**:
  Recording Engineer, Sound Mixer, Sound Technician, Audio Operator, Stage Technician, Light
  Technician, Multimedia Producer, Digital Video Editor/Film-or-Videotape Editor,
  Audio-Video Repairer. These are 16 of 1,440 titles (~1.1%) on the full DOL list — see
  `national_arts_related_occupations_extract.csv`.

- **Texas aggregate apprenticeship totals (all occupations, not arts-specific)**: TWC reports
  945 registered programs and 35,500+ active participants as of its Nov-2024 release, plus
  $8.8M in DOL Apprenticeship Expansion grant funding in 2024. A slightly higher "37,000+
  active apprentices" figure appears in related coverage for early 2025 but wasn't
  independently pinned to one primary document.

- **Texas arts/music-specific apprenticeship count is unconfirmed, not verified-zero.** The
  public DOL dashboards (Active Programs, Apprentices by State) are JS/Tableau-only with no
  export, and the RAPIDS microdata itself is officially non-public. We could not extract a
  Texas x occupation cross-tab in this session. Absence of any TX-specific arts/music program
  in secondary sources (news, TWC materials, union sites) is consistent with a "near-zero"
  count but is a **gap, not a confirmed number** — flagged as a follow-up item (email
  apprenticeship-public-data@dol.gov for a filtered state extract).

- **No TWC or Workforce Solutions Capital Area creative-sector apprenticeship/training track
  found.** TWC's apprenticeship messaging centers on construction, manufacturing, and
  healthcare; Workforce Solutions Capital Area (Austin/Travis County) has no music- or
  creative-industry-specific program visible on its own site. One secondary reference to an
  Austin economic-development document discussing exploratory "training and certificate
  programs in music and creative industry subsectors" could not be directly verified in this
  session (PDF fetch failed) — flagged as an unverified lead worth a follow-up read.

- **Best real-world precedent is IATSE stagehand/entertainment-technician apprenticeships**
  (e.g., IATSE Local One, 2-3 year programs covering lighting, sound, rigging, carpentry).
  These train **crew/technical occupations**, not performing musicians, and we could not
  confirm DOL/state registration status from the union's own public pages in this session.

- **Private/industry alternatives fill the gap where registered apprenticeship doesn't
  reach**: The Blackbird Academy (Nashville, ~6-month tuition-funded audio-engineering
  certificate, ~$23,100) and the GRAMMY U Mentorship Program (unpaid, relationship-based,
  6 months) are both explicitly **not** registered apprenticeships — no wage progression, no
  DOL-recognized competency standard — but show the industry has built informal substitutes.

- **International contrast: the UK has live, current apprenticeship standards purpose-built
  for music/creative-technical work** — Assistant Recording Technician (Level 4, approved
  2021) and Creative Industries Production Technician (Level 3, with Live Event Technician /
  Creative Venue Technician / Screen Lighting Technician pathways), both administered via
  IfATE/Skills England. Like the U.S., these target **technical/production roles**, not
  solo performing musicians — reinforcing that even where governments build apprenticeship
  infrastructure for music, it lands on crew/technical occupations rather than gig performers.

- **Overall read for the white paper**: the registered-apprenticeship model is formally
  *available* (Musician is listed; several audio/production titles are listed) but essentially
  *unused* for music-industry work in Texas and nationally. The structural reason is plausible
  and consistent with precedent elsewhere (UK): apprenticeship requires a stable employer-
  sponsor providing wage-earning, supervised, multi-year training — a fit for venue/production
  crews and unionized stagehands, but a poor fit for freelance/gig performing musicians who
  lack a single employer-sponsor. Consider stating this as an inference supported by the
  pattern of evidence, not as a directly-cited DOL policy statement.

## Files in this folder
- `DOL_Available_Occupations_full_list_20260801.xlsx` — full DOL apprenticeable-occupations list (1,440 titles)
- `national_arts_related_occupations_extract.csv` — 16-row filtered extract (arts/entertainment/audio/media)
- `01_musician_apprenticeable_status.md`
- `02_texas_rapids_aggregate_totals.md`
- `03_precedent_iatse_stagehand.md`
- `04_texas_creative_workforce_check.md`
- `05_precedent_blackbird_academy_grammyu.md`
- `06_precedent_uk_music_apprenticeship_standards.md`
- `_sources.md`
- `_findings.md` (this file)
