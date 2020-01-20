module dud.semver2.setoperation;

import std.array : array;
import std.algorithm.iteration : map, filter, joiner;
import std.exception : enforce;

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
// intersectionOf
//

SemVer intersectionOf(const(SemVer) a, const(SemVer) b) {
	return a == b ? a.dup : SemVer.init;
}

SemVer intersectionOf(const(VersionRange) a, const(SemVer) b) {
	return allowsAny(a, b) ? b.dup : SemVer.init;
}

SemVer intersectionOf(const(SemVer) a, const(VersionRange) b) {
	return intersectionOf(b, a);
}

SemVer intersectionOf(const(VersionUnion) a, const(SemVer) b) {
	return allowsAny(a, b) ? b.dup : SemVer.init;
}

SemVer intersectionOf(const(SemVer) a, const(VersionUnion) b) {
	return intersectionOf(b, a);
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

VersionUnion intersectionOf(const(VersionRange) a, const(VersionUnion) b) {
	return intersectionOf(b, a);
}

VersionUnion intersectionOf(const(VersionUnion) a, const(VersionUnion) b) {
	return a.ranges
		.map!(it => b.ranges.map!(jt => intersectionOf(it, jt)))
		.joiner
		.filter!(it => it != VersionRange.init)
		.array
		.VersionUnion;
}

//
// invert
//

VersionUnion invert(const(SemVer) a) {
	enforce(a != SemVer.init);
	return VersionUnion(
		[ VersionRange(SemVer.min, Inclusive.yes, a.dup, Inclusive.no)
		, VersionRange(a.dup, Inclusive.no, SemVer.max, Inclusive.yes)
		]);
}

VersionUnion invert(const(VersionRange) a) {
	enforce(a.low != SemVer.init);
	return VersionUnion(
		[ VersionRange(SemVer.init, Inclusive.yes, a.low.dup, cast(Inclusive)!a.inclusiveLow)
		, VersionRange(a.high.dup, cast(Inclusive)!a.inclusiveHigh, SemVer.max, Inclusive.yes)
		]);
}

VersionUnion invert(const(VersionUnion) a) {
	//return a.ranges.map!(it => invert(it).ranges).joiner.array.VersionUnion;
	VersionRange[] tmp;
	foreach(idx; 0 .. a.ranges.length) {
		const SemVer low = idx == 0
			? SemVer.min
			: a.ranges[idx].high;
		const Inclusive lowInc = idx == 0
			? Inclusive.yes
			: cast(Inclusive)!a.ranges[idx].inclusiveHigh;

		const SemVer high = (idx + 1 == a.ranges.length)
			? SemVer.max()
			: a.ranges[idx + 1].low;
		const Inclusive highInc = (idx + 1 == a.ranges.length)
			? Inclusive.yes
			: cast(Inclusive)!a.ranges[idx + 1].inclusiveLow;

		auto t = VersionRange(low, lowInc, high, highInc);
		import std.stdio;
		debug writeln(t);
		tmp ~= t;
	}

	return VersionUnion(tmp);
}

//
// difference
//

SemVer differenceOf(const(SemVer) a, const(SemVer) b) {
	const VersionUnion bInt = invert(b);
	return intersectionOf(a, bInt);
}
