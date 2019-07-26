#
#    Copyright (c) 2019 Google LLC. All Rights Reserved.
#    Copyright (c) 2016-2018 Nest Labs Inc. All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

##
#    @file
#       This file is a makefile wrapper around the Weave Data Language
#       (WDL) Compiler (wdlc) to automatically check/generate schema for
#       this schema repository.
#

# If your build is failing comparison validation, please talk to the
# owners for this schema repository to assess if you should be granted
# an exception. If you are indeed granted an exception, please update
# this has to point to the tip of the remotely tracked branch.

.DEFAULT_GOAL                        := help

PACKAGE                              := openweave-schema-vendor-common

DEBUG                                ?= 0
V                                    ?= 0

GIT                                  ?= git

SKIP_COMPARE_COMMIT_REV              := HEAD
REMOTE_COMPARISON_BRANCH             := master

#
# git-get-commit-hash-command <commitish>
#
# The git command used to convert a commit, tag, or other label into a
# git hash.
#
define git-get-commit-hash-command
$(GIT) rev-parse --verify $(1)
endef # git-get-commit-hash-command

#
# git-get-commit-hash <commitish>
#
# Convert a commit, tag, or other label into a git hash.
#
define git-get-commit-hash
$(shell $(call git-get-commit-hash-command,$(1)))
endef # git-get-commit-hash

#
# git-get-commit-hash <commitish>
#
# Convert a branch into the latest commit hash on that branch.
#
define git-get-commit-hash-for-branch
$(shell $(call git-get-commit-hash-command,origin/$(1)) || $(call git-get-commit-hash-command,$(1)))
endef # git-get-commit-hash-for-branch

SKIP_COMPARE_COMMIT_HASH             := $(call git-get-commit-hash,$(SKIP_COMPARE_COMMIT_REV))
SKIP_COMPARE_BRANCH                  := $(shell $(GIT) rev-parse --abbrev-ref $(SKIP_COMPARE_COMMIT_REV))
REMOTE_COMPARISON_BRANCH_LATEST_HASH := $(call git-get-commit-hash-for-branch,$(REMOTE_COMPARISON_BRANCH))

BUILDDIR                             := $(CURDIR)/build
RESULTSDIR                           := $(BUILDDIR)/results

PREVIOUS_SCHEMA_STAGING_DIR          := $(RESULTSDIR)/previous_schema
CURRENT_SCHEMA_STAGING_DIR           := $(RESULTSDIR)/current_schema
WORKSPACE_DIFF_PATH                  := $(RESULTSDIR)/workspace_diff.patch

PREVIOUS_SCHEMA_INTERMEDIATE_BIN     := $(RESULTSDIR)/previous-schema-intermediate.bin

WDLC                                 ?= wdlc
SCHEMA_DEPENDENCY_PATHS              :=
WDLC_SCHEMA_INCLUDE_PATHS_OPTION     := $(addprefix --include-schema-path , $(SCHEMA_DEPENDENCY_PATHS))

