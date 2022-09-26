# required makefiles:
# - misc.mk

# required variables:
# - CHKTEX
# - LATEX_MAIN_SRCS
# - LATEXMK
# - NPM
# - PDF_READER

# optional variables:
#

LATEX_BUILD_DIR  := build/latex
LATEX_DIST_DIR   := dist/latex
NODE_MODULES_DIR := node_modules

LATEX_MAIN_OBJS  := $(LATEX_MAIN_SRCS:%.tex=$(LATEX_DIST_DIR)/%.pdf)
LATEX_SRCS       := $(shell /usr/bin/find ./ -name "*.tex" -type f)


LATEX_OPTS := -pdflatex="lualatex %O %S" -pdf -dvi- -ps- --halt-on-error --interaction=nonstopmode --output-directory=$(LATEX_BUILD_DIR) --output-format=pdf


.PHONY: clean-latex-dist clean-latex latex-devdeps latex-lint latex read-pdf text-lint


$(LATEX_BUILD_DIR) $(LATEX_DIST_DIR):
	@mkdir -p $(@)

$(LATEX_BUILD_DIR)/%.pdf: %.tex $(LATEX_SRCS)
	$(LATEXMK) $(LATEX_OPTS) $<

$(LATEX_DIST_DIR)/%.pdf: $(LATEX_BUILD_DIR)/%.pdf
	@$(call prompt-info,Creating PDF $(@))
	@cp $< $(LATEX_DIST_DIR)

$(NODE_MODULES_DIR)/%: package.json
	@$(call prompt-info,Install textlint module $$(basename $(@)))
	@$(NPM) install --save-dev $$(basename $(@))

package.json:
	@$(NPM) init --yes

latex-clean-dist: ## Clean pdf in dist folder
	@$(call prompt-log,Removing pdf output files)
	@-rm -f $(LATEX_MAIN_OBJS)
	@-rm -rf $(LATEX_DIST_DIR) || echo ""
	@-rm -rf $(NODE_MODULES_DIR) || echo ""
	@-rm package.json package-lock.json || echo ""

latex-clean: ## Clean-up latex build artifacts
	@$(call prompt-log,Removing temporary generated latex files)
	@-rm -rf $(LATEX_BUILD_DIR)

latex-devdeps: $(NODE_MODULES_DIR)/textlint $(NODE_MODULES_DIR)/textlint-rule-terminology ## Install latex dev dependencies (textlint)

latex-lint: ## LaTex syntax linting
# Uses chktex (https://www.nongnu.org/chktex/ChkTeX.pdf)
# No Warning 13: Intersentence spacing (‘\@’) should perhaps be used.
	@$(CHKTEX) -v0qn13 $(LATEX_SRCS)

latex: $(LATEX_DIST_DIR) $(LATEX_MAIN_OBJS) ## Build latex documents to pdf

read-pdf: latex ## Open document in pdf reader
	@$(PDF_READER) $(LATEX_MAIN_OBJS) &

text-lint: ## Text linting
	@npx textlint --rule terminology $(LATEX_SRCS)

# ~@:-]