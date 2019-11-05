module dud.pkgdescription.sdltests;

import std.algorithm.sorting : sort;
import std.array : empty;
import std.conv;
import std.typecons : nullable;
import std.format : format;
import std.stdio;
import std.json;

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
targetPath "outDir" platform="posix"
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
	auto e = Path(
		[ PathPlatform(UnprocessedPath("outDir"), [Platform.posix]) ]);
	assert(pkg.targetPath == e, format("\nexp:\n%s\ngot:\n%s", e,
				pkg.targetPath));

	auto dep =
		[ Dependency("semver")
		, Dependency("sdlang")
		, Dependency("graphqld")
		, Dependency("path")
		];
	dep[0].path = UnprocessedPath("../semver");
	dep[3].path = UnprocessedPath("../path");
	dep[1].path = UnprocessedPath("../sdlang");
	dep[2].version_ = parseVersionSpecifier(">=1.0.0");
	dep[2].default_ = nullable(true);
	dep[2].optional = nullable(false);
	pkg.dependencies.sort!((a,b) => a.name < b.name);
	dep.sort!((a,b) => a.name < b.name);

	assert(pkg.dependencies == dep, format("\ngot:\n%(\t%s\n%)\nexp:\n%(\t%s\n%)",
		pkg.dependencies, dep));

	string output = toSDL(pkg);
	assert(!output.empty);
	PackageDescription pkgReParse = sdlToPackageDescription(output);
	assert(pkg == pkgReParse, format("\nexp:\n%s\ngot:\n%s", pkg, pkgReParse));
	JSONValue j = toJSON(pkg);
	PackageDescription fromJ = jsonToPackageDescription(j);
	fromJ.dependencies.sort!((a,b) => a.name < b.name);
	assert(fromJ == pkg, format("\nexp:\n%s\ngot:\n%s", pkg, fromJ));
}

unittest {
	string input = `
configuration "default"

configuration "testing" {
}
`;

	PackageDescription pkg = sdlToPackageDescription(input);
}


unittest {
	string toParse = `
	subConfiguration "pkg1" "fast"
	subConfiguration "pkg2" "slow"
	subConfiguration "pkg3" "experimental" platform="posix"
	workingDirectory "/root"
	workingDirectory "C:" platform="windows"
`;

	PackageDescription pkg = sdlToPackageDescription(toParse);
	string output = toSDL(pkg);
	PackageDescription pkgReParse = sdlToPackageDescription(output);
	string output2 = toSDL(pkgReParse);
	assert(pkg == pkgReParse, format("\nexp:\n%s\ngot:\n%s", pkg, pkgReParse));
}

unittest {
	string toParse = `
	postBuildCommands "format C:" "install linux" platform="windows"
	postBuildCommands "echo \"You are good\"" platform="linux"
`;

	PackageDescription pkg = sdlToPackageDescription(toParse);
	string output = toSDL(pkg);
	PackageDescription pkgReParse = sdlToPackageDescription(output);
	string output2 = toSDL(pkgReParse);
	assert(pkg == pkgReParse, format("\nexp:\n%s\ngot:\n%s", pkg, pkgReParse));
}

unittest {
	string toParse = `
	buildRequirements "allowWarnings" "disallowDeprecations"
`;

	PackageDescription pkg = sdlToPackageDescription(toParse);
	string output = toSDL(pkg);
	PackageDescription pkgReParse = sdlToPackageDescription(output);
	string output2 = toSDL(pkgReParse);
	assert(pkg == pkgReParse, format("\nexp:\n%s\ngot:\n%s", pkg, pkgReParse));
}

unittest {
	string toParse = `
	buildOptions "verbose"
	buildOptions "debugMode" "coverage" platform="windows"
	buildOptions "debugMode" "inline" "coverage" platform="posix"
`;

	PackageDescription pkg = sdlToPackageDescription(toParse);
	string output = toSDL(pkg);
	PackageDescription pkgReParse = sdlToPackageDescription(output);
	string output2 = toSDL(pkgReParse);
	assert(pkg == pkgReParse, format("\nexp:\n%s\ngot:\n%s", pkg, pkgReParse));
}

