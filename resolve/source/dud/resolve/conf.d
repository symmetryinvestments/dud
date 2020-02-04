module dud.resolve.conf;

import std.array : empty;
import std.typecons : Flag;
import std.format : format;

import dud.resolve.positive;
import dud.semver.versionrange;

@safe pure:

struct Conf {
@safe pure:
	/// empty means wildcard
	string conf;
	/// true means the inverse of the `conf` inverse of `conf.empty`
	/// still means wildcard
	IsPositive isPositive;

	this(string s) {
		this(s, IsPositive.yes);
	}

	this(string s, IsPositive b) {
		this.conf = s;
		this.isPositive = b;
	}

	Conf dup() const {
		return Conf(this.conf, this.isPositive);
	}

	int opCmp(const(Conf) other) const nothrow @nogc {
		return this.conf < other.conf
			? -1
			: this.conf > other.conf
				? 1
				: this.isPositive < other.isPositive
					? -1
					: this.isPositive > other.isPositive
						? 1
						: 0;
	}

	bool opEquals(const(Conf) other) const nothrow @nogc {
		return this.conf == other.conf && this.isPositive == other.isPositive;
	}
}

struct Confs {
@safe pure:
	Conf[] confs;
	IsPositive isPositive;

	this(const(Conf)[] input) {
		import std.algorithm.iteration : each;
		input.each!(it => this.insert(it));
	}

	void insert(const(Conf) c) {
		import std.algorithm.searching : canFind;
		import std.algorithm.sorting : sort;
		if(!canFind(this.confs, c)) {
			this.confs ~= c.dup();
			this.confs.sort();
		}
	}
}

Conf invert(const(Conf) c) {
	return c.conf.empty
		? Conf("", IsPositive.yes)
		: Conf(c.conf, cast(IsPositive)!c.isPositive);
}

bool allowsAny(const(Conf) a, const(Conf) b) {
	if(a.isPositive == IsPositive.no && a.conf.empty) {
		return false;
	}

	if(b.isPositive == IsPositive.no && b.conf.empty) {
		return false;
	}

	if(a.isPositive == IsPositive.yes && a.conf.empty) {
		return true;
	}

	if(b.isPositive == IsPositive.yes && b.conf.empty) {
		return true;
	}

	return a.isPositive == IsPositive.yes && b.isPositive == IsPositive.yes
		? a.conf == b.conf
		: a.isPositive != b.isPositive
			? a.conf != b.conf
			: true;
}

bool allowsAll(const(Conf) a, const(Conf) b) {
	return a.isPositive == IsPositive.yes && a.conf.empty
		? true
		: a.isPositive == IsPositive.no && a.conf.empty
			? false
			: a.isPositive == b.isPositive && a.conf == b.conf;
}

Confs intersectionOf(const(Conf) a, const(Conf) b) {
	if((a.isPositive == IsPositive.no && a.conf.empty)
		|| (b.isPositive == IsPositive.no && b.conf.empty))
	{
		return Confs([Conf("", IsPositive.no)]);
	}

	const bool aEqB = a.conf == b.conf;

	if(a.isPositive == b.isPositive && a.isPositive == IsPositive.yes) {
		return Confs([a.conf.empty && b.conf.empty
			? Conf("", IsPositive.yes)
			: !a.conf.empty && !b.conf.empty
				? Conf(aEqB ? a.conf : "", cast(IsPositive)aEqB)
				: !a.conf.empty && b.conf.empty
					? Conf(a.conf, IsPositive.yes)
					: Conf(b.conf, IsPositive.yes)]);
	}

	if(a.isPositive == b.isPositive && a.isPositive == IsPositive.no) {
		return aEqB
			? Confs([a.dup()])
			: Confs([a.dup(), b.dup()]);
	}

	if(a.isPositive != b.isPositive) {
		return aEqB
			? Confs([Conf("", IsPositive.no)])
			: Confs([a.dup(), b.dup()]);
	}

	assert(false, format("intersectionOf a: %s, b: %s failed", a, b));
}

/** Return if a is a subset of b, or if a and b are disjoint, or
if a and b overlap
*/
SetRelation relation(const(Conf) a, const(Conf) b) pure {
	return allowsAll(b, a)
		? SetRelation.subset
		: allowsAny(b, a)
			? SetRelation.overlapping
			: SetRelation.disjoint;
}
private {
	const c1 = Conf("foo", IsPositive.yes);
	const c2 = Conf("foo", IsPositive.no);
	const c3 = Conf("bar", IsPositive.yes);
	const c4 = Conf("bar", IsPositive.no);
	const c5 = Conf("", IsPositive.yes);
	const c6 = Conf("", IsPositive.no);
}

//
// intersectionOf
//

unittest {
	void test(const(Conf) a, const(Conf) b, const(Confs) exp,
			int line = __LINE__)
	{
		import std.exception : enforce;
		import core.exception : AssertError;
		const(Confs) rslt = intersectionOf(a, b);
		enforce!AssertError(rslt == exp,
			format("\na: %s\nb: %s\nexp: %s\nrsl: %s", a, b, exp, rslt),
			__FILE__, line);
	}

	test(c1, c1, Confs([c1]));
	test(c1, c2, Confs([c6]));
	test(c1, c3, Confs([c6]));
	test(c1, c4, Confs([c1, c4]));
	test(c1, c5, Confs([c1]));
	test(c1, c6, Confs([c6]));

	test(c2, c1, Confs([c6]));
	test(c2, c2, Confs([c2]));
	test(c2, c3, Confs([c3]));
	test(c2, c4, Confs([c6]));
	test(c2, c5, Confs([c2]));
	test(c2, c6, Confs([c6]));
}

//
// invert
//

