module dud.semver2.versionunion;

import std.algorithm.sorting : sort;
import std.array : empty, front, popFront;
import std.format : format;
import dud.semver2.versionrange;
import dud.semver2.semver;

@safe pure:

struct VersionUnion {
@safe pure:
	VersionRange[] ranges;

	void insert(const(VersionRange) nvu) {
		this.ranges = merge(this.ranges, nvu);
	}
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

package VersionRange[] merge(const(VersionRange)[] old,
		const(VersionRange) nvu)
{
	VersionRange[] ret;
	if(old.empty) {
		return [ nvu.dup() ];
	}

	ret ~= nvu.dup;

	foreach(it; old) {
		VersionRange top = ret.front();
		ret.popFront();

		VersionRange m = merge(top, it);
		if(m == VersionRange.init) {
			ret ~= top;
			ret ~= it.dup();
		} else {
			ret ~= m;
		}
	}

	ret.sort();

	return ret;
}
