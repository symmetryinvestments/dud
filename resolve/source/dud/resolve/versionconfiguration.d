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

SetRelation relation(const(Conf) a, const(Conf) b) pure {
	return allowsAll(b, a)
		? SetRelation.subset
		: allowsAny(b, a)
			? SetRelation.overlapping
			: SetRelation.disjoint;

	/*if(a.conf == b.conf && a.conf.empty) {
		return SetRelation.subset;
	}

	if(a.conf != b.conf
			&& !a.conf.empty && !b.conf.empty
			&& !a.not && !b.not)
	{
		return SetRelation.disjoint;
	}

	if(a.conf == b.conf && !a.conf.empty && a.not != b.not) {
		return SetRelation.disjoint;
	}

	if(a.conf == b.conf && a.not == b.not) {
		return SetRelation.subset;
	}

	if(!a.conf.empty && !b.conf.empty
			&& a.conf != b.conf
			&& a.not != b.not)
	{
		return SetRelation.overlapping;
	}

	if(!a.conf.empty && !b.conf.empty
			&& a.conf != b.conf
			&& a.not == b.not
			&& a.not)
	{
		return SetRelation.overlapping;
	}

	if(a.conf.empty && !b.conf.empty) {
		return SetRelation.overlapping;
	}

	if(!a.conf.empty && b.conf.empty) {
		return SetRelation.subset;
	}

	assert(false, format("a %s, b %s", a, b));
*/
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

@safe pure unittest {
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
		//relation(a.ver, b.ver);
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

/// Ditto
SetRelation relation(const(VersionConfiguration) a,
		const(VersionConfiguration[2]) other) pure
{
	return relation(a, other[0], other[1]);
}

/// Ditto
SetRelation relation(const(VersionConfiguration) a,
		const(VersionConfiguration) b, const(VersionConfiguration) c) pure
{
	const SetRelation ab = relation(a, b);
	const SetRelation ac = relation(a, c);

	//debug {
	//	const SetRelation bc = relation(b, c);
	//	enforce(bc == SetRelation.disjoint, format(
	//		"\nb: %s\nc: %s must be disjoint", b, c));
	//}

	//debug writefln("ab %s, ac %s", ab, ac);

	if(ab == ac) {
		return ab;
	}

	if(ab == SetRelation.subset || ac == SetRelation.subset) {
		return SetRelation.subset;
	}

	if(ab == SetRelation.overlapping || ac == SetRelation.overlapping) {
		return SetRelation.overlapping;
	}

	assert(false, format("\na: %s\nb: %s\nc: %s", a, b, c));
}


VersionConfiguration invert(const(VersionConfiguration) vs) {
	return VersionConfiguration(vs.ver.invert(), invert(vs.conf));
}

__EOF__

unittest {
	SemVer a = parseSemVer("1.0.0");
	SemVer b = parseSemVer("2.0.0");
	auto v1 = VersionConfiguration(VersionRange(a, Inclusive.yes, b,
				Inclusive.yes), Conf(""));

	VersionConfiguration[2] v1Inv = v1.invert();
	assert(v1Inv[0].ver.low == parseSemVer("0.0.0"), format("%s", v1Inv[0]));
	assert(v1Inv[0].ver.inclusiveLow == Inclusive.yes, format("%s", v1Inv[0]));
	assert(v1Inv[0].ver.high == parseSemVer("1.0.0"), format("%s", v1Inv[0]));
	assert(v1Inv[0].ver.inclusiveHigh == Inclusive.no, format("%s", v1Inv[0]));
	assert(v1Inv[0].conf.isNot == true, format("%s", v1Inv[0]));

	assert(v1Inv[1].ver.low == parseSemVer("2.0.0"), format("%s", v1Inv[1]));
	assert(v1Inv[1].ver.inclusiveLow == Inclusive.no, format("%s", v1Inv[1]));
	assert(v1Inv[1].ver.high == SemVer.MaxRelease, format("%s", v1Inv[1]));
	assert(v1Inv[1].ver.inclusiveHigh == Inclusive.yes, format("%s", v1Inv[1]));
	assert(v1Inv[1].conf.isNot == true, format("%s", v1Inv[1]));
}

unittest {
	SemVer a = parseSemVer("1.0.0");
	SemVer b = parseSemVer("2.0.0");
	auto v1 = VersionConfiguration(VersionRange(a, Inclusive.yes, b,
				Inclusive.no), Conf(""));

	VersionConfiguration[2] v1Inv = v1.invert();
	assert(v1Inv[0].ver.low == parseSemVer("0.0.0"), format("%s", v1Inv[0]));
	assert(v1Inv[0].ver.inclusiveLow == Inclusive.yes, format("%s", v1Inv[0]));
	assert(v1Inv[0].ver.high == parseSemVer("1.0.0"), format("%s", v1Inv[0]));
	assert(v1Inv[0].ver.inclusiveHigh == Inclusive.no, format("%s", v1Inv[0]));
	assert(v1Inv[1].conf.isNot == true, format("%s", v1Inv[0]));

	assert(v1Inv[1].ver.low == parseSemVer("2.0.0"), format("%s", v1Inv[1]));
	assert(v1Inv[1].ver.inclusiveLow == Inclusive.yes, format("%s", v1Inv[1]));
	assert(v1Inv[1].ver.high == SemVer.MaxRelease, format("%s", v1Inv[1]));
	assert(v1Inv[1].ver.inclusiveHigh == Inclusive.yes, format("%s", v1Inv[1]));
	assert(v1Inv[1].conf.isNot == true, format("%s", v1Inv[1]));
}

private void test(const VersionConfiguration a,
		const(VersionConfiguration[2]) o, const SetRelation exp)
{
	SetRelation sr = relation(a, o);
	assert(sr == exp, format(
		"\ngot: %s\nexp: %s\na: %s\nb: %s\nc: %s", sr, exp, a, o[0], o[1]));
}

unittest {
	SemVer a = parseSemVer("0.0.0");
	SemVer b = parseSemVer("1.0.0");
	SemVer c = parseSemVer("2.0.0");
	SemVer d = parseSemVer("3.0.0");

	auto v1 = VersionConfiguration(
			VersionRange(b, Inclusive.yes, c, Inclusive.no),
			Conf(""));

	auto notV1 = v1.invert();
	test(v1, notV1, SetRelation.disjoint);

	auto v2 = VersionConfiguration(
			VersionRange(a, Inclusive.yes, b, Inclusive.yes),
			Conf(""));
	test(v2, notV1, SetRelation.overlapping);

	auto v3 = VersionConfiguration(
			VersionRange(c, Inclusive.yes, d, Inclusive.yes),
			Conf(""));
	test(v3, notV1, SetRelation.subset);
}

unittest {
	SemVer a = parseSemVer("0.0.0");
	SemVer b = parseSemVer("1.0.0");
	SemVer c = parseSemVer("2.0.0");
	SemVer d = parseSemVer("3.0.0");
	SemVer e = parseSemVer("4.0.0");

	auto v1 = VersionConfiguration(
			VersionRange(a, Inclusive.yes, b, Inclusive.yes),
			Conf("conf1"));

	auto notV1 = v1.invert();
	test(v1, notV1, SetRelation.disjoint);

	foreach(end; [c, d, e]) {
		auto v2 = VersionConfiguration(
				VersionRange(b, Inclusive.yes, end, Inclusive.yes),
				Conf(""));

		test(v2, notV1, SetRelation.overlapping);
	}
}

unittest {
	SemVer a = parseSemVer("0.0.0");
	SemVer b = parseSemVer("1.0.0");
	SemVer c = parseSemVer("2.0.0");
	SemVer d = parseSemVer("3.0.0");
	SemVer e = parseSemVer("4.0.0");

	auto v1 = VersionConfiguration(
			VersionRange(b, Inclusive.yes, c, Inclusive.yes),
			Conf("conf1"));

	auto notV1 = v1.invert();
	test(v1, notV1, SetRelation.disjoint);

	auto v2 = VersionConfiguration(
			VersionRange(a, Inclusive.yes, b, Inclusive.yes),
			Conf(""));

	test(v2, notV1, SetRelation.overlapping);

	auto v3 = VersionConfiguration(
			VersionRange(a, Inclusive.yes, b, Inclusive.no),
			Conf(""));
	test(v3, notV1, SetRelation.overlapping);

	auto v4 = VersionConfiguration(
			VersionRange(a, Inclusive.yes, b, Inclusive.no),
			Conf("!conf1"));

	test(v4, notV1, SetRelation.subset);

	auto v5 = VersionConfiguration(
			VersionRange(d, Inclusive.no, e, Inclusive.no),
			Conf(""));

	test(v5, notV1, SetRelation.overlapping);

	auto v6 = VersionConfiguration(
			VersionRange(d, Inclusive.no, e, Inclusive.no),
			Conf("!conf1"));

	test(v6, notV1, SetRelation.subset);

	auto v7 = VersionConfiguration(
			VersionRange(b, Inclusive.no, c, Inclusive.no),
			Conf("!conf1"));

	test(v7, notV1, SetRelation.disjoint);
}

unittest {
	SemVer a = parseSemVer("0.0.0");
	SemVer b = parseSemVer("1.0.0");
	SemVer c = parseSemVer("2.0.0");
	SemVer d = parseSemVer("3.0.0");
	SemVer e = parseSemVer("4.0.0");

	auto sms = [a, b, c, d, e];
	auto confs = ["", "!", "conf1", "conf2", "!conf1", "!conf2"];
	auto incs = [Inclusive.no, Inclusive.yes];

	VersionConfiguration[] verConfs;
	foreach(idx, sm0; sms[0 .. $ - 1]) {
		foreach(sm1; sms[idx .. idx + 1]) {
			foreach(conf; confs) {
				foreach(inc0; incs) {
					foreach(inc1; incs) {
						verConfs ~= VersionConfiguration(
								VersionRange(sm0, inc0, sm1, inc1),
								Conf(conf)
							);
					}
				}
			}
		}
	}

	foreach(ver0; verConfs) {
		foreach(ver1; verConfs) {
			auto sr = relation(ver0, ver1);
			if(!ver1.conf.conf.empty && ver0.conf != ver1.conf) {
				assert(sr == SetRelation.disjoint
						|| sr == SetRelation.overlapping,
					format("\ngot: %s\nver0: %s\nver1: %s", sr, ver0, ver1));
			}
		}

		auto notVer0 = ver0.invert();
		foreach(ver1; verConfs) {
			relation(ver1, notVer0);
		}
	}
}
