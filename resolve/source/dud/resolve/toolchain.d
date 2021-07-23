module dud.resolve.toolchain;

import dud.pkgdescription : Toolchain;
import dud.semver.setoperation;
import dud.semver.versionunion;

@safe pure:

struct ToolchainVersionUnion {
	Toolchain tool;
	bool no;
	VersionUnion version_;
}

ToolchainVersionUnion dup(const(ToolchainVersionUnion) old) {
	return ToolchainVersionUnion(old.tool, old.no
			, old.version_.dup());
}

ToolchainVersionUnion invert(const(ToolchainVersionUnion) old) {
	return ToolchainVersionUnion(cast()old.tool, !old.no
			, dud.semver.setoperation.invert(old.version_));
}
