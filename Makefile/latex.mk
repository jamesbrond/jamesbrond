# required makefiles:
# - misc.mk

# required variables:
# - BUILD_DIR
# - CHKTEX
# - DIST_DIR
# - LATEX_MAIN_SRCS
# - LATEXMK
# - PDF_READER
# optional variables:
#
LATEX_BUILD_DIR  := $(BUILD_DIR)/latex
LATEX_DIST_DIR   := $(DIST_DIR)/latex

LATEX_MAIN_OBJS  := $(LATEX_MAIN_SRCS:%.tex=$(LATEX_BUILD_DIR)/%.pdf)
LATEX_DIST_OBJS  := $(LATEX_MAIN_SRCS:%.tex=$(LATEX_DIST_DIR)/%.pdf)
LATEX_SRCS       := $(shell /usr/bin/find ./ -name "*.tex" -type f)
LATEX_LOG_PREF   := LATEX

LATEX_OPTS := -pdflatex="lualatex %O %S" -pdf -dvi- -ps- --halt-on-error --interaction=nonstopmode --output-directory=$(LATEX_BUILD_DIR) --output-format=pdf

DIRS := $(DIRS) $(LATEX_BUILD_DIR) $(LATEX_DIST_DIR)

.PHONY: clean-dist clean compile lint read-pdf release


$(LATEX_BUILD_DIR)/%.pdf: %.tex $(LATEX_SRCS) | $(LATEX_BUILD_DIR)
	@$(call log-info,$(LATEX_LOG_PREF),creating PDF $@)
	@$(LATEXMK) $(LATEX_OPTS) $<

$(LATEX_DIST_DIR)/%.pdf: $(LATEX_BUILD_DIR)/%.pdf | $(LATEX_DIST_DIR)
	@$(call log-info,$(LATEX_LOG_PREF),promove PDF $@ to dist)
	@cp $< $@

distclean::
	@$(call log-info,$(LATEX_LOG_PREF),removing pdf output files)
	-@rm -rf $(LATEX_DIST_OBJS)
	@$(call log-info,$(LATEX_LOG_PREF),deep clean of latex solution)
	-@rm -rf $(LATEX_BUILD_DIR)
	-@rm -rf $(LATEX_DIST_DIR)

clean::
	@$(call log-info,$(LATEX_LOG_PREF),removing temporary generated latex files)
# Remove leftovers from latex
	-@rm -f $(LATEX_BUILD_DIR)/*.{aux,log,out}
# Remove leftovers from bibtex
	-@rm -f $(LATEX_BUILD_DIR)/*.{bbl,blg,bcf}
# Remove leftovers from glossaries
	-@rm -f $(LATEX_BUILD_DIR)/*.{glg,gls,glo}
# Remove leftovers from lists
	-@rm -f $(LATEX_BUILD_DIR)/*.{lof,lot,toc}
# Remove leftovers from minitoc
	-@rm -f $(LATEX_BUILD_DIR)/*.{mtc,maf}
# Remove leftovers from latexmk
	-@rm -f $(LATEX_BUILD_DIR)/*.{fdb_latexmk,fls}
# Remove other stuff
	-@rm -f $(LATEX_BUILD_DIR)/*.{run.xml,acn,acr,alg,ist,synctex*,alg}
	-@rm -f $(LATEX_MAIN_OBJS)

build:: $(LATEX_MAIN_OBJS)

dist:: latex-compile $(LATEX_DIST_OBJS)

lint:: $(LATEX_SRCS)
# Uses chktex (https://www.nongnu.org/chktex/ChkTeX.pdf)
# No Warning 13: Intersentence spacing (�\@�) should perhaps be used.
	@$(call log-debug,$(LATEX_LOG_PREF),run CHKTEX for latex linting)
	@$(CHKTEX) -v0qn13 $(LATEX_SRCS)

read-pdf: $(LATEX_MAIN_OBJS) ## Open document in pdf reader
	@$(call log-info,$(LATEX_LOG_PREF),open $(LATEX_MAIN_OBJS))
	@$(PDF_READER) $(LATEX_MAIN_OBJS) &

# ~@:-]