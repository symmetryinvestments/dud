module dud.pkgdescription.versionspecifier;

import std.array : empty;
import std.exception : enforce;
import std.format : format;
import std.stdio;
import std.typecons : nullable, Nullable;

import dud.semver;
import dud.semver.operations;

@safe pure:

struct VersionSpecifier {
@safe pure:
	string orig;
	bool inclusiveA;
	bool inclusiveB;
	SemVer versionA;
	SemVer versionB;

	this(string input) pure {
		Nullable!VersionSpecifier s = parseVersionSpecifier(input);
		enforce(!s.isNull());
		VersionSpecifier snn = s.get();
		this = snn;
	}


	bool opEquals(const VersionSpecifier o) const pure @safe {
		return o.inclusiveA == this.inclusiveA
			&& o.inclusiveB == this.inclusiveB
			&& o.versionA == this.versionA
			&& o.versionB == this.versionB;
	}

	/// ditto
	int opCmp(const VersionSpecifier o) const pure @safe {
		if(this.inclusiveA != o.inclusiveA) {
			return this.inclusiveA < o.inclusiveA ? -1 : 1;
		}

		if(this.inclusiveB != o.inclusiveB) {
			return this.inclusiveB < o.inclusiveB ? -1 : 1;
		}

		if(this.versionA != o.versionA) {
			return this.versionA < o.versionA ? -1 : 1;
		}

		if(this.versionB != o.versionB) {
			return this.versionB < o.versionB ? -1 : 1;
		}

		return 0;
	}

	/// ditto
	size_t toHash() const nothrow @trusted @nogc {
		size_t hash = 0;
		hash = this.inclusiveA.hashOf(hash);
		hash = this.versionA.toString().hashOf(hash);
		hash = this.inclusiveB.hashOf(hash);
		hash = this.versionB.toString().hashOf(hash);
		return hash;
	}
}

unittest {
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
Nullable!VersionSpecifier parseVersionSpecifier(string ves) {
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
		ret.inclusiveA = true;
		ret.inclusiveB = false;
		ves = ves[2..$];
		ret.versionA = SemVer(expandVersion(ves));
		ret.versionB = SemVer(bumpVersion(ves) ~ "-0");
	} else if (ves.startsWith("^")) {
		// Shortcut: "^x.y.z" variant. "Semver compatible" - no breaking changes.
		// if 0.x.y, ==0.x.y
		// if x.y.z, >=x.y.z <(x+1).0.0-0
		// ^x.y is equivalent to ^x.y.0.
		ret.inclusiveA = true;
		ret.inclusiveB = false;
		ves = ves[1..$].expandVersion;
		ret.versionA = SemVer(ves);
		ret.versionB = SemVer(bumpIncompatibleVersion(ves) ~ "-0");
	} else if (ves[0] == SemVer.BranchPrefix) {
		ret.inclusiveA = true;
		ret.inclusiveB = true;
		ret.versionA = ret.versionB = SemVer(ves);
	} else if (std.string.indexOf("><=", ves[0]) == -1) {
		ret.inclusiveA = true;
		ret.inclusiveB = true;
		ret.versionA = ret.versionB = SemVer(ves);
	} else {
		auto cmpa = skipComp(ves);
		size_t idx2 = std.string.indexOf(ves, " ");
		if (idx2 == -1) {
			if (cmpa == "<=" || cmpa == "<") {
				ret.versionA = SemVer.MinRelease;
				ret.inclusiveA = true;
				ret.versionB = SemVer(ves);
				ret.inclusiveB = cmpa == "<=";
			} else if (cmpa == ">=" || cmpa == ">") {
				ret.versionA = SemVer(ves);
				ret.inclusiveA = cmpa == ">=";
				ret.versionB = SemVer.MaxRelease;
				ret.inclusiveB = true;
			} else {
				// Converts "==" to ">=a&&<=a", which makes merging easier
				ret.versionA = ret.versionB = SemVer(ves);
				ret.inclusiveA = ret.inclusiveB = true;
			}
		} else {
			enforce(cmpa == ">" || cmpa == ">=", "First comparison operator expected to be either > or >=, not "~cmpa);
			assert(ves[idx2] == ' ');
			ret.versionA = SemVer(ves[0..idx2]);
			ret.inclusiveA = cmpa == ">=";
			string v2 = ves[idx2+1..$];
			auto cmpb = skipComp(v2);
			enforce(cmpb == "<" || cmpb == "<=", "Second comparison operator expected to be either < or <=, not "~cmpb);
			ret.versionB = SemVer(v2);
			ret.inclusiveB = cmpb == "<=";

			enforce(!ret.versionA.isBranch && !ret.versionB.isBranch, format("Cannot compare branches: %s", ves));
			enforce(ret.versionA <= ret.versionB, "First version must not be greater than the second one.");
		}
	}

	return nullable(ret);
}

