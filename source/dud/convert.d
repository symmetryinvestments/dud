module dud.convert;

import std.array : empty, front;
import std.algorithm.iteration : filter;
import std.path;
import std.experimental.logger;
import std.file;
import std.format : format;
import std.stdio;
import std.typecons : nullable, Nullable;

import dud.options;
import dud.pkgdescription;
import dud.pkgdescription.json;
import dud.pkgdescription.sdl;
import dud.pkgdescription.output;
import dud.pkgdescription.exception;

@safe:

int convert(ref string[] args) {
	const OptionReturn!(ConvertOptions) opts = getConvertOptions(args);
	if(args == ["convert"]) {
		writefln("Failed to process cmd options [%(%s, %)]", args);
		return 1;
	}

	if(opts.common.help) {
		() @trusted { writeOptions(stdout.lockingTextWriter(), opts); }();
		return 0;
	}

	const string relPath = opts.options.inputFilename.empty
		? dubFileInCWD()
		: opts.options.inputFilename;

	tracef(opts.common.vverbose, "Relative input file name '%s'", relPath);
	const string absNormInputPath = relPath.absolutePath().buildNormalizedPath();
	tracef(opts.common.vverbose, "Absolute normalized input file name '%s'",
		absNormInputPath);

	if(!exists(absNormInputPath)) {
		writefln("No path '%s' exists in the filesystem", absNormInputPath);
		return 1;
	}

	if(!isFile(absNormInputPath)) {
		writefln("No File '%s' exists in the filesystem", absNormInputPath);
		return 1;
	}

	const string inExt = extension(absNormInputPath);
	tracef(opts.common.vverbose, "Input file extension '%s'", inExt);

	if(inExt != ".json" && inExt != ".sdl") {
		writefln("The file '%s' has an unsupported extension '%s'",
			absNormInputPath, inExt);
		return 0;
	}

	const string outFilename = opts.options.outputFilename.empty
		? buildOutFilename(opts.options.outputTargetType)
		: opts.options.outputFilename;

	tracef(opts.common.vverbose, "Relative output file name '%s'", outFilename);
	const string absNormOutputPath = outFilename.absolutePath()
		.buildNormalizedPath();
	tracef(opts.common.vverbose, "Absolute normalized output file name '%s'",
		outFilename);

	if(!opts.options.override_ && exists(absNormOutputPath)) {
		writefln("The given output file '%s' exists and no option were set"
			~ " to override the file", absNormOutputPath);
		return 1;
	}

	const string outExt = extension(absNormOutputPath);
	tracef(opts.common.vverbose, "Output file extension '%s'", outExt);

	if(!extMatchesConvertTargetFormat(outExt, opts.options.outputTargetType)) {
		writefln("The target format '%s' does not match the given output file"
			~ " name '%s'", opts.options.outputTargetType, absNormOutputPath);
		return 1;
	}

	Nullable!PackageDescription nParse = parse(absNormInputPath, inExt);
	if(nParse.isNull()) {
		writefln("Failed to parse file '%s'", absNormInputPath);
		return 2;
	}

	PackageDescription nnParse = nParse.get();

	int writeRslt = writeOutput(nnParse, absNormOutputPath, outExt);
	if(writeRslt != 0) {
		writefln("Failed to copy the PackageDescription into file '%s'",
			absNormOutputPath);
		return 1;
	}

	if(!opts.options.keepInput) {
		tracef("Removing '%s", absNormInputPath);
		remove(absNormInputPath);
		if(exists(absNormInputPath)) {
			writefln("Failed to remove '%s'", absNormInputPath);
			return 1;
		}
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

string buildOutFilename(const ConvertTargetFormat ctf) {
	const string cwd = getcwd();
	final switch(ctf) {
		case ConvertTargetFormat.json:
			return buildPath(cwd, "dub.json");
		case ConvertTargetFormat.sdl:
			return buildPath(cwd, "dub.sdl");
		case ConvertTargetFormat.undefined:
			return "";
	}
}

bool extMatchesConvertTargetFormat(string ext, const ConvertTargetFormat ctf)
	pure nothrow @nogc
{
	final switch(ctf) {
		case ConvertTargetFormat.json:
			return ext == ".json";
		case ConvertTargetFormat.sdl:
			return ext == ".sdl";
		case ConvertTargetFormat.undefined:
			return true;
	}
}

Nullable!PackageDescription parse(const string absNormPath, const string inExt)
{
	const string input = readText(absNormPath);
	Nullable!PackageDescription ret;
	try {
		ret = inExt == ".json"
			? nullable(jsonToPackageDescription(input))
			: nullable(sdlToPackageDescription(input));
	} catch(DudPkgDescriptionException e) {
		printExceptionChain(e);
	}
	return ret;
}

int writeOutput(PackageDescription pkg, const string absOutputFilename,
		const string ext)
{
	import std.json;
	auto f = File(absOutputFilename, "w");

	try {
		if(ext == ".json") {
			JSONValue tmp = dud.pkgdescription.output.toJSON(pkg);
			f.writeln(tmp.toPrettyString());
		} else {
			toSDL(pkg, f.lockingTextWriter());
		}
	} catch(DudPkgDescriptionException e) {
		printExceptionChain(e);
		return 1;
	}
	return 0;
}

void printExceptionChain(Throwable it) @trusted {
	while(it !is null) {
		writeln(it.toString());
		it = it.next();
	}
}
