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
import dud.resolve.confs : Confs;
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
	static import dud.resolve.confs;
	return VersionConfiguration(
			dud.semver.setoperation.invert(conf.ver),
			conf.conf.invert());
}

bool allowsAny(const(VersionConfiguration) a, const(VersionConfiguration) b) {
	static import dud.resolve.confs;
	static import dud.semver.checks;
	return dud.semver.checks.allowsAny(a.ver, b.ver)
		&& dud.resolve.confs.allowsAny(a.conf, b.conf);
}

bool allowsAll(const(VersionConfiguration) a, const(VersionConfiguration) b) {
	static import dud.resolve.confs;
	static import dud.semver.checks;
	return dud.semver.checks.allowsAll(a.ver, b.ver)
		&& dud.resolve.confs.allowsAll(a.conf, b.conf);
}

__EOF__

/** Return if a is a subset of b, or if a and b are disjoint, or
if a and b overlap
*/
SetRelation relation(const(VersionConfiguration) a,
		const(VersionConfiguration) b) pure
{
	static import dud.resolve.confs;
	const SetRelation ver = allowsAll(b.ver, a.ver)
		? SetRelation.subset
		: allowsAny(b.ver, a.ver)
			? SetRelation.overlapping
			: SetRelation.disjoint;

	const SetRelation conf = dud.resolve.confs.relation(a.conf, b.conf);

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

VersionConfiguration intersectionOf(const(VersionConfiguration) a,
		const(VersionConfiguration) b)
{
	static import dud.semver.setoperation;
	static import dud.resolve.confs;
	return VersionConfiguration(
			dud.semver.setoperation.intersectionOf(a.ver, b.ver),
			dud.resolve.confs.intersectionOf(a.conf, b.conf)
		);
}
