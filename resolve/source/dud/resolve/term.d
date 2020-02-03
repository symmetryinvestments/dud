module dud.resolve.term;

import std.exception : enforce;

import dud.semver.versionrange;
import dud.semver.checks;
import dud.semver.versionunion;
import dud.pkgdescription;
import dud.resolve.versionconfiguration : VersionConfiguration;
import dud.resolve.providier;
import dud.resolve.positive;
import dud.resolve.conf;

@safe pure:
struct Term {
	VersionConfiguration constraint;
	PackageDescriptionVersionRange pkg;
	IsPositive isPositive;
}

Term invert(const(Term) t) {
	VersionConfiguration vc = t.constraint.invert();
	return Term(vc, t.pkg.dup(), cast(IsPositive)!t.isPositive);
}

bool satisfies(const(Term) that, const(Term) other) {
	return that.pkg.pkg.name == other.pkg.pkg.name
		&& relation(other, that) == SetRelation.subset;
}

unittest {
	Term t1;
	t1.pkg.ver = parseVersionRange("1.2.3").get();
	t1.isPositive = IsPositive.yes;
	t1.constraint = VersionConfiguration(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ]),
			Conf("")
		);

	Term t2 = t1.invert();
	assert(!allowsAny(t1.constraint.ver, t2.constraint.ver));
}

SetRelation relation(const(Term) a, const(Term) b) {
	assert(false);
}
