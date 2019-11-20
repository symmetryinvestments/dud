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
configuration "test" {
	platforms "windows"
	libs "libc"
}
`;

	PackageDescription pkg = sdlToPackageDescription(input);
	PackageDescriptionNoPlatform posix = selectPlatform(pkg, [ Platform.posix ]);
	writeln(posix);

	PackageDescriptionNoPlatform win = selectPlatform(pkg, [ Platform.windows ]);
	writeln(win);
}
