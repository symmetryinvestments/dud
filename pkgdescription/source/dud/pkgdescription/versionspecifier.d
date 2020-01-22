module dud.pkgdescription.versionspecifier;

__EOF__

import std.array : empty;
import std.exception : enforce;
import std.format : format;
import std.stdio;
import std.typecons : nullable, Nullable;

import dud.semver;
import dud.semver.operations;

@safe:

enum Inclusive : bool {
	no = false,
	yes = true
}

struct VersionSpecifier {
@safe pure:
	string orig;
	Inclusive inclusiveLow;
	Inclusive inclusiveHigh;
	SemVer low;
	SemVer high;

	this(string input) pure {
		Nullable!VersionSpecifier s = parseVersionRange(input);
		enforce(!s.isNull());
		VersionSpecifier snn = s.get();
		this = snn;
	}

	this(SemVer low, Inclusive incLow, SemVer high, Inclusive incHigh) {
		enforce(low <= high, format("low %s must be lower equal to high %s",
			low, high));
		this.low = low;
		this.inclusiveLow = incLow;
		this.high = high;
		this.inclusiveHigh = incHigh;
	}

	bool opEquals(const VersionSpecifier o) const pure @safe {
		return o.inclusiveLow == this.inclusiveLow
			&& o.inclusiveHigh == this.inclusiveHigh
			&& o.low == this.low
			&& o.high == this.high;
	}

	/// ditto
	int opCmp(const VersionSpecifier o) const pure @safe {
		if(this.inclusiveLow != o.inclusiveLow) {
			return this.inclusiveLow < o.inclusiveLow ? -1 : 1;
		}

		if(this.inclusiveHigh != o.inclusiveHigh) {
			return this.inclusiveHigh < o.inclusiveHigh ? -1 : 1;
		}

		if(this.low != o.low) {
			return this.low < o.low ? -1 : 1;
		}

		if(this.high != o.high) {
			return this.high < o.high ? -1 : 1;
		}

		return 0;
	}

	/// ditto
	size_t toHash() const nothrow @trusted @nogc {
		size_t hash = 0;
		hash = this.inclusiveLow.hashOf(hash);
		hash = this.low.toString().hashOf(hash);
		hash = this.inclusiveHigh.hashOf(hash);
		hash = this.high.toString().hashOf(hash);
		return hash;
	}
}

pure unittest {
	VersionSpecifier s = VersionSpecifier("1.0.0");
	assert(s == s);
	assert(s.toHash() != 0);
}

