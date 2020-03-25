module dud.resolve.versionconfigurationtest;

@safe pure:

import dud.resolve.versionconfiguration;
import dud.resolve.conf;
import dud.resolve.confs;
import dud.resolve.positive;
import dud.semver.semver;
import dud.semver.setoperation;
import dud.semver.parse;
import dud.semver.versionunion;
import dud.semver.versionrange;

import std.format : format;
import std.stdio;

private:

immutable SemVer s10 = SemVer(1,0,0);
immutable SemVer s15 = SemVer(1,5,0);
immutable SemVer s20 = SemVer(2,0,0);
immutable SemVer s25 = SemVer(2,5,0);
immutable SemVer s30 = SemVer(3,0,0);

immutable Conf c1 = Conf("", IsPositive.yes);
immutable Conf c2 = Conf("", IsPositive.no);
immutable Conf c3 = Conf("foo", IsPositive.yes);
immutable Conf c4 = Conf("foo", IsPositive.no);
immutable Conf c5 = Conf("bar", IsPositive.yes);
immutable Conf c6 = Conf("bar", IsPositive.no);

immutable vc1 = VersionConfiguration(
		VersionUnion([VersionRange(s15, Inclusive.yes, s25, Inclusive.yes)]),
		Confs([c1, c3])
	);

immutable vc2 = VersionConfiguration(
		VersionUnion([VersionRange(s15, Inclusive.yes, s25, Inclusive.yes)]),
		Confs([c3])
	);

immutable vc3 = VersionConfiguration(
		VersionUnion([VersionRange(s15, Inclusive.yes, s25, Inclusive.yes)]),
		Confs([c1])
	);

immutable vc4 = VersionConfiguration(
		VersionUnion([VersionRange(s20, Inclusive.yes, s30, Inclusive.yes)]),
		Confs([c1, c3])
	);

immutable vc5 = VersionConfiguration(
		VersionUnion([VersionRange(s10, Inclusive.yes, s15, Inclusive.yes)]),
		Confs([c1, c3])
	);

immutable vc6 = VersionConfiguration(
		VersionUnion([VersionRange(s25, Inclusive.yes, s30, Inclusive.yes)]),
		Confs([c1, c3])
	);

// allowsAny
unittest {
	assert(allowsAny(vc1, vc2));
	assert(!allowsAny(vc5, vc6));
}


/+
void testRelation(const(VersionConfiguration) a, const(VersionConfiguration) b,
		const(SetRelation) exp, int line = __LINE__)
{
	import std.exception : enforce;
	import core.exception : AssertError;
	const(SetRelation) rslt = relation(a, b);
	enforce!AssertError(rslt == exp,
		format("\na: %s\nb: %s\nexp: %s\nrsl: %s", a, b, exp, rslt),
		__FILE__, line);

}

unittest {
	auto v1 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.yes)])
				, Confs([Conf("", IsPositive.yes)])
			);
	auto v2 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.no)])
				, Confs([Conf("", IsPositive.yes)])
			);
	auto v3 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, c, Inclusive.no)])
				, Confs([Conf("", IsPositive.yes)])
			);
	auto v4 = VersionConfiguration(
			VersionUnion([VersionRange(b, Inclusive.yes, c, Inclusive.no)])
				, Confs([Conf("", IsPositive.yes)])
			);

	testRelation(v1, v2, SetRelation.overlapping);
	testRelation(v1, v3, SetRelation.subset);
	testRelation(v2, v4, SetRelation.disjoint);
	testRelation(v1, v4, SetRelation.overlapping);
}

__EOF__

unittest {
	auto v1 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.yes)])
			, Confs([Conf("conf1", IsPositive.yes)]));
	auto v2 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.no)])
			, Confs([Conf("", IsPositive.yes)]));
	auto v3 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.yes)])
			, Confs([Conf("conf2", IsPositive.yes)]));

	testRelation(v1, v1, SetRelation.subset);
	testRelation(v1, v2, SetRelation.overlapping);
	testRelation(v1, v3, SetRelation.disjoint);

	testRelation(v2, v1, SetRelation.subset);
	testRelation(v2, v2, SetRelation.subset);
	testRelation(v2, v3, SetRelation.subset);

	testRelation(v3, v1, SetRelation.disjoint);
	testRelation(v3, v2, SetRelation.overlapping);
	testRelation(v3, v3, SetRelation.subset);
}

unittest {
	auto v1 = VersionConfiguration(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ])
			, Confs([Conf("", IsPositive.yes)])
		);

	auto v2 = v1.invert();
	assert(relation(v1, v2) == SetRelation.disjoint);
}

unittest {
	auto v1 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, e, Inclusive.yes)])
			, Confs([Conf("conf1", IsPositive.yes)]));
	auto v2 = VersionConfiguration(
			VersionUnion([VersionRange(b, Inclusive.yes, c, Inclusive.no)])
			, Confs([Conf("", IsPositive.yes)]));

	auto v12 = intersectionOf(v1, v2);
	debug writeln(v12);
	testRelation(v1, v12, SetRelation.overlapping);
	testRelation(v2, v12, SetRelation.overlapping);

	auto v3 = VersionConfiguration(
			VersionUnion([VersionRange(d, Inclusive.yes, e, Inclusive.no)])
			, Confs([Conf("conf1", IsPositive.yes)]));
	testRelation(v3, v12, SetRelation.subset);
	testRelation(v12, v3, SetRelation.subset);
}
+/
