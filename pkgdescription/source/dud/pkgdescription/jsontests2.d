module dud.pkgdescription.jsontests2;

version(ExcessivJSONTests):

import std.stdio;
import std.file : readText;
import std.format : format;
import std.json;

import dud.pkgdescription.duplicate : ddup = dup;
import dud.pkgdescription.json;
import dud.pkgdescription.output;
import dud.pkgdescription.testhelper;
import dud.pkgdescription.validation;
import dud.pkgdescription.exception;
import dud.pkgdescription;
import dud.testdata;

unittest {
	string[] dubs = () @trusted { return allDubJSONFiles(); }();
	size_t[TestFailKind] failCnt;
	foreach(idx, f; dubs) {
		string input = readText(f);
		PackageDescription pkg;
		try {
			pkg = () @safe {
				return jsonToPackageDescription(input);
			}();
		} catch(Exception e) {
			unRollException(e, f);
			incrementFailCnt(failCnt, TestFailKind.fromJsonOrig);
			continue;
		}
		JSONValue s = testToJson(pkg, f, failCnt);
		if(s == JSONValue.init) {
			incrementFailCnt(failCnt, TestFailKind.toJson);
			continue;
		}

		if(!fromJsonTest(s, pkg, f, failCnt)) {
			continue;
		}

		PackageDescription copy = ddupTest(pkg, f, failCnt);

		assert(pkg == copy, format("%s\nexp:\n%s\ngot:\n%s", f, pkg, copy));
	}
	writefln("num files %s, %s", dubs.length, failCnt);
}