/** Sets/gets the matching version range as a specification string.

	The acceptable forms for this string are as follows:

	$(UL
		$(LI `"1.0.0"` - a single version in SemVer format)
		$(LI `"==1.0.0"` - alternative single version notation)
		$(LI `">1.0.0"` - version range with a single bound)
		$(LI `">1.0.0 <2.0.0"` - version range with two bounds)
		$(LI `"~>1.0.0"` - a fuzzy version range)
		$(LI `"~>1.0"` - a fuzzy version range with partial version)
		$(LI `"^1.0.0"` - semver compatible version range (same version if 0.x.y, ==major >=minor.patch if x.y.z))
		$(LI `"^1.0"` - same as ^1.0.0)
		$(LI `"~master"` - a branch name)
		$(LI `"*" - match any version (see also `any`))
	)

	Apart from "$(LT)" and "$(GT)", "$(GT)=" and "$(LT)=" are also valid
	comparators.
*/
Nullable!VersionSpecifier parseVersionSpecifier(string ves) pure {
	static import std.string;
	import std.algorithm.searching : startsWith;
	import std.format : format;

	enforce(ves.length > 0, "Can not process empty version specifier");
	string orig = ves;

	VersionSpecifier ret;
	ret.orig = orig;

	if(orig.empty) {
		return Nullable!(VersionSpecifier).init;
	}

	ves = ves == "*"
		// Any version is good.
		? ves = ">=0.0.0"
		: ves;

	if (ves.startsWith("~>")) {
		// Shortcut: "~>x.y.z" variant. Last non-zero number will indicate
		// the base for this so something like this: ">=x.y.z <x.(y+1).z"
		ret.inclusiveLow = Inclusive.yes;
		ret.inclusiveHigh = Inclusive.no;
		ves = ves[2..$];
		ret.low = SemVer(expandVersion(ves));
		ret.high = SemVer(bumpVersion(ves) ~ "-0");
	} else if (ves.startsWith("^")) {
		// Shortcut: "^x.y.z" variant. "Semver compatible" - no breaking changes.
		// if 0.x.y, ==0.x.y
		// if x.y.z, >=x.y.z <(x+1).0.0-0
		// ^x.y is equivalent to ^x.y.0.
		ret.inclusiveLow = Inclusive.yes;
		ret.inclusiveHigh = Inclusive.no;
		ves = ves[1..$].expandVersion;
		ret.low = SemVer(ves);
		ret.high = SemVer(bumpIncompatibleVersion(ves) ~ "-0");
	} else if (ves[0] == SemVer.BranchPrefix) {
		ret.inclusiveLow = Inclusive.yes;
		ret.inclusiveHigh = Inclusive.yes;
		ret.low = ret.high = SemVer(ves);
	} else if (std.string.indexOf("><=", ves[0]) == -1) {
		ret.inclusiveLow = Inclusive.yes;
		ret.inclusiveHigh = Inclusive.yes;
		ret.low = ret.high = SemVer(ves);
	} else {
		auto cmpa = skipComp(ves);
		size_t idx2 = std.string.indexOf(ves, " ");
		if (idx2 == -1) {
			if (cmpa == "<=" || cmpa == "<") {
				ret.low = SemVer.MinRelease;
				ret.inclusiveLow = Inclusive.yes;
				ret.high = SemVer(ves);
				ret.inclusiveHigh = cast(Inclusive)(cmpa == "<=");
			} else if (cmpa == ">=" || cmpa == ">") {
				ret.low = SemVer(ves);
				ret.inclusiveLow = cast(Inclusive)(cmpa == ">=");
				ret.high = SemVer.MaxRelease;
				ret.inclusiveHigh = Inclusive.yes;
			} else {
				// Converts "==" to ">=a&&<=a", which makes merging easier
				ret.low = ret.high = SemVer(ves);
				ret.inclusiveLow = ret.inclusiveHigh = Inclusive.yes;
			}
		} else {
			enforce(cmpa == ">" || cmpa == ">=",
				"First comparison operator expected to be either > or >=, not "
				~ cmpa);
			assert(ves[idx2] == ' ');
			ret.low = SemVer(ves[0..idx2]);
			ret.inclusiveLow = cast(Inclusive)(cmpa == ">=");
			string v2 = ves[idx2+1..$];
			auto cmpb = skipComp(v2);
			enforce(cmpb == "<" || cmpb == "<=",
				"Second comparison operator expected to be either < or <=, not "
				~ cmpb);
			ret.high = SemVer(v2);
			ret.inclusiveHigh = cast(Inclusive)(cmpb == "<=");

			enforce(!ret.low.isBranch && !ret.high.isBranch,
				format("Cannot compare branches: %s", ves));
			enforce(ret.low <= ret.high,
				"First version must not be greater than the second one.");
		}
	}

	return nullable(ret);
}

private string skipComp(ref string c) pure {
	import std.ascii : isDigit;
	size_t idx = 0;
	while(idx < c.length && !isDigit(c[idx]) && c[idx] != SemVer.BranchPrefix) {
		idx++;
	}
	enforce(idx < c.length, "Expected version number in version spec: "~c);
	string cmp = idx == c.length - 1 || idx == 0 ? ">=" : c[0..idx];
	c = c[idx..$];

	switch(cmp) {
		default:
			enforce(false, "No/Unknown comparison specified: '"~cmp~"'");
			return ">=";
		case ">=": goto case; case ">": goto case;
		case "<=": goto case; case "<": goto case;
		case "==": return cmp;
	}
}

pure unittest {
	string tt = ">=1.0.0";
	auto v = parseVersionSpecifier(tt);
}

bool isInRange(const(VersionSpecifier) range, const(SemVer) v) pure {
	enforce(!v.isBranch(), format("isInRange v must not be a branch '%s'",
		v.toString()));

	const int low = compareVersions(v.toString(), range.low.toString());
	const int high = compareVersions(range.high.toString(), v.toString());

	if(low < 0 || (low == 0 && !range.inclusiveLow)) {
		return false;
	}

	if(high < 0 || (high == 0 && !range.inclusiveHigh)) {
		return false;
	}

	return true;
}

