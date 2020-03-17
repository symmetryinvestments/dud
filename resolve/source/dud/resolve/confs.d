module dud.resolve.confs;

import std.algorithm.iteration : each, filter;
import std.algorithm.searching : all, any;
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

		if(isOkayToInset(this.confs, c)) {
			this.confs ~= c;
			this.confs = normalize(this.confs);
			this.confs.sort();
		}
	}

	Confs invert() const {
		return this.confs.map!(it => it.invert()).array.Confs;
	}
}

private bool isOkayToInset(const(Conf[]) arr, const(Conf) it) {
	import std.algorithm.searching : canFind;

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
		.filter!(it => !isNegativPresent(arr, it) || it.isPositive == IsPositive.no)
		.array;
}





































__EOF__

Confs normalize(const(Confs) input) {
	Confs ret;
	normalizeImpl(input).each!(it => ret.insert(it));
	return ret;
}

private auto normalizeImpl(const(Conf)[] input) {
	bool test(const(Conf) i) {
		return allowsAllImpl(input, i) || i.isPositive == IsPositive.no;
	}

	return input.filter!(test)();
}

private auto normalizeImpl(const(Confs) input) {
	return normalizeImpl(input.confs);
}

Confs invert(const(Confs) input) {
	import std.algorithm.iteration : map;
	import std.array : array;
	return Confs(input.confs
			.map!(it => dud.resolve.conf.invert(it))
			.array
		);
}

bool allowsAll(const(Confs) a, const(Confs) b) {
	static import dud.resolve.conf;
	return !a.confs.empty && b.confs.all!(bIt => allowsAll(a, b));
}

bool allowsAll(const(Confs) a, const(Conf) b) {
	return allowsAllImpl(a.confs, b);
}

private bool allowsAllImpl(const(Conf[]) a, const(Conf) b) {
	static import dud.resolve.conf;
	return a.empty || a.all!(it => dud.resolve.conf.allowsAll(it, b));
}

bool allowsAny(const(Confs) a, const(Confs) b) {
	return allowsAnyImpl(a.confs, b);
}

private bool allowsAnyImpl(const(Conf[]) as, const(Conf) b) {
	static import dud.resolve.conf;
	return !as.empty
		&& as
			.all!(
				aIt => b.confs.all!(
					bIt => dud.resolve.conf.allowsAny(aIt, bIt)
				)
			);
}

private bool anyDisallow(const(Conf[]) as, const(Conf) b) {
	return as.any!(a => a.conf == b.conf && a.isPositive == IsPositive.no);
}

bool allowsAny(const(Confs) a, const(Conf) b) {
	static import dud.resolve.conf;
	return !a.confs.empty
		&& a.confs.any!(it => dud.resolve.conf.allowsAny(it, b));
}

SetRelation relation(const(Confs) a, const(Confs) b) {
	static import dud.resolve.conf;
	import std.algorithm.iteration : joiner, map;

	SetRelation[] rslt = a.confs
		.map!(aIt =>
				b.confs.map!(bIt => dud.resolve.conf.relation(bIt, aIt)))
		.joiner
		.array;

	if(rslt.all!(it => it == SetRelation.subset)) {
		return SetRelation.subset;
	}

	if(rslt.all!(it =>
				it == SetRelation.subset || it == SetRelation.overlapping))
	{
		return SetRelation.overlapping;
	}

	return SetRelation.disjoint;
}

Confs intersectionOf(const(Confs) a, const(Confs) b) {
	Confs ret;
	a.confs.filter!(it => allowsAll(b, it)).each!(it => ret.insert(it));
	b.confs.filter!(it => allowsAll(a, it)).each!(it => ret.insert(it));
	chain(a.confs, b.confs)
		.filter!(it => it.isPositive == IsPositive.no)
		.each!(it => ret.insert(it));

	return ret;
}

Confs differenceOf(const(Confs) a, const(Confs) b) {
	Confs ret = a.dup();
	b.invert().confs.each!(it => ret.insert(it));
	return ret;
}
