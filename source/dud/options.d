module dud.options;

import std.array : empty;
import std.getopt;
import std.stdio;
import std.traits : FieldNameTuple;

@safe:

struct OptionUDA {
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

OptionReturn!CommandOptions getGenericCommandOptions(CommandOptions)(ref string[] args) {
	CommonOptions common;
	getOptions(common, args);

	CommandOptions command;
	getOptions(command, args);

	return OptionReturn!(CommandOptions)(command, common);
}

@OptionUDA("", "", `
General options that apply to all functions of dud`)
struct CommonOptions {
	@OptionUDA("h", "help", "Display general or command specific help")
	bool help;

	@OptionUDA("v", "verbose", "Print diagnostic output")
	bool verbose;

	@OptionUDA("", "vverbose", "Print debug output")
	bool vverbose;
}