pure unittest {
	VersionSpecifier r1 = parseVersionSpecifier("^1.0.0").get();
	SemVer v1 = SemVer("1.0.0");
	SemVer v2 = SemVer("2.0.0");
	SemVer v3 = SemVer("2.0.1");
	SemVer v4 = SemVer("0.999.999");
	SemVer v5 = SemVer("1.999.999");
	SemVer v6 = SemVer("89.0.1");

	assert( isInRange(r1, v1));
	assert(!isInRange(r1, v2));
	assert(!isInRange(r1, v3));
	assert(!isInRange(r1, v4));
	assert( isInRange(r1, v5));
	assert(!isInRange(r1, v6));
}

pure unittest {
	VersionSpecifier r1 = parseVersionSpecifier("*").get();
	SemVer v1 = SemVer("1.0.0");
	SemVer v2 = SemVer("2.0.0");
	SemVer v3 = SemVer("2.0.1");
	SemVer v4 = SemVer("0.999.999");
	SemVer v5 = SemVer("1.999.999");
	SemVer v6 = SemVer("89.0.1");

	assert( isInRange(r1, v1));
	assert( isInRange(r1, v2));
	assert( isInRange(r1, v3));
	assert( isInRange(r1, v4));
	assert( isInRange(r1, v5));
	assert( isInRange(r1, v6));
}

pure unittest {
	VersionSpecifier r1 = parseVersionSpecifier("~master").get();
	SemVer v1 = SemVer("1.0.0");
	SemVer v2 = SemVer("2.0.0");
	SemVer v3 = SemVer("2.0.1");
	SemVer v4 = SemVer("0.999.999");
	SemVer v5 = SemVer("1.999.999");
	SemVer v6 = SemVer("89.0.1");

	assert(!isInRange(r1, v1));
	assert(!isInRange(r1, v2));
	assert(!isInRange(r1, v3));
	assert(!isInRange(r1, v4));
	assert(!isInRange(r1, v5));
	assert(!isInRange(r1, v6));
}

///
enum BoundRelation {
	less,
	equal,
	unequal,
	more
}

/** Return whether a is less than, equal, or greater than b
*/
BoundRelation relation(const(SemVer) a, const Inclusive aInclusive,
		const(SemVer) b, const Inclusive bInclusive) pure
{
	import dud.semver.operations : compareVersions;
	const int cmp = compareVersions(a, b);
	if(cmp < 0) {
		return BoundRelation.less;
	} else if(cmp > 0) {
		return BoundRelation.more;
	} else if(cmp == 0 && aInclusive == Inclusive.yes
			&& aInclusive == bInclusive)
	{
		return BoundRelation.equal;
	} else if(cmp == 0 && aInclusive == Inclusive.no
			&& aInclusive == bInclusive)
	{
		return BoundRelation.unequal;
	} else if(cmp == 0 && aInclusive == Inclusive.no
			&& bInclusive == Inclusive.yes)
	{
		return BoundRelation.unequal;
	} else if(cmp == 0 && aInclusive == Inclusive.yes
			&& bInclusive == Inclusive.no)
	{
		return BoundRelation.unequal;
	}
	assert(false, format(
		"invalid state a '%s', aInclusive '%s', b '%s', bInclusive '%s'",
		a, aInclusive, b, bInclusive));
}

unittest {
	SemVer a = SemVer("1.0.0");

	BoundRelation aa = relation(a, Inclusive.yes, a, Inclusive.yes);
	assert(aa == BoundRelation.equal, format("%s", aa));

	aa = relation(a, Inclusive.yes, a, Inclusive.no);
	assert(aa == BoundRelation.unequal, format("%s", aa));

	aa = relation(a, Inclusive.no, a, Inclusive.yes);
	assert(aa == BoundRelation.unequal, format("%s", aa));

	aa = relation(a, Inclusive.yes, a, Inclusive.yes);
	assert(aa == BoundRelation.equal, format("%s", aa));
}

