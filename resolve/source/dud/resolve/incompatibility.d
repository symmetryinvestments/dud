module dud.resolve.incompatibility;

import std.array : array, empty;
import std.exception : enforce;
import std.format : format;
import std.typecons : Nullable, nullable;
import std.algorithm.iteration : filter;
import std.algorithm.searching : any;

import dud.resolve.positive;
import dud.resolve.term;

struct Incompatibility {
	Term[] terms;
}

Nullable!(Incompatibility) resolve(const(Incompatibility) input) {
	import std.algorithm.comparison : min;

	Term[] ret;
	bool[size_t] alreadyProcessed;

	Nullable!Term cur;
	foreach(idx, ref it; input.terms) {
		if(idx in alreadyProcessed) {
			continue;
		}

		cur = dud.resolve.term.dup(it);

		foreach(jdx, ref jt; input.terms[min(idx + 1, input.terms.length) .. $]) {
			const actualJdx = idx + 1 + jdx;
			if(actualJdx !in alreadyProcessed
					&& input.terms[actualJdx].pkg.pkg.name ==
						input.terms[idx].pkg.pkg.name)
			{
				alreadyProcessed[actualJdx] = true;
				cur = cur.isNull()
					? Nullable!(Term).init
					: intersectionOf(cur.get(), input.terms[actualJdx]);
			}
		}

		if(!cur.isNull()) {
			ret ~= cur.get();
		}
	}

	return ret.empty
		? Nullable!(Incompatibility).init
		: nullable(Incompatibility(ret));
}
