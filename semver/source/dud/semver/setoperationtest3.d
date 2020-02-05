module dud.semver.setoperationtest3;

@safe pure private:
import std.exception : assertThrown, assertNotThrown;
import std.stdio;
import std.format : format;

import dud.semver.checks;
import dud.semver.parse;
import dud.semver.semver;
import dud.semver.versionrange;
import dud.semver.versionunion;
import dud.semver.setoperation;

unittest {
	immutable SemVer v1 = SemVer(1,1,1);
	immutable SemVer v2 = SemVer(2,2,2);
	immutable SemVer v3 = SemVer(3,3,3);
	immutable SemVer v4 = SemVer(4,4,4);
	immutable VersionRange a = VersionRange(v1, Inclusive.yes, v2, Inclusive.yes);
	immutable VersionRange b = VersionRange(v3, Inclusive.yes, v4, Inclusive.yes);
	immutable VersionRange c = VersionRange(v2, Inclusive.yes, v3, Inclusive.yes);

	assert(intersectionOf(a, invert(a)).ranges.length == 0);
	assert(intersectionOf(a, a) == a);
	assert(intersectionOf(a, b) != a);
	assert(intersectionOf(a, b) != b);
	assert(intersectionOf(b, a) != a);
	assert(intersectionOf(b, a) != b);
	assert(intersectionOf(invert(a), invert(a)) == invert(a));
	assert(invert(intersectionOf(a, invert(b))) == invert(intersectionOf(a,a)));

	auto add(T, P)(T a, P b) {
		return invert(intersectionOf(invert(a), invert(b)));
	}
	auto remove(T, P)(T a, P b) {
		return intersectionOf(a, invert(b));
	}

	assert(add(a,b) == add(b,a));

	assert(invert(invert(a)) == add(intersectionOf(a,c), remove(a,c)));
	assert(differenceOf(a, a).ranges.length == 0);
	assert(invert(intersectionOf(invert(a), invert(a))) == invert(invert(a)));
	assert(invert(invert(differenceOf(a, invert(a)))) == invert(invert(a)));
	assert(invert(invert(intersectionOf(a, c))) ==
			invert(invert(remove(a, remove(a, c)))));
}
