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

immutable SemVer a = parseSemVer("1.0.0");
immutable SemVer b = parseSemVer("2.0.0");
immutable SemVer c = parseSemVer("3.0.0");
immutable SemVer d = parseSemVer("1.5.0");
immutable SemVer e = parseSemVer("2.5.0");

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

__EOF__

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
