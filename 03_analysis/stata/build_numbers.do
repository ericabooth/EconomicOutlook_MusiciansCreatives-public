*! build_numbers.do - turn the modules' number ledgers into LaTeX macros.
*!
*! Every quantity the written report quotes comes from a macro defined here, so
*! no number is typed by hand into the prose. If an input changes, the macro
*! changes with it and the text cannot silently go stale.
*!
*! Inputs  : 03_analysis/out/numbers/numbers_*.csv   (one per module)
*! Outputs : 05_report/canonical_numbers.tex          (macro definitions)
*!           03_analysis/out/canonical_numbers.csv    (merged ledger, for review)
*!
*! Macro naming: the key  pums_median_earnings_tx  becomes  \NpumsMedianEarningsTx.
*! LaTeX macro names cannot contain digits or underscores, so underscores drive
*! camel-casing and digits are spelled out. The merged CSV lists both key and
*! macro so a reader can trace either direction.

clear all
do "_setup.do"

* ------------------------------------------------------- collect the parts --
local files : dir "${NUMDIR}" files "numbers_*.csv"
local nfiles : word count `files'
if `nfiles' == 0 {
    display as error "No ledgers found in ${NUMDIR}. Run the analysis modules first."
    exit 601
}

tempfile all
local first 1
foreach f of local files {
    preserve
    import delimited "${NUMDIR}/`f'", varnames(1) stringcols(_all) clear
    if _N > 0 {
        if `first' == 1 {
            save `all', replace
            local first 0
        }
        else {
            append using `all'
            save `all', replace
        }
    }
    restore
}
use `all', clear
display as text "Loaded `=_N' registered numbers from `nfiles' module ledger(s)."

