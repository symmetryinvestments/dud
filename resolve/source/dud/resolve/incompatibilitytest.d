module dud.resolve.incompatibilitytest;

import std.array : empty;
import std.format : format;

import dud.resolve.conf;
import dud.resolve.confs;
import dud.resolve.incompatibility;
import dud.resolve.positive;
import dud.resolve.term;
import dud.resolve.versionconfigurationtoolchain;
import dud.semver.versionrange;
import dud.semver.versionunion;

unittest {
	Term t1;
	t1.pkg.pkg.name = "Foo";
	t1.isPositive = IsPositive.yes;
	t1.constraint = VersionConfigurationToolchain(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ]),
			Confs([Conf("", IsPositive.yes)])
		);

	Term t2;
	t2.pkg.pkg.name = "Foo";
	t2.isPositive = IsPositive.yes;
	t2.constraint = VersionConfigurationToolchain(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ]),
			Confs([Conf("", IsPositive.yes)])
		);

	auto i = Incompatibility([t1, t2]);
	auto ir = resolve(i);
	assert(!ir.isNull());
	auto irNN = ir.get();
	assert(irNN.terms.length == 1, format("%s", irNN));
	assert(irNN.terms[0] == t1, format("\n%s\n%s", irNN.terms[0], t1));
}

unittest {
	Term t1;
	t1.pkg.pkg.name = "Foo";
	t1.isPositive = IsPositive.yes;
	t1.constraint = VersionConfigurationToolchain(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ]),
			Confs([Conf("", IsPositive.yes)])
		);

	Term t2;
	t2.pkg.pkg.name = "Bar";
	t2.isPositive = IsPositive.no;
	t2.constraint = VersionConfigurationToolchain(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ]),
			Confs([Conf("", IsPositive.yes)])
		);

	auto i = Incompatibility([t1, t2]);
	auto ir = resolve(i);
	assert(!ir.isNull());
	auto irNN = ir.get();
	assert(irNN.terms.length == 2, format("%s", irNN));
}

unittest {
	Term t1;
	t1.pkg.pkg.name = "Foo";
	t1.isPositive = IsPositive.yes;
	t1.constraint = VersionConfigurationToolchain(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ]),
			Confs([Conf("", IsPositive.yes)])
		);

	Term t2;
	t2.pkg.pkg.name = "Foo";
	t2.isPositive = IsPositive.no;
	t2.constraint = VersionConfigurationToolchain(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ]),
			Confs([Conf("", IsPositive.yes)])
		);

	auto i = Incompatibility([t1, t2]);
	auto ir = resolve(i);
	assert(ir.isNull(), format("%s", ir.get()));
}
