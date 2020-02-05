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
static import dud.semver.setoperation;
import dud.resolve.conf : Confs, allowsAll, allowsAny, invert;
import dud.resolve.positive;

@safe pure:

/** The algebraic datatype that stores a version range and a configuration
*/
struct VersionConfiguration {
@safe pure:
	VersionUnion ver;
	Confs conf;
}

VersionConfiguration dup(const(VersionConfiguration) old) {
	return VersionConfiguration(old.ver.dup, old.conf.dup);
}

VersionConfiguration invert(const(VersionConfiguration) conf) {
	static import dud.resolve.conf;
	return VersionConfiguration(
			dud.semver.setoperation.invert(conf.ver),
			dud.resolve.conf.invert(conf.conf));
}

bool allowsAny(const(VersionConfiguration) a, const(VersionConfiguration) b) {
	return allowsAny(a.ver, b.ver) && allowsAny(a.conf, b.conf);
}

bool allowsAll(const(VersionConfiguration) a, const(VersionConfiguration) b) {
	return allowsAll(a.ver, b.ver) && allowsAll(a.conf, b.conf);
}

/** Return if a is a subset of b, or if a and b are disjoint, or
if a and b overlap
*/
SetRelation relation(const(VersionConfiguration) a,
		const(VersionConfiguration) b) pure
{
	static import dud.resolve.conf;
	const SetRelation ver = allowsAll(b.ver, a.ver)
		? SetRelation.subset
		: allowsAny(b.ver, a.ver)
			? SetRelation.overlapping
			: SetRelation.disjoint;

	const SetRelation conf = dud.resolve.conf.relation(a.conf, b.conf);

	//debug writefln("ver %s, conf %s", ver, conf);
	if(ver == SetRelation.disjoint || conf == SetRelation.disjoint) {
		return SetRelation.disjoint;
	}

	if(ver == SetRelation.overlapping || conf == SetRelation.overlapping) {
		return SetRelation.overlapping;
	}

	assert(ver == SetRelation.subset && conf == SetRelation.subset,
			format("a: %s, b: %s", a, b));
	return SetRelation.subset;
}
