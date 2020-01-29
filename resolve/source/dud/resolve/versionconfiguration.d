module dud.resolve.versionconfiguration;

import std.array : empty;
import std.stdio;
import std.exception : enforce;
import std.array : empty;
import std.format : format;
import dud.semver.semver;
import dud.semver.parse;
import dud.semver.checks : allowsAll, allowsAny;
import dud.semver.versionrange;
import dud.semver.versionunion;
import dud.semver.setoperation : invert;
import dud.resolve.conf : Conf, allowsAll, allowsAny, invert;
import dud.resolve.positive;

@safe pure:

/** The algebraic datatype that stores a version range and a configuration
*/
struct VersionConfiguration {
	VersionUnion ver;
	Conf conf;
}

VersionConfiguration dup(const(VersionConfiguration) old) {
	return VersionConfiguration(old.ver.dup, old.conf);
}

SetRelation relation(const(Conf) a, const(Conf) b) pure {
	return allowsAll(b, a)
		? SetRelation.subset
		: allowsAny(b, a)
			? SetRelation.overlapping
			: SetRelation.disjoint;
}

unittest {
	Conf nc1 = Conf("", IsPositive.yes);
	Conf nc2 = Conf("conf1", IsPositive.yes);
	Conf nc3 = Conf("conf1", IsPositive.no);
	Conf nc4 = Conf("conf2", IsPositive.yes);
	Conf nc5 = Conf("conf2", IsPositive.no);
	Conf nc6 = Conf("", IsPositive.no);

	SetRelation sr = relation(nc1, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	// nc1 a

	sr = relation(nc1, nc2);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc1, nc3);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc1, nc4);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc1, nc5);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc1, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc1 b

	sr = relation(nc2, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc3, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc4, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc5, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc6, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	// nc2

	sr = relation(nc2, nc2);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc2, nc3);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc2, nc4);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc2, nc5);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc2, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc2 b

	sr = relation(nc3, nc2);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc4, nc2);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc5, nc2);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc6, nc2);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc3

	sr = relation(nc3, nc4);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc3, nc5);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc3, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc3 b

	sr = relation(nc1, nc3);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc2, nc3);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc3, nc3);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc4, nc3);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc5, nc3);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc6, nc3);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc4

	sr = relation(nc4, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc4, nc2);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc4, nc3);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc4, nc4);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc4, nc5);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc4, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc4 b

	sr = relation(nc1, nc4);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc2, nc4);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc3, nc4);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc4, nc4);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc5, nc4);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc6, nc4);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc5

	sr = relation(nc5, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc5, nc2);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc5, nc3);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc5, nc4);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc5, nc5);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc5, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc5 b

	sr = relation(nc1, nc5);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc2, nc5);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc3, nc5);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc4, nc5);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc5, nc5);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc6, nc5);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc6

	sr = relation(nc6, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc6, nc2);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc6, nc3);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc6, nc4);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc6, nc5);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc6, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	// nc6 b

	sr = relation(nc1, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc2, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc3, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc4, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc5, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc6, nc6);
	assert(sr == SetRelation.disjoint, format("%s", sr));
}

unittest {
	Conf[] tt;
	foreach(c1; ["", "conf", "conf2", "conf3"]) {
		foreach(c2; [IsPositive.no, IsPositive.yes]) {
			tt ~= Conf(c1, c2);
		}
	}

	foreach(it; tt) {
		foreach(jt; tt) {
			relation(it, jt);
		}
	}
}

/** Return if a is a subset of b, or if a and b are disjoint, or
if a and b overlap
*/
SetRelation relation(const(VersionConfiguration) a,
		const(VersionConfiguration) b) pure
{
	const SetRelation ver = allowsAll(b.ver, a.ver)
		? SetRelation.subset
		: allowsAny(b.ver, a.ver)
			? SetRelation.overlapping
			: SetRelation.disjoint;

	const SetRelation conf = relation(a.conf, b.conf);

	//debug writefln("ver %s, conf %s", ver, conf);
	if(ver == SetRelation.disjoint || conf == SetRelation.disjoint) {
		return SetRelation.disjoint;
	}

	if(ver == SetRelation.overlapping || conf == SetRelation.overlapping) {
		return SetRelation.overlapping;
	}

	if(ver == SetRelation.subset && conf == SetRelation.subset) {
		return SetRelation.subset;
	}

	assert(false, format("a: %s, b: %s", a, b));
}

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

VersionConfiguration invert(const(VersionConfiguration) vs) {
	return VersionConfiguration(
			invert(vs.ver),
			invert(vs.conf));
}

unittest {
	auto v1 = VersionConfiguration(
			VersionUnion([ parseVersionRange(">=1.0.0").get() ]),
			Conf("")
		);

	auto v2 = v1.invert();
	assert(relation(v1, v2) == SetRelation.disjoint);
}
