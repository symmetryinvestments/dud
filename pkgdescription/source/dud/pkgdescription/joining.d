module dud.pkgdescription.joining;

import std.array : array, empty, front;
import std.algorithm.searching : canFind, find;
import std.algorithm.sorting : sort;
import std.algorithm.iteration : uniq, filter, each;
import std.exception : enforce;
import std.format : format;
import std.traits : FieldNameTuple;
import std.typecons : nullable, Nullable, apply;

import dud.pkgdescription;
import dud.pkgdescription.exception;
import dud.pkgdescription.compare;
import dud.pkgdescription.duplicate;
import dud.pkgdescription.duplicate : ddup = dup;

@safe:

private template isMem(string name) {
	static if(__traits(hasMember, PackageDescription, name)) {
		enum isMem = name;
	} else {
		static assert(false,
			format("'%s' is not a member of PackageDescription", name));
	}
}

unittest {
	static assert(!__traits(compiles, isMem!"foo"));
	static assert( __traits(compiles, isMem!"name"));
}

PackageDescription expandConfiguration(ref const PackageDescription pkg,
		string confName)
{
	PackageDescription ret = dud.pkgdescription.duplicate.dup(pkg);
	ret.configurations = [];

	const(PackageDescription) conf = findConfiguration(pkg, confName);
	joinPackageDescription(ret, conf);
	return ret;
}

void joinPackageDescription(ref PackageDescription ret,
		ref const(PackageDescription) conf)
{
	static foreach(mem; FieldNameTuple!PackageDescription) {
		// override with conf
		static if(canFind(
			[ isMem!"targetPath", isMem!"targetName", isMem!"mainSourceFile"
			, isMem!"workingDirectory", isMem!"targetType"
			, isMem!"systemDependencies", isMem!"ddoxTool", isMem!"platforms"
			, isMem!"buildOptions"
			], mem))
		{
			__traits(getMember, ret, mem) =
				dud.pkgdescription.duplicate.dup(
					__traits(getMember, conf, mem));
		} else static if(canFind(
			[ isMem!"dflags", isMem!"lflags", isMem!"versions"
			, isMem!"importPaths", isMem!"sourcePaths", isMem!"sourceFiles"
			, isMem!"stringImportPaths" , isMem!"excludedSourceFiles"
			, isMem!"copyFiles" , isMem!"preGenerateCommands"
			, isMem!"postGenerateCommands" , isMem!"preBuildCommands"
			, isMem!"postBuildCommands" , isMem!"preRunCommands"
			, isMem!"postRunCommands", isMem!"libs", isMem!"versionFilters"
			, isMem!"debugVersionFilters", isMem!"debugVersions"
			, isMem!"toolchainRequirements", isMem!"dependencies"
			, isMem!"subConfigurations", isMem!"buildTypes"
			], mem))
		{
			__traits(getMember, ret, mem) =
				join(__traits(getMember, pkg, mem),
						__traits(getMember, conf, mem));
		} else static if(canFind(
			[ isMem!"name", isMem!"description", isMem!"homepage"
			, isMem!"license", isMem!"authors", isMem!"version_"
			, isMem!"copyright", isMem!"subPackages"
			, isMem!"ddoxFilterArgs", isMem!"configurations"
			, isMem!"buildRequirements"
			], mem))
		{
			// global options not allowed to change by configuration
		} else {
			pragma(msg, mem);
		}
	}
}

const(PackageDescription) findConfiguration(const PackageDescription pkg,
	string confName)
{
	auto ret = find!((a, b) => a.name == b)(pkg.configurations, confName);
	enforce!UnknownConfiguration(!ret.empty,
		format("'%s' is a unknown configuration of package '%s'", pkg.name));
	return ret.front;
}

SubConfigs join(ref const(SubConfigs) a, ref const(SubConfigs) b) {
	SubConfigs ret = b.ddup();
	a.unspecifiedPlatform.byKeyValue()
		.filter!(kv => kv.key !in ret.unspecifiedPlatform)
		.each!(kv => ret.unspecifiedPlatform[kv.key] = kv.value);

	foreach(key, value; a.configs) {
		if(key !in ret.configs) {
			ret.configs[key] = string[string].init;
		}
		foreach(key2, value2; value) {
			if(key2 !in ret.configs[key]) {
				ret.configs[key][key2] = value2.ddup();
			}
		}
	}
	return ret;
}

BuildType[] join(const(BuildType[]) a, const(BuildType[]) b) {
	BuildType[] ret = b.ddup();
	a.filter!(bt =>
			canFind!((g, h) => g.name == h.name
				&& g.platforms == h.platforms)(ret, bt))
		.each!(bt => ret ~= bt.ddup());
	return ret;
}

Dependency[] join(const(Dependency[]) a, const(Dependency[]) b) {
	Dependency[] ret = b.ddup();
	a.filter!(dep =>
			!canFind!((g, h) => g.name == h.name
				&& g.platforms == h.platforms)(ret, dep))
		.each!(dep => ret ~= dep.ddup());
	return ret;
}

ToolchainRequirement[Toolchain] join(const(ToolchainRequirement[Toolchain]) a,
		const(ToolchainRequirement[Toolchain]) b)
{
	ToolchainRequirement[Toolchain] ret = dud.pkgdescription.duplicate.dup(a);
	b.byKeyValue()
		.each!(it => ret[it.key] =
				dud.pkgdescription.duplicate.dup(it.value));
	return ret;
}

Paths join(const(Paths) a, const(Paths) b) {
	Paths ret = dud.pkgdescription.duplicate.dup(a);
	b.platforms
		.filter!(it =>
				!canFind!((g, h) => areEqual(g, h))(a.platforms, it))
		.each!(it => ret.platforms ~= dud.pkgdescription.duplicate.dup(it));
	return ret;
}

Strings join(const(Strings) a, const(Strings) b) {
	Strings ret = dud.pkgdescription.duplicate.dup(a);
	b.platforms
		.filter!(it =>
				!canFind!((g, h) => areEqual(g, h))(a.platforms, it))
		.each!(it => ret.platforms ~= dud.pkgdescription.duplicate.dup(it));
	return ret;
}

string[] join(const(string[]) a, const(string[]) b) {
	string[] ret = (dud.pkgdescription.duplicate.dup(a)
			~ dud.pkgdescription.duplicate.dup(b)).sort.uniq.array;
	return ret;
}
