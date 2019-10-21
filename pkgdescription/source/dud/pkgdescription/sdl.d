module dud.pkgdescription.sdl;

import dud.pkgdescription : Dependency, PackageDescription, TargetType;
import dud.semver : SemVer;
import dud.path : Path;

PackageDescription sdlToPackageDescription(string sdl) {
	Tag jv = parseFile(sdl);
	return jsonToPackageDescription(jv);
}

PackageDescription sdlPackageDescription(Tag t) {
}
