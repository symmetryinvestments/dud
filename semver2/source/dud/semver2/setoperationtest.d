module dud.semver2.setoperationtest;

@safe pure private:
import std.exception : assertThrown, assertNotThrown;
import std.stdio;
import std.format : format;

import dud.semver2.checks;
import dud.semver2.parse;
import dud.semver2.semver;
import dud.semver2.versionrange;
import dud.semver2.versionunion;
import dud.semver2.setoperation;

import dud.semver2.testdata;

unittest { // SemVer, SemVer
	VersionUnion vu = unionOf(v1, v2);
	assert( allowsAll(vu, v1));
	assert( allowsAll(vu, v2));
	assert(!allowsAll(vu, v3));
	assert(!allowsAll(vu, v4));

	assert(!allowsAll(vu, vr1));
}
