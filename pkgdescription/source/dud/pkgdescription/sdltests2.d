module dud.pkgdescription.sdltests2;

version(ExcessivTests):

import std.stdio;
import std.file : readText;
import std.format : format;

import dud.testdata;
import dud.pkgdescription;
import dud.pkgdescription.sdl;
import dud.pkgdescription.output;

void unRollException(Exception e, string f) {
	Throwable en = e;
	writefln("%s", f);
	while(en.next !is null) {
		en = en.next;
	}
	writefln("excp %s", en.msg);
}

unittest {
	string[] dubs = () @trusted { return allDubSDLFiles(); }();
	size_t failCnt;
	foreach(idx, f; dubs) {
		writeln(f);
		string input = readText(f);
		PackageDescription pkg;
		try {
			pkg = () @safe {
				return sdlToPackageDescription(input);
			}();
		} catch(Exception e) {
			unRollException(e, f);
			++failCnt;
			continue;
		}
		string s;
		try {
			s = toSDL(pkg);
		} catch(Exception e) {
			unRollException(e, f);
			++failCnt;
			continue;
		}

		try {
			PackageDescription nPkg = sdlToPackageDescription(s);
			assert(pkg == nPkg, format("\nexp:\n%s\ngot:\n%s", pkg, nPkg));
		} catch(Exception e) {
			unRollException(e, f);
			++failCnt;
		}
	}
	writefln("%6u of %6u failed", failCnt, dubs.length);
}
