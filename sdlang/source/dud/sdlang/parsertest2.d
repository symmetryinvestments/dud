module dud.sdlang.parsertest2;

version(ExcessivTests):

import std.algorithm.iteration : map, filter, each;
import std.algorithm.searching : canFind;
import std.array;
import std.file;
import std.stdio;
import std.string : indexOf;
import std.format : formattedWrite;

import dud.sdlang;

enum dubsdlfilename = "dubsdlfilelist.txt";

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

@safe unittest {
	string[] dubs = () @trusted { return allDubSDLFiles(); }();
	size_t failCnt;
	foreach(idx, f; dubs) {
		//writefln("%5u of %5u %s", idx, dubs.length, f);
		string t = readText(f);
		try {
			Lexer l = Lexer(t);
			Parser p = Parser(l);
			Root r = p.parseRoot();
		} catch(Exception e) {
			Throwable en = e;
			++failCnt;
			writefln("%5u of %5u %s", idx, dubs.length, f);
			while(en.next !is null) {
				en = en.next;
			}
			writefln("excp %s", en.msg);
		}
	}
	writefln("%6u of %6u failed", failCnt, dubs.length);
}
