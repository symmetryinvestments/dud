module dud.resolve.incompatibility;

import std.array : array, empty;
import std.exception : enforce;
import std.format : format;
import std.typecons : Nullable, nullable;
import std.algorithm.iteration : filter;
import std.algorithm.searching : any;

import dud.resolve.positive;
import dud.resolve.term;

@safe:

struct Incompatibility {
	Term[] terms;
}

/** Given an array of Term's this functions will minimize or as known in CS
 * terms resolve this array.
 * The idea is to join Term's that are about the same package.
 * For instance if we have { name: 'FOO', isPositive: true, semver: ^1.0.0 }
 * and { name: 'FOO', isPositive: false, semver: ^1.0.0 } in the input
 * no Term for package FOO will be in the output as the positive and negative
 * Term cancel each other out.
 */
Nullable!(Incompatibility) resolve(const(Incompatibility) input) pure {
	import std.algorithm.comparison : min;

	Term[] ret;
	bool[size_t] alreadyProcessed;

	Nullable!Term cur;
	foreach(idx, ref it; input.terms) {
		if(idx in alreadyProcessed) {
			continue;
		}

		cur = dud.resolve.term.dup(it);

		foreach(jdx, ref jt; input.terms[min(idx + 1, input.terms.length) .. $])
		{
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

bool isSatisfiesBy(const(Incompatibility) incompatibility
		, const(Term)[] partialSolution) pure
{
	import std.algorithm.searching : all, any;

	return incompatibility.terms
		.all!(it => partialSolution
			.any!(t => dud.resolve.term.satisfies(t, it)));
}
