module dud.semver2.setoperation;

import std.array : array;
import std.algorithm.iteration : map, filter, joiner;

import dud.semver2.versionunion;
import dud.semver2.versionrange;
import dud.semver2.semver;

import dud.semver2.checks;

@safe pure:

//
// unionOf
//

VersionUnion unionOf(const(SemVer) a, const(SemVer) b) {
	VersionUnion ret = VersionUnion(
			[ VersionRange(a, Inclusive.yes, a, Inclusive.yes)
			, VersionRange(b, Inclusive.yes, b, Inclusive.yes)
			]);
	return ret;
}

VersionUnion unionOf(const(SemVer) a, const(VersionRange) b) {
	return unionOf(b, a);
}

VersionUnion unionOf(const(VersionRange) a, const(SemVer) b) {
	VersionUnion ret = VersionUnion(
			[ a.dup
			, VersionRange(b, Inclusive.yes, b, Inclusive.yes)
			]);
	return ret;
}

VersionUnion unionOf(const(SemVer) a, const(VersionUnion) b) {
	return unionOf(b, a);
}

VersionUnion unionOf(const(VersionUnion) a, const(SemVer) b) {
	VersionUnion ret = a.dup();
	ret.insert(VersionRange(b, Inclusive.yes, b, Inclusive.yes));
	return ret;
}

VersionUnion unionOf(const(VersionRange) a, const(VersionRange) b) {
	VersionUnion ret = VersionUnion([a.dup , b.dup]);
	return ret;
}

VersionUnion unionOf(const(VersionRange) a, const(VersionUnion) b) {
	return unionOf(b, a);
}
VersionUnion unionOf(const(VersionUnion) a, const(VersionRange) b) {
	VersionUnion ret = a.dup();
	ret.insert(b);
	return ret;
}

VersionUnion unionOf(const(VersionUnion) a, const(VersionUnion) b) {
	import std.algorithm.iteration : each;

	VersionUnion ret = a.dup();
	b.ranges.each!(it => ret.insert(it));
	return ret;
}

//
// unionOf
//

SemVer intersectionOf(const(SemVer) a, const(SemVer) b) {
	return a == b ? a.dup : SemVer.init;
}

SemVer intersectionOf(const(VersionRange) a, const(SemVer) b) {
	return allowsAny(a, b) ? b.dup : SemVer.init;
}

SemVer intersectionOf(const(VersionUnion) a, const(SemVer) b) {
	return allowsAny(a, b) ? b.dup : SemVer.init;
}

VersionRange intersectionOf(const(VersionRange) a, const(VersionRange) b) {
	// a: . . ( . . ] . .
	// b: . [ . . ) . . .

	// a: . [ . . ) . . .
	// b: . . ( . . ] . .

	// a: . [ . ] . . . .
	// b: . . . . [ ] . .

	// a: . . . . [ ] . .
	// b: . [ . ] . . . .

	// a: . . [ ] . . . .
	// b: . [ . . ] . . .

	const SemVer low = a.low < b.low ? b.low : a.low;
	const SemVer high = a.high > b.high ? b.high : a.high;

	const Inclusive incLow =
		a.low == b.low && (!a.inclusiveLow || !b.inclusiveLow)
			? Inclusive.no
			: Inclusive.yes;

	const Inclusive incHigh =
		a.high == b.high && (!a.inclusiveHigh || !b.inclusiveHigh)
			? Inclusive.no
			: Inclusive.yes;

	return low <= high
		? VersionRange(low, incLow, high, incHigh)
		: VersionRange.init;
}

VersionUnion intersectionOf(const(VersionUnion) a, const(VersionRange) b) {
	return a.ranges
		.map!(it => intersectionOf(it, b))
		.filter!(it => it != VersionRange.init)
		.array
		.VersionUnion;
}

VersionUnion intersectionOf(const(VersionUnion) a, const(VersionUnion) b) {
	return a.ranges
		.map!(it => b.ranges.map!(jt => intersectionOf(it, jt)))
		.joiner
		.filter!(it => it != VersionRange.init)
		.array
		.VersionUnion;
}
