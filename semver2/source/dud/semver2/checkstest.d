module dud.semver2.checktest;

@safe pure private:
import std.exception : assertThrown, assertNotThrown;
import std.stdio;
import std.format : format;

import dud.semver2.checks;
import dud.semver2.parse;
import dud.semver2.semver;
import dud.semver2.versionrange;
import dud.semver2.versionunion;
import dud.semver2.exception;

immutable VersionRange vr1 = parseVersionRange(">=1.0.0 <=2.0.0").get();
immutable VersionRange vr2 = parseVersionRange(">=2.5.0 <=3.0.0").get();
immutable VersionRange vr3 = parseVersionRange(">=1.5.0 <=3.0.0").get();
immutable SemVer v1 = SemVer(0, 1, 0);
immutable SemVer v2 = SemVer(1, 1, 0);
immutable SemVer v3 = SemVer(2, 1, 0);
immutable SemVer v4 = SemVer(2, 5, 0);

unittest { // VersionRange, SemVer
	assert(!allows(vr1, v1));
	assert( allows(vr1, v2));
	assert(!allows(vr1, v3));
	assert(!allows(vr1, v4));

	assert(!allows(vr2, v1));
	assert(!allows(vr2, v2));
	assert(!allows(vr2, v3));
	assert( allows(vr2, v4));
}

unittest { // VersionRange, VersionRange
	assert( allows(vr1, vr1));
	assert(!allows(vr1, vr2));
	assert( allows(vr1, vr3));

	assert(!allows(vr2, vr1));
	assert( allows(vr2, vr2));
	assert( allows(vr2, vr3));

	assert( allows(vr3, vr1));
	assert( allows(vr3, vr2));
	assert( allows(vr3, vr3));
}
