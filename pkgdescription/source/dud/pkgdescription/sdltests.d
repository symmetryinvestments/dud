module dud.pkgdescription.sdltests;

import std.conv;

import dud.path : Path;
import dud.pkgdescription : PackageDescription, TargetType;
import dud.pkgdescription.sdl;

unittest {
	import dud.semver : SemVer;

	string input = `
name "pkgdescription"
dependency "semver" path="../semver"
dependency "path" path="../path"
dependency "sdlang" path="../sdlang"
dependency "graphql" version=">=1.0.0" default=true optional=false
targetType "library"
importPaths "source" "source1" "source2"
`;

	PackageDescription pkg = sdlToPackageDescription(input);
	assert(pkg.name == "pkgdescription", pkg.name);
	assert(pkg.targetType == TargetType.library, to!string(pkg.targetType));
	assert(pkg.importPaths ==
			[ Path("source") , Path("source1"), Path("source2") ],
			to!string(pkg.importPaths));
}
