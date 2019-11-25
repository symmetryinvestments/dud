module dud.testdata.main;

import std.array : empty;
import std.json;
import std.stdio;
import std.getopt;
import std.file : readText;

import dud.descriptiongetter.code;

private struct Options {
	bool getCodeDump;
	string outFilename;
	string inFilename;
}

void main(string[] args) {
	Options options;
	auto helpWanted = getopt(args,
		"g|getCodeDump", "Download the dump from the code.dlang.org api",
		&options.getCodeDump,
		"o|outFilename", "The filename of the output of the trimed dump",
		&options.outFilename,
		"i|inFilename", "In filename to a code.dlang.org dump.json file",
		&options.inFilename
		);

	if(helpWanted.helpWanted) {
		defaultGetoptPrinter("CLI to handle the code.dlang.org api dump",
			helpWanted.options);
		return;
	}

	JSONValue all = !options.inFilename.empty
		? parseJSON(readText(options.inFilename))
		: options.getCodeDump
			? getCodeDlangDump()
			: JSONValue.init;

	if(all.type == JSONType.null_) {
		return;
	}

	JSONValue shorter = trimCodeDlangDump(all);

	if(!options.outFilename.empty) {
		auto f = File(options.outFilename, "w");
		f.writeln(shorter.toPrettyString());
	} else {
		writeln(shorter.toPrettyString());
	}
}
