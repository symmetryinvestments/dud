module dud.resolve.term;

import std.exception : enforce;
import std.typecons : Nullable, nullable;
debug import std.stdio;

import dud.pkgdescription;
import dud.semver.versionrange : SetRelation;
import dud.resolve.versionconfigurationtoolchain : invert
	   , VersionConfigurationToolchain;
import dud.resolve.providier;
import dud.resolve.positive;
import dud.resolve.conf;
import dud.resolve.confs;

@safe pure:
struct Term {
@safe pure:
	VersionConfigurationToolchain constraint;
	PackageDescriptionVersionRange pkg;

	/// is only an indicator `contraint` is used to store both stats
	IsPositive isPositive;

	string toString() const {
		import std.format : format;
		return format("Term(%s, %s, %s)", this.pkg.pkg.name
				, this.isPositive, this.constraint);
	}
}

Term invert(const(Term) t) {
	VersionConfigurationToolchain vc = t.constraint.invert();
	return Term(vc, t.pkg.dup(), cast(IsPositive)!t.isPositive);
}

bool satisfies(const(Term) that, const(Term) other) {
	return that.pkg.pkg.name == other.pkg.pkg.name
		&& relation(other, that) == SetRelation.subset;
}

SetRelation relation(const(Term) that, const(Term) other) {
	enforce(that.pkg.pkg.name == other.pkg.pkg.name);

	debug writefln("that: %3s other: %3s", that.isPositive, other.isPositive);
	const(Term) that2 = that.isPositive
		? that
		: that.invert();

	const(Term) other2 = other.isPositive
		? other
		: other.invert();

	return dud.resolve.versionconfigurationtoolchain.relation(that2.constraint
			, other2.constraint);
}

Nullable!(Term) intersectionOf(const(Term) a, const(Term) b) {
	const(VersionConfigurationToolchain) a2 = a.isPositive
		? a.constraint
		: dud.resolve.versionconfigurationtoolchain.invert(a.constraint);

	const(VersionConfigurationToolchain) b2 = b.isPositive
		? b.constraint
		: dud.resolve.versionconfigurationtoolchain.invert(b.constraint);

	VersionConfigurationToolchain r = dud.resolve.versionconfigurationtoolchain
		.intersectionOf(a2, b2);

	return r.conf.confs.empty || r.ver.ranges.empty
		? Nullable!(Term).init
		: nullable(Term(r, a.pkg, IsPositive.yes));
}
