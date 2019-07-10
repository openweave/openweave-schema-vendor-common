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

SKIP_COMPARE_COMMIT_HASH            := HEAD
REMOTE_COMPARISON_BRANCH            := master

BUILDDIR                            := $(CURDIR)/build
RESULTSDIR                          := $(BUILDDIR)/results

PREVIOUS_SCHEMA_STAGING_DIR         := $(RESULTSDIR)/previous_schema
CURRENT_SCHEMA_STAGING_DIR          := $(RESULTSDIR)/current_schema
WORKSPACE_DIFF_PATH                 := $(RESULTSDIR)/workspace_diff

WDLC                                ?= wdlc
SCHEMA_DEPENDENCY_PATHS             :=
WDLC_SCHEMA_INCLUDE_PATHS_OPTION    := $(addprefix --include-schema-path , $(SCHEMA_DEPENDENCY_PATHS))

WARNING_COLOR                       = \033[0;31m
NC                                  = \033[0m # No Color

ifeq ($(V),1)
VERBOSE                             :=
else
VERBOSE                             := @
endif

#
# Function that attempts to merge in a remote branch into the local branch
# in a separate git worktree so that it doesn't affect the user's changes.
#
# The changes have to be staged for it to be picked up by this function. If not, a warning is emitted to the user.
#
define try_merge_remote_to_local
    @echo "Cleaning up previous staged changes..."

    @rm -rf $(PREVIOUS_SCHEMA_STAGING_DIR)
    @rm -rf $(CURRENT_SCHEMA_STAGING_DIR)
    @rm -rf $(WORKSPACE_DIFF_PATH)

    @mkdir -p $(RESULTSDIR)

    @$(eval COMPARISON_COMMIT := $(shell git rev-parse --verify origin/$(1) || git rev-parse --verify $(1)))
    @echo "Retrieved the latest commit on $(1) = $(COMPARISON_COMMIT)"

    @git diff > $(WORKSPACE_DIFF_PATH)
    @[ -s $(WORKSPACE_DIFF_PATH) ] && echo "${WARNING_COLOR}*** WARNING ** Unstaged changes present! These will not be picked up during validation!${NC}" || true

    @git diff --cached > $(WORKSPACE_DIFF_PATH)
    @git worktree add --force $(PREVIOUS_SCHEMA_STAGING_DIR) $(COMPARISON_COMMIT)
    @git worktree add --force $(CURRENT_SCHEMA_STAGING_DIR) HEAD

    @[ -s $(WORKSPACE_DIFF_PATH) ] && echo Workspace Dirty && git -C $(CURRENT_SCHEMA_STAGING_DIR) apply $(WORKSPACE_DIFF_PATH) || true

    @git -C $(CURRENT_SCHEMA_STAGING_DIR) merge --no-commit --no-edit $(COMPARISON_COMMIT) || \
        { echo "Merge conflicts when merging with $(COMPARISON_BRANCH). Schema comparison cannot proceed."; exit 1; }
endef

clean:
	rm -rf $(RESULTSDIR)

check: clean validate-schema compare-schema

# Validate the corpus of schema local to this vendor
validate-schema:
	mkdir -p $(RESULTSDIR)

	# Emit the descriptor binary if needed for comparison later.
	$(VERBOSE)$(WDLC) --check $(WDLC_SCHEMA_INCLUDE_PATHS_OPTION) --include-schema-path . -o $(RESULTSDIR) .

# Compare the local copy of schema against a remotely tracked version of schema and ensure the local changes are valid against WDL rules.
compare-schema:
	@$(eval LATEST_REMOTE_COMMIT := $(shell git rev-parse --verify origin/$(REMOTE_COMPARISON_BRANCH) || git rev-parse --verify $(REMOTE_COMPARISON_BRANCH)))

ifeq ($(SKIP_COMPARE_COMMIT_HASH), $(LATEST_REMOTE_COMMIT))
	echo "Skipping compare"
else
	@$(call try_merge_remote_to_local,$(REMOTE_COMPARISON_BRANCH))
endif

	# Compile the remotely tracked version (which houses the prior version of the local schema).
	$(WDLC) --check $(WDLC_SCHEMA_INCLUDE_PATHS_OPTION) --include-schema-path $(PREVIOUS_SCHEMA_STAGING_DIR)/openweave-schema-vendor-common --output-intermediate $(RESULTSDIR)/previous-schema-intermediate.bin $(PREVIOUS_SCHEMA_STAGING_DIR)/openweave-schema-vendor-common

	# Compile the newer version which has the locally merged content from the remote, and do a comparison against the old content.
	$(WDLC) --check $(WDLC_SCHEMA_INCLUDE_PATHS_OPTION) --previous-intermediate-in $(RESULTSDIR)/previous-schema-intermediate.bin --include-schema-path $(CURRENT_SCHEMA_STAGING_DIR)/openweave-schema-vendor-common \
		$(CURRENT_SCHEMA_STAGING_DIR)/openweave-schema-vendor-common
