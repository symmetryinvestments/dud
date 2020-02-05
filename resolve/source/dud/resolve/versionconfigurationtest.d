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

unittest {
	SemVer a = parseSemVer("1.0.0");
	SemVer b = parseSemVer("2.0.0");
	SemVer c = parseSemVer("3.0.0");

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

	auto r = relation(v1, v2);
	assert(r == SetRelation.overlapping, format("%s", r));

	r = relation(v1, v3);
	assert(r == SetRelation.subset, format("%s", r));

	r = relation(v2, v4);
	assert(r == SetRelation.disjoint, format("%s", r));

	r = relation(v1, v4);
	assert(r == SetRelation.overlapping, format("%s", r));
}

unittest {
	SemVer a = parseSemVer("1.0.0");
	SemVer b = parseSemVer("2.0.0");
	SemVer c = parseSemVer("3.0.0");

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
	testRelation(v2, v2, SetRelation.subset);
	testRelation(v2, v3, SetRelation.subset);
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
