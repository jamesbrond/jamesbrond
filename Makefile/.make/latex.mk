# required makefiles:
# - misc.mk

# required variables:
# - CHKTEX
# - LATEX_MAIN_SRCS
# - LATEXMK
# - PDF_READER
# optional variables:
# - WORK_DIR


LATEX_BUILD_DIR  := $(BUILD_DIR)/latex
LATEX_DIST_DIR   := $(DIST_DIR)/latex

LATEX_MAIN_OBJS  := $(LATEX_MAIN_SRCS:%.tex=$(LATEX_BUILD_DIR)/%.pdf)
LATEX_DIST_OBJS  := $(LATEX_MAIN_SRCS:%.tex=$(LATEX_DIST_DIR)/%.pdf)
LATEX_SRCS       := $(shell /usr/bin/find ./ -name "*.tex" -type f)
LATEX_LOG_PREF   := LATEX

LATEX_OPTS := -pdflatex="lualatex %O %S" -pdf -dvi- -ps- --halt-on-error --interaction=nonstopmode --output-directory=$(LATEX_BUILD_DIR) --output-format=pdf

DIRS += $(LATEX_BUILD_DIR) $(LATEX_DIST_DIR)

.PHONY: read-pdf

$(LATEX_BUILD_DIR)/%.pdf: %.tex $(LATEX_SRCS) | $(LATEX_BUILD_DIR)
	@$(call log-info,$(LATEX_LOG_PREF),creating PDF $@)
	@$(LATEXMK) $(LATEX_OPTS) $<

$(LATEX_DIST_DIR)/%.pdf: $(LATEX_BUILD_DIR)/%.pdf | $(LATEX_DIST_DIR)
	@$(call log-info,$(LATEX_LOG_PREF),promove PDF $@ to dist)
	@cp $< $@

build:: $(LATEX_MAIN_OBJS)

clean::
	@$(call log-debug,$(LATEX_LOG_PREF),Remove leftovers from latex)
	@-$(RM) $(LATEX_BUILD_DIR)/*.{aux,log,out}
	@$(call log-debug,$(LATEX_LOG_PREF),Remove leftovers from bibtex)
	@-$(RM) $(LATEX_BUILD_DIR)/*.{bbl,blg,bcf}
	@$(call log-debug,$(LATEX_LOG_PREF),Remove leftovers from glossaries)
	@-$(RM) $(LATEX_BUILD_DIR)/*.{glg,gls,glo}
	@$(call log-debug,$(LATEX_LOG_PREF),Remove leftovers from lists)
	@-$(RM) $(LATEX_BUILD_DIR)/*.{lof,lot,toc}
	@$(call log-debug,$(LATEX_LOG_PREF),Remove leftovers from minitoc)
	@-$(RM) $(LATEX_BUILD_DIR)/*.{mtc,maf}
	@$(call log-debug,$(LATEX_LOG_PREF),Remove leftovers from latexmk)
	@-$(RM) $(LATEX_BUILD_DIR)/*.{fdb_latexmk,fls}
	@$(call log-debug,$(LATEX_LOG_PREF),Remove other stuff)
	@-$(RM) $(LATEX_BUILD_DIR)/*.{run.xml,acn,acr,alg,ist,synctex*,alg}
	@-$(RM) $(LATEX_MAIN_OBJS)

distclean:: clean
	@$(call log-debug,$(LATEX_LOG_PREF),removing pdf output files)
	@-$(RMDIR) $(LATEX_DIST_OBJS) $(NULL_STDERR)
	@$(call log-debug,$(LATEX_LOG_PREF),deep clean of latex solution)
	@-$(RMDIR) $(LATEX_BUILD_DIR) $(NULL_STDERR)
	@-$(RMDIR) $(LATEX_DIST_DIR) $(NULL_STDERR)

dist:: build $(LATEX_DIST_OBJS)

lint::
# Uses chktex (https://www.nongnu.org/chktex/ChkTeX.pdf)
# No Warning 13: Intersentence spacing (�\@�) should perhaps be used.
ifdef CHKTEX
	@$(call log-info,$(LATEX_LOG_PREF),LaTeX lint)
	@$(call log-debug,$(LATEX_LOG_PREF),run CHKTEX for latex linting)
	@$(CHKTEX) -v0qn13 $(LATEX_SRCS)
else
	@$(call log-warn,$(LATEX_LOG_PREF),CHKTEX is not defined)
endif

read-pdf: $(LATEX_MAIN_OBJS) ## Open document in pdf reader
ifdef PDF_READER
	@$(call log-info,$(LATEX_LOG_PREF),open $(LATEX_MAIN_OBJS))
	@$(PDF_READER) $(LATEX_MAIN_OBJS) &
else
	@$(call log-warn,$(LATEX_LOG_PREF),PDF_READER is not defined)
endif

# ~@:-]
