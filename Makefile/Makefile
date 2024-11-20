# Define program variables and folders
MAKE_DIR  	 := .make

# define all directories to be created
# each included Makefile may add to $(DIRS)
DIRS = $(MAKE_DIR)

SHELL:=/bin/bash

-include $(MAKE_DIR)/misc.mk
-include $(MAKE_DIR)/git.mk
# -include $(MAKE_DIR)/py.mk
# -include $(MAKE_DIR)/latex.mk
-include $(CONFIGURE)

# download all missing include Makefiles
$(MAKE_DIR)/%.mk: | $(MAKE_DIR)
	@URL=$$(echo "https://raw.githubusercontent.com/jamesbrond/jamesbrond/main/Makefile/.make/$(@F)"); \
	echo "get $$URL"; \
	curl -s -H 'Cache-Control: no-cache, no-store' $${URL} -o $@

.PHONY: all clean distclean maintainer-clean dist init lint test
.DEFAULT_GOAL := all

$(DIRS):
	@$(call log-debug,MAKE,make '$@' folder)
	@mkdir -p $@

# Compile the entire program.
# This should be the default target. This target need not rebuild any documentation files;
# Info files should normally be included in the distribution, and DVI (and other
# documentation format) files should be made only when explicitly asked for.
all:: ## Compile the entire program
	@$(call log-info,MAKE,$@ done)

# Delete all files in the current directory that are normally created by building
# the program. Also delete files in other directories if they are created by
# this makefile. However, don’t delete the files that record the configuration.
# Also preserve files that could be made by building, but normally aren’t because
# the distribution comes with them.
clean:: ## Delete all files created by this makefile, however don’t delete the files that record configuration or environment
	@$(call log-info,MAKE,$@ done)

# Delete all files in the current directory (or created by this makefile) that
# are created by configuring or building the program. If you have unpacked the
# source and built the program without creating any other files, ‘make distclean’
# should leave only the files that were in the distribution.
distclean:: clean ## Delete all files in the current directory (or created by this makefile) that
# are created by configuring or building the program.
	@-$(RMDIR) $(BUILD_DIR) $(NULL_STDERR)
	@-$(RMDIR) $(DIST_DIR) $(NULL_STDERR)
	@-$(RMDIR) $(MAKE_DIR) $(NULL_STDERR)
	@$(call log-info,MAKE,$@ done)

# Delete almost everything that can be reconstructed with this Makefile.
# This typically includes everything deleted by distclean, plus more:
# source files produced, tags tables, Info files, and so on.
# The reason we say “almost everything” is that running the command ‘make maintainer-clean’
# should not delete configure even if configure can be remade using a rule in
# the Makefile. More generally, ‘make maintainer-clean’ should not delete
# anything that needs to exist in order to run configure and then begin to build
# the program.
# The ‘maintainer-clean’ target is intended to be used by a maintainer of the package,
# not by ordinary users. You may need special tools to reconstruct some of the files
# that ‘make maintainer-clean’ deletes. Since these files are normally included in the
# distribution, we don’t take care to make them easy to reconstruct.
maintainer-clean:: distclean ##Delete almost everything that can be reconstructed with this Makefile.
	@$(call log-info,MAKE,$@ done)

# Create a distribution tar file for this program.
# The tar file should be set up so that the file names in the tar file start
# with a subdirectory name which is the name of the package it is a distribution for.
# This name can include the version number.
# The easiest way to do this is to create a subdirectory appropriately named, use ln
# or cp to install the proper files in it, and then tar that subdirectory.
# The dist target should explicitly depend on all non-source files that are in the
# distribution, to make sure they are up to date in the distribution.
dist:: ## Create a distribution file or files for this program
	@$(call log-info,MAKE,$@ done)

# Prepare the environment to build the software on your specific system.
# It makes sure all of the dependencies for the rest of the build and install
# process are available, and finds out whatever it needs to know to use
# those dependencies.
init:: ## Initialize development environment
	@$(call log-info,MAKE,$@ done)

# Performs static code analysis for this program.
lint:: ## Perform static linting
	@$(call log-info,MAKE,$@ done)

# Runs unit test for this program.
test:: ## Unit test
	@$(call log-info,MAKE,$@ done)

# ~@:-]