unittest {
	string toParse = `
name "describe-dependency-1"
version "~master"
description "A test describe project"
homepage "fake.com"
authors "nobody"
copyright "Copyright © 2015, nobody"
license "BSD 2-clause"
x:ddoxFilterArgs "dfa1" "dfa2"
`;

	PackageDescription pkg = sdlToPackageDescription(toParse);
	string output = toSDL(pkg);
	PackageDescription pkgReParse = sdlToPackageDescription(output);
	string output2 = toSDL(pkgReParse);
	assert(pkg == pkgReParse, format("\nexp:\n%s\ngot:\n%s", pkg, pkgReParse));
}

unittest {
	string toParse = `
subPackage {
	name "sub1"
}
subPackage {
	name "sub2"
	targetType "executable"
}
`;

	PackageDescription pkg = sdlToPackageDescription(toParse);
	string output = toSDL(pkg);
	assert(pkg.subPackages.length == 2, output);
	assert(pkg.subPackages[0].inlinePkg.get().name == "sub1",
			pkg.subPackages[0].inlinePkg.get().name);
	assert(pkg.subPackages[1].inlinePkg.get().name == "sub2",
			pkg.subPackages[1].inlinePkg.get().name);
	PackageDescription pkgReParse = sdlToPackageDescription(output);
	string output2 = toSDL(pkgReParse);
	assert(pkg == pkgReParse, format("\nexp:\n%s\ngot:\n%s", pkg, pkgReParse));
}

unittest {
	string toParse = `
dependency "vibe-d:core" version="*"
dependency "mir-linux-kernel" version="~>1.0.0" platform="linux"
libs "advapi32" platform="windows"
`;

	PackageDescription pkg = sdlToPackageDescription(toParse);
	string output = toSDL(pkg);
	PackageDescription pkgReParse = sdlToPackageDescription(output);
	string output2 = toSDL(pkgReParse);
	assert(pkg == pkgReParse, format("\nexp:\n%s\ngot:\n%s", pkg, pkgReParse));
}

unittest {
	string toParse = `
configuration "libevent" {
	libs "wsock32" "ws2_32" "advapi32" platform="windows"
	sourceFiles "../lib/win-i386/event2.lib" platform="windows-x86"
}
`;

	PackageDescription pkg = sdlToPackageDescription(toParse);
	string output = toSDL(pkg);
	PackageDescription pkgReParse = sdlToPackageDescription(output);
	string output2 = toSDL(pkgReParse);
	assert(pkg == pkgReParse, format("\nexp:\n%s\ngot:\n%s", pkg, pkgReParse));
}

unittest {
	string toParse = `
configuration "windows-mscoff" {
	platforms "windows-x86_mscoff" "windows-x86_64" "windows-x86-ldc"
	sourceFiles "../lib/win-i386-mscoff/libeay32.lib" "../lib/win-i386-mscoff/ssleay32.lib" platform="windows-x86_mscoff"
	sourceFiles "../lib/win-amd64/libeay32.lib" "../lib/win-amd64/ssleay32.lib" platform="windows-x86_64"
}
`;

	PackageDescription pkg = sdlToPackageDescription(toParse);
	string output = toSDL(pkg);
	PackageDescription pkgReParse = sdlToPackageDescription(output);
	string output2 = toSDL(pkgReParse);
	assert(pkg == pkgReParse, format("\nexp:\n%s\ngot:\n%s", pkg, pkgReParse));
}

unittest {
	string toParse = `
x:versionFilters "Daughter" "Parent"
x:debugVersionFilters "dDaughter" "dParent"
`;

	PackageDescription pkg = sdlToPackageDescription(toParse);
	string output = toSDL(pkg);
	PackageDescription pkgReParse = sdlToPackageDescription(output);
	string output2 = toSDL(pkgReParse);
	assert(pkg == pkgReParse, format("\nexp:\n%s\ngot:\n%s", pkg, pkgReParse));
}

unittest {
	string toParse = `
subPackage "../common"
`;

	PackageDescription pkg = sdlToPackageDescription(toParse);
	string output = toSDL(pkg);
	PackageDescription pkgReParse = sdlToPackageDescription(output);
	string output2 = toSDL(pkgReParse);
	assert(pkg == pkgReParse, format("\nexp:\n%s\ngot:\n%s", pkg, pkgReParse));
}

unittest {
	string toParse = `
description "A basic \"Hello, World\" program."
`;

	PackageDescription pkg = sdlToPackageDescription(toParse);
	string output = toSDL(pkg);
	PackageDescription pkgReParse = sdlToPackageDescription(output);
	string output2 = toSDL(pkgReParse);
	assert(pkg == pkgReParse, format("\nexp:\n%s\ngot:\n%s", pkg, pkgReParse));
}
