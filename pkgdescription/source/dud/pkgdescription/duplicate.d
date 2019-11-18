module dud.pkgdescription.duplicate;

import std.array : empty;
import std.algorithm.iteration : each;
import std.traits : FieldNameTuple;
import std.typecons : nullable;
import std.format : format;

import dud.semver;
import dud.pkgdescription;

@safe:

PackageDescription dup(const ref PackageDescription pkg) {
	PackageDescription ret;

	static foreach(mem; FieldNameTuple!(PackageDescription)) {{
		alias MemType = typeof(__traits(getMember, PackageDescription, mem));
		static if(is(MemType == string)
				|| is(MemType == SemVer)
				|| is(MemType == Path)
				|| is(MemType == Paths)
				|| is(MemType == BuildOptions)
				|| is(MemType == Dependency[])
				|| is(MemType == Platform[][])
				|| is(MemType == SubPackage[])
				|| is(MemType == BuildType[string])
				|| is(MemType == ToolchainRequirement[Toolchain])
				|| is(MemType == SubConfigs)
				|| is(MemType == BuildRequirement[])
				|| is(MemType == PackageDescription[string])
				|| is(MemType == String)
				|| is(MemType == Strings)
				|| is(MemType == string[]))
		{
			__traits(getMember, ret, mem) = __traits(getMember, pkg, mem).dup();
		} else static if(is(MemType == TargetType)
				|| is(MemType == string)
				)
		{
			__traits(getMember, ret, mem) = __traits(getMember, pkg, mem);
		} else {
			static assert(false, format(
				"Type '%s' of member '%s' is not handled in dup",
				MemType.stringof, mem));
		}
	}}

	return ret;
}

//
// ToolchainRequirement
//

VersionSpecifier dup(const ref VersionSpecifier old) {
	VersionSpecifier ret = parseVersionSpecifier(old.orig);
	return ret;
}

unittest {
	import dud.pkgdescription.compare;
	auto old = parseVersionSpecifier(">=1.15.0");
	assert(!old.isNull());

	VersionSpecifier d = dup(old.get());
	assert(areEqual(old.get(), d));
}

ToolchainRequirement dup(const ref ToolchainRequirement old) {
	ToolchainRequirement ret;
	ret.no = old.no;
	ret.version_ = old.version_.dup();
	return ret;
}

ToolchainRequirement[Toolchain] dup(
		ref const(ToolchainRequirement[Toolchain]) old)
{
	ToolchainRequirement[Toolchain] ret;
	old.byKeyValue().each!(it => ret[it.key] = it.value.dup());
	return ret;
}

//
// TargetType
//

TargetType dup(const(TargetType) old) {
	TargetType ret = old;
	return ret;
}

//
// SemVer
//

SemVer dup(ref const(SemVer) old) {
	return old.m_version.empty
		? SemVer.init
		: SemVer(old.m_version.dup);
}

SemVer[] dup(const(SemVer[]) old) {
	SemVer[] ret;
	old.each!(it => ret ~= it.dup());
	return ret;
}

//
// BuildOption
//

BuildOption[] dup(const(BuildOption[]) old) {
	BuildOption[] ret;
	old.each!(it => ret ~= it);
	return ret;
}

BuildOptions dup(ref const(BuildOptions) old) {
	BuildOptions ret;
	ret.unspecifiedPlatform = old.unspecifiedPlatform.dup();
	foreach(key, value; old.platforms) {
		ret.platforms[key] = value.dup();
	}
	return ret;
}

//
// SubConfig
//

SubConfigs dup(ref const(SubConfigs) old) {
	SubConfigs ret;
	old.unspecifiedPlatform
		.byKeyValue
		.each!(it => ret.unspecifiedPlatform[it.key] = it.value);

	foreach(key, value; old.configs) {
		string[string] tmp;
		foreach(key2, value2; value) {
			tmp[key2] = value2;
		}
		ret.configs[key] = tmp;
	}
	return ret;
}

Platform[] dup(const(Platform[]) old) {
	Platform[] ret;
	old.each!(it => ret ~= it);
	return ret;
}

