module dud.sdlang.parsertest2;

version(ExcessivTests):

import std.algorithm.iteration : map;
import std.array;
import std.file;
import std.stdio;
import std.format : formattedWrite;

import dud.sdlang;

enum dubsdlfilename = "dubsdlfilelist.txt";

void writeDubSDLFileList(string[] fns) {
	auto f = File(dubsdlfilename, "w");
	auto ltw = f.lockingTextWriter();
	foreach(fn; fns) {
		formattedWrite(ltw, "%s\n", fn);
	}
}

string[] readDubSDLFileList() {
	return readText(dubsdlfilename).split("\n");
}

string[] allDubSDLFiles() {
	if(exists(dubsdlfilename)) {
		return readDubSDLFileList();
	}
	string[] dubs = dirEntries("../testpackages/", "dub.sdl", SpanMode.depth)
		.map!(it => it.name)
		.array;
	writeDubSDLFileList(dubs);
	return dubs;
}

@safe unittest {
	string[] dubs = () @trusted { return allDubSDLFiles(); }();
	foreach(f; dubs) {
		string t = readText(f);
		try {
			Lexer l = Lexer(t);
			Parser p = Parser(l);
			Root r = p.parseRoot();
		} catch(Exception e) {
			writefln("file %s", f);
			writefln("excp %s", e.msg);
		}
	}
}
