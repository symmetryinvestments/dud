module dud.pkgdescription.sdltests;

import dud.pkgdescription.sdl;
import dud.pkgdescription : PackageDescription, TargetType;

unittest {
	import dud.semver : SemVer;

	string input = `
name "pkgdescription"
dependency "semver" path="../semver"
dependency "path" path="../path"
dependency "sdlang" path="../sdlang"
targetType "library"`;

	PackageDescription pkg = sdlToPackageDescription(input);
	assert(pkg.name == "pkgdescription", pkg.name);
}
