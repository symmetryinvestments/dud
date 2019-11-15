module dud.pkgdescription.sdltests2;

version(ExcessivSDLTests):

import std.array : empty;
import std.file : readText;
import std.format : format;
import std.stdio;

import dud.pkgdescription.duplicate : ddup = dup;
import dud.pkgdescription.output;
import dud.pkgdescription.sdl;
import dud.pkgdescription.testhelper;
import dud.pkgdescription.validation;
import dud.pkgdescription.exception;
import dud.pkgdescription;
import dud.testdata;

unittest {
	string[] dubs = () @trusted { return allDubSDLFiles(); }();
	size_t[TestFailKind] failCnt;
	foreach(idx, f; dubs) {
		string input = readText(f);
		PackageDescription pkg;
		try {
			pkg = () @safe {
				return sdlToPackageDescription(input);
			}();
		} catch(Exception e) {
			unRollException(e, f);
			incrementFailCnt(failCnt, TestFailKind.fromSDLOrig);
			continue;
		}
		string s = testToSDL(pkg, f, failCnt);
		if(s.empty) {
			continue;
		}

		try {
			PackageDescription nPkg = sdlToPackageDescription(s);
			assert(pkg == nPkg, format("\nexp:\n%s\ngot:\n%s", pkg, nPkg));
		} catch(Exception e) {
			unRollException(e, f);
			incrementFailCnt(failCnt, TestFailKind.fromSDLOrig);
		}

		PackageDescription copy = ddupTest(pkg, f, failCnt);

		assert(pkg == copy, format("%s\nexp:\n%s\ngot:\n%s", f, pkg, copy));
	}
	writefln("num files %s, %s", dubs.length, failCnt);
}
