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
		immutable all = Conf("", IsPositive.yes);
		if(c != all && !canFind(this.confs, c)) {
			this.confs ~= c.dup();
			this.confs.sort();
		}
		immutable none = Conf("", IsPositive.no);
		if(canFind(this.confs, none)) {
			this.confs = [none.dup()];
		}
	}
}

Conf invert(const(Conf) c) {
	// If no configuration is selected aka
	// c.conf.empty && c.isPositive == IsPositive.yes what does it even mean
	// to invert that selection.
	// Currently, the answer is that it is a no op
	return c.conf.empty && c.isPositive == IsPositive.yes
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

	assert(a.isPositive != b.isPositive);
	return aEqB
		? Confs([Conf("", IsPositive.no)])
		: Confs([a.dup(), b.dup()]);
}

Confs differenceOf(const(Conf) a, const(Conf) b) {
	Conf inv = invert(b);
	return intersectionOf(a, inv);
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
