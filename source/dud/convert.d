module dud.convert;

import std.array : empty, front;
import std.algorithm.iteration : filter;
import std.path;
import std.experimental.logger;
import std.file;
import std.format : format;
import std.stdio;
import dud.options;

int convert(string[] args) {
	const OptionReturn!(ConvertOptions) opts = getConvertOptions(args);

	if(opts.common.help) {
		writeOptions(stdout.lockingTextWriter(), opts);
		return 0;
	}

	const string relPath = opts.options.inputFilename.empty
		? dubFileInCWD()
		: opts.options.inputFilename;

	tracef(opts.common.vverbose, "Relative input file name '%s'", relPath);
	const string absNormPath = relPath.absolutePath().buildNormalizedPath();
	tracef(opts.common.vverbose, "Absolute normalized input file name '%s'",
		absNormPath);

	if(!exists(absNormPath)) {
		writefln("No path '%s' exists in the filesystem", absNormPath);
		return 1;
	}

	if(!isFile(absNormPath)) {
		writefln("No File '%s' exists in the filesystem", absNormPath);
		return 1;
	}

	return 0;
}

string dubFileInCWD() {
	const string cwd = getcwd();
	const string js = buildPath(cwd, "dub.json");
	const string sdl = buildPath(cwd, "dub.sdl");
	const string pkg = buildPath(cwd, "package.json");

	auto ret = [js, sdl, pkg].filter!(it => exists(it));
	return ret.empty ? "" : ret.front;
}