unittest {
	SemVer a = SemVer("1.0.0");
	SemVer b = SemVer("2.0.0");

	BoundRelation ab = relation(a, Inclusive.yes, b, Inclusive.yes);
	assert(ab == BoundRelation.less, format("%s", ab));

	ab = relation(a, Inclusive.no, b, Inclusive.yes);
	assert(ab == BoundRelation.less, format("%s", ab));

	ab = relation(a, Inclusive.yes, b, Inclusive.no);
	assert(ab == BoundRelation.less, format("%s", ab));

	ab = relation(a, Inclusive.no, b, Inclusive.no);
	assert(ab == BoundRelation.less, format("%s", ab));

	ab = relation(a, Inclusive.no, b, Inclusive.no);
	assert(ab == BoundRelation.less, format("%s", ab));

	ab = relation(a, Inclusive.no, b, Inclusive.no);
	assert(ab == BoundRelation.less, format("%s", ab));

	ab = relation(b, Inclusive.yes, a, Inclusive.yes);
	assert(ab == BoundRelation.more, format("%s", ab));

	ab = relation(b, Inclusive.no, a, Inclusive.yes);
	assert(ab == BoundRelation.more, format("%s", ab));

	ab = relation(b, Inclusive.no, a, Inclusive.no);
	assert(ab == BoundRelation.more, format("%s", ab));

	ab = relation(b, Inclusive.yes, a, Inclusive.no);
	assert(ab == BoundRelation.more, format("%s", ab));
}

pure unittest {
	SemVer[] sv = [SemVer("1.0.0"), SemVer("2.0.0"), SemVer("3.0.0")];
	Inclusive[] b = [Inclusive.yes, Inclusive.no];

	BoundRelation[] brs = [ BoundRelation.more, BoundRelation.less,
		BoundRelation.equal];

	relation(sv[0], Inclusive.yes, sv[0], Inclusive.no);
	foreach(sa; sv) {
		foreach(sb; sv) {
			foreach(ba; b) {
				foreach(bb; b) {
					foreach(br; brs) {
						foreach(bl; brs) {
							relation(sa, ba, sb, bb);
						}
					}
				}
			}
		}
	}
}

enum SetRelation {
	/// The second set contains all elements of the first, as well as possibly
	/// more.
	subset,

	/// Neither set contains any elements of the other.
	disjoint,

	/// The sets have elements in common, but the first is not a superset of the
	/// second.
	///
	/// This is also used when the first set is a superset of the first, but in
	/// practice we don't need to distinguish that from overlapping sets.
	overlapping
}

