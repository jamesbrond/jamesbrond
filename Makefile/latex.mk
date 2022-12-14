# required makefiles:
# - misc.mk

# required variables:
# - BUILD_DIR
# - CHKTEX
# - DIST_DIR
# - LATEX_MAIN_SRCS
# - LATEXMK
# - PDF_READER
# - NPM
# optional variables:
#
LATEX_BUILD_DIR  := $(BUILD_DIR)/latex
LATEX_DIST_DIR   := $(DIST_DIR)/latex
LATEX_NODE_DIR   := $(LATEX_BUILD_DIR)/node_modules

LATEX_MAIN_OBJS  := $(LATEX_MAIN_SRCS:%.tex=$(LATEX_BUILD_DIR)/%.pdf)
LATEX_DIST_OBJS  := $(LATEX_MAIN_SRCS:%.tex=$(LATEX_DIST_DIR)/%.pdf)
LATEX_SRCS       := $(shell /usr/bin/find ./ -name "*.tex" -type f)
LATEX_PACKAGE    := $(LATEX_BUILD_DIR)/package.json
LATEX_MK_PREFIX  := LATEX


LATEX_OPTS := -pdflatex="lualatex %O %S" -pdf -dvi- -ps- --halt-on-error --interaction=nonstopmode --output-directory=$(LATEX_BUILD_DIR) --output-format=pdf


.PHONY: clean-dist clean compile devdeps lint read-pdf release


$(LATEX_BUILD_DIR) $(LATEX_DIST_DIR) $(LATEX_NODE_DIR):
	@$(call log,$(LATEX_MK_PREFIX),make $@)
	@mkdir -p $@

$(LATEX_BUILD_DIR)/%.pdf: %.tex $(LATEX_SRCS) | $(LATEX_BUILD_DIR)
	@$(call log,$(LATEX_MK_PREFIX),creating PDF $@)
	@$(LATEXMK) $(LATEX_OPTS) $<

$(LATEX_DIST_DIR)/%.pdf: $(LATEX_BUILD_DIR)/%.pdf | $(LATEX_DIST_DIR)
	@$(call log,$(LATEX_MK_PREFIX),promove PDF $@ do dist)
	@cp $< $(LATEX_DIST_DIR)

$(LATEX_NODE_DIR)/%: $(LATEX_PACKAGE)
	@$(call log,$(LATEX_MK_PREFIX),install module $$(basename $@))
	@$(NPM) install --pefix $(LATEX_BUILD_DIR) --save-dev $$(basename $@)

$(LATEX_PACKAGE): | $(LATEX_NODE_DIR)
	@cd $(LATEX_BUILD_DIR) && $(NPM) init --yes

clean-deep::
	@$(call log,$(LATEX_MK_PREFIX),[LATEXdeep clean of latex solution)
	@-rm -f $(LATEX_PACKAGE)
	@-rm -rf $(LATEX_NODE_DIR)
	@-rm -rf $(LATEX_BUILD_DIR)

clean-release::
	@$(call log,$(LATEX_MK_PREFIX),removing pdf output files)
	@-rm -rf $(LATEX_DIST_OBJS)

clean::
	@$(call log,$(LATEX_MK_PREFIX),removing temporary generated latex files)
# Remove leftovers from latex
	@-rm -f $(LATEX_BUILD_DIR)/*.{aux,log,out}
# Remove leftovers from bibtex
	@-rm -f $(LATEX_BUILD_DIR)/*.{bbl,blg,bcf}
# Remove leftovers from glossaries
	@-rm -f $(LATEX_BUILD_DIR)/*.{glg,gls,glo}
# Remove leftovers from lists
	@-rm -f $(LATEX_BUILD_DIR)/*.{lof,lot,toc}
# Remove leftovers from minitoc
	@-rm -f $(LATEX_BUILD_DIR)/*.{mtc,maf}
# Remove leftovers from latexmk
	@-rm -f $(LATEX_BUILD_DIR)/*.{fdb_latexmk,fls}
# Remove other stuff
	@-rm -f $(LATEX_BUILD_DIR)/*.{run.xml,acn,acr,alg,ist,synctex*,alg}
	@-rm -f $(LATEX_MAIN_OBJS)

latex-compile: $(LATEX_MAIN_OBJS) ## Build latex files with latexmk
compile:: latex-compile

latex-devdeps: $(LATEX_NODE_DIR)/textlint $(LATEX_NODE_DIR)/textlint-rule-terminology ## Download node dependencies for latex file linting
devdeps:: latex-devdeps

release:: latex-compile $(LATEX_DIST_OBJS)

lint:: latex-devdeps
# Uses chktex (https://www.nongnu.org/chktex/ChkTeX.pdf)
# No Warning 13: Intersentence spacing (�\@�) should perhaps be used.
	@$(call log,$(LATEX_MK_PREFIX),run latex linting)
	@$(CHKTEX) -v0qn13 $(LATEX_SRCS)
	@$(call log,$(LATEX_MK_PREFIX),run text linting to latex documents)
	@node $(LATEX_NODE_DIR)/.bin/textlint --rule terminology $(LATEX_SRCS)

read-pdf: latex-compile ## Open document in pdf reader
	@$(call log-info,$(LATEX_MK_PREFIX),open $(LATEX_MAIN_OBJS))
	@$(PDF_READER) $(LATEX_MAIN_OBJS) &

# ~@:-]