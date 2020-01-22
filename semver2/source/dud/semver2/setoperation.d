module dud.semver2.setoperation;

import std.array : array;
import std.algorithm.iteration : map, filter, joiner;
import std.exception : enforce;
import std.stdio;

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

	// a: . . . . ( . ] .
	// b: . [ . . ] . . .

	const SemVer low = a.low < b.low ? b.low : a.low;
	const SemVer high = a.high > b.high ? b.high : a.high;

	const Inclusive incLow =
		a.low == b.low && (!a.inclusiveLow || !b.inclusiveLow)
			? Inclusive.no
			: a.low == low ? a.inclusiveLow : b.inclusiveLow;

	const Inclusive incHigh =
		a.high == b.high && (!a.inclusiveHigh || !b.inclusiveHigh)
			? Inclusive.no
			: a.high == high ? a.inclusiveHigh : b.inclusiveHigh;

	return low < high
		? VersionRange(low, incLow, high, incHigh)
		: a.high == b.low && a.inclusiveHigh && b.inclusiveLow
			? VersionRange(a.high, Inclusive.yes, a.high, Inclusive.yes)
			: b.high == a.low && b.inclusiveHigh && a.inclusiveLow
				? VersionRange(b.high, Inclusive.yes, b.high, Inclusive.yes)
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
	import std.range : chain, chunks, only, repeat, take;

	auto zz = chain(
			[ [ VersionRange(SemVer.min(), Inclusive.no, SemVer.min(), Inclusive.no) ]
			, a.ranges.map!(r => r.dup.repeat.take(2)).joiner.array
			, [ VersionRange(SemVer.max(), Inclusive.no, SemVer.max(), Inclusive.yes) ]
			]
		)
		.joiner
		.array
		.chunks(2)
		.map!(c => VersionRange(c[0].high, cast(Inclusive)!c[0].inclusiveHigh,
					c[1].low, cast(Inclusive)!c[1].inclusiveLow))
		.array;

	return VersionUnion(zz);
}

//
// difference
//

SemVer differenceOf(const(SemVer) a, const(SemVer) b) {
	const VersionUnion bInt = invert(b);
	return intersectionOf(a, bInt);
}

VersionUnion differenceOf(const(VersionRange) a, const(SemVer) b) {
	const VersionUnion bInt = invert(b);
	return intersectionOf(a, bInt);
}

SemVer differenceOf(const(SemVer) a, const(VersionRange) b) {
	const VersionUnion bInt = invert(b);
	return intersectionOf(a, bInt);
}

VersionUnion differenceOf(const(VersionRange) a, const(VersionRange) b) {
	const VersionUnion bInt = invert(b);
	auto ret = intersectionOf(a, bInt);
	return ret;
}

VersionUnion differenceOf(const(VersionUnion) a, const(VersionRange) b) {
	const VersionUnion bInt = invert(b);
	auto ret = intersectionOf(a, bInt);
	return ret;
}

VersionUnion differenceOf(const(VersionRange) a, const(VersionUnion) b) {
	const VersionUnion bInt = invert(b);
	auto ret = intersectionOf(a, bInt);
	return ret;
}

VersionUnion differenceOf(const(VersionUnion) a, const(VersionUnion) b) {
	const VersionUnion bInt = invert(b);
	auto ret = intersectionOf(a, bInt);
	return ret;
}
