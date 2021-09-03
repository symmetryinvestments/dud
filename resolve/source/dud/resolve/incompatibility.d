module dud.resolve.incompatibility;

import std.array : array;
import std.exception : enforce;
import std.format : format;
import std.typecons : Nullable;
import std.algorithm.iteration : filter;
import std.algorithm.searching : any;

import dud.resolve.positive;
import dud.resolve.term;

/// The reason an [Incompatibility]'s terms are incompatible.
abstract class IncompatibilityCause {
	/// The incompatibility represents the requirement that the root package
	/// exists.
	static const IncompatibilityCause root = new _Cause("root");

	/// The incompatibility represents a package's dependency.
	static const IncompatibilityCause dependency = new _Cause("dependency");

	/// The incompatibility represents the user's request that we use the latest
	/// version of a given package.
	static const IncompatibilityCause useLatest = new _Cause("use latest");

	/// The incompatibility indicates that the package has no versions that
	/// match the given constraint.
	static const IncompatibilityCause noVersions = new _Cause("no versions");

	/// The incompatibility indicates that the package has an unknown source.
	static const IncompatibilityCause unknownSource =
		new _Cause("unknown source");
}

/// The incompatibility was derived from two existing incompatibilities during
/// conflict resolution.
class ConflictCause : IncompatibilityCause {
	/// The incompatibility that was originally found to be in conflict, from
	/// which the target incompatibility was derived.
	const Incompatibility conflict;

	/// The incompatibility that caused the most recent satisfier for [conflict],
	/// from which the target incompatibility was derived.
	const Incompatibility other;

	this(Incompatibility conflict, Incompatibility other) {
		this.conflict = conflict;
		this.other = other;
	}
}

/// A class for stateless [IncompatibilityCause]s.
class _Cause : IncompatibilityCause {
	const string name;

	this(string name) {
		this.name = name;
	}
}

/// The incompatibility represents a package that couldn't be found by its
/// source.
class PackageNotFoundCause : IncompatibilityCause {
	/// The exception indicating why the package couldn't be found.
	Exception exception;

	this(Exception exception) {
		this.exception = exception;
	}
}

struct Incompatibility {
	Term[] terms;
	IncompatibilityCause cause;

	static Incompatibility opCall(Term[] terms, IncompatibilityCause cause) {
		Incompatibility ret;

		if(terms.length != 1
				&& (cast(ConflictCause)cause) !is null
				&& terms.any!(t => t.isPositive == IsPositive.yes
						&& t.isRootPackage == IsRootPackage.yes))
		{
			terms = terms
				.filter!(t => t.isPositive == IsPositive.no
						&& t.isRootPackage == IsRootPackage.no)
				.array;
		}

		if(terms.length == 1
				|| (terms.length == 2
					&& terms[0].pkg.pkg.name == terms[1].pkg.pkg.name))
		{
			ret.terms = terms;
			ret.cause = cause;
			return ret;
		}

		Term[string] byName;
		foreach(term; terms) {
			Term* fromAA = term.pkg.pkg.name in byName;
			if(fromAA is null) {
				byName[term.pkg.pkg.name] = term;
			} else {
				Nullable!Term inter = intersectionOf(*fromAA, term);
				enforce(!inter.isNull, format("the following terms where "
							~ "expected to intersect\na: %s\nb: %s"
							, *fromAA, term));
				Term interNN = inter.get();
				byName[interNN.pkg.pkg.name] = interNN;
			}
		}


		ret.terms = terms;
		ret.cause = cause;
		return ret;
	}
}
