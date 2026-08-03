# Analysis conventions (Stata)

All analysis for this report runs in Stata. Every module do-file follows these
rules so that six independently written modules produce one coherent report.

## 1. Portability (non-negotiable)

The project folder must zip up, move to another machine, and still run.

- **Never write an absolute path.** `_setup.do` finds the project root by
  searching upward for a sentinel file and defines every path as a global.
- **Never symlink.** Inputs that live outside the project are copied into
  `03_analysis/data/external/`.
- **Never `ssc install` inside a module.** Required packages (`reghdfe`,
  `ftools`, `gtools`, `estout`, `spmap`, `shp2dta`, `palettes`, `colrspace`,
  `grstyle`, `require`) are already installed into `03_analysis/stata/ado/`
  and travel with the folder. `_setup.do` puts them on the ado path.

## 2. Module shape

```stata
*! 10_pums_earnings.do - one sentence on what this module answers.
*! Inputs  : <evidence files>
*! Outputs : <figures, tables, registry keys>

clear all
do "_setup.do"                    // run from 03_analysis/stata/
global CURMODULE "pums"
numinit

...analysis...

display as text "10_pums_earnings.do complete"
```

Comment the intent, not the syntax. A comment earns its place when it records a
data quirk, a definitional choice, or a reason a reader would otherwise
question the line. Do not restate what the code plainly does.

## 3. Dollars

- Every dollar figure is real, in **2025 dollars**.
- Merge the deflator and multiply:
  ```stata
  merge m:1 year using "${OUT}/cpi_annual.dta", keep(master match) nogenerate
  generate double earnings_real = earnings_nominal * defl
  ```
- Name real variables with a `_real` or `_2025usd` suffix. Name nominal ones
  `_nominal`. Never leave it ambiguous.
- ACS PUMS dollars need `ADJINC` applied first (it puts all five survey years
  on a common 2024 basis), and only then the 2024 deflator factor.
- A ratio of two same-year nominal quantities needs no deflation. Say so in the
  registry note so no reader thinks it was forgotten.

## 4. Figures

- Export with `figsave, name(figNN_slug)`. Nothing else writes to `04_figures`.
- **Title states the finding**, as a short sentence a reader can repeat:
  `title("Texas musicians earn about half the state median", $TITLEOPT)`.
- **Keep the title to one line, about 70 characters.** A longer string wraps
  and collides with the subtitle and the plot region. If two lines are truly
  needed, pass them as separate quoted segments so Stata sets the leading
  itself: `title("First line" "Second line", $TITLEOPT)`.
- **Check the exported PNG for clipped titles and subtitles.** Stata does not
  wrap a long `title()` or `subtitle()` string; it lets the text run past the
  edge of the exported canvas and silently truncates it. A subtitle that looks
  complete in the Stata window can lose its last several words in the PNG.
  Open every exported figure and read the top two lines before you call the
  figure done. Subtitles run longer than titles, so they clip more often; keep
  each subtitle line to roughly 95 characters, or split it:
  `subtitle("First line." "Second line.", $SUBOPT)`.
- **The title must be true of the chart as drawn.** Before shipping a figure,
  reread the title against the plotted values and confirm nothing in the image
  contradicts it. A superlative ("earns the least", "the largest") is only
  allowed when the chart shows every category it implicitly compares, and the
  claimed extreme is visibly the extreme. When in doubt, state the comparison
  the figure actually makes rather than a ranking.
- **Subtitle qualifies it**: population, geography, years, units, dollar base:
  `subtitle("Median personal earnings, 2025 dollars, ACS 2020-2024", $SUBOPT)`.
- **No source notes, citations, or caveats inside the image.** Those belong in
  the LaTeX caption. The image carries title, subtitle, axes, direct labels and
  legend only. Do not use `note()`.
- Use the palette globals. `$ORANGE` marks the musician or Austin series;
  `$NAVY` and `$MUTED` mark comparisons. Keep that constant across figures.
- Pass `$TITLEOPT`, `$SUBOPT`, `$XTOPT`, `$YTOPT`, `$LEGOPT` rather than
  hand-setting sizes, so every figure matches.
- Add `graphregion(color(white))`.
- Prefer direct labels on lines over a legend when it can be done without
  clutter.
- Never truncate a bar chart's y-axis. Truncating a line chart's axis is fine
  when the subtitle says the axis does not start at zero.
