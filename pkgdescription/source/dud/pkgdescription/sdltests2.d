module dud.pkgdescription.sdltests2;

version(ExcessivTests):

import std.stdio;
import std.file : readText;

import dud.testdata;
import dud.pkgdescription;
import dud.pkgdescription.sdl;

@safe unittest {
	string[] dubs = () @trusted { return allDubSDLFiles(); }();
	size_t failCnt;
	foreach(idx, f; dubs) {
		string input = readText(f);
		writeln(f);
		try {
			PackageDescription pkg = sdlToPackageDescription(input);
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
