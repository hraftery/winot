# Winot - Putting the IoT in Wine
## Balena Residency Project

This document is a chapter in the Winot project documentation. To see it in context, open the project [README](README.md).

---

# Avenues For Investigation

TODO: intro.

1. Installing target dependencies into `sysroot` for cross-compiling.
1. Cross-compilation of Qt6.
	- Still needs some work to finalise, but soooooo much novel work done, and bound to become popular.
	- > I’m starting to see balena as this sort of translation layer between non-embedded and embedded software development, and wonder whether the pain of porting software that runs on the Desktop or the cloud to a physical (probably-ARM) device is one balena ought to ease.
1. ARM binaries for Qt6.
	- Unofficially host them?
2. Evangelise build-anywhere-test-on-target development workflow.
	- Needs better name but "local mode" already taken.
	- Basically embedded dev for edge developers.
- 