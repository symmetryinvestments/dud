module dud.pkgdescription.sdl;

import dud.pkgdescription : Dependency, PackageDescription, TargetType;
import dud.semver : SemVer;
import dud.path : Path;

import dud.sdlang;

PackageDescription sdlToPackageDescription(string sdl) {
	Tag jv = parseFile(sdl);
	return sdlToPackageDescription(jv);
}

PackageDescription sdlToPackageDescription(Tag t) {
	return PackageDescription.init;
}
