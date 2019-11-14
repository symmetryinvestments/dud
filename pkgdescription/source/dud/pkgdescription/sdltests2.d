module dud.pkgdescription.sdltests2;

version(ExcessivSDLTests):

import std.stdio;
import std.file : readText;
import std.format : format;

import dud.testdata;
import dud.pkgdescription;
import dud.pkgdescription.sdl;
import dud.pkgdescription.output;
import dud.pkgdescription.testhelper;
import dud.pkgdescription.duplicate : ddup = dup;

unittest {
	string[] dubs = () @trusted { return allDubSDLFiles(); }();
	size_t failCnt;
	foreach(idx, f; dubs) {
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

		PackageDescription copy = ddup(pkg);
		assert(pkg == copy, format("%s\nexp:\n%s\ngot:\n%s", f, pkg, copy));
	}
	writefln("%6u of %6u failed", failCnt, dubs.length);
}
