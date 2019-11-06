module dud.testdata;

import std.algorithm.iteration : filter, map, each;
import std.algorithm.searching : canFind;
import std.array : array, empty;
import std.format : formattedWrite;
import std.string : split, indexOf;
import std.stdio : File;
import std.file : exists, readText, dirEntries, SpanMode;

enum dubsdlfilename = "../dubsdlfilelist.txt";
enum dubjsonfilename = "../dubjsonfilelist.txt";

immutable string[] knownBad = [
	"dtiled-0.3.0/dtiled"
];

bool isKnownBad(string s) @safe pure {
	return canFind!((string a, string b) => b.indexOf(a) == -1)(knownBad, s);
}

unittest {
	assert( isKnownBad("helloWorlddtiled-3.0/dtiled"));
	assert(!isKnownBad("helloWorlddtiled-0.3.0/dtiled"));
	assert(!isKnownBad("../testpackages/dtiled-0.3.0/dtiled/dub.sdl"));
}

void writeDubSDLFileList(string[] fns) {
	auto f = File(dubsdlfilename, "w");
	auto ltw = f.lockingTextWriter();
	fns
		.filter!(isKnownBad)
		.each!(it => formattedWrite(ltw, "%s\n", it));
}

string[] readDubSDLFileList() {
	return readText(dubsdlfilename)
		.split("\n")
		.filter!(it => !it.empty)
		.filter!(isKnownBad)
		.array;
}

string[] allDubSDLFiles() {
	if(exists(dubsdlfilename)) {
		return readDubSDLFileList();
	}
	string[] dubs = dirEntries("../testpackages/", "dub.sdl", SpanMode.depth)
		.map!(it => it.name)
		.filter!(isKnownBad)
		.array;
	writeDubSDLFileList(dubs);
	return dubs;
}

void writeDubJSONFileList(string[] fns) {
	auto f = File(dubjsonfilename, "w");
	auto ltw = f.lockingTextWriter();
	fns
		.filter!(isKnownBad)
		.each!(it => formattedWrite(ltw, "%s\n", it));
}

string[] readDubJSONFileList() {
	return readText(dubjsonfilename)
		.split("\n")
		.filter!(it => !it.empty)
		.filter!(isKnownBad)
		.array;
}

string[] allDubJSONFiles() {
	if(exists(dubjsonfilename)) {
		return readDubJSONFileList();
	}
	string[] dubs = dirEntries("../testpackages/", "dub.json", SpanMode.depth)
		.map!(it => it.name)
		.filter!(isKnownBad)
		.array;
	writeDubJSONFileList(dubs);
	return dubs;
}
