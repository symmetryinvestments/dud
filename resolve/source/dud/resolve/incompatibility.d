module dud.resolve.incompatibility;

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
}
