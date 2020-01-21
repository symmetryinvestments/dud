module dud.semver2.setoperationtest1;

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

//
// intersectionOf
//

// SemVer, SemVer
unittest {
	SemVer r = intersectionOf(v1, v1);
	assert(r == v1);

	r = intersectionOf(v1, v2);
	assert(r == SemVer.init);
}

// VersionRange, SemVer
unittest {
	SemVer r = intersectionOf(vr1, v1);
	assert(r == v1);

	r = intersectionOf(vr1, v3);
	assert(r == SemVer.init);

	assert(intersectionOf(v3, vr1) == r);
}

// VersionUnion, SemVer
unittest {
	const vu = VersionUnion([vr1, vr2]);
	SemVer r = intersectionOf(vu, v1);
	assert(r == v1);
	assert(r == intersectionOf(v1, vu));

	r = intersectionOf(vu, v4);
	assert(r == SemVer.init);

}

// VersionRange, VersionRange
unittest {
	const VersionRange r = intersectionOf(vr4, vr5);
	assert(r == vr2);
}

unittest {
	const vr6 = VersionRange(v2, Inclusive.no, v5, Inclusive.yes);
	const VersionRange r = intersectionOf(vr5, vr6);
	assert(r == vr6);
}

unittest {
	const vr6 = VersionRange(v2, Inclusive.yes, v5, Inclusive.no);
	const VersionRange r = intersectionOf(vr5, vr6);
	assert(r == vr6);
}

unittest {
	const VersionRange r = intersectionOf(vr1, vr2);
	assert(r != VersionRange.init);
	assert( allowsAll(r, v2));
	assert(!allowsAll(r, v1));
	assert(!allowsAll(r, v3));

	const VersionRange r2 = intersectionOf(vr2, vr1);
	assert(r != VersionRange.init);
	assert( allowsAll(r, v2));
	assert(!allowsAll(r, v1));
	assert(!allowsAll(r, v3));
	assert(r == r2);
}

unittest {
	const VersionRange r = intersectionOf(vr1, vr3);
	assert(r == VersionRange.init);
}

unittest {
	const VersionRange a = parseVersionRange(">=1.0.0 <2.0.0");
	const VersionRange b = parseVersionRange(">=1.0.0 <=3.0.0");
	const VersionRange c = intersectionOf(a, b);
	const VersionRange r = parseVersionRange(">=1.0.0 <2.0.0");
	assert(c == r, format("%s", c));
}

// VersionUnion, VersionRange
unittest {
	const v6 = SemVer(2,5,0);
	const v7 = SemVer(4,5,0);

	const vr6 = VersionRange(v6, Inclusive.yes, v7, Inclusive.yes);
	const vr7 = VersionRange(v4, Inclusive.yes, v5, Inclusive.yes);

	const vu = VersionUnion([vr1, vr2, vr7]);
	const r = intersectionOf(vu, vr6);

	assert(r.ranges.length == 2, format("\n%s", r));
	assert(r.ranges[0] == VersionRange(v6, Inclusive.yes, v3, Inclusive.yes));
	assert(r.ranges[1] == VersionRange(v4, Inclusive.yes, v7, Inclusive.yes));

	assert(r == intersectionOf(vr6, vu));
}

unittest {
	const VersionRange a = parseVersionRange(">=1.0.0 <2.0.0");
	const VersionRange b = parseVersionRange(">2.0.0 <=3.0.0");

	const VersionUnion ab = VersionUnion([a, b]);
	assert(ab.ranges.length == 2);
	assert(ab.ranges[0] == a);
	assert(ab.ranges[1] == b);

	const VersionRange c = parseVersionRange(">=1.0.0 <=3.0.0");
	const VersionUnion abc = intersectionOf(ab, c);
	assert(abc.ranges.length == 2, format("%s", abc.ranges.length));
	assert(ab.ranges[0] == a);
	assert(ab.ranges[1] == b);
}

// VersionUnion, VersionUnion
unittest {
	const vu1 = VersionUnion([vr1, vr3]);
	assert(vu1.ranges.length == 2);
	const vu2 = VersionUnion([vr2]);

	const r = intersectionOf(vu1, vu2);
	assert(r.ranges.length == 2);
	assert(r.ranges[0] == VersionRange(v2, Inclusive.yes, v2, Inclusive.yes));
	assert(r.ranges[1] == VersionRange(v3, Inclusive.yes, v3, Inclusive.yes));
}
