module dud.sdlang.parsertest2;

version(ExcessiveTestsSDLang):
import std.algorithm.iteration : map, filter, each;
import std.algorithm.searching : canFind;
import std.array;
import std.file;
import std.stdio;
import std.string : indexOf;
import std.format : formattedWrite;

import dud.sdlang;
import dud.testdata;

void main() {
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
