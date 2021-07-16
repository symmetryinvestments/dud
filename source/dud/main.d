module dud.main;

import std.array : empty, front;
import std.algorithm.searching : countUntil;
import std.stdio;

@safe:

private int genericCommand(string command, CommandOptions, alias action)(ref string[] args)
{
	import dud.options : OptionReturn, getGenericCommandOptions, writeOptions;
	OptionReturn!CommandOptions opts = getGenericCommandOptions!CommandOptions(args);

	if(args == [command]) {
		writefln!"Failed to process cmd options [%(%s, %)]"(args);
		return 1;
	}

	if(opts.common.help) {
		() @trusted { writeOptions(stdout.lockingTextWriter(), opts); }();
		return 0;
	}

	return action(opts.common, opts.options);
}

int main(string[] args) {
	const ptrdiff_t doubleSlash = args.countUntil("--");
	string[] noUserOptions = doubleSlash == -1 ? args : args[0 .. doubleSlash];

	if(noUserOptions.length == 1) {
		return 0;
	}

	switch(noUserOptions[1]) {
		case "convert":
			import dud.convert : ConvertOptions, convert;
			return genericCommand!("convert", ConvertOptions, convert)(args);
		case "upgrade":
			import dud.upgrade : UpgradeOptions, upgrade;
			return genericCommand!("upgrade", UpgradeOptions, upgrade)(args);
		default:
			writefln("Operation '%s' is not supported", noUserOptions[1]);
			return 1;
	}
}
