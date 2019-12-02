module dud.resolve.versionconfiguration;

import std.stdio;
import std.exception : enforce;
import std.array : empty;
import std.format : format;
import dud.semver;
import dud.pkgdescription.versionspecifier;

@safe:

struct NotConf {
@safe pure:
	/// empty means wildcard
	string conf;
	/// true means the inverse of the `conf` inverse of `conf.empty`
	/// still means wildcard
	bool isNot;

	this(string s) {
		import std.algorithm.searching : startsWith;
		const bool sw = s.startsWith("!");
		s = sw ? s[1 .. $] : s;
		this(s, sw);
	}

	this(string s, bool b) {
		this.conf = s;
		this.isNot = b;
	}
}

SetRelation relation(const(NotConf) a, const(NotConf) b) pure {
	if(a.conf == b.conf && a.conf.empty) {
		return SetRelation.subset;
	}

	if(a.conf != b.conf
			&& !a.conf.empty && !b.conf.empty
			&& !a.isNot && !b.isNot)
	{
		return SetRelation.disjoint;
	}

	if(a.conf == b.conf && !a.conf.empty && a.isNot != b.isNot) {
		return SetRelation.disjoint;
	}

	if(a.conf == b.conf && a.isNot == b.isNot) {
		return SetRelation.subset;
	}

	if(!a.conf.empty && !b.conf.empty
			&& a.conf != b.conf
			&& a.isNot != b.isNot)
	{
		return SetRelation.overlapping;
	}

	if(!a.conf.empty && !b.conf.empty
			&& a.conf != b.conf
			&& a.isNot == b.isNot
			&& a.isNot)
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
}

unittest {
	NotConf nc1 = NotConf("");
	NotConf nc2 = NotConf("conf1");
	NotConf nc3 = NotConf("!conf1");
	NotConf nc4 = NotConf("conf2");
	NotConf nc5 = NotConf("!conf2");
	NotConf nc6 = NotConf("!");

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
	assert(sr == SetRelation.subset, format("%s", sr));

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
	assert(sr == SetRelation.subset, format("%s", sr));

	// nc2 b

	sr = relation(nc3, nc2);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc4, nc2);
	assert(sr == SetRelation.disjoint, format("%s", sr));

	sr = relation(nc5, nc2);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc6, nc2);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	// nc3

	sr = relation(nc3, nc4);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc3, nc5);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc3, nc6);
	assert(sr == SetRelation.subset, format("%s", sr));

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
	assert(sr == SetRelation.overlapping, format("%s", sr));

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
	assert(sr == SetRelation.subset, format("%s", sr));

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
	assert(sr == SetRelation.overlapping, format("%s", sr));

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
	assert(sr == SetRelation.subset, format("%s", sr));

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
	assert(sr == SetRelation.overlapping, format("%s", sr));

	// nc6

	sr = relation(nc6, nc1);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc6, nc2);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc6, nc3);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc6, nc4);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc6, nc5);
	assert(sr == SetRelation.overlapping, format("%s", sr));

	sr = relation(nc6, nc6);
	assert(sr == SetRelation.subset, format("%s", sr));

	// nc6 b

	sr = relation(nc1, nc6);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc2, nc6);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc3, nc6);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc4, nc6);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc5, nc6);
	assert(sr == SetRelation.subset, format("%s", sr));

	sr = relation(nc6, nc6);
	assert(sr == SetRelation.subset, format("%s", sr));
}

@safe pure unittest {
	NotConf[] tt;
	foreach(c1; ["", "conf", "conf2", "conf3"]) {
		foreach(c2; ["", "!"]) {
			tt ~= NotConf(c2 ~ c1);
		}
	}

	foreach(it; tt) {
		foreach(jt; tt) {
			relation(it, jt);
		}
	}
}

/** The algebraic datatype that stores a version range and a configuration
*/
struct VersionConfiguration {
	VersionSpecifier ver;
	NotConf conf;
}