ERROR_COLOR                          := \033[0;31m
WARNING_COLOR                        := \033[0;35m
NOTE_COLOR                           := \033[0;36m
DEBUG_COLOR                          := \033[0;90m
NO_COLOR                             := \033[0m

ERROR_LABEL                          := ERROR
WARNING_LABEL                        := WARNING
NOTE_LABEL                           := NOTE
DEBUG_LABEL                          := DEBUG

ifeq ($(V),1)
PROGRESS                             := true
VERBOSE                              :=
else
PROGRESS                             := printf "  %-13s %s\n"
VERBOSE                              := @
endif

#
# log <ANSI color escape sequence> <label> <message>
#
# Write the specified message to standard output with the specified
# color and label.
#
define log
printf '$(1)$(2): %s${NO_COLOR}\n' '$(3)'
endef # log

#
# log-level <level> <message>
#
# Write the specified message to standard output at the specified level.
#
define log-level
$(call log,$($(1)_COLOR),$($(1)_LABEL),$(2))
endef # log-level

#
# log-error <message>
#
# Write the specified message to standard output at the error level.
#
define log-error
$(call log-level,ERROR,$(1))
endef # log-error

#
# log-warning <message>
#
# Write the specified message to standard output at the warning level.
#
define log-warning
$(call log-level,WARNING,$(1))
endef # log-warning

#
# log-note <message>
#
# Write the specified message to standard output at the note level.
#
define log-note
$(call log-level,NOTE,$(1))
endef # log-note

#
# log-debug <message>
#
# Write the specified message to standard output at the debug level.
#
# The action is only taken when DEBUG is asserted to '1'.
#
ifeq ($(DEBUG),1)
define log-debug
$(call log-level,DEBUG,$(1))
endef
else
define log-debug
endef
endif

#
# path-relative-to <base path> <full path>
#
# This attempts to, using a simple string substitution, to return the
# portion of the full path relative to the specified base path.
#
define path-relative-to
$(subst $(1)/,,$(2))
endef # dir-reltive-to

#
# path-relative-to-curdir <full path>
#
# This attempts to, using a simple string substitution, to return the
# portion of the full path relative to the current directory.
#
define path-relative-to-curdir
$(call path-relative-to,$(CURDIR),$(1))
endef # path-relative-to-curdir

#
# git-worktree-add <commitish> <path>
#
# Create <path> and checkout the specified tag, branch, or commit hash
# into it. The new working directory is linked to the current
# repository, sharing everything except working directory specific
# files such as HEAD, index, etc.
# 
define git-worktree-add
@$(PROGRESS) "GIT WORKTREE" "ADD $(1) $(call path-relative-to-curdir,$(2))"
$(VERBOSE)$(GIT) worktree add --quiet --force $(2) $(1)
endef # git-worktree-add

#
# wdlc-check <corpus dir> <pretty corpus dir> <additional options>
#
# Run WDLC with the '--check' option and the additional provided
# options against the specified schema corpus directory, using the
# specified pretty corpus directory for progress output.
#
define wdlc-check
@$(PROGRESS) "WDLC CHECK" "$(2)"
$(VERBOSE)$(WDLC) --check $(WDLC_SCHEMA_INCLUDE_PATHS_OPTION) $(3) --include-schema-path $(1) $(1)
endef # wdlc-check

#
# wdlc-check-validate <corpus dir> <results dir>
#
define wdlc-check-validate
$(call wdlc-check,$(1),$(notdir $(1)),-o $(2))
endef # wdlc-check-validate

#
# wdlc-check-compare <previous corpus dir> <current corpus dir> <intermediate binary path>
#
define wdlc-check-compare
$(call wdlc-check,$(1),$(call path-relative-to-curdir,$(1)),--output-intermediate $(3))
$(call wdlc-check,$(2),$(call path-relative-to-curdir,$(2)),--previous-intermediate-in $(3))
endef # wdlc-check-validate

#
# git-try-merge-remote-to-local <git branch name> <git branch commit hash>
#
# Function that attempts to merge in the specified git remote branch
# into the current local branch in a separate git worktree so that it
# does not affect the user's changes.
#
# The current local branch changes have to be staged for it to be
# picked up by this function. If not, a warning is emitted to the
# user.
#
define git-try-merge-remote-to-local
@$(PROGRESS) "GIT DIFF" "$(notdir $(CURDIR)) $(call path-relative-to-curdir,$(WORKSPACE_DIFF_PATH))"
$(VERBOSE)$(GIT) diff > $(WORKSPACE_DIFF_PATH)

$(VERBOSE)[ -s $(WORKSPACE_DIFF_PATH) ] && $(call log-warning,Unstaged changes present; these will not be picked up during validation!) || true
$(VERBOSE)$(GIT) diff --cached > $(WORKSPACE_DIFF_PATH)

$(call git-worktree-add,$(1),$(PREVIOUS_SCHEMA_STAGING_DIR))
$(call git-worktree-add,HEAD,$(CURRENT_SCHEMA_STAGING_DIR))

$(VERBOSE)[ -s $(WORKSPACE_DIFF_PATH) ] && $(call log-note,Staged changes present.) && $(GIT) -C $(CURRENT_SCHEMA_STAGING_DIR) apply $(WORKSPACE_DIFF_PATH) || true

$(VERBOSE)$(GIT) -C $(CURRENT_SCHEMA_STAGING_DIR) merge --quiet --no-commit --no-edit $(2) || \
    { $(call log-error,Merge conflicts when merging with $(1). Schema comparison cannot proceed.); exit 1; }
endef # git-try-merge-remote-to-local

all $(PACKAGE):
	@true

clean:
	@$(PROGRESS) "CLEAN" "$(call path-relative-to-curdir,$(RESULTSDIR))"
	-$(VERBOSE)rm -rf $(PREVIOUS_SCHEMA_STAGING_DIR)
	-$(VERBOSE)rm -rf $(CURRENT_SCHEMA_STAGING_DIR)
	-$(VERBOSE)rm -rf $(WORKSPACE_DIFF_PATH)
	-$(VERBOSE)rm -rf $(RESULTSDIR)

check: check-compare-schema check-validate-schema

$(CURRENT_SCHEMA_STAGING_DIR) $(PREVIOUS_SCHEMA_STAGING_DIR): | $(RESULTSDIR)

$(CURRENT_SCHEMA_STAGING_DIR) $(PREVIOUS_SCHEMA_STAGING_DIR) $(RESULTSDIR):
	@$(PROGRESS) "MKDIR" "$(call path-relative-to-curdir,$(@))"
	$(VERBOSE)mkdir -p "$(@)"

# Validate the corpus of schema local to this vendor using, checking
# only syntax of the branch and local changes thereto in isolation.
#
# This WILL NOT validate that the changes are "breaking" with respect
# to another branch or instance of the schema corpus and in violation
# of such contextual policies.

check-validate-schema: clean | $(RESULTSDIR)
	$(call wdlc-check-validate,$(CURDIR),$(RESULTSDIR))

# Compare the local copy of schema against a remotely-tracked version
# of schema and ensure the local changes are valid against WDL rules
# and policies.
#
# This WILL validate that the changes are NOT "breaking" with respect
# to another branch or instance of the schema corpus are NOT violation
# of such contextual policies.

check-compare-schema: check-validate-schema | $(RESULTSDIR) $(CURRENT_SCHEMA_STAGING_DIR) $(PREVIOUS_SCHEMA_STAGING_DIR)
	@$(call log-debug,Determined the latest commit on '$(SKIP_COMPARE_BRANCH)' is '$(SKIP_COMPARE_COMMIT_HASH)')
	@$(call log-debug,Determined the latest commit on '$(REMOTE_COMPARISON_BRANCH)' is '$(REMOTE_COMPARISON_BRANCH_LATEST_HASH)')
ifeq ($(SKIP_COMPARE_COMMIT_HASH),$(REMOTE_COMPARISON_BRANCH_LATEST_HASH))
	@$(call log-note,Latest commit on the current branch $(SKIP_COMPARE_BRANCH) and $(REMOTE_COMPARISON_BRANCH) match; skipping comparison.)
else
	$(VERBOSE)$(call git-try-merge-remote-to-local,$(REMOTE_COMPARISON_BRANCH),$(REMOTE_COMPARISON_BRANCH_LATEST_HASH))
	$(call wdlc-check-compare,$(PREVIOUS_SCHEMA_STAGING_DIR),$(CURRENT_SCHEMA_STAGING_DIR),$(PREVIOUS_SCHEMA_INTERMEDIATE_BIN))
endif

help:
	$(VERBOSE)echo "This makefile supports the following build targets:"
	$(VERBOSE)echo ""
	$(VERBOSE)echo "  all"
	$(VERBOSE)echo "  $(PACKAGE)"
	$(VERBOSE)echo "    Generate all configured build artifacts for this package."
	$(VERBOSE)echo ""
	$(VERBOSE)echo "  check"
	$(VERBOSE)echo "    Generate all configured build artifacts and run all unit "
	$(VERBOSE)echo "    and functional tests for this package."
	$(VERBOSE)echo ""
	$(VERBOSE)echo "  clean"
	$(VERBOSE)echo "    Remove all configured build artifacts."
	$(VERBOSE)echo ""
	$(VERBOSE)echo "  help"
	$(VERBOSE)echo "    Display this content."
	$(VERBOSE)echo ""