private string skipComp(ref string c) {
	import std.ascii : isDigit;
	size_t idx = 0;
	while (idx < c.length && !isDigit(c[idx]) && c[idx] != SemVer.BranchPrefix) {
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

unittest {
	string tt = ">=1.0.0";
	auto v = parseVersionSpecifier(tt);
}

bool isInRange(const(VersionSpecifier) range, const(SemVer) v) {
	enforce(!v.isBranch(), format("isInRange v must not be a branch '%s'",
		v.toString()));

	const int low = compareVersions(v.toString(), range.versionA.toString());
	const int high = compareVersions(range.versionB.toString(), v.toString());

	if(low < 0 || (low == 0 && !range.inclusiveA)) {
		return false;
	}

	if(high < 0 || (high == 0 && !range.inclusiveB)) {
		return false;
	}

	return true;
}

unittest {
	VersionSpecifier r1 = parseVersionSpecifier("^1.0.0");
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

unittest {
	VersionSpecifier r1 = parseVersionSpecifier("*");
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

unittest {
	VersionSpecifier r1 = parseVersionSpecifier("~master");
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

SetRelation relation(const(VersionSpecifier) a, const(VersionSpecifier) b) {
	const BoundRelation lowLow = relation(a.versionA, a.inclusiveA,
			b.versionA, b.inclusiveA);
	const BoundRelation lowHigh = relation(a.versionA, a.inclusiveA,
			b.versionB, b.inclusiveB);
	const BoundRelation highHigh = relation(a.versionB, a.inclusiveB,
			b.versionB, b.inclusiveB);
	const BoundRelation highLow = relation(a.versionB, a.inclusiveB,
			b.versionA, b.inclusiveA);

	// Disjoint

	if(highLow == BoundRelation.less || lowHigh == BoundRelation.more) {
		// a: | . | . . . .
		// b: . . . . | . |

		// a: . . . . | . |
		// b: | . | . . . .
		return SetRelation.disjoint;
	}

	if((lowLow == BoundRelation.equal && highHigh == BoundRelation.less)
	|| (lowLow == BoundRelation.more && highHigh == BoundRelation.less)
	|| (lowLow == BoundRelation.more && highHigh == BoundRelation.equal))
	{
		// a: | . . . | . .
		// b: | . . . . | .

		// a: . | . . | . .
		// b: | . . . . | .

		// a: . | . . | . .
		// b: | . . . | . .
		return SetRelation.subset;
	}

	if( (highHigh == BoundRelation.less &&
			(highLow == BoundRelation.more || highLow == BoundRelation.equal))
	||
		((lowLow == BoundRelation.more || lowLow == BoundRelation.more) &&
			highHigh == BoundRelation.more)
	) {
		// a: | . . . | . .
		// b: . . | . . | .

		// a: . . . | . . |
		// b: . | . . . | .
		return SetRelation.overlapping;
	}

	assert(false, format("\na:%s\nb:%s", a, b));
}

///
enum BoundRelation {
	less,
	equal,
	more
}

/** Return whether a is less than, equal, or greater than b
*/
BoundRelation relation(const(SemVer) a, const bool aInclusive,
		const(SemVer) b, const bool bInclusive)
{
	import dud.semver.operations : compareVersions;
	const int cmp = compareVersions(a, b);
	if(cmp < 0) {
		return BoundRelation.less;
	} else if(cmp > 0) {
		return BoundRelation.more;
	} else if(cmp == 0 && aInclusive == bInclusive) {
		return BoundRelation.equal;
	} else if(cmp == 0 && aInclusive == false && bInclusive == true) {
		return BoundRelation.more;
	} else if(cmp == 0 && aInclusive == true && bInclusive == false) {
		return BoundRelation.less;
	}
	assert(false, format(
		"invalid state a '%s', aInclusive '%s', b '%s', bInclusive '%s'",
		a, aInclusive, b, bInclusive));
}

unittest {
	SemVer[] sv = [SemVer("1.0.0"), SemVer("2.0.0"), SemVer("3.0.0")];
	bool[] b = [true, false];

	relation(sv[0], true, sv[0], false);
	foreach(sa; sv) {
		foreach(sb; sv) {
			foreach(ba; b) {
				foreach(bb; b) {
					relation(sa, ba, sb, bb);
				}
			}
		}
	}
}
