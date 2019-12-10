module dud.semver2.versionunion;

import std.format : format;
import dud.semver2.versionrange;
import dud.semver2.semver;

@safe pure:

struct VersionUnion {
@safe pure:
	VersionRange[] ranges;

	/*void insert(VersionRange vr) {
		const SetRelation sr = relation
	}*/
}

VersionRange merge(const(VersionRange) a, const(VersionRange) b) {
	if(a.high == b.low && a.inclusiveHigh && b.inclusiveLow) {
		return VersionRange(a.low, a.inclusiveLow, b.high, b.inclusiveHigh);
	} else if(a.low == b.high && a.inclusiveLow && b.inclusiveHigh) {
		return VersionRange(b.low, b.inclusiveLow, a.high, a.inclusiveHigh);
	} if(a.low < b.high && a.low > b.low) {
		return VersionRange(b.low, b.inclusiveLow, a.high, a.inclusiveHigh);
	} else if(b.low < a.high && b.low > a.low) {
		return VersionRange(a.low, a.inclusiveLow, b.high, b.inclusiveHigh);
	}
	return VersionRange(SemVer.init, Inclusive.no, SemVer.init, Inclusive.no);
}
