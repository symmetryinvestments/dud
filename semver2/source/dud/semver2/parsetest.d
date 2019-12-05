module dud.semver2.parsetest;

@safe private:
import std.exception : assertThrown, assertNotThrown;
import std.stdio;
import std.format : format;

import dud.semver2.parse;
import dud.semver2.semver;

struct StrSV {
	string str;
	SemVer sv;
}

unittest {
	StrSV[] tests = [
		StrSV("0.0.4", SemVer(0,0,4)),
		StrSV("1.2.3", SemVer(1,2,3)),
		StrSV("10.20.30", SemVer(10,20,30)),
		StrSV("1.1.2-prerelease+meta", SemVer(1,1,2,["prerelease"], ["meta"])),
		StrSV("1.1.2+meta", SemVer(1,1,2,[],["meta"])),
		StrSV("1.0.0-alpha", SemVer(1,0,0,["alpha"],[])),
		StrSV("1.0.0-beta", SemVer(1,0,0,["beta"],[])),
		StrSV("1.0.0-alpha.beta", SemVer(1,0,0,["alpha", "beta"],[])),
		StrSV("1.0.0-alpha.beta.1", SemVer(1,0,0,["alpha", "beta", "1"],[])),
		StrSV("1.0.0-alpha.1", SemVer(1,0,0,["alpha", "1"],[])),
		StrSV("1.0.0-alpha0.valid", SemVer(1,0,0,["alpha0", "valid"],[])),
		StrSV("1.0.0-alpha.0valid", SemVer(1,0,0,["alpha", "0valid"],[])),
		StrSV("1.0.0-alpha-a.b-c-somethinglong+build.1-aef.1-its-okay",
				SemVer(1,0,0,["alpha-a", "b-c-somethinglong"],
					["build","1-aef","1-its-okay"])),
		StrSV("1.0.0-rc.1+build.1", SemVer(1,0,0,["rc", "1"],["build","1"])),
		StrSV("2.0.0-rc.1+build.123", SemVer(2,0,0,["rc", "1"],["build", "123"])),
		StrSV("1.2.3-beta", SemVer(1,2,3,["beta"],[])),
		StrSV("10.2.3-DEV-SNAPSHOT", SemVer(10,2,3,["DEV-SNAPSHOT"],[])),
		StrSV("1.2.3-SNAPSHOT-123", SemVer(1,2,3,["SNAPSHOT-123"],[])),
		StrSV("1.0.0", SemVer(1,0,0,[],[])),
		StrSV("2.0.0", SemVer(2,0,0,[],[])),
		StrSV("1.1.7", SemVer(1,1,7,[],[])),
		StrSV("2.0.0+build.1848", SemVer(2,0,0,[],["build","1848"])),
		StrSV("2.0.1-alpha.1227", SemVer(2,0,1,["alpha", "1227"],[])),
		StrSV("1.0.0-alpha+beta", SemVer(1,0,0,["alpha"],["beta"])),
		StrSV("1.0.0-0A.is.legal", SemVer(1,0,0,["0A", "is", "legal"],[])),
		StrSV("1.1.2+meta-valid", SemVer(1,1,2, [], ["meta-valid"]))
	];

	foreach(test; tests) {
		SemVer sv = assertNotThrown(parseSemVer(test.str),
			format("An exception was thrown while parsing '%s'", test.str));
		assert(sv == test.sv, format("\ngot: %s\nexp: %s", sv, test.sv));
	}
}
