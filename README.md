[![OpenWeave][ow-logo]][ow-schema-vendor-common-repo]
<br/>
<br/>
[![Build Status][ow-schema-vendor-common-travis-svg]][ow-schema-vendor-common-travis]

---

# What is OpenWeave?

<img src="https://github.com/openweave/openweave-core/raw/master/doc/images/ow-logo-weave.png" width="200px" align="right">

Weave is the network application layer that provides a secure, reliable
communications backbone for Nest's products. OpenWeave is the open source
release of Weave.

At Google, we believe the core technologies that underpin connected
home products need to be open and accessible. Alignment around common
fundamentals will help products securely and seamlessly communicate
with one another. Google's first open source release was our
implementation of Thread, OpenThread. OpenWeave can run on OpenThread,
other IPv6-bearing network links, or Bluetooth Low Energy, and is
another step in the direction of making our core technologies more
widely available.

# What is OpenWeave WDL "Common" Schema?

This package makes available the Weave Data Language (WDL) schema
corpus published under the "Common" vendor name space.

The "Common" vendor name space is a shared, global namespace
administered by Google that contains schema beneficial to and
leverageable by all other WDL schema vendor namespaces. In addition,
it represents schema that has been sufficiently vetted and generalized
to be deemed of broad utility to the WDL ecosystem that it warrants
transition and evolution from a vendor-administered namespace.

WDL is Weave's publish and subscribe schema language. The WDL schema
can be compiled with the WDL Compiler WDLC (see [Dependencies](#dependencies)).

[ow-schema-vendor-common-repo]: https://github.com/openweave/openweave-schema-vendor-common
[ow-wdlc-repo]: https://github.com/openweave/openweave-wdlc
[ow-logo]: https://github.com/openweave/openweave-core/raw/master/doc/images/ow-logo.png
[ow-logo-weave]: https://github.com/openweave/openweave-core/raw/master/doc/images/ow-logo-weave.png
[ow-schema-vendor-common-travis]: https://travis-ci.org/openweave/openweave-schema-vendor-common
[ow-schema-vendor-common-travis-svg]: https://travis-ci.org/openweave/openweave-schema-vendor-common.svg?branch=master

# Getting started with OpenWeave WDL "Common" Schema

## Building OpenWeave WDL "Common" Schema

*Validate device identity trait:*

    % wdlc --check --output ./build -I ~/schema/openweave-schema-vendor-common ~/schema/openweave-schema-vendor-common/weave/trait/description/device_identity_trait.proto

*Code-generate for Weave Device C++:*

    % wdlc --gen weave-device-cpp --output ./build -I ~/schema/openweave-schema-vendor-common ~/schema/openweave-schema-vendor-common/weave/trait/description/device_identity_trait.proto

*Code-generate using base protoc C++ template:*

    % wdlc --gen cpp --output ./build -I ~/schema/openweave-schema-vendor-common ~/schema/openweave-schema-vendor-common/weave/trait/description/device_identity_trait.proto

*Validate all traits in a given folder:*

    % wdlc --check --output ./build -I ~/schema/openweave-schema-vendor-common ~/schema/openweave-schema-vendor-common/weave/trait/located

*Code-generate schema + dependencies:*

    % wdlc -I ~/openweave-schema-vendor-nest -I ~/openweave-schema-vendor-common --gen weave-device-cpp --gen_dependencies --output ./build ~/openweave-schema-vendor-nest/nest/resource/nest_detect_resource.proto ~/openweave-schema-vendor-nest/nest/resource/nest_guard_resource.proto

### Dependencies

OpenWeave WDL "Common" Schema depends on WDLC. WDLC is available from
[ow-wdlc-repo].

# Need help?

There are numerous avenues for OpenWeave support:
* Bugs and feature requests — [submit to the Issue Tracker](https://github.com/openweave/openweave-schema-vendor-common/issues)
* Stack Overflow — [post questions using the openweave tag](http://stackoverflow.com/questions/tagged/openweave)
* Google Groups — discussion and announcements at [openweave-users](https://groups.google.com/forum/#!forum/openweave-users)

The openweave-users Google Group is the recommended place for users to
discuss OpenWeave and interact directly with the OpenWeave team.

# Directory Structure

The OpenWeave WDL "Common" Schema repository is structured as follows:

| File / Folder | Contents |
|----|----|
| `CHANGELOG` | Description of changes to OpenWeave from release-to-release.|
| `CONTRIBUTING.md` | Guidelines for contributing to OpenWeave WDL "Common" Schema.|
| `LICENSE` | OpenWeave WDL "Common" Schema license file (Apache 2.0).|
| `Makefile` | Top-level makefile.|
| `README.md` | This file.|
| `weave/` | "Common" WDL schema source.|

# Contributing

We would love for you to contribute to OpenWeave WDL "Common" Schema
and help make it even better than it is today! See the
[CONTRIBUTING.md](./CONTRIBUTING.md) file for more information.

# Versioning

OpenWeave WDL "Common" Schema follows the [Semantic Versioning
guidelines](http://semver.org/) for release cycle transparency and to
maintain backwards compatibility.

# License

**License and the Weave and OpenWeave Brands**

The OpenWeave software is released under the [Apache 2.0
license](./LICENSE), which does not extend a license for the use of
the Weave and OpenWeave name and marks beyond what is required for
reasonable and customary use in describing the origin of the software
and reproducing the content of the NOTICE file.

The Weave and OpenWeave name and word (and other trademarks, including
logos and logotypes) are property of Google LLC. Please refrain
from making commercial use of the Weave and OpenWeave names and word
marks and only use the names and word marks to accurately reference
this software distribution. Do not use the names and word marks in any
way that suggests you are endorsed by or otherwise affiliated with
Nest without first requesting and receiving a written license from us
to do so. See our [Trademarks and General
Principles](https://nest.com/legal/ip-and-other-notices/tm-list/) page
for additional details. Use of the Weave and OpenWeave logos and
logotypes is strictly prohibited without a written license from us to
do so.