SetRelation relation(const(VersionSpecifier) a, const(VersionSpecifier) b)
		pure
{
	const BoundRelation lowLow = relation(
			a.low, a.inclusiveLow,
			b.low, b.inclusiveLow);
	const BoundRelation lowHigh = relation(
			a.low, a.inclusiveLow,
			b.high, b.inclusiveHigh);
	const BoundRelation highHigh = relation(
			a.high, a.inclusiveHigh,
			b.high, b.inclusiveHigh);
	const BoundRelation highLow = relation(
			a.high, a.inclusiveHigh,
			b.low, b.inclusiveLow);

	//debug writefln(
	//	"\na: %s\nb: %s\n\tlowLow %s\n\tlowHigh %s\n\thighLow %s\n\thighHigh %s",
	//	a, b, lowLow, lowHigh, highLow, highHigh);


	// a: | . | . . . . . . . .
	// b: . . . | . . . | . . .

	// a: | . . ) . . . . . . .
	// b: . . . | . . . | . . .

	// a: | . . | . . . . . . .
	// b: . . . ( . . . | . . .
	if(highLow == BoundRelation.less
			|| (highLow == BoundRelation.unequal
				&& (!a.inclusiveHigh || !b.inclusiveLow)))
	{
		return SetRelation.disjoint;
	}

	// a: . . . . . . . . | . |
	// b: . . . | . . . | . . .

	// a: . . . . . . . ( . . |
	// b: . . . | . . . | . . .

	// a: . . . . . . . | . . |
	// b: . . . | . . . ) . . .
	if(lowHigh == BoundRelation.more
			|| (lowHigh == BoundRelation.unequal
				&& (!a.inclusiveLow || !b.inclusiveHigh)))
	{
		return SetRelation.disjoint;
	}

	// a: . . . | . . . | . . .
	// b: . . . | . . . | . . .

	// a: . . . | . . . | . . .
	// b: . . . [ . . . ] . . .

	// a: . . . . | . | . . . .
	// b: . . . | . . . | . . .
	if(((lowLow == BoundRelation.equal)
			|| (lowLow == BoundRelation.more)
			|| (lowLow == BoundRelation.unequal && b.inclusiveLow)
			|| (lowLow == BoundRelation.unequal
				&& a.inclusiveLow == b.inclusiveLow)
		)
		&&
		((highHigh == BoundRelation.equal)
			|| (highHigh == BoundRelation.less)
			|| (highHigh == BoundRelation.unequal && b.inclusiveHigh)
			|| (highHigh == BoundRelation.unequal
				&& a.inclusiveHigh == b.inclusiveHigh)
		)
	)
	{
		return SetRelation.subset;
	}

	// a: . | . | . . . . . . .
	// b: . . . | . . . | . . .

	// a: . . . . . . . | . | .
	// b: . . . | . . . | . . .
	if(lowHigh == BoundRelation.equal
			|| highLow == BoundRelation.equal)
	{
		return SetRelation.overlapping;
	}

	// a: . . . . . . | . . | .
	// b: . . . | . . . | . . .

	// a: . . . | . . . . . | .
	// b: . . . | . . . | . . .
	if((lowLow == BoundRelation.more || lowLow == BoundRelation.equal)
			&& lowHigh == BoundRelation.less
			&& ((highHigh == BoundRelation.more)
				|| (highHigh == BoundRelation.unequal
					&& a.inclusiveHigh
					&& !b.inclusiveHigh)
				)
		)
	{
		return SetRelation.overlapping;
	}

	// a: . . . | . . . | . . .
	// b: . . . . . . | . . | .

	// a: . . . | . . . . . | .
	// b: . . . . . . | . . | .

	// a: . . . [ . . . . . | .
	// b: . . . ( . . . . . | .
	if(highLow == BoundRelation.more
			&& (highHigh == BoundRelation.less
				|| highHigh == BoundRelation.equal)
			&& ((lowLow == BoundRelation.less)
				|| (lowLow == BoundRelation.unequal
					&& a.inclusiveLow
					&& !b.inclusiveLow))
		)
	{
		return SetRelation.overlapping;
	}

	if(lowLow == BoundRelation.less && highLow != BoundRelation.less) {
		return SetRelation.overlapping;
	}

	if(highHigh == BoundRelation.more && lowHigh != BoundRelation.more) {
		return SetRelation.overlapping;
	}

	// a: . . | . . . | . . . .
	// b: . . | . . . | . . . .

	if(lowLow == BoundRelation.unequal && a.inclusiveLow && !b.inclusiveLow
		&& (highHigh == BoundRelation.unequal
			|| highHigh == BoundRelation.more
			)
	)
	{
		return SetRelation.overlapping;
	}

	if((lowLow == BoundRelation.unequal && highHigh == BoundRelation.unequal)
			&& ((a.inclusiveLow && !b.inclusiveLow)
				|| (a.inclusiveHigh && !b.inclusiveHigh)))
	{
		return SetRelation.overlapping;
	}

	assert(false, format(
		"\na:%s\nb:%s\nlowLow:%s\nlowHigh:%s\nhighLow:%s\nhighHigh:%s", a, b,
		lowLow, lowHigh, highLow, highHigh));
}

