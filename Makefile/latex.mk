# requires misc.mk an user.mk

LATEX_BUILD_DIR  := build/latex
LATEX_DIST_DIR   := dist/latex

LATEX_MAIN_OBJS  := $(LATEX_MAIN_SRCS:%.tex=$(LATEX_DIST_DIR)/%.pdf)
LATEX_DEPS       := $(shell /usr/bin/find ./ -name "*.tex" -type f)


LATEX_OPTS := -pdflatex="lualatex %O %S" -pdf -dvi- -ps- --halt-on-error --interaction=nonstopmode --output-directory=$(LATEX_BUILD_DIR) --output-format=pdf


.PHONY: clean-latex latex read


$(LATEX_BUILD_DIR) $(LATEX_DIST_DIR):
	@mkdir -p $(@)

$(LATEX_BUILD_DIR)/%.pdf: %.tex $(LATEX_DEPS)
	$(LATEXMK) $(LATEX_OPTS) $<

$(LATEX_DIST_DIR)/%.pdf: $(LATEX_BUILD_DIR)/%.pdf
	@$(call prompt-info,Creating PDF $(@))
	@cp $< $(LATEX_DIST_DIR)

clean-latex-dist: ## ## Clean pdf in dist folder
	@$(call prompt-log,Removing pdf output files)
	@-rm -f $(LATEX_MAIN_OBJS)
	@-rm -d $(LATEX_DIST_DIR) || echo ""

clean-latex: ## Clean-up latex build artifacts
	@$(call prompt-log,Removing temporary generated latex files)
	@-rm -rf $(LATEX_BUILD_DIR)

latex: $(LATEX_DIST_DIR) $(LATEX_MAIN_OBJS) ## Build latex documents to pdf

read-pdf: latex ## Open document in pdf reader
	@$(PDF_READER) $(LATEX_MAIN_OBJS) &

# ~@:-]