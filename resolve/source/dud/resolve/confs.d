module dud.resolve.confs;

import std.algorithm.iteration : each, filter, map;
import std.algorithm.searching : all, any, canFind;
import std.array : array, empty, front;
import std.format : format;
import std.typecons : Flag;
import std.range : chain;
import std.stdio;

import dud.resolve.positive;
import dud.resolve.conf;
import dud.semver.versionrange;

@safe pure:

private immutable nothing = Conf("", IsPositive.no);

struct Confs {
	import std.algorithm.iteration : map;

@safe pure:
	Conf[] confs;

	this(const(Conf)[] input) {
		import std.algorithm.iteration : each;
		this.insert(input);
	}

	Confs dup() const {
		import std.array : array;
		return Confs(this.confs.map!(it => it.dup).array);
	}

	void insert(const(Conf[]) cs) {
		cs.each!(it => this.insert(it));
	}

	void insert(const(Conf) c) {
		import std.algorithm.sorting : sort;

		// Negativ all means nothing can be added anymore
		if(!this.confs.empty && this.confs.front == nothing) {
			return;
		}

		// Got a new nothing
		if(c == nothing) {
			this.confs = [ nothing.dup() ];
			return;
		}

		// Already in ignore
		if(canFind(this.confs, c)) {
			return;
		}

		this.confs ~= Conf(c.conf, c.isPositive);
		this.confs = normalize(this.confs);
	}

	Confs invert() const {
		return this.confs.map!(it => it.invert()).array.Confs;
	}

	bool opEquals(const(Confs) other) const {
		return this.confs.length == other.confs.length
			&& this.confs.all!(c => canFind(other.confs, c));
	}
}

private Conf[] normalize(Conf[] toNorm) {
	Conf[] ret;
	outer: foreach(idx, it; toNorm) {
		Conf inv = it.invert();
		foreach(jdx, jt; toNorm) {
			if(idx != jdx && inv == jt) {
				continue outer;
			}
		}
		ret ~= it;
	}
	const everything = Conf("", IsPositive.yes);
	if(canFind(ret, everything)) {
		ret = ret.filter!(it => it == everything
				|| it.isPositive == IsPositive.no)
			.array;
	}
	return ret;
}

bool allowsAll(const(Confs) a, const(Confs) b) {
	return b.confs.all!(it => allowsAny(a, it));
}

bool allowsAny(const(Confs) a, const(Confs) b) {
	return b.confs.empty || b.confs.any!(it => allowsAny(a, it));
}

bool allowsAll(const(Confs) a, const(Conf) b) {
	static import dud.resolve.conf;
	return !a.confs.empty
		&& a.confs.any!(it => dud.resolve.conf.allowsAll(it, b));
}

bool allowsAny(const(Confs) a, const(Conf) b) {
	static import dud.resolve.conf;
	const t = !a.confs.empty
		&& a.confs.any!(it => dud.resolve.conf.allowsAny(it, b));
	return t;
}

Confs intersectionOf(const(Confs) a, const(Confs) b) {
	import std.algorithm.setops : cartesianProduct;
	import std.algorithm.iteration : joiner;

	Confs ret;
	foreach(aIt; a.confs) {
		foreach(bIt; b.confs) {
			Confs i = dud.resolve.conf.intersectionOf(aIt, bIt);
			foreach(abIt; i.confs) {
				ret.insert(abIt);
			}
		}
	}
	return ret;
}

Confs differenceOf(const(Confs) a, const(Confs) b) {
	Conf[] neg = b.confs
		.map!(it => it.isPositive == IsPositive.no
				? it.dup
				: Conf(it.conf, IsPositive.no))
		.array;

	Conf[] ret = a.confs.map!(it => it.dup).array ~ neg;
	return Confs(ret);
}

/** Return if a is a subset of b, or if a and b are disjoint, or
if a and b overlap
*/
SetRelation relation(const(Confs) a, const(Confs) b) pure {
	if(b.allowsAll(a)) {
		return SetRelation.subset;
	}
	if(b.allowsAny(a)) {
		return SetRelation.overlapping;
	}
	return SetRelation.disjoint;
}