/** Return if a is a subset of b, or if a and b are disjoint, or
if a and b overlap
*/
SetRelation relation(const(VersionConfiguration) a,
		const(VersionConfiguration) b) pure
{
	const SetRelation ver = dud.pkgdescription.versionspecifier
		.relation(a.ver, b.ver);
	const SetRelation conf = relation(a.conf, b.conf);

	debug writefln("ver %s, conf %s", ver, conf);
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
	SemVer a = SemVer("1.0.0");
	SemVer b = SemVer("2.0.0");
	SemVer c = SemVer("3.0.0");

	auto v1 = VersionConfiguration(
			VersionSpecifier(a, Inclusive.yes, b, Inclusive.yes), NotConf(""));
	auto v2 = VersionConfiguration(
			VersionSpecifier(a, Inclusive.yes, b, Inclusive.no), NotConf(""));
	auto v3 = VersionConfiguration(
			VersionSpecifier(a, Inclusive.yes, c, Inclusive.no), NotConf(""));
	auto v4 = VersionConfiguration(
			VersionSpecifier(b, Inclusive.yes, c, Inclusive.no), NotConf(""));

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
	SemVer a = SemVer("1.0.0");
	SemVer b = SemVer("2.0.0");
	SemVer c = SemVer("3.0.0");

	auto v1 = VersionConfiguration(
			VersionSpecifier(a, Inclusive.yes, b, Inclusive.yes),
			NotConf("conf1"));
	auto v2 = VersionConfiguration(
			VersionSpecifier(a, Inclusive.yes, b, Inclusive.no),
			NotConf(""));
	auto v3 = VersionConfiguration(
			VersionSpecifier(a, Inclusive.yes, b, Inclusive.yes),
			NotConf("conf2"));

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
		const(VersionConfiguration)[2] other) pure
{
	return relation(a, other[0], other[1]);
}

/// Ditto
SetRelation relation(const(VersionConfiguration) a,
		const(VersionConfiguration) b, const(VersionConfiguration) c) pure
{
	const SetRelation ab = relation(a, b);
	const SetRelation ac = relation(a, c);

	debug {
		const SetRelation bc = relation(b, c);
		enforce(bc == SetRelation.disjoint, format(
			"b %s and c %s must be disjoint", b, c));
	}

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


VersionConfiguration[2] invert(const(VersionConfiguration) vs) {
	VersionConfiguration[2] ret;
	if(vs.ver.low > SemVer("0.0.0")) {
		VersionConfiguration tmp = VersionConfiguration(
			VersionSpecifier(SemVer("0.0.0"), Inclusive.yes,
				vs.ver.low, vs.ver.inclusiveLow ? Inclusive.no : Inclusive.yes),
			NotConf(vs.conf.conf, !vs.conf.isNot));

		ret[0] = tmp;
	}

	VersionConfiguration tmp = VersionConfiguration(
			VersionSpecifier(vs.ver.high,
				vs.ver.inclusiveHigh ? Inclusive.no : Inclusive.yes,
				SemVer.MaxRelease, Inclusive.yes),
			NotConf(vs.conf.conf, !vs.conf.isNot));

	ret[1] = tmp;
	return ret;
}

unittest {
	SemVer a = SemVer("1.0.0");
	SemVer b = SemVer("2.0.0");
	SemVer c = SemVer("3.0.0");

	auto v1 = VersionConfiguration(
			VersionSpecifier(a, Inclusive.yes, b, Inclusive.yes),
			NotConf("conf1"));
	auto v2 = VersionConfiguration(
			VersionSpecifier(a, Inclusive.yes, b, Inclusive.no),
			NotConf(""));
	auto v3 = VersionConfiguration(
			VersionSpecifier(a, Inclusive.yes, b, Inclusive.yes),
			NotConf("conf2"));

	auto notV1 = v1.invert();
	SetRelation sr = relation(v1, notV1);
	assert(sr == SetRelation.disjoint, format(
		"\nsr: %s\na: %s\nb: %s\nc: %s", sr, v1, notV1[0], notV1[1]));
}
