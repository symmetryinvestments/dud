module dud.resolve.partialsolution;

import dud.pkgdescription : Toolchain;
import dud.resolve.assignment;
import dud.resolve.conf : Conf;
import dud.resolve.toolchain;
import dud.semver.semver : SemVer;

@safe:

struct ToolchainSemVer {
@safe pure:
	Toolchain tool;
	SemVer version_;
}

struct Decision {
	SemVer ver;
	Conf conf;
	ToolchainSemVer[] toolchains;
}

struct PartialSolution {
	Assignment[] assignments;
	Decision[string] decisions;
}
