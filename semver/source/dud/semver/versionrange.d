module dud.semver.versionrange;

import std.array : empty, split, join;
import std.conv : to;
import std.exception : enforce;
import std.format : format;
import std.stdio;
import std.string : indexOfAny;
import std.typecons : nullable, Nullable;

import dud.semver.semver;
import dud.semver.parse;
import dud.semver.comparision;

@safe pure:

enum Inclusive : bool {
	no = false,
	yes = true
}

struct VersionRange {
@safe:
	string branch;
	Inclusive inclusiveLow;
	Inclusive inclusiveHigh;
	SemVer low;
	SemVer high;

	this(string branch) nothrow @nogc pure {
		this.branch = branch;
	}

	this(const(SemVer) low, const(Inclusive) incLow, const(SemVer) high,
			const(Inclusive) incHigh) pure
	{
		enforce(low <= high, format("low %s must be lower equal to high %s",
			low, high));
		//enforce(low < high || (incLow == incHigh && incLow == Inclusive.yes),
		//	format("tried to construct an empty range with incLow '%s', "
		//		~ "low '%s', incHigh '%s', high '%s'", incLow, low, incHigh,
		//		high));
		this.low = low.dup();
		this.inclusiveLow = incLow;
		this.high = high.dup();
		this.inclusiveHigh = incHigh;
	}

	bool isBranch() const pure @safe nothrow @nogc {
		return !this.branch.empty;
	}

	bool opEquals()(auto ref const VersionRange o) const pure @safe {
		return this.isBranch() != o.isBranch()
				? false
				: this.isBranch()
					? this.branch == o.branch
					: o.inclusiveLow == this.inclusiveLow
						&& o.inclusiveHigh == this.inclusiveHigh
						&& o.low == this.low
						&& o.high == this.high
						&& o.branch == this.branch;
	}

	/// ditto
	int opCmp(const VersionRange o) const pure @safe {
		import std.algorithm.comparison : cmp;
		if(this.isBranch() && o.isBranch()) {
			return cmp(this.branch, o.branch);
		} else if(this.isBranch() && !o.isBranch()) {
			return -1;
		} else if(!this.isBranch() && o.isBranch()) {
			return 1;
		}

		const int lowCmp = compare(this.low, o.low);
		if(lowCmp == -1 || lowCmp == 1) {
			return lowCmp;
		} else {
			return this.inclusiveLow && o.inclusiveLow
				? 0
				: this.inclusiveLow && !o.inclusiveLow
					? 1
					: -1;
		}
	}

	/// ditto
	size_t toHash() const nothrow @trusted @nogc pure {
		size_t hash = 0;
		hash = this.inclusiveLow.hashOf(hash);
		hash = this.low.hashOf(hash);
		hash = this.inclusiveHigh.hashOf(hash);
		hash = this.high.hashOf(hash);
		hash = this.branch.hashOf(hash);
		return hash;
	}

	@property VersionRange dup() const pure {
		return this.isBranch
			? VersionRange(this.branch)
			: VersionRange(this.low.dup(), this.inclusiveLow, this.high.dup(),
				this.inclusiveHigh);
	}

	string toString() const @safe pure {
		import std.array : appender;
		import std.format : format;
		if(!this.branch.empty) {
			return format("%s", this.branch);
		}

		string ret = format(">%s%s", this.inclusiveLow ? "=" : "", this.low);
		if(this.high != SemVer.max()) {
			ret ~= format(" <%s%s", this.inclusiveHigh ? "=" : "", this.high);
		}
		return ret;
	}
}