unittest {
	void test(const SemVer lowA, const Inclusive lowAIn, const SemVer highA,
			const Inclusive highAIn, const SemVer lowB, const Inclusive lowBIn,
			const SemVer highB, const Inclusive highBIn,
			const SetRelation br)
	{
		auto v1 = VersionSpecifier(lowA, lowAIn, highA, highAIn);
		auto v2 = VersionSpecifier(lowB, lowBIn, highB, highBIn);

		auto b = relation(v1, v2);
		assert(b == br, format(
			"\nexp: %s\ngot: %s\na: %s\nb: %s", br, b, v1, v2));
	}

	const i = Inclusive.yes;
	const o = Inclusive.no;

	auto a = SemVer("0.0.0");
	auto b = SemVer("1.0.0");
	auto c = SemVer("2.0.0");
	auto d = SemVer("3.0.0");
	auto e = SemVer("4.0.0");

	// a: [ . ] . . . . . . . .
	// b: . . . [ . . . ] . . .

	test(a, i, b, i, c, i, e, i, SetRelation.disjoint);

	// a: [ . ) . . . . . . . .
	// b: . . [ . . . . ] . . .
	test(a, i, b, o, b, i, e, i, SetRelation.disjoint);
	// a: . . . . . . . . [ . ]
	// b: . . . [ . . . ] . . .

	test(e, i, e, i, b, i, c, i, SetRelation.disjoint);

	// a: . . . . . . . . [ . ]
	// b: . . . [ . . . . ) . .
	test(d, i, e, i, b, i, d, o, SetRelation.disjoint);
	// a: . . . ( . . . . ) . .
	// b: . . . [ . . . . ] . .
	test(b, o, e, o, b, i, e, i, SetRelation.subset);

	// a: . . . [ . . . . ) . .
	// b: . . . [ . . . . ] . .
	test(b, i, e, o, b, i, e, i, SetRelation.subset);

	// a: . . . [ . . . . ] . .
	// b: . . . [ . . . . ] . .
	test(b, i, e, i, b, i, e, i, SetRelation.subset);

	// a: . . . ( . . . . ] . .
	// b: . . . [ . . . . ] . .
	test(b, o, e, i, b, i, e, i, SetRelation.subset);

	// a: . . . ( . . . . ] . .
	// b: . . . ( . . . . ] . .
	test(b, o, e, i, b, o, e, i, SetRelation.subset);

	// a: . . . ( . . . . ) . .
	// b: . . . ( . . . . ) . .
	test(b, o, e, o, b, o, e, o, SetRelation.subset);

	// a: . . . . | . . . | . .
	// b: . . . | . . . . | . .
	test(c, o, e, o, b, o, e, o, SetRelation.subset);

	// a: . . . . | . . | . . .
	// b: . . . | . . . . | . .
	test(c, o, d, o, b, o, e, o, SetRelation.subset);

	// a: . . . | . . . | . . .
	// b: . . . | . . . . | . .
	test(b, o, d, o, b, o, e, o, SetRelation.subset);
	test(b, o, d, o, b, i, e, i, SetRelation.subset);

	// a: [ . ] . . . . . . . .
	// b: . . [ . . . . ] . . .
	test(a, i, b, i, b, i, e, i, SetRelation.overlapping);

	// a: . . . . . . . . [ . ]
	// b: . . . [ . . . . ] . .
	test(d, i, e, i, b, i, d, i, SetRelation.overlapping);

	// a: . . . . . . . | . . |
	// b: . . . [ . . . . ] . .
	test(c, i, e, i, b, i, d, i, SetRelation.overlapping);

	// a: . | . . . . . | . . .
	// b: . . . [ . . . . ] . .
	test(a, i, c, i, b, i, d, i, SetRelation.overlapping);

	// a: . | . . . . . . | . .
	// b: . . . | . . . . | . .
	test(a, i, d, i, b, i, d, i, SetRelation.overlapping);

	// a: . . . | . . . . . | .
	// b: . . . | . . . . | . .
	test(b, i, e, i, b, i, d, i, SetRelation.overlapping);

	// a: . . [ . . . . . . ] .
	// b: . . . [ . . . . ] . .
	test(a, i, e, i, b, i, d, i, SetRelation.overlapping);

	// a: . . . [ . . . . ] . .
	// b: . . . [ . . . . ) . .
	test(b, i, c, i, b, i, c, o, SetRelation.overlapping);

	// a: . . . [ . . . . ] . .
	// b: . . . ( . . . . ] . .
	test(b, i, c, i, b, o, c, i, SetRelation.overlapping);

	// a: . . . [ . . . . ] . .
	// b: . . . ( . . . . ) . .
	test(b, i, c, i, b, o, c, i, SetRelation.overlapping);

	// a: . . . ( . . . . ] . .
	// b: . . . [ . . . . ) . .
	test(b, i, c, o, b, o, c, i, SetRelation.overlapping);

	// a: . . . [ . . . . ] . .
	// b: . . . ( . . . . ) . .
	test(b, i, c, i, b, o, c, o, SetRelation.overlapping);

	// a: . . . [ . . . . ) . .
	// b: . . . ( . . . . ) . .
	test(b, i, c, o, b, o, c, o, SetRelation.overlapping);

	// a: . . . [ . . . . ] . .
	// b: . . . ( . . . ] . . .
	test(b, i, d, i, b, o, c, i, SetRelation.overlapping);

	// a: . . . [ . . . . ) . .
	// b: . . . . ( . . . ] . .
	test(b, i, d, o, c, i, d, i, SetRelation.overlapping);

	// a: . . . ( . . . . ] . .
	// b: . . . [ . . . . ) . .
	test(b, o, d, i, b, i, d, o, SetRelation.overlapping);
}