Platform[][] dup(const(Platform[][]) old) {
	Platform[][] ret;
	old.each!(it => ret ~= it.dup);
	return ret;
}

BuildType dup(const(BuildType) old) {
	BuildType ret;
	ret.pkg = old.pkg.dup();
	ret.name = old.name;
	return ret;
}

BuildType[string] dup(const(BuildType[string]) old) {
	BuildType[string] ret;
	old.byKeyValue().each!(it => ret[it.key] = it.value.dup());
	return ret;
}

BuildRequirement[] dup(const(BuildRequirement[]) old) {
	BuildRequirement[] ret;
	old.each!(it => ret ~= it);
	return ret;
}

PackageDescription[string] dup(const(PackageDescription[string]) old) {
	PackageDescription[string] ret;
	old.byKeyValue().each!(it => ret[it.key] = it.value.dup());
	return ret;
}

SubPackage dup(ref const(SubPackage) old) {
	SubPackage ret;
	ret.path = old.path.dup();
	if(!old.inlinePkg.isNull()) {
		ret.inlinePkg = nullable(old.inlinePkg.get().dup());
	}
	return ret;
}

SubPackage[] dup(const(SubPackage[]) old) {
	SubPackage[] ret;
	old.each!(it => ret ~= it.dup());
	return ret;
}

//
// Dependency
//

Dependency dup(ref const(Dependency) old) {
	Dependency ret;
	ret.name = old.name;
	ret.platforms = old.platforms.dup();
	ret.path = old.path.dup();
	if(!old.default_.isNull()) {
		ret.default_ = nullable(old.default_.get());
	}

	if(!old.optional.isNull()) {
		ret.optional = nullable(old.optional.get());
	}

	if(!old.version_.isNull()) {
		ret.version_ = nullable(old.version_.get());
	}
	return ret;
}

Dependency[] dup(const(Dependency[]) old) {
	Dependency[] ret;
	old.each!(it => ret ~= it.dup());
	return ret;
}

//
// String
//

StringsPlatform dup(ref const(StringsPlatform) old) {
	StringsPlatform ret;
	ret.strs = old.strs.dup();
	ret.platforms = old.platforms.dup();
	return ret;
}

Strings dup(ref const(Strings) old) {
	Strings ret;
	old.platforms.each!(p => ret.platforms ~= p.dup());
	return ret;
}

//
// String
//

StringPlatform dup(ref const(StringPlatform) old) {
	StringPlatform ret;
	ret.str = old.str.dup();
	ret.platforms = old.platforms.dup();
	return ret;
}

String dup(ref const(String) old) {
	String ret;
	old.platforms.each!(p => ret.platforms ~= p.dup());
	return ret;
}

//
// Paths
//

Paths dup(ref const(Paths) old) {
	Paths ret;
	old.platforms.each!(p => ret.platforms ~= p.dup());
	return ret;
}

//
// Path
//

PathPlatform dup(ref const(PathPlatform) old) {
	PathPlatform ret;
	ret.path = UnprocessedPath(old.path.path);
	ret.platforms = old.platforms.dup();
	return ret;
}

PathPlatform[] dup(const(PathPlatform[]) old) {
	PathPlatform[] ret;
	old.each!(it => ret ~= it.dup());
	return ret;
}

UnprocessedPath dup(ref const(UnprocessedPath) old) {
	return UnprocessedPath(old.path.dup());
}

PathsPlatform dup(ref const(PathsPlatform) old) {
	PathsPlatform ret;
	old.paths.each!(it => ret.paths ~= it.dup());
	ret.platforms = old.platforms.dup();
	return ret;
}

PathsPlatform[] dup(const(PathsPlatform[]) old) {
	PathsPlatform[] ret;
	old.each!(it => ret ~= it.dup());
	return ret;
}

Path dup(ref const(Path) old) {
	Path ret;
	old.platforms.each!(p => ret.platforms ~= p.dup());
	return ret;
}

string dup(const(string) old) {
	return old;
}

string[] dup(const(string[]) old) {
	string[] ret;
	old.each!(it => ret ~= it);
	return ret;
}

