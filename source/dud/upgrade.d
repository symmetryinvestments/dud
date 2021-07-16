module dud.upgrade;

import std.stdio;

import dud.options;

@safe:

@OptionUDA("", "", `
Command specific options
========================

Determines suitable versions for dependencies and updates the selections.

If no $input filename is given the current working directory is assumed to be
the package root and searched for a file named "dub.json", "dub.sdl", or
"package.json". Otherwise, the directory containing the package description
file is the package root.

If no $output filename is specified, the updated selections are written to
"dub.selections.json" in the project root.
`)
struct UpgradeOptions {
	@OptionUDA("i", "input", "The input filename")
	string inputFilename;

	@OptionUDA("o", "output", "The output filename")
	string outputFilename;
}

int upgrade(CommonOptions common, UpgradeOptions options) {
    return 1;
}