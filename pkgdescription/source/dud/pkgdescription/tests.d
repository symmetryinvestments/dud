module dud.pkgdescription.tests;

version(ExcessivTests):

import std.stdio;
import std.file : readText;

import dud.pkgdescription;
import dud.pkgdescription.sdl;
import dud.testdata;
import dud.sdlang;

@safe unittest {
	string[] dubs = () @trusted { return allDubSDLFiles(); }();
	size_t failCnt;
	foreach(idx, f; dubs) {
		//writefln("%5u of %5u %s", idx, dubs.length, f);
		string t = readText(f);
		try {
			PackageDescription pkg = sdlToPackageDescription(t);
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

