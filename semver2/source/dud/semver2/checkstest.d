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
immutable VersionRange vr4 = parseVersionRange(">=2.7.0 <=3.0.0").get();
immutable VersionRange vr5 = parseVersionRange(">3.0.0 <=4.0.0").get();

immutable VersionUnion vu1 = VersionUnion([vr1, vr4]);
immutable VersionUnion vu2 = VersionUnion([vr1, vr2]);
immutable VersionUnion vu3 = VersionUnion([vr3, vr4]);
immutable VersionUnion vu4 = VersionUnion([vr2, vr4]);
immutable VersionUnion vu5 = VersionUnion([vr1, vr5]);

immutable SemVer v1 = SemVer(0, 1, 0);
immutable SemVer v2 = SemVer(1, 1, 0);
immutable SemVer v3 = SemVer(2, 1, 0);
immutable SemVer v4 = SemVer(2, 5, 0);

unittest { // VersionUnion, VersionRange
	assert( allows(vu1, vr1));
	assert( allows(vu1, vr2));
	assert( allows(vu1, vr3));
	assert( allows(vu1, vr4));
	assert(!allows(vu1, vr5));

	assert( allows(vu2, vr1));
	assert( allows(vu2, vr2));
	assert( allows(vu2, vr3));
	assert( allows(vu2, vr4));
	assert(!allows(vu2, vr5));

	assert( allows(vu3, vr1));
	assert( allows(vu3, vr2));
	assert( allows(vu3, vr3));
	assert( allows(vu3, vr4));
	assert(!allows(vu3, vr5));

	assert(!allows(vu4, vr1));
	assert( allows(vu4, vr2));
	assert( allows(vu4, vr3));
	assert( allows(vu4, vr4));
	assert(!allows(vu4, vr5));

	assert( allows(vu5, vr1));
	assert(!allows(vu5, vr2));
	assert( allows(vu5, vr3));
	assert(!allows(vu5, vr4));
	assert( allows(vu5, vr5));
}

unittest { // VersionUnion, SemVer
	assert(!allows(vu1, v1));
	assert( allows(vu1, v2));
	assert(!allows(vu1, v3));
	assert(!allows(vu1, v4));

	assert(!allows(vu2, v1));
	assert( allows(vu2, v2));
	assert(!allows(vu2, v3));
	assert( allows(vu2, v4));

	assert(!allows(vu3, v1));
	assert(!allows(vu3, v2));
	assert( allows(vu3, v3));
	assert( allows(vu3, v4));

	assert(!allows(vu4, v1));
	assert(!allows(vu4, v2));
	assert(!allows(vu4, v3));
	assert( allows(vu4, v4));

	assert(!allows(vu5, v1));
	assert( allows(vu5, v2));
	assert(!allows(vu5, v3));
	assert(!allows(vu5, v4));
}

unittest { // VersionRange, VersionUnion
	assert( allows(vr1, vu1));
	assert( allows(vr1, vu2));
	assert( allows(vr1, vu3));
	assert(!allows(vr1, vu4));
	assert( allows(vr1, vu5));

	assert( allows(vr2, vu1));
	assert( allows(vr2, vu2));
	assert( allows(vr2, vu3));
	assert( allows(vr2, vu4));
	assert(!allows(vr2, vu5));

	assert( allows(vr3, vu1));
	assert( allows(vr3, vu2));
	assert( allows(vr3, vu3));
	assert( allows(vr3, vu4));
	assert( allows(vr3, vu5));

	assert( allows(vr4, vu1));
	assert( allows(vr4, vu2));
	assert( allows(vr4, vu3));
	assert( allows(vr4, vu4));
	assert(!allows(vr4, vu5));

	assert(!allows(vr5, vu1));
	assert(!allows(vr5, vu2));
	assert(!allows(vr5, vu3));
	assert(!allows(vr5, vu4));
	assert( allows(vr5, vu5));
}

unittest { // VersionRange, VersionRange
	assert( allows(vr1, vr1));
	assert(!allows(vr1, vr2));
	assert( allows(vr1, vr3));
	assert(!allows(vr1, vr4));
	assert(!allows(vr1, vr5));

	assert(!allows(vr2, vr1));
	assert( allows(vr2, vr2));
	assert( allows(vr2, vr3));
	assert( allows(vr2, vr4));
	assert(!allows(vr2, vr5));

	assert( allows(vr3, vr1));
	assert( allows(vr3, vr2));
	assert( allows(vr3, vr3));
	assert( allows(vr3, vr4));
	assert(!allows(vr3, vr5));

	assert(!allows(vr4, vr1));
	assert( allows(vr4, vr2));
	assert( allows(vr4, vr3));
	assert( allows(vr4, vr4));
	assert(!allows(vr4, vr5));

	assert(!allows(vr5, vr1));
	assert(!allows(vr5, vr2));
	assert(!allows(vr5, vr3));
	assert(!allows(vr5, vr4));
	assert( allows(vr5, vr5));
}

unittest { // VersionRange, SemVer
	assert(!allows(vr1, v1));
	assert( allows(vr1, v2));
	assert(!allows(vr1, v3));
	assert(!allows(vr1, v4));

	assert(!allows(vr2, v1));
	assert(!allows(vr2, v2));
	assert(!allows(vr2, v3));
	assert( allows(vr2, v4));

	assert(!allows(vr3, v1));
	assert(!allows(vr3, v2));
	assert( allows(vr3, v3));
	assert( allows(vr3, v4));

	assert(!allows(vr4, v1));
	assert(!allows(vr4, v2));
	assert(!allows(vr4, v3));
	assert(!allows(vr4, v4));

	assert(!allows(vr5, v1));
	assert(!allows(vr5, v2));
	assert(!allows(vr5, v3));
	assert(!allows(vr5, v4));
}
