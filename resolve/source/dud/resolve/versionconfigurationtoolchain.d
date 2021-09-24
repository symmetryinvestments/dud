module dud.resolve.versionconfigurationtoolchain;

import std.algorithm.iteration : map;
import std.array : empty;
import std.algorithm.searching : canFind;
import std.array : array, empty;
import std.stdio;
import std.exception : enforce;
import std.format : format;
import std.typecons : Nullable, nullable;

import dud.semver.semver;
import dud.semver.parse;
import dud.semver.checks : allowsAll, allowsAny;
import dud.semver.versionrange;
import dud.semver.versionunion;
static import dud.semver.setoperation;
import dud.resolve.confs : Confs;
import dud.resolve.positive;
import dud.resolve.toolchain;

@safe pure:

/** The algebraic datatype that stores a version range and a configuration
*/
struct VersionConfigurationToolchain {
@safe pure:
	VersionUnion ver;
	Confs conf;
	ToolchainVersionUnion[] toolchains;

	bool opEquals()(auto ref const(VersionConfigurationToolchain) other) const {
		return this.ver == other.ver
			&& this.conf == other.conf
			&& areEqual(this.toolchains, other.toolchains);
	}
}

VersionConfigurationToolchain dup(const(VersionConfigurationToolchain) old) {
	return VersionConfigurationToolchain(old.ver.dup(), old.conf.dup()
			, old.toolchains.map!(it => dud.resolve.toolchain.dup(it)).array);
}

VersionConfigurationToolchain invert(const(VersionConfigurationToolchain) conf) {
	static import dud.resolve.confs;
	return VersionConfigurationToolchain(
			dud.semver.setoperation.invert(conf.ver)
			, conf.conf.invert());
}

bool allowsAny(const(VersionConfigurationToolchain) a, const(VersionConfigurationToolchain) b) {
	static import dud.resolve.confs;
	static import dud.semver.checks;
	return dud.semver.checks.allowsAny(a.ver, b.ver)
		&& dud.resolve.confs.allowsAny(a.conf, b.conf)
		&& dud.resolve.toolchain.allowsAny(a.toolchains, b.toolchains);
}

bool allowsAll(const(VersionConfigurationToolchain) a, const(VersionConfigurationToolchain) b) {
	static import dud.resolve.confs;
	static import dud.semver.checks;
	return dud.semver.checks.allowsAll(a.ver, b.ver)
		&& dud.resolve.confs.allowsAll(a.conf, b.conf)
		&& dud.resolve.toolchain.allowsAll(a.toolchains, b.toolchains);
}

Nullable!(VersionConfigurationToolchain) intersectionOf(
		const(VersionConfigurationToolchain) a
		, const(VersionConfigurationToolchain) b)
{
	static import dud.resolve.confs;
	static import dud.semver.setoperation;
	auto ver = dud.semver.setoperation.intersectionOf(a.ver, b.ver);
	auto confs = dud.resolve.confs.intersectionOf(a.conf, b.conf);
	auto tc = dud.resolve.toolchain.intersectionOf(a.toolchains, b.toolchains);

	if(tc.isNull()) {
		return Nullable!(VersionConfigurationToolchain).init;
	}

	return nullable(VersionConfigurationToolchain(ver, confs, tc.get()));
}

/** Return if a is a subset of b, or if a and b are disjoint, or
if a and b overlap
*/
SetRelation relation(const(VersionConfigurationToolchain) a,
		const(VersionConfigurationToolchain) b) pure
{
	static import dud.resolve.confs;
	const SetRelation ver = allowsAll(b.ver, a.ver)
		? SetRelation.subset
		: allowsAny(b.ver, a.ver)
			? SetRelation.overlapping
			: SetRelation.disjoint;

	const SetRelation conf = dud.resolve.confs.relation(a.conf, b.conf);
	const SetRelation tc = dud.resolve.toolchain.relation(a.toolchains,
			b.toolchains);

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
