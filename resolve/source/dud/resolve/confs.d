module dud.resolve.confs;

import std.algorithm.iteration : each, filter;
import std.algorithm.searching : all, any;
import std.array : array, empty, front;
import std.format : format;
import std.typecons : Flag;
import std.range : chain;

import dud.resolve.positive;
import dud.resolve.conf;
import dud.semver.versionrange;

@safe pure:

struct Confs {
@safe pure:
	Conf[] confs;
	//IsPositive isPositive;

	this(Conf[] input) {
		import std.algorithm.iteration : each;
		input
			.filter!(it => allowsAllImpl(confs, it))
			.each!(it => this.insert(it));
	}

	Confs dup() const {
		import std.array : array;
		import std.algorithm.iteration : map;
		return Confs(this.confs.map!(it => it.dup).array);
	}

	void insert(const(Conf) c) {
		import std.algorithm.searching : canFind;
		import std.algorithm.sorting : sort;

		// See if the negativ is present, than there is no point in inserting it
		if(c.isPositive == IsPositive.yes) {
			const inv = Conf(c.conf, IsPositive.no);
			if(canFind(this.confs, inv)) {
				return;
			}
		}

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
	return !a.empty && a.any!(it => dud.resolve.conf.allowsAll(it, b));
}

bool allowsAny(const(Confs) a, const(Confs) b) {
	static import dud.resolve.conf;
	return !a.confs.empty
		&& a.confs
			.all!(
				aIt => b.confs.all!(
					bIt => dud.resolve.conf.allowsAny(aIt, bIt)
				)
			);
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
