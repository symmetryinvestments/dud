module dud.resolve.termtest;

import dud.resolve.term;
import dud.resolve.positive;
import dud.resolve.confs;
import dud.resolve.conf;
import dud.resolve.versionconfigurationtoolchain : VersionConfigurationToolchain;

unittest {
	import dud.semver.versionrange;
	import dud.semver.versionunion;
	import dud.semver.checks;

	Term t1;
	t1.pkg.ver = parseVersionRange("1.2.3").get();
	t1.isPositive = IsPositive.yes;
	t1.constraint = VersionConfigurationToolchain(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ]),
			Confs([Conf("", IsPositive.yes)])
		);

	Term t2 = t1.invert();
	assert(!allowsAny(t1.constraint.ver, t2.constraint.ver));
}
