module dud.resolve.incompatibility;

import std.array : array;
import std.exception : enforce;
import std.format : format;
import std.typecons : Nullable;
import std.algorithm.iteration : filter;
import std.algorithm.searching : any;

import dud.resolve.positive;
import dud.resolve.term;

struct Incompatibility {
	Term[] terms;
}

Incompatibility resolve(const(Incompatibility) input) {
	assert(false);
}
