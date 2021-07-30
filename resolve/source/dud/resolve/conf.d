module dud.resolve.conf;

import std.array : empty;
import std.typecons : Flag;
import std.stdio;
import std.format : format;

import dud.resolve.positive;
import dud.semver.versionrange;
import dud.resolve.confs;

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

Conf invert(const(Conf) c) {
	return Conf(c.conf, cast(IsPositive)!c.isPositive);
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
		: false;
}

bool allowsAll(const(Conf) a, const(Conf) b) {
	return a.isPositive == IsPositive.yes && a.conf.empty
		? true
		: a.isPositive == IsPositive.no && a.conf.empty
			? false
			: a.isPositive == IsPositive.yes && a.isPositive == b.isPositive
				? a.conf == b.conf
				: false;
}

Confs intersectionOf(const(Conf) a, const(Conf) b) {
	if((a.isPositive == IsPositive.no && a.conf.empty)
		|| (b.isPositive == IsPositive.no && b.conf.empty))
	{
		debug writeln(__LINE__);
		return Confs([Conf("", IsPositive.no)]);
	}

	if(a.isPositive == IsPositive.yes && a.conf.empty) {
		debug writeln(__LINE__);
		return b.isPositive == IsPositive.no
			? Confs([a, Conf(b.conf, b.isPositive)])
			: Confs([Conf(b.conf, b.isPositive)]);
	}

	if(b.isPositive == IsPositive.yes && b.conf.empty) {
		debug writeln(__LINE__);
		return a.isPositive == IsPositive.no
			? Confs([b, Conf(a.conf, a.isPositive)])
			: Confs([Conf(a.conf, a.isPositive)]);
	}

	/*
	if(a.isPositive == b.isPositive && a.isPositive == IsPositive.yes
			&& a.conf == b.conf)
	{
		debug writeln(__LINE__);
		return Confs([Conf(a.conf, IsPositive.yes)]);
	}
	*/
	if(a == b) {
		debug writeln(__LINE__);
		return Confs([Conf(a.conf, a.isPositive)]);
	}

	debug writeln(__LINE__);
	return Confs([]);
}

Confs differenceOf(const(Conf) a, const(Conf) b) {
	return a == b
		? Confs([])
		: Confs([a]);
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
