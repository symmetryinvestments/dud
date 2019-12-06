module dud.semver2.comparisontest;

@safe pure private:
import std.exception : assertThrown, assertNotThrown;
import std.stdio;
import std.format : format;

import dud.semver2.parse;
import dud.semver2.semver;
import dud.semver2.exception;
import  dud.semver2.comparision;

unittest {
	auto s1 = SemVer(0,0,1);
	auto s2 = SemVer(0,0,2);
	auto s3 = SemVer(0,1,0);
	auto s4 = SemVer(0,1,1);
	auto s5 = SemVer(0,1,2);
	auto s6 = SemVer(1,0,0);
	auto s7 = SemVer(1,0,1);
	auto s8 = SemVer(1,0,2);
	auto s9 = SemVer(1,1,0);
	auto s10 = SemVer(1,1,1);
	auto s11 = SemVer(1,1,2);

	auto all = [ s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11 ];

	foreach(idx, it; all) {
		foreach(jdx, jt; all) {
			int cmp = compare(it, jt);
			if(idx < jdx) {
				assert(cmp == -1, format("%s %s %s", it, cmp, jt));
			} else if(idx == jdx) {
				assert(cmp == 0, format("%s %s %s", it, cmp, jt));
			} else if(idx > jdx) {
				assert(cmp == 1, format("%s %s %s", it, cmp, jt));
			}
		}
	}
}

unittest {
	auto s1 = SemVer(1,0,0,["foo", "bar"], []);
	auto s2 = SemVer(1,0,0,["foo", "bar", "args"], []);

	assert(compare(s1, s1) == 0);
	assert(compare(s2, s2) == 0);
	assert(compare(s1, s2) == -1);
	assert(compare(s2, s1) == 1);
}

unittest {
	auto s1 = SemVer(1,0,0,["12", "34"], []);
	auto s2 = SemVer(1,0,0,["12", "35"], []);

	assert(compare(s1, s1) == 0);
	assert(compare(s2, s2) == 0);
	assert(compare(s1, s2) == -1);
	assert(compare(s2, s1) == 1);
}

unittest {
	auto s1 = SemVer(1,0,0,["12", "foo", "34"], []);
	auto s2 = SemVer(1,0,0,["12", "foo", "35"], []);

	assert(compare(s1, s1) == 0);
	assert(compare(s2, s2) == 0);
	assert(compare(s1, s2) == -1);
	assert(compare(s2, s1) == 1);
}

unittest {
	auto s1 = SemVer(1,0,0,[], []);
	auto s2 = SemVer(1,0,0,["12", "foo", "35"], []);

	assert(compare(s1, s1) == 0);
	assert(compare(s2, s2) == 0);
	assert(compare(s1, s2) == 1);
	assert(compare(s2, s1) == -1);
}

unittest {
	auto s1 = SemVer(1,0,0,["foo", "baz"], []);
	auto s2 = SemVer(1,0,0,["foo", "bar"], []);

	assert(compare(s1, s1) == 0);
	assert(compare(s2, s2) == 0);
	assert(compare(s1, s2) == 1);
	assert(compare(s2, s1) == -1);
}