unittest {
	assert(invert(c1) == c2);
	assert(invert(c2) == c1);
	assert(invert(c3) == c4);
	assert(invert(c4) == c3);
	assert(invert(c5) == c5);
	assert(invert(c6) == c5);
}

//
// allowsAny
//

unittest {
	assert( allowsAny(c1, c1));
	assert(!allowsAny(c1, c2));
	assert(!allowsAny(c1, c3));
	assert( allowsAny(c1, c4));
	assert( allowsAny(c1, c5));
	assert(!allowsAny(c1, c6));

	assert(!allowsAny(c2, c1));
	assert( allowsAny(c2, c2));
	assert( allowsAny(c2, c3));
	assert( allowsAny(c2, c4));
	assert( allowsAny(c2, c5));
	assert(!allowsAny(c2, c6));

	assert(!allowsAny(c3, c1));
	assert( allowsAny(c3, c2));
	assert( allowsAny(c3, c3));
	assert(!allowsAny(c3, c4));
	assert( allowsAny(c3, c5));
	assert(!allowsAny(c3, c6));

	assert( allowsAny(c4, c1));
	assert( allowsAny(c4, c2));
	assert(!allowsAny(c4, c3));
	assert( allowsAny(c4, c4));
	assert( allowsAny(c4, c5));
	assert(!allowsAny(c4, c6));

	assert( allowsAny(c5, c1));
	assert( allowsAny(c5, c2));
	assert( allowsAny(c5, c3));
	assert( allowsAny(c5, c4));
	assert( allowsAny(c5, c5));
	assert(!allowsAny(c5, c6));

	assert(!allowsAny(c6, c1));
	assert(!allowsAny(c6, c2));
	assert(!allowsAny(c6, c3));
	assert(!allowsAny(c6, c4));
	assert(!allowsAny(c6, c5));
	assert(!allowsAny(c6, c6));
}

//
// allowsAll
//

unittest {
	assert( allowsAll(c1, c1));
	assert(!allowsAll(c1, c2));
	assert(!allowsAll(c1, c3));
	assert(!allowsAll(c1, c4));
	assert(!allowsAll(c1, c5));
	assert(!allowsAll(c1, c6));

	assert(!allowsAll(c2, c1));
	assert( allowsAll(c2, c2));
	assert(!allowsAll(c2, c3));
	assert(!allowsAll(c2, c4));
	assert(!allowsAll(c2, c5));
	assert(!allowsAll(c2, c6));

	assert(!allowsAll(c3, c1));
	assert(!allowsAll(c3, c2));
	assert( allowsAll(c3, c3));
	assert(!allowsAll(c3, c4));
	assert(!allowsAll(c3, c5));
	assert(!allowsAll(c3, c6));

	assert(!allowsAll(c4, c1));
	assert(!allowsAll(c4, c2));
	assert(!allowsAll(c4, c3));
	assert( allowsAll(c4, c4));
	assert(!allowsAll(c4, c5));
	assert(!allowsAll(c4, c6));

	assert( allowsAll(c5, c1));
	assert( allowsAll(c5, c2));
	assert( allowsAll(c5, c3));
	assert( allowsAll(c5, c4));
	assert( allowsAll(c5, c5));
	assert( allowsAll(c5, c6));

	assert(!allowsAll(c6, c1));
	assert(!allowsAll(c6, c2));
	assert(!allowsAll(c6, c3));
	assert(!allowsAll(c6, c4));
	assert(!allowsAll(c6, c5));
	assert(!allowsAll(c6, c6));
}

//
// relation
//

unittest {
	Conf nc1 = Conf("", IsPositive.yes);
	Conf nc2 = Conf("conf1", IsPositive.yes);
	Conf nc3 = Conf("conf1", IsPositive.no);
	Conf nc4 = Conf("conf2", IsPositive.yes);
	Conf nc5 = Conf("conf2", IsPositive.no);
	Conf nc6 = Conf("", IsPositive.no);

	SetRelation sr = relation(nc1, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	// nc1 a

	sr = relation(nc1, nc2);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc1, nc3);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc1, nc4);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc1, nc5);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc1, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc1 b

	sr = relation(nc2, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc3, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc4, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc5, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc6, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	// nc2

	sr = relation(nc2, nc2);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc2, nc3);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc2, nc4);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc2, nc5);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc2, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc2 b

	sr = relation(nc3, nc2);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc4, nc2);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc5, nc2);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc6, nc2);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc3

	sr = relation(nc3, nc4);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc3, nc5);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc3, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc3 b

	sr = relation(nc1, nc3);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc2, nc3);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc3, nc3);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc4, nc3);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc5, nc3);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc6, nc3);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc4

	sr = relation(nc4, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc4, nc2);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc4, nc3);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc4, nc4);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc4, nc5);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc4, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc4 b

	sr = relation(nc1, nc4);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc2, nc4);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc3, nc4);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc4, nc4);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc5, nc4);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc6, nc4);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc5

	sr = relation(nc5, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc5, nc2);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc5, nc3);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc5, nc4);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc5, nc5);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc5, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc5 b

	sr = relation(nc1, nc5);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc2, nc5);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc3, nc5);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc4, nc5);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc5, nc5);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc6, nc5);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc6

	sr = relation(nc6, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc6, nc2);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc6, nc3);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc6, nc4);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc6, nc5);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc6, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc6 b

	sr = relation(nc1, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc2, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc3, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc4, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc5, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc6, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));
}

unittest {
	Conf[] tt;
	foreach(c1; ["", "conf", "conf2", "conf3"]) {
		foreach(c2; [IsPositive.no, IsPositive.yes]) {
			tt ~= Conf(c1, c2);
		}
	}

	foreach(it; tt) {
		foreach(jt; tt) {
			relation(it, jt);
		}
	}
}

