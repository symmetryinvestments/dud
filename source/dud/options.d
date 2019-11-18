module dud.options;

import std.array : empty;
import std.getopt;
import std.stdio;
import std.traits : FieldNameTuple;

@safe:

private struct OptionUDA {
	string s;
	string l;
	string documentation;
	string type;
}

private template buildSelector(alias thing) {
	enum attr = __traits(getAttributes, thing);
	static if(attr.length == 1) {
		alias First = attr[0];
		alias FirstType = typeof(First);
		static if(is(FirstType == OptionUDA)) {

			static assert(First.s.length == 1 || First.s.length == 0);
			static assert(First.l.length > 1 || First.l.length == 0);

			static if(First.s.length > 0 && First.l.length > 0) {
				enum buildSelector = First.s ~ "|" ~ First.l;
			} else static if(First.s.length == 0 && First.l.length > 0) {
				enum buildSelector = First.l;
			} else static if(First.s.length > 0 && First.l.length == 0) {
				enum buildSelector = First.s;
			} else {
				enum buildSelector = "";
			}
		}
	} else {
		enum buildSelector = "";
	}
}

private template optionUDASelector(alias thing) {
	enum attr = __traits(getAttributes, thing);
	static if(attr.length == 1) {
		alias First = attr[0];
		alias FirstType = typeof(First);
		static if(is(FirstType == OptionUDA)) {
			enum optionUDASelector = First;
		} else {
			enum optionUDASelector = OptionUDA.init;
		}
	} else {
		enum optionUDASelector = OptionUDA.init;
	}
}

private OptionUDA[] allOptions(T)() {
	OptionUDA[] ret;
	static foreach(mem; FieldNameTuple!T) {{
		OptionUDA tmp = optionUDASelector!(__traits(getMember, T, mem));
		if(tmp != OptionUDA.init) {
			tmp.type = typeof(__traits(getMember, T, mem)).stringof;
			ret ~= tmp;
		}
	}}
	return ret;
}

struct OptionReturn(Option) {
	const Option options;
	const CommonOptions common;
}

void getOptions(T)(ref T t, ref string[] args) {
	static foreach(mem; FieldNameTuple!T) {
		getopt(args, config.passThrough,
			buildSelector!(__traits(getMember, T, mem)),
			&__traits(getMember, t, mem));
	}
}

void writeOption(Out, Ops)(auto ref Out output, const ref Ops option) {
	import std.algorithm.searching : maxElement;
	import std.algorithm.iteration : map, each;
	import std.format : formattedWrite;

	enum opsDoc = optionUDASelector!Ops;
	writeln(opsDoc.documentation);

	enum OptionUDA[] ops = allOptions!(Ops)();
	const size_t sMax = ops.map!(it => it.s.length).maxElement + "-".length;
	const size_t lMax = ops.map!(it => it.l.length).maxElement + "--".length;
	const size_t tMax = ops.map!(it => it.type.length).maxElement;

	ops.each!(op =>
		formattedWrite(output, "%*s %*s %*s: %s\n",
			sMax, (op.s.empty ? "" : "-" ~ op.s),
			lMax, (op.l.empty ? "" : "--" ~ op.l),
			tMax, op.type,
			op.documentation)
	);
}

void writeOptions(Out, Ops)(auto ref Out output,
		const ref OptionReturn!Ops options)
{
	writeOption(output, options.options);
	writeOption(output, options.common);
}

OptionReturn!ConvertOptions getConvertOptions(ref string[] args) {
	CommonOptions common;
	getOptions(common, args);

	ConvertOptions conv;
	getOptions(conv, args);

	return OptionReturn!(ConvertOptions)(conv, common);
}

enum ConvertTargetFormat {
	undefined,
	sdl,
	json
}

@OptionUDA("", "", `
Command specific options
========================

dud convert to convert $input.(sdl,json) to $output.$format files.

If no $input filename is given the current working directory is search
for a file with name "dub.json", "dub.sdl", or "package.json".

If no $output is given the output file name will be derived from $format.
If also no $format is given an error is printed.

The option $keepInput will prevent dud convert from deleting $input.
The option $keepInput is false by default.

dud will not override $output if it exists.
To override a file with name $output pass $override to convert.
`)
struct ConvertOptions {
	@OptionUDA("i", "input", "The filename of the dub file to convert")
	string inputFilename;

	@OptionUDA("o", "output", "The filename of the output")
	string outputFilename;

	@OptionUDA("f", "format", "The type to convert to")
	ConvertTargetFormat outputTargetType;

	@OptionUDA("k", "keepInput", "Keep the input file")
	bool keepInput;

	@OptionUDA("", "override", "Override output file if exists")
	bool override_;
}

@OptionUDA("", "", `
Common Options
==============

General options that apply to all functions of dud`)
struct CommonOptions {
	@OptionUDA("h", "help", "Display general or command specific help")
	bool help;

	@OptionUDA("v", "verbose", "Print diagnostic output")
	bool verbose;

	@OptionUDA("", "vverbose", "Print debug output")
	bool vverbose;
}
