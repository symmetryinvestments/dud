module dud.pkgdescription.platformselectiontest;

import std.stdio;
import std.range : tee;
import std.format;

import dud.pkgdescription;
import dud.pkgdescription.joining;
import dud.pkgdescription.sdl;
import dud.pkgdescription.output;
import dud.pkgdescription.platformselection;

unittest {
	string input = `
name "pkgdescription"
dependency "semver" path="../semver"
dependency "semver" path="../semver" version=">=1.0.0" platform="posix"
dependency "semver" path="../semver" version=">=2.0.0" platform="android"
dependency "path" path="../path" platform="windows"
dependency "sdlang" path="../sdlang"
dependency "graphqld" version=">=1.0.0" default=true optional=false
targetType "library"
targetName "foobar" platform="posix"
targetName "barfoo" platform="windows"
targetName "should_be_foobar_or_barfoo"
preGenerateCommands "rm -rf /" "install windows" platform="posix"
preGenerateCommands "format C:" "install linux" platform="windows"
targetPath "outDir"
importPaths "source_win" "source1_win" "source2_win" platform="windows"
importPaths "source_pos86" "source1_pos86" "source2_pos86" platform="posix-x86"
importPaths "source_pos" "source1_pos" "source2_pos" platform="posix"
buildRequirements "allowWarnings" "disallowInlining" platform="windows"
buildRequirements "allowWarnings" platform="posix"
subConfiguration "semver" "subConf_posix" platform="posix"
subConfiguration "semver" "subConf_windows" platform="windows"
subConfiguration "graphql" "the_fast_version"
license "LGPL3"
version "1.0.0"
configuration "test-win" {
	platforms "windows"
	libs "libc"
}
configuration "test-posix" {
	platforms "posix"
	libs "glibc"
}
`;

	string inputPosixExp = `
name "pkgdescription"
dependency "semver" path="../semver" version=">=1.0.0"
dependency "sdlang" path="../sdlang"
dependency "graphqld" version=">=1.0.0" default=true optional=false
targetType "library"
targetName "foobar"
preGenerateCommands "rm -rf /" "install windows"
targetPath "outDir"
importPaths "source_pos" "source1_pos" "source2_pos"
buildRequirements "allowWarnings"
subConfiguration "semver" "subConf_posix"
subConfiguration "graphql" "the_fast_version"
license "LGPL3"
version "1.0.0"
libs "glibc"
`;

	PackageDescription pkg = sdlToPackageDescription(input);
	PackageDescription afterExpands = pkg.expandConfiguration("test-posix");
	PackageDescriptionNoPlatform posix = afterExpands.select([Platform.posix]);
	writeln(afterExpands);

	PackageDescription posixExp = sdlToPackageDescription(inputPosixExp);
	PackageDescriptionNoPlatform posixExpNP = posixExp
			.select([]);

	assert(posix == posixExpNP,
		format("\ngot:\n%s\nexp:\n%s", posix, posixExpNP));
	//string output = toSDL(pkg);
	//writeln(output);

	//PackageDescriptionNoPlatform win = pkg
	//	.expandConfiguration("test-win")
	//	.select([Platform.windows]);
	//writeln(win);
}
