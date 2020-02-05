module dud.resolve.confs;

import std.array : empty;
import std.typecons : Flag;
import std.format : format;

import dud.resolve.positive;
import dud.resolve.conf;
import dud.semver.versionrange;

@safe pure:

struct Confs {
@safe pure:
	Conf[] confs;
	IsPositive isPositive;

	this(const(Conf)[] input) {
		import std.algorithm.iteration : each;
		input.each!(it => this.insert(it));
	}

	Confs dup() const {
		import std.array : array;
		import std.algorithm.iteration : map;
		return Confs(this.confs.map!(it => it.dup).array);
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