unittest {
	auto a = SemVer("0.0.0");
	auto b = SemVer("1.0.0");
	auto c = SemVer("2.0.0");

	auto v1 = VersionSpecifier(b, Inclusive.yes, c, Inclusive.no);
	auto v2 = VersionSpecifier(a, Inclusive.yes, b, Inclusive.no);

	SetRelation sr = relation(v1, v2);
	assert(sr == SetRelation.disjoint, format("%s", sr));
}

unittest {
	SemVer[] sv =
		[ SemVer("1.0.0"), SemVer("2.0.0"), SemVer("3.0.0")
		, SemVer("4.0.0"), SemVer("5.0.0")
		];

	Inclusive[] inclusive  = [Inclusive.yes, Inclusive.no];

	VersionSpecifier[] vers;
	foreach(idx, low; sv[0 .. $ - 1]) {
		foreach(lowIn; inclusive) {
			foreach(high; sv[idx + 1 .. $]) {
				foreach(highIn; inclusive) {
					VersionSpecifier tmp;
					tmp.inclusiveLow = lowIn;
					tmp.low = low;
					tmp.inclusiveHigh = highIn;
					tmp.high = high;
					vers ~= tmp;
				}
			}
		}
	}

	//debug writefln("%(%s\n%)", vers);
	foreach(adx, verA; vers) {
		foreach(bdx, verB; vers) {
			auto rel = relation(verA, verB);
			//writefln("a: %s, b: %s, rel %s", verA, verB, rel);
			/*
			auto reporter = () {
				return format("\na: %s, b: %s, rel %s", verA, verB, rel);
			};
			if(adx == bdx) {
				assert(rel == SetRelation.subset, reporter());
			} else if(verA.high < verB.low) {
				assert(rel == SetRelation.disjoint, reporter());
			} else if(verA.low > verB.high) {
				assert(rel == SetRelation.disjoint, reporter());
			} else if(verA.low < verB.low && verA.high > verB.high) {
				assert(rel == SetRelation.overlapping, reporter());
			} else if(verA.low > verB.low && verA.high < verB.high) {
				assert(rel == SetRelation.subset, reporter());
			} else {
				assert((rel == SetRelation.overlapping)
						|| (rel == SetRelation.subset)
						|| (rel == SetRelation.disjoint), reporter());
			}*/
		}
	}
}

unittest {
	SemVer a = SemVer("1.0.0");
	SemVer b = SemVer("2.0.0");
	SemVer c = SemVer("3.0.0");

	auto v1 = VersionSpecifier(a, Inclusive.no, b, Inclusive.yes);
	auto v2 = VersionSpecifier(b, Inclusive.yes, c, Inclusive.yes);

	auto rel = relation(v1, v2);
	assert(rel == SetRelation.overlapping, format("%s", rel));
}

unittest {
	SemVer a = SemVer("1.0.0");
	SemVer b = SemVer("2.0.0");
	SemVer c = SemVer("3.0.0");
	SemVer d = SemVer("99999.0.0");

	auto v1 = VersionSpecifier(a, Inclusive.no, b, Inclusive.no);
	auto v2 = VersionSpecifier(b, Inclusive.no, c, Inclusive.yes);
	auto v3 = VersionSpecifier(b, Inclusive.yes, c, Inclusive.yes);
	auto v4 = VersionSpecifier(a, Inclusive.no, b, Inclusive.yes);
	auto v5 = VersionSpecifier(b, Inclusive.yes, c, Inclusive.yes);
	auto v6 = VersionSpecifier(c, Inclusive.no, d, Inclusive.yes);

	auto rel = relation(v1, v2);
	assert(rel == SetRelation.disjoint, format("%s", rel));

	rel = relation(v1, v3);
	assert(rel == SetRelation.disjoint, format("%s", rel));

	rel = relation(v3, v4);
	assert(rel == SetRelation.overlapping, format("%s", rel));

	writefln("v5: %s\nv6: %s", v5, v6);
	rel = relation(v5, v6);
	assert(rel == SetRelation.disjoint, format("%s", rel));
}

