module dud.pkgdescription.jsontests2;

version(ExcessivJSONTests):

import std.stdio;
import std.file : readText;
import std.format : format;
import std.json;

import dud.testdata;
import dud.pkgdescription;
import dud.pkgdescription.json;
import dud.pkgdescription.output;

private void unRollException(Exception e, string f) {
	Throwable en = e;
	writefln("%s", f);
	while(en.next !is null) {
		en = en.next;
	}
	writefln("excp %s", en.msg);
}

unittest {
	string[] dubs = () @trusted { return allDubJSONFiles(); }();
	size_t failCnt;
	foreach(idx, f; dubs) {
		string input = readText(f);
		PackageDescription pkg;
		try {
			pkg = () @safe {
				return jsonToPackageDescription(input);
			}();
		} catch(Exception e) {
			unRollException(e, f);
			++failCnt;
			continue;
		}
		JSONValue s;
		try {
			s = toJSON(pkg);
		} catch(Exception e) {
			unRollException(e, f);
			++failCnt;
			continue;
		}

		try {
			PackageDescription nPkg = jsonToPackageDescription(s);
			assert(pkg == nPkg, format("%s\nexp:\n%s\ngot:\n%s", f, pkg, nPkg));
		} catch(Exception e) {
			unRollException(e, f);
			++failCnt;
		}
	}
	writefln("%6u of %6u failed", failCnt, dubs.length);
}