* ------------------------------------------------- build the macro name -----
* Split the key on underscores, capitalise each piece, then spell out digits.
generate str100 macroname = ""
quietly {
    forvalues i = 1/`=_N' {
        local k = key[`i']
        local out ""
        * Walk the key one underscore-delimited piece at a time, capitalising
        * each piece and appending it. Stata concatenates by juxtaposing macro
        * expansions inside one quoted string, not with a plus sign.
        while strpos("`k'", "_") > 0 {
            local piece = substr("`k'", 1, strpos("`k'", "_") - 1)
            local k = substr("`k'", strpos("`k'", "_") + 1, .)
            local cap = upper(substr("`piece'", 1, 1)) + lower(substr("`piece'", 2, .))
            local out "`out'`cap'"
        }
        local cap = upper(substr("`k'", 1, 1)) + lower(substr("`k'", 2, .))
        local out "`out'`cap'"
        * Spell out digits so the name is a legal LaTeX control sequence.
        local out : subinstr local out "0" "Zero", all
        local out : subinstr local out "1" "One", all
        local out : subinstr local out "2" "Two", all
        local out : subinstr local out "3" "Three", all
        local out : subinstr local out "4" "Four", all
        local out : subinstr local out "5" "Five", all
        local out : subinstr local out "6" "Six", all
        local out : subinstr local out "7" "Seven", all
        local out : subinstr local out "8" "Eight", all
        local out : subinstr local out "9" "Nine", all
        replace macroname = "N" + "`out'" in `i'
    }
}

* A duplicate macro would silently redefine an earlier number, so fail loudly.
duplicates tag macroname, generate(dup)
quietly count if dup > 0
if r(N) > 0 {
    display as error "Duplicate macro names across modules:"
    list module key macroname if dup > 0, clean noobs
    exit 459
}
drop dup

sort module key
export delimited using "${OUT}/canonical_numbers.csv", replace

* ------------------------------------------------ escape for LaTeX (vector) --
* Escaping happens on the VARIABLE with the subinstr() function, not on a local
* macro. A bare dollar sign inside a macro-level subinstr gets re-scanned by
* Stata as a global macro reference and the substitution silently does nothing,
* which is how an unescaped $ reaches the .tex file and breaks the build.
* char(92) is a backslash and char(36) is a dollar sign.
quietly {
    * Normalise first, so escaping is idempotent. Modules disagree about whether
    * to pre-escape dollar signs: some write a bare $, some write \textdollar{}.
    * Escaping a value that is already escaped turns it into
    * \textbackslash{}textdollar{}, which prints the markup instead of the
    * glyph. Undo any pre-escaping here, then escape once, so it does not matter
    * which convention a module followed.
    replace formatted = subinstr(formatted, char(92) + "textdollar{}", char(36), .)
    replace formatted = subinstr(formatted, char(92) + "$", char(36), .)

    * Widen the string columns first. `import delimited` sizes a string variable
    * to the longest value it saw, so adding an escape character to a value that
    * is already at that width silently truncates the result back down, which is
    * how an escaped dollar sign loses its backslash and reaches the .tex file
    * as raw math-mode syntax.
    recast str2045 formatted, force
    recast str2045 note, force
    replace formatted = subinstr(formatted, char(92), char(92) + "textbackslash{}", .)
    replace formatted = subinstr(formatted, "&", char(92) + "&", .)
    replace formatted = subinstr(formatted, "%", char(92) + "%", .)
    * Do NOT emit a dollar character at all. Writing "\$" does not survive the
    * round trip: Stata reads a backslash-dollar inside a double-quoted string
    * as its own escape for a literal dollar and strips the backslash on
    * output, so the .tex ends up with a bare $ that opens math mode and breaks
    * the build. LaTeX's \textdollar prints the same glyph and contains no
    * character Stata wants to interpret.
    replace formatted = subinstr(formatted, char(36), char(92) + "textdollar{}", .)
    replace formatted = subinstr(formatted, "#", char(92) + "#", .)
    replace formatted = subinstr(formatted, "_", char(92) + "_", .)
    * Notes become LaTeX comment lines, where a backslash would still be read as
    * a control sequence, so neutralise it there too.
    replace note = subinstr(note, char(92), "/", .)
}

* ------------------------------------------------------- write the macros --
tempname fh
file open `fh' using "${PROJ}/05_report/canonical_numbers.tex", write text replace
file write `fh' "% canonical_numbers.tex - GENERATED FILE, DO NOT EDIT BY HAND." _n
file write `fh' "% Produced by 03_analysis/stata/build_numbers.do from the module ledgers." _n
file write `fh' "% Every quantity quoted in the report is defined here, so the prose and" _n
file write `fh' "% the analysis cannot drift apart." _n
file write `fh' "% Generated from `=_N' registered numbers." _n _n

* One pass down the rows, which are already sorted by module then key. A single
* row loop avoids the quoting traps that come with nested levelsof loops.
local prevmod ""
forvalues i = 1/`=_N' {
    local m  = module[`i']
    local k  = key[`i']
    local mn = macroname[`i']
    local fv = formatted[`i']
    local nt = note[`i']

    if "`m'" != "`prevmod'" {
        if "`prevmod'" != "" {
            file write `fh' _n
        }
        quietly count if module == "`m'"
        file write `fh' "% ---- `m' (`r(N)' numbers) ------------------------------" _n
        local prevmod "`m'"
    }

    * Keep the note short enough to stay a readable comment line.
    if length("`nt'") > 140 {
        local nt = substr("`nt'", 1, 140) + "..."
    }
    * A stray percent sign would comment out the rest of a LaTeX line, and a
    * stray dollar sign would open math mode, so escape both here. Backslash is
    * handled first, otherwise it would escape the escapes added after it.
    file write `fh' "% `k': `nt'" _n
    file write `fh' "\newcommand{\" "`mn'" "}{`fv'\xspace}" _n
}
file close `fh'

display as text "Wrote `=_N' macros -> 05_report/canonical_numbers.tex"
display as text "Merged ledger      -> 03_analysis/out/canonical_numbers.csv"
tabulate module
