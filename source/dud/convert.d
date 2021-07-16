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

enum ConvertTargetFormat {
	undefined,
	sdl,
	json
}

@OptionUDA("", "", `
Command specific options
========================

Converts the package description $input.(sdl,json) to $output.$format.

If no $input filename is given the current working directory is searched for
a file with name "dub.json", "dub.sdl", or "package.json".

If no $format is given an error is printed and dud does not perform any
conversion.

If no $output is given the output file name will be derived from $format.

The option $keepInput will prevent dud convert from deleting $input. The
option $keepInput is false by default.

If $output already exists it will not be overwritten. To overwrite an $output
that already exists pass $override to convert.
`)
struct ConvertOptions {
	@OptionUDA("i", "input", "The filename of ")
	string inputFilename;

	@OptionUDA("o", "output", "The output filename")
	string outputFilename;

	@OptionUDA("f", "format", "The format written to the output")
	ConvertTargetFormat outputTargetType;

	@OptionUDA("k", "keepInput", "Keep the input file")
	bool keepInput;

	@OptionUDA("", "override", "Overwrite the output file if it exists")
	bool override_;
}

int convert(CommonOptions common, ConvertOptions options) {
	const string relPath = options.inputFilename.empty
		? dubFileInCWD()
		: options.inputFilename;

	tracef(common.vverbose, "Relative input file name '%s'", relPath);
	const string absNormInputPath = relPath.absolutePath().buildNormalizedPath();
	tracef(common.vverbose, "Absolute normalized input file name '%s'", absNormInputPath);

	if(!exists(absNormInputPath)) {
		writefln("Input '%s' doesn't exists in the filesystem",
			absNormInputPath);
		return 1;
	}

	if(!isFile(absNormInputPath)) {
		writefln("No File '%s' exists in the filesystem", absNormInputPath);
		return 1;
	}

	const string inExt = extension(absNormInputPath);
	tracef(common.vverbose, "Input file extension '%s'", inExt);

	if(inExt != ".json" && inExt != ".sdl") {
		writefln("The file '%s' has an unsupported extension '%s'",
			absNormInputPath, inExt);
		return 0;
	}

	const string outFilename = options.outputFilename.empty
		? buildOutFilename(options.outputTargetType)
		: options.outputFilename;

	tracef(common.vverbose, "Relative output file name '%s'", outFilename);
	const string absNormOutputPath = outFilename.absolutePath()
		.buildNormalizedPath();
	tracef(common.vverbose, "Absolute normalized output file name '%s'", outFilename);

	if(absNormOutputPath.empty
			&& options.outputTargetType == ConvertTargetFormat.undefined)
	{
		writefln("Could determine output file name as target format was "
				~ "undefined");
		return 1;
	}

	if(!options.override_ && exists(absNormOutputPath)) {
		writefln("The given output file '%s' exists and no option were set"
			~ " to override the file", absNormOutputPath);
		return 1;
	}

	const string outExt = extension(absNormOutputPath);
	tracef(common.vverbose, "Output file extension '%s'", outExt);

	if(!extMatchesConvertTargetFormat(outExt, options.outputTargetType)) {
		writefln("The target format '%s' does not match the given output file"
			~ " name '%s'", options.outputTargetType, absNormOutputPath);
		return 1;
	}

	Nullable!PackageDescription nParse = parse(absNormInputPath, inExt, common);
	if(nParse.isNull()) {
		writefln("Failed to parse file '%s'", absNormInputPath);
		return 2;
	}

	PackageDescription nnParse = nParse.get();

	tracef(common.vverbose, "Write output to '%s'", absNormOutputPath);
	const int writeRslt = writeOutput(nnParse, absNormOutputPath, outExt, common);
	if(writeRslt != 0) {
		writefln("Failed to copy the PackageDescription into file '%s'",
			absNormOutputPath);
		return 1;
	}

	if(!options.keepInput) {
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

Nullable!PackageDescription parse(const string absNormPath, const string inExt,
	const ref CommonOptions opts)
{
	const string input = readText(absNormPath);
	Nullable!PackageDescription ret;
	try {
		ret = inExt == ".json"
			? nullable(jsonToPackageDescription(input))
			: nullable(sdlToPackageDescription(input));
	} catch(DudPkgDescriptionException e) {
		() @trusted {
			tracef(opts.vverbose, "%s %s", e.toString(), e.info);
		}();
		printExceptionChain(e);
	}
	return ret;
}

int writeOutput(PackageDescription pkg, const string absOutputFilename,
		const string ext, const ref CommonOptions opts)
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
		() @trusted {
			tracef(opts.vverbose, "%s %s", e.toString(), e.info);
		}();
		printExceptionChain(e);
		return 1;
	}
	return 0;
}

void printExceptionChain(Throwable it) @trusted {
	while(it !is null) {
		writefln(it.msg);
		it = it.next();
	}
}
