# Build the report. Run `make` from inside 05_report/.
#
# The whole project folder is portable: every path below is relative, so this
# works after the folder is zipped and moved to another machine with a TeX
# distribution and Python installed.
#
#   make          build the PDF
#   make numbers  regenerate canonical_numbers.tex from the analysis ledgers
#   make all      re-run the analysis, then rebuild everything
#   make clean    remove build artifacts (keeps the PDF)
#   make pages    report the page count, to track the budget

MAIN    := musicians_austin
LATEXMK := latexmk -xelatex -interaction=nonstopmode -halt-on-error

.PHONY: all pdf numbers analysis clean pages

pdf:
	$(LATEXMK) $(MAIN).tex

numbers:
	cd ../03_analysis/stata && "/Applications/StataNow/StataMP.app/Contents/MacOS/stata-mp" -b do build_numbers.do

analysis:
	cd ../03_analysis/stata && "/Applications/StataNow/StataMP.app/Contents/MacOS/stata-mp" -b do run_all.do

all: analysis numbers pdf

pages: pdf
	@python3 -c "import re,pathlib; \
	log=pathlib.Path('$(MAIN).log').read_text(errors='ignore'); \
	m=re.findall(r'Output written on .*\((\d+) pages', log); \
	print('Pages:', m[-1] if m else 'unknown')"

clean:
	latexmk -c $(MAIN).tex
	rm -f $(MAIN).bbl $(MAIN).run.xml
