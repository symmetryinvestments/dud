module dud.resolve.termtest;

import std.format : format;

import dud.resolve.conf;
import dud.resolve.confs;
import dud.resolve.positive;
import dud.resolve.term;
import dud.resolve.versionconfigurationtoolchain : VersionConfigurationToolchain;
import dud.semver.checks;
import dud.semver.versionrange;
import dud.semver.versionunion;

@safe pure:

unittest {
	Term t1;
	t1.pkg.ver = parseVersionRange("1.2.3").get();
	t1.isPositive = IsPositive.yes;
	t1.constraint = VersionConfigurationToolchain(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ]),
			Confs([Conf("", IsPositive.yes)])
		);

	assert(satisfies(t1, t1));

	Term t2 = t1.invert();

	// Inverting does also invert isPositive which yields another inversion when
	// running statisfies
	t2.isPositive = IsPositive.yes;
	assert(!allowsAny(t1.constraint.ver, t2.constraint.ver));
	assert(!satisfies(t1, t2), format("\nt1: %s\nt2: %s", t1, t2));
}

private void testRelation(const(Term) a, const(Term) b, const(SetRelation) exp
		, int line = __LINE__)
{
	import core.exception : AssertError;
	import std.exception : enforce;
	import std.format : format;

	const(SetRelation) rslt = relation(a, b);
	enforce!AssertError(rslt == exp,
		format("\na: %s\nb: %s\nexp: %s\nrsl: %s", a, b, exp, rslt),
		__FILE__, line);

}

unittest {
	Term t1;
	t1.isPositive = IsPositive.yes;
	t1.constraint = VersionConfigurationToolchain(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ]),
			Confs([Conf("", IsPositive.yes)])
		);

	Term t2;
	t2.isPositive = IsPositive.no;
	t2.constraint = VersionConfigurationToolchain(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ]),
			Confs([Conf("", IsPositive.yes)])
		);

	testRelation(t1, t2, SetRelation.disjoint);
}

unittest {
	Term t1;
	t1.isPositive = IsPositive.yes;
	t1.constraint = VersionConfigurationToolchain(
			VersionUnion([ parseVersionRange("1.0.0").get() ]),
			Confs([Conf("", IsPositive.yes)])
		);

	Term t2;
	t2.isPositive = IsPositive.no;
	t2.constraint = VersionConfigurationToolchain(
			VersionUnion([ parseVersionRange("<1.0.0").get() ]),
			Confs([Conf("", IsPositive.yes)])
		);

	testRelation(t1, t2, SetRelation.disjoint);
}
