module dud.pkgdescription.platformselectiontest;

import std.stdio;

import dud.pkgdescription;
import dud.pkgdescription.sdl;
import dud.pkgdescription.platformselection;

unittest {
	string input = `
name "pkgdescription"
dependency "semver" path="../semver"
dependency "path" path="../path" platform="windows"
dependency "sdlang" path="../sdlang"
dependency "graphqld" version=">=1.0.0" default=true optional=false
targetType "library"
targetPath "outDir" platform="posix"
importPaths "source" "source1" "source2"
license "LGPL3"
version "1.0.0"
configuration "test" {
	platforms "windows"
	libs "libc"
}
`;

	PackageDescription pkg = sdlToPackageDescription(input);
	PackageDescriptionNoPlatform np = selectPlatform(pkg, [ Platform.posix ]);

	writeln(np);
}
