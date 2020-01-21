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

__EOF__

// SemVer, SemVer
unittest {
	SemVer r = differenceOf(v1, v1);
	assert(r == v1, format("%s", r));

	r = differenceOf(v1, v2);
	assert(r == SemVer.init);
}