unittest {
	Nullable!VersionRange snn = parseVersionRange("1.0.0");
	assert(!snn.isNull);
	VersionRange s = snn.get();
	assert(s == s);
	assert(s.toHash() != 0);

	snn = parseVersionRange("~master");
	assert(!snn.isNull);
	s = snn.get();
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
Nullable!VersionRange parseVersionRange(string ves) pure {
	import std.string;
	import std.algorithm.searching : startsWith;
	import std.format : format;

	enforce(ves.length > 0, "Can not process empty version specifier");
	const string orig = ves;

	VersionRange ret;

	if(orig.empty) {
		return Nullable!(VersionRange).init;
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
		ret.low = parseSemVer(expandVersion(ves));
		ret.high = parseSemVer(bumpVersion(ves) ~ "-0");
	} else if (ves.startsWith("^")) {
		// Shortcut: "^x.y.z" variant. "Semver compatible" - no breaking changes.
		// if 0.x.y, ==0.x.y
		// if x.y.z, >=x.y.z <(x+1).0.0-0
		// ^x.y is equivalent to ^x.y.0.
		ret.inclusiveLow = Inclusive.yes;
		ret.inclusiveHigh = Inclusive.no;
		ves = ves[1..$].expandVersion;
		ret.low = parseSemVer(ves);
		ret.high = parseSemVer(bumpIncompatibleVersion(ves) ~ "-0");
	} else if (ves[0] == '~') {
		ret.inclusiveLow = Inclusive.yes;
		ret.inclusiveHigh = Inclusive.yes;
		ret.branch = ves;
	} else if (indexOf("><=", ves[0]) == -1) {
		ret.inclusiveLow = Inclusive.yes;
		ret.inclusiveHigh = Inclusive.yes;
		ret.low = ret.high = parseSemVer(ves);
	} else {
		auto cmpa = skipComp(ves);
		size_t idx2 = indexOf(ves, " ");
		if (idx2 == -1) {
			if (cmpa == "<=" || cmpa == "<") {
				ret.low = SemVer.MinRelease.dup;
				ret.inclusiveLow = Inclusive.yes;
				ret.high = parseSemVer(ves);
				ret.inclusiveHigh = cast(Inclusive)(cmpa == "<=");
			} else if (cmpa == ">=" || cmpa == ">") {
				ret.low = parseSemVer(ves);
				ret.inclusiveLow = cast(Inclusive)(cmpa == ">=");
				ret.high = SemVer.MaxRelease.dup;
				ret.inclusiveHigh = Inclusive.yes;
			} else {
				// Converts "==" to ">=a&&<=a", which makes merging easier
				ret.low = ret.high = parseSemVer(ves);
				ret.inclusiveLow = ret.inclusiveHigh = Inclusive.yes;
			}
		} else {
			enforce(cmpa == ">" || cmpa == ">=",
				"First comparison operator expected to be either > or >=, not "
				~ cmpa);
			assert(ves[idx2] == ' ');
			ret.low = parseSemVer(ves[0..idx2]);
			ret.inclusiveLow = cast(Inclusive)(cmpa == ">=");
			string v2 = ves[idx2+1..$];
			auto cmpb = skipComp(v2);
			enforce(cmpb == "<" || cmpb == "<=",
				"Second comparison operator expected to be either < or <=, not "
				~ cmpb);
			ret.high = parseSemVer(v2);
			ret.inclusiveHigh = cast(Inclusive)(cmpb == "<=");

			enforce(ret.low <= ret.high,
				"First version must not be greater than the second one.");
		}
	}

	return nullable(ret);
}

private string expandVersion(string ver) pure {
	auto mi = ver.indexOfAny("+-");
	auto sub = "";
	if (mi > 0) {
		sub = ver[mi..$];
		ver = ver[0..mi];
	}
	//auto splitted = () @trusted { return split(ver, "."); } (); // DMD 2.065.0
	auto splitted = split(ver, ".");
	assert(splitted.length > 0 && splitted.length <= 3, "Version corrupt: " ~ ver);
	while (splitted.length < 3) splitted ~= "0";
	return splitted.join(".") ~ sub;
}

unittest {
	assert("1.0.0" == expandVersion("1"));
	assert("1.0.0" == expandVersion("1.0"));
	assert("1.0.0" == expandVersion("1.0.0"));
	// These are rather excotic variants...
	assert("1.0.0-pre.release" == expandVersion("1-pre.release"));
	assert("1.0.0+meta" == expandVersion("1+meta"));
	assert("1.0.0-pre.release+meta" == expandVersion("1-pre.release+meta"));
}

/**
	Increments a given (partial) version number to the next higher version.

	Prerelease and build metadata information is ignored. The given version
	can skip the minor and patch digits. If no digits are skipped, the next
	minor version will be selected. If the patch or minor versions are skipped,
	the next major version will be selected.

	This function corresponds to the semantivs of the "~>" comparison operator's
	upper bound.

	The semantics of this are the same as for the "approximate" version
	specifier from rubygems.
	(https://github.com/rubygems/rubygems/tree/81d806d818baeb5dcb6398ca631d772a003d078e/lib/rubygems/version.rb)

	See_Also: `expandVersion`
*/
private string bumpVersion(string ver) {
	// Cut off metadata and prerelease information.
	auto mi = ver.indexOfAny("+-");
	if (mi > 0) ver = ver[0..mi];
	// Increment next to last version from a[.b[.c]].
	auto splitted =  split(ver, ".");
	assert(splitted.length > 0 && splitted.length <= 3, "Version corrupt: " ~ ver);
	auto to_inc = splitted.length == 3 ? 1 : 0;
	splitted = splitted[0 .. to_inc+1];
	splitted[to_inc] = to!string(to!int(splitted[to_inc]) + 1);
	// Fill up to three compontents to make valid SemVer version.
	while (splitted.length < 3) splitted ~= "0";
	return splitted.join(".");
}

///
unittest {
	assert("1.0.0" == bumpVersion("0"));
	assert("1.0.0" == bumpVersion("0.0"));
	assert("0.1.0" == bumpVersion("0.0.0"));
	assert("1.3.0" == bumpVersion("1.2.3"));
	assert("1.3.0" == bumpVersion("1.2.3+metadata"));
	assert("1.3.0" == bumpVersion("1.2.3-pre.release"));
	assert("1.3.0" == bumpVersion("1.2.3-pre.release+metadata"));
}

/**
	Increments a given version number to the next incompatible version.

	Prerelease and build metadata information is removed.

	This implements the "^" comparison operator, which represents "nonbreaking semver compatibility."
	With 0.x.y releases, any release can break.
	With x.y.z releases, only major releases can break.
*/
string bumpIncompatibleVersion(string ver) {
	// Cut off metadata and prerelease information.
	auto mi = ver.indexOfAny("+-");
	if (mi > 0) ver = ver[0..mi];
	// Increment next to last version from a[.b[.c]].
	auto splitted = split(ver, ".");
	assert(splitted.length == 3, "Version corrupt: " ~ ver);
	if(splitted[0] == "0") {
		splitted[2] = to!string(to!int(splitted[2]) + 1);
	} else {
		splitted = [ to!string(to!int(splitted[0]) + 1), "0", "0" ];
	}
	return splitted.join(".");
}
///
unittest {
	assert(bumpIncompatibleVersion("0.0.0") == "0.0.1");
	assert(bumpIncompatibleVersion("0.1.2") == "0.1.3");
	assert(bumpIncompatibleVersion("1.0.0") == "2.0.0");
	assert(bumpIncompatibleVersion("1.2.3") == "2.0.0");
	assert(bumpIncompatibleVersion("1.2.3+metadata") == "2.0.0");
	assert(bumpIncompatibleVersion("1.2.3-pre.release") == "2.0.0");
	assert(bumpIncompatibleVersion("1.2.3-pre.release+metadata") == "2.0.0");
}

private string skipComp(ref string c) pure {
	import std.ascii : isDigit;
	size_t idx = 0;
	while(idx < c.length && !isDigit(c[idx]) && c[idx] != '~') {
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
	auto v = parseVersionRange(tt);
}

bool isInRange(const(VersionRange) range, const(SemVer) v) pure {
	import dud.semver.comparision : compare;

	const int low = compare(v, range.low);
	const int high = compare(range.high, v);

	if(low < 0 || (low == 0 && !range.inclusiveLow)) {
		return false;
	}

	if(high < 0 || (high == 0 && !range.inclusiveHigh)) {
		return false;
	}

	return true;
}

pure unittest {
	Nullable!VersionRange r1N = parseVersionRange("^1.0.0");
	assert(!r1N.isNull());
	VersionRange r1 = r1N.get();
	SemVer v1 = parseSemVer("1.0.0");
	SemVer v2 = parseSemVer("2.0.0");
	SemVer v3 = parseSemVer("2.0.1");
	SemVer v4 = parseSemVer("0.999.999");
	SemVer v5 = parseSemVer("1.999.999");
	SemVer v6 = parseSemVer("89.0.1");

	assert( isInRange(r1, v1));
	assert(!isInRange(r1, v2));
	assert(!isInRange(r1, v3));
	assert(!isInRange(r1, v4));
	assert( isInRange(r1, v5));
	assert(!isInRange(r1, v6));
}

pure unittest {
	Nullable!VersionRange r1N = parseVersionRange("*");
	assert(!r1N.isNull());
	VersionRange r1 = r1N.get();
	SemVer v1 = parseSemVer("1.0.0");
	SemVer v2 = parseSemVer("2.0.0");
	SemVer v3 = parseSemVer("2.0.1");
	SemVer v4 = parseSemVer("0.999.999");
	SemVer v5 = parseSemVer("1.999.999");
	SemVer v6 = parseSemVer("89.0.1");

	assert( isInRange(r1, v1));
	assert( isInRange(r1, v2));
	assert( isInRange(r1, v3));
	assert( isInRange(r1, v4));
	assert( isInRange(r1, v5));
	assert( isInRange(r1, v6));
}

pure unittest {
	Nullable!VersionRange r1N = parseVersionRange("~master");
	assert(!r1N.isNull());
	VersionRange r1 = r1N.get();
	SemVer v1 = parseSemVer("1.0.0");
	SemVer v2 = parseSemVer("2.0.0");
	SemVer v3 = parseSemVer("2.0.1");
	SemVer v4 = parseSemVer("0.999.999");
	SemVer v5 = parseSemVer("1.999.999");
	SemVer v6 = parseSemVer("89.0.1");

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
	import dud.semver.comparision : compare;
	const int cmp = compare(a, b);
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
	SemVer a = parseSemVer("1.0.0");

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
	SemVer a = parseSemVer("1.0.0");
	SemVer b = parseSemVer("2.0.0");

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
	SemVer[] sv =
		[ parseSemVer("1.0.0"), parseSemVer("2.0.0")
		, parseSemVer("3.0.0")
		];
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

enum SetRelation : int {
	/// The second set contains all elements of the first, as well as possibly
	/// more.
	subset = 0,

	/// Neither set contains any elements of the other.
	disjoint = 1,

	/// The sets have elements in common, but the first is not a superset of the
	/// second.
	///
	/// This is also used when the first set is a superset of the second
	overlapping = 2
}

/** Tests the relation between a and b.
A and b can be overlapping or disjoint and a can be a subset of b.
*/
SetRelation relation(const(VersionRange) a, const(VersionRange) b)
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
