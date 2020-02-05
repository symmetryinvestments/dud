module dud.resolve.versionconfigurationtest;

import dud.resolve.versionconfiguration;
import dud.resolve.conf;
import dud.resolve.positive;
import dud.semver.semver;
import dud.semver.setoperation;
import dud.semver.parse;
import dud.semver.versionunion;
import dud.semver.versionrange;

@safe pure:
import std.format : format;

/// Ditto
unittest {
	SemVer a = parseSemVer("1.0.0");
	SemVer b = parseSemVer("2.0.0");
	SemVer c = parseSemVer("3.0.0");

	auto v1 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.yes)])
				, Conf("")
			);
	auto v2 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.no)])
				, Conf("")
			);
	auto v3 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, c, Inclusive.no)])
				, Conf("")
			);
	auto v4 = VersionConfiguration(
			VersionUnion([VersionRange(b, Inclusive.yes, c, Inclusive.no)])
				, Conf("")
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

/// Ditto
unittest {
	SemVer a = parseSemVer("1.0.0");
	SemVer b = parseSemVer("2.0.0");
	SemVer c = parseSemVer("3.0.0");

	auto v1 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.yes)]),
			Conf("conf1"));
	auto v2 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.no)]),
			Conf(""));
	auto v3 = VersionConfiguration(
			VersionUnion([VersionRange(a, Inclusive.yes, b, Inclusive.yes)]),
			Conf("conf2"));

	auto r = relation(v1, v2);
	assert(r == SetRelation.overlapping, format("%s", r));

	r = relation(v1, v1);
	assert(r == SetRelation.subset, format("%s", r));

	r = relation(v1, v3);
	assert(r == SetRelation.disjoint, format("%s", r));

	r = relation(v2, v3);
	assert(r == SetRelation.overlapping, format("%s", r));

	r = relation(v2, v2);
	assert(r == SetRelation.subset, format("%s", r));

	r = relation(v3, v3);
	assert(r == SetRelation.subset, format("%s", r));
}

unittest {
	auto v1 = VersionConfiguration(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ]),
			Conf("")
		);

	auto v2 = v1.invert();
	assert(relation(v1, v2) == SetRelation.disjoint);
}
