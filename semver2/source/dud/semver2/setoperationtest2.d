module dud.semver2.setoperationtest2;

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

immutable SemVer v1 = SemVer(1,0,0);
immutable SemVer v2 = SemVer(2,0,0);
immutable SemVer v3 = SemVer(3,0,0);
immutable SemVer v4 = SemVer(4,0,0);
immutable SemVer v5 = SemVer(5,0,0);

immutable VersionRange vr1 = VersionRange(v1, Inclusive.yes, v2, Inclusive.yes);
immutable VersionRange vr2 = VersionRange(v2, Inclusive.yes, v3, Inclusive.yes);
immutable VersionRange vr3 = VersionRange(v3, Inclusive.yes, v4, Inclusive.yes);
immutable VersionRange vr4 = VersionRange(v1, Inclusive.yes, v3, Inclusive.yes);
immutable VersionRange vr5 = VersionRange(v2, Inclusive.yes, v5, Inclusive.yes);

// SemVer, SemVer
unittest {
	SemVer r = intersectionOf(v1, v1);
	assert(r == v1);

	r = intersectionOf(v1, v2);
	assert(r == SemVer.init);
}

