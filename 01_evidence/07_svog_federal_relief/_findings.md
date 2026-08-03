# Findings — SVOG / Federal Relief Evidence Pack (retrieved 2026-08-01)

Data vintage: SBA SVOG awards file "as of 07-05-2022" (13,011 national records); SBA PPP FOIA loan data "as of 2024-09-30" snapshot of 2020-2021 loans. See `_sources.md` for full URLs, extraction method, and caveats before citing any of these numbers in the white paper.

- **Texas received about $1.17 billion in SVOG awards across 758 recipients** (state field required case-normalizing before filtering — see caveat in `_sources.md`). That is roughly 8% of the $14.57 billion in SVOG funds captured in this national awards file, for a state with about 9% of the U.S. population — so Texas's share looks roughly proportionate, not obviously over- or under-represented, though this is a simple ratio, not an adjusted comparison.

- **Austin-area recipients (Austin, Round Rock, San Marcos, Pflugerville, and 13 other nearby places — see city list in `_sources.md`) received about $238.4 million across 152 awards.** That's about 20% of the Texas SVOG total and about 1.6% of the national total, from a metro area with roughly 6-7% of the state's population — a plausible over-representation given Austin's live-music/entertainment concentration, but this uses a rough population comparison, not a rigorous per-capita adjustment.

- **Top 10 Austin-area recipients account for about $92.5 million — 39% of all Austin-area SVOG dollars — despite being only 10 of 152 recipients:**
  1. Alamo South Lamar, L.P. (Austin) — motion picture theater operator — $10.00M
  2. Circuit of the Americas LLC dba Germania Insurance Amphitheater (Austin) — live venue operator/promoter — $10.00M
  3. Flix Entertainment LLC (Round Rock) — motion picture theater operator — $10.00M
  4. Messina Touring Group, LLC (Austin) — live venue operator/promoter — $10.00M
  5. The University of Texas at Austin (Austin) — live venue operator/promoter — $10.00M
  6. Cinestarz Entertainment LLC (San Marcos) — motion picture theater operator — $9.27M
  7. Alamo Lakeline LLC (Austin) — motion picture theater operator — $9.20M
  8. Double Feature Partners LP (Austin) — motion picture theater operator — $8.25M
  9. SXSW LLC (Austin) — live venue operator/promoter — $8.00M
  10. BuenaVista Music LLC (Austin) — live venue operator/promoter — $7.74M

  Five of the ten hit the program's $10 million per-entity cap exactly. **The University of Texas at Austin as a $10M recipient is an outlier worth verifying independently before citing** — it is possible/plausible a UT-affiliated performance venue applied and qualified as a "live venue operator," but this is unusual enough (a public university receiving small-business pandemic relief) that it deserves a second look before it appears in a public-facing report.

- **Entity-type mix differs between the U.S., Texas, and Austin.** Nationally, "live venue operator or promoter" is the largest category by dollars (about 42% of national SVOG funds, ~4,824 awards). In Texas and especially Austin, motion picture theater operators pull roughly even with or ahead of live venues by dollar amount (Texas: $455M to theaters vs. $439M to live venues; Austin: $109.8M to theaters vs. $104.9M to live venues), even though theaters have far fewer recipients than live venues in both geographies. This looks driven by concentration among large theater chains (several Alamo Drafthouse-affiliated LLCs each near the $10M cap) rather than a broader movie-theater share of the sector.

- **Austin-area SVOG dollars ($238.4M) exceed our city-based match for Houston-area ($215.0M, 130 awards) and for Nashville city alone ($159.9M, 114 awards), but fall well short of the Dallas-Fort Worth match ($410.9M, 202 awards).** These metro comparisons are simple city-name string matches against a self-assembled, non-exhaustive suburb list (not official Census MSA definitions) — treat them as directional, not authoritative. San Antonio (city only) totaled $70.4M / 48 awards for reference.

- **Optional PPP subset (NAICS 711130 musical groups/artists, 711310 performing-arts promoters with facilities, 722410 drinking places) was completed, not skipped.** Texas: 6,546 loans, $345.5M combined current approval amount. Austin-area subset: 816 loans, $61.8M — split roughly $46.1M to bars (722410), $11.4M to promoters-with-facilities (711310), and $4.3M to musical groups/artists proper (711130). SXSW LLC shows up again here with a $5.0M PPP loan on top of its $8.0M SVOG award — a reminder that some entities stacked multiple federal relief programs, which matters if the white paper tries to estimate total federal support to the sector without double-counting.

- **Caveat on the PPP subset's precision**: NAICS 722410 ("drinking places") is a broad bar/tavern category, most of which likely have no meaningful live-music programming — this subset should be read as a loose upper-bound proxy for music-adjacent small business relief, not a clean count of support to working musicians or venues.

- **Caveat on program totals**: the commonly cited "$16.25 billion" SVOG figure is the amount Congress *appropriated*, not the amount actually awarded. The awards file itself sums to $14.57 billion nationally, which is close to a $14 billion figure SBA's own January 2025 fact sheet cites for "over 13,000" venues — the two independent figures corroborate each other and both sit below the appropriation, consistent with unawarded funds, administrative costs, and the $544 million in "potential improper payments" flagged in SBA OIG Report 25-21 (July 2025).

- **Gaps/things not done**: no county-level or FIPS geocoding was attempted (city-name matching only); Austin-area and Houston/Dallas comparison city lists are not exhaustive and could undercount each metro somewhat; no adjustment was made for population, number of venues, or cost of living when comparing metros; the SVOG file's "Total Awarded" field is a single combined figure (initial + reconsideration + supplemental), so award tranches cannot be separated out from this file alone.
