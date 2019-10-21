module dud.pkgdescription.sdl;

import dud.pkgdescription : Dependency, PackageDescription, TargetType;
import dud.semver : SemVer;
import dud.path : Path;

import dud.sdlang;

PackageDescription sdlToPackageDescription(string sdl) {
	Tag jv = parseSource(sdl);
	return sdlToPackageDescription(jv);
}

PackageDescription sdlToPackageDescription(Tag t) {
	import std.stdio;
	writeln("Attributes");
	foreach(it; t.attributes()) {
		writeln(it);
	}

	writeln("Tags");
	foreach(it; t.tags()) {
		writeln(it);
	}
	return PackageDescription.init;
}
