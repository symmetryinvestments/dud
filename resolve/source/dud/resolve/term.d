module dud.resolve.term;

import std.exception : enforce;

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
	VersionConfigurationToolchain constraint;
	PackageDescriptionVersionRange pkg;

	/// is only an indicator `contraint` is used to store both stats
	IsPositive isPositive;
}

Term invert(const(Term) t) {
	VersionConfigurationToolchain vc = t.constraint.invert();
	return Term(vc, t.pkg.dup(), cast(IsPositive)!t.isPositive);
}

bool satisfies(const(Term) that, const(Term) other) {
	return that.pkg.pkg.name == other.pkg.pkg.name
		&& relation(other, that) == SetRelation.subset;
}

SetRelation relation(const(Term) a, const(Term) b) {
	static import dud.resolve.versionconfigurationtoolchain;
	enforce(a.pkg.pkg.name == b.pkg.pkg.name);
	return dud.resolve.versionconfigurationtoolchain.relation(
			a.constraint, b.constraint);
}
