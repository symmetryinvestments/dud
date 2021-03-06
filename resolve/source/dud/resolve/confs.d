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

		if(isOkayToInsert(this.confs, c)) {
			this.confs ~= c;
			this.confs = normalize(this.confs);
			this.confs.sort();
		}
	}

	Confs invert() const {
		return this.confs.map!(it => it.invert()).array.Confs;
	}
}

private bool isOkayToInsert(const(Conf[]) arr, const(Conf) it) {
	const isNeg = it.isPositive == IsPositive.no;
	const negPr = !isNegativPresent(arr, it);
	const cf = !canFind(arr, it);

	return (isNeg || negPr) && cf;
}

private bool isNegativPresent(const(Conf[]) arr, const(Conf) it) {
	return arr
		.filter!(a => a.isPositive == IsPositive.no)
		.any!(a => a.conf == it.conf);
}

private Conf[] normalize(Conf[] arr) {
	return arr
		.filter!(
			it => !isNegativPresent(arr, it) || it.isPositive == IsPositive.no)
		.array;
}

bool allowsAll(const(Confs) a, const(Conf) b) {
	static import dud.resolve.conf;
	return !a.confs.empty
		&& a.confs.all!(it => dud.resolve.conf.allowsAll(it, b));
}

bool allowsAll(const(Confs) a, const(Confs) b) {
	return b.confs.all!(it => allowsAny(a, it));
}

bool allowsAny(const(Confs) a, const(Conf) b) {
	static import dud.resolve.conf;
	const t = a.confs.any!(it => dud.resolve.conf.allowsAny(it, b));
	//debug writefln("%s %s %s", a, b, t);
	return t;
}

bool allowsAny(const(Confs) a, const(Confs) b) {
	return b.confs.any!(it => allowsAny(a, it));
}

Confs intersectionOf(const(Confs) a, const(Confs) b) {
	Conf[] allNeg = chain(a.confs, b.confs)
		.filter!(it => it.isPositive == IsPositive.no)
		.map!(it => it.dup())
		.array;

	Conf[] inBoth = chain(a.confs, b.confs)
		.filter!(it => isOkayToInsert(allNeg, it)
				&& canFind(a.confs, it)
				&& canFind(b.confs, it)
			)
		.map!(it => it.dup())
		.array;

	Conf[] comb = allNeg ~ inBoth;

	Confs ret = Confs(comb.empty ? [Conf("", IsPositive.no)] : comb);
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
