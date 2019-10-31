module dud.pkgdescription.sdltests;

import std.array : empty;
import std.conv;
import std.typecons : nullable;
import std.format : format;
import std.stdio;

import dud.pkgdescription;
import dud.pkgdescription.versionspecifier;
import dud.pkgdescription.sdl;
import dud.pkgdescription.output;
import dud.semver : SemVer;

unittest {
	string input = `
name "pkgdescription"
dependency "semver" path="../semver"
dependency "path" path="../path"
dependency "sdlang" path="../sdlang"
dependency "graphqld" version=">=1.0.0" default=true optional=false
targetType "library"
targetPath "outDir"
importPaths "source" "source1" "source2"
license "LGPL3"
version "1.0.0"
configuration "test" {
	platforms "NotWindows"
	libs "libc"
}
`;

	PackageDescription pkg = sdlToPackageDescription(input);
	assert(pkg.name == "pkgdescription", pkg.name);
	assert(pkg.targetType == TargetType.library, to!string(pkg.targetType));
	assert(pkg.importPaths ==
		Paths([PathsPlatform(
			[ UnprocessedPath("source") , UnprocessedPath("source1")
			, UnprocessedPath("source2") ]
			, [ ]
		)])
	, to!string(pkg.importPaths));
	assert(pkg.version_ == SemVer("1.0.0"), pkg.version_.toString);
	assert(pkg.license == "LGPL3", pkg.license);
	assert(pkg.dependencies.length == 4, to!string(pkg.dependencies.length));

	auto dep =
		[ "semver" : Dependency("semver")
		, "sdlang" : Dependency("sdlang")
		, "graphqld" : Dependency("graphqld")
		, "path" : Dependency("path")
		];
	dep["semver"].path = UnprocessedPath("../semver");
	dep["path"].path = UnprocessedPath("../path");
	dep["sdlang"].path = UnprocessedPath("../sdlang");
	dep["graphqld"].version_ = parseVersionSpecifier(">=1.0.0");
	dep["graphqld"].default_ = nullable(true);
	dep["graphqld"].optional = nullable(false);

	assert(pkg.dependencies == dep, format("\ngot:\n%s\nexp:\n%s",
		pkg.dependencies, dep));

	string output = toSDL(pkg);
	writeln(output);
	assert(!output.empty);
	PackageDescription pkgReParse = sdlToPackageDescription(output);
	assert(pkg == pkgReParse, format("\nexp:\n%s\ngot:\n%s", pkg, pkgReParse));
}

unittest {
	string input = `
configuration "default"

configuration "testing" {
}
`;

	PackageDescription pkg = sdlToPackageDescription(input);
}
