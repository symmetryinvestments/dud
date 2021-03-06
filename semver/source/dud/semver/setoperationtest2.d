module dud.semver.setoperationtest2;

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
// invert
//

// SemVer
unittest {
	const VersionUnion r = invert(v1);
	assert(r.ranges.length == 2);

	assert(r.ranges[0] ==
			VersionRange(SemVer.min, Inclusive.yes, v1, Inclusive.no));

	assert(r.ranges[1] ==
			VersionRange(v1, Inclusive.no, SemVer.max, Inclusive.yes));
}

// VersionRange
unittest {
	const VersionUnion r = invert(vr1);
	assert(r.ranges.length == 2);
	assert(r.ranges[0] ==
			VersionRange(SemVer.min(), Inclusive.yes, vr1.low.dup,
				cast(Inclusive)!vr1.inclusiveLow));
	assert(r.ranges[1] ==
			VersionRange(vr1.high.dup, cast(Inclusive)!vr1.inclusiveHigh,
				SemVer.max(), Inclusive.yes), format("%s", r.ranges[1]));
}

// VersionUnion
unittest {
	const VersionUnion vu = VersionUnion([vr1, vr3]);
	const VersionUnion r = invert(vu);
	assert(r.ranges.length == 3);
	assert(r.ranges[0] ==
			VersionRange(SemVer.min(), Inclusive.yes, v1, Inclusive.no),
			format("%s", r.ranges[0]));
	assert(r.ranges[1] ==
			VersionRange(v2, Inclusive.no, v3, Inclusive.no),
			format("%s", r.ranges[1]));
	assert(r.ranges[2] ==
			VersionRange(v4, Inclusive.no, SemVer.max(), Inclusive.yes),
			format("%s", r.ranges[2]));
}

unittest {
	const VersionUnion vu = VersionUnion([]);
	const VersionUnion r = invert(vu);
	assert(r.ranges.length == 1);
	assert(r.ranges[0] == VersionRange(SemVer.min(), Inclusive.yes,
				SemVer.max(), Inclusive.yes));
}

//
// differenceOf
//

// SemVer, SemVer
unittest {
	SemVer r = differenceOf(v1, v1);
	assert(r == SemVer.init);

	r = differenceOf(v1, v2);
	assert(r == v1, format("%s", r));
}

// VersionRange, Semver
unittest {
	const VersionUnion d1 = differenceOf(vr4, v2);
	assert(d1.ranges.length == 2, format("%s", d1.ranges.length));
	assert(d1.ranges[0] == VersionRange(v1, Inclusive.yes, v2, Inclusive.no));
	assert(d1.ranges[1] == VersionRange(v2, Inclusive.no, v3, Inclusive.yes));
}

// SemVer, VersionRange
unittest {
	const SemVer d1 = differenceOf(v2, vr4);
	assert(d1 == SemVer.init);
}

unittest {
	const SemVer d1 = differenceOf(v1, vr5);
	assert(d1 == v1);
}

// VersionRange, VersionRange
unittest {
	const VersionUnion d1 = differenceOf(vr4, vr2);
	assert(d1.ranges.length == 1);
	assert(d1.ranges[0] == VersionRange(v1, Inclusive.yes, v2, Inclusive.no));
}

unittest {
	const VersionUnion d1 = differenceOf(vr1, vr3);
	assert(d1.ranges.length == 1);
	assert(d1.ranges[0] == vr1);
}

unittest {
	const VersionUnion d1 = differenceOf(vr1, vr1);
	assert(d1.ranges.length == 0);
}

unittest {
	const VersionUnion d1 = differenceOf(vr2, vr1);
	assert(d1.ranges.length == 1);
	assert(d1.ranges[0] == VersionRange(v2, Inclusive.no, v3, Inclusive.yes));
}

// VersionUnion, VersionRange
unittest {
	const VersionUnion vu1 = VersionUnion([vr1, vr2]);
	const VersionUnion d1 = differenceOf(vu1, vr3);

	assert(d1.ranges.length == 1);
	assert(d1.ranges[0] == VersionRange(v1, Inclusive.yes, v3, Inclusive.no));
}

unittest {
	const VersionUnion vu1 = VersionUnion([vr1, vr2, vr3]);
	const VersionUnion d1 = differenceOf(vu1, vr2);

	assert(d1.ranges.length == 2);
	assert(d1.ranges[0] == VersionRange(v1, Inclusive.yes, v2, Inclusive.no));
	assert(d1.ranges[1] == VersionRange(v3, Inclusive.no, v4, Inclusive.yes));
}

// VersionRange, VersionUnion
unittest {
	const VersionUnion vu1 = VersionUnion([vr1, vr2, vr3]);
	const VersionUnion d1 = differenceOf(vr2, vu1);

	assert(d1.ranges.length == 0);
}

unittest {
	const VersionUnion vu1 = VersionUnion([vr1, vr3]);
	const VersionUnion d1 = differenceOf(vr2, vu1);

	assert(d1.ranges.length == 1);
	assert(d1.ranges[0] == VersionRange(v2, Inclusive.no, v3, Inclusive.no));
}

unittest {
	const VersionUnion vu1 = VersionUnion([vr3]);
	const VersionUnion d1 = differenceOf(vr1, vu1);

	assert(d1.ranges.length == 1);
	assert(d1.ranges[0] == vr1);
}

// VersionUnion, VersionUnion
unittest {
	const VersionUnion vu1 = VersionUnion([vr1, vr2]);
	const VersionUnion vu2 = VersionUnion([vr2, vr3]);
	const VersionUnion d1 = differenceOf(vu1, vu2);

	assert(d1.ranges.length == 1);
	assert(d1.ranges[0] == VersionRange(v1, Inclusive.yes, v2, Inclusive.no));
}

unittest {
	const VersionUnion vu1 = VersionUnion([vr1, vr2]);
	const VersionUnion vu2 = VersionUnion([vr3]);
	const VersionUnion d1 = differenceOf(vu1, vu2);

	assert(d1.ranges.length == 1);
	assert(d1.ranges[0] == VersionRange(v1, Inclusive.yes, v3, Inclusive.no));
}
