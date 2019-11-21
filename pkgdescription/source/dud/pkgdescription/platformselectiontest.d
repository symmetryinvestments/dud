module dud.pkgdescription.platformselectiontest;

import std.stdio;

import dud.pkgdescription;
import dud.pkgdescription.joining;
import dud.pkgdescription.sdl;
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
targetPath "outDir" platform="posix"
importPaths "source" "source1" "source2" platform="windows"
importPaths "source_pos" "source1_pos" "source2" platform="posix"
importPaths "source_pos" "source1_pos" "source2" platform="posix-x86"
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

	PackageDescription pkg = sdlToPackageDescription(input);
	PackageDescriptionNoPlatform posix =
		pkg.expandConfiguration("test-posix").select([Platform.posix]);
	writeln(posix);

	PackageDescriptionNoPlatform win =
		pkg.expandConfiguration("test-win").select([Platform.posix]);
	writeln(win);
}