- Every figure must read in grayscale and at 60% size.
- Also write the plotted data to `${OUT}/figNN_slug.csv` with `export delimited`,
  so a reader can check the chart against numbers.

## 4b. Stata traps already hit in this project

Each of these cost real debugging time here. They fail silently or with a
misleading message, so they are listed rather than left to be rediscovered.

- **An ASCII apostrophe inside a local macro breaks macro expansion**, because
  it is the macro-close delimiter. `local t = "Austin's fund"` produces
  `r(132)` or worse, garbage. Use the typographic right single quote in any
  title or label text.
- **`confirm file` needs a compound-quoted path.** This project's paths contain
  spaces, and an unquoted path returns a misleading `r(601)` "file not found"
  for a file that plainly exists.
- **Stata does not wrap `title()` or `subtitle()`.** Long strings run past the
  exported canvas and truncate silently. Read the top two lines of every PNG.
- **Never write `\$` into a file you intend LaTeX to read.** Stata treats
  backslash-dollar inside a double-quoted string as its own escape for a
  literal dollar and strips the backslash on output, so the file receives a
  bare `$` that opens math mode. Emit `\textdollar{}` instead.
- **A string variable's storage width truncates in-place edits.** `import
  delimited` sizes a string column to the longest value it saw, so adding an
  escape character to a value already at that width silently drops the last
  character. `recast str2045` before editing.
- **`reshape wide ..., j(var) string` fails when the j-variable contains a
  hyphen**, because Stata cannot build a variable-name suffix from it. SOC
  codes like `27-2042` hit this. Extract each value in its own
  preserve/keep/rename/merge block instead.
- **`local x : word 2 of "$GLOBAL"` with the global QUOTED returns garbage**,
  silently: the first call returns the entire list and later calls return
  blank. Drop the quotes: `word 2 of $GLOBAL`.
- **Disclosure-suppressed QCEW rows are zeros, not missing.** Filter on
  `disclosure_code == "N"` before any computation, or the zeros average in.

## 5. Numbers registry

Register every number the written report will quote:

```stata
numadd, key(pums_median_earnings_tx) value(22800) ///
        formatted("$22,800") unit("2025 dollars") ///
        source("01_evidence/02_pums_nes_microdata/pums_musicians...csv") ///
        note("ACS PUMS 2020-2024 5-yr, OCCP 2752, PWGTP-weighted median, ADJINC applied")
```

- `key` becomes a LaTeX macro: letters, digits, underscores only.
- `formatted` is exactly how the number should appear in prose.
- `note` must let a reader reproduce it: population, filter, weight, vintage,
  caveat.
- Register denominators next to rates. A share with no denominator in the
  ledger is incomplete.

## 6. Statistical practice

- **Survey data.** Use `svyset` for ACS PUMS. With replicate weights:
  ```stata
  svyset [pw=PWGTP], sdrweight(PWGTP1-PWGTP80) vce(sdr) mse
  ```
  That is the Census Bureau's own successive-difference method and the only
  correct way to attach uncertainty to a PUMS estimate. Treating microdata
  records as an independent sample understates the error substantially.
  If replicate weights are unavailable, use `[pw=PWGTP]`, report point
  estimates only, and register that limitation. Never invent standard errors.
- **Panel regressions.** Use `reghdfe` with `absorb()` for high-dimensional
  fixed effects and `vce(cluster <unit>)` for repeated observations on a unit.
- **Suppression.** Suppress any estimate resting on fewer than 50 unweighted
  records and register the reason instead of the number.
- **Report uncertainty** for any estimate the report leans on.
- Save regression output to `${OUT}/tables/` with `esttab ... , csv`.

## 7. Honesty rules

- Never smooth over a data quirk silently. Register it, and flag it in the
  caption material you hand back.
- If an input does not contain what the spec assumes, stop and report it. Do
  not substitute a plausible number.
- Where a finding has an innocent explanation, say so in the caption draft.
  This is a neutral policy analysis, not an advocacy document.

## 8. What each module hands back

1. The figures it wrote, with the exact title and subtitle used.
2. For each figure, a **caption draft**: source, vintage, how to read it, and
   caveats. This becomes the LaTeX caption.
3. The registry keys it created.
4. Anything it could not compute, stated plainly.
