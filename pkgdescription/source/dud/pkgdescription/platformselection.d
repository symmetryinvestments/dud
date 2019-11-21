module dud.pkgdescription.platformselection;

import std.algorithm.iteration : each, map, filter;
import std.algorithm.searching : canFind, all, any;
import std.algorithm.sorting : sort;
import std.array : array, empty, front;
import std.exception : enforce;
import std.format;
import std.range : tee;
import std.stdio;
import std.traits : FieldNameTuple;
import std.typecons : Nullable, apply, nullable;

import dud.pkgdescription.duplicate : ddup = dup;
import dud.pkgdescription.exception;
import dud.pkgdescription.path;
import dud.pkgdescription;
import dud.semver;

PackageDescriptionNoPlatform select(const(PackageDescription) pkg,
		const(Platform[]) platform)
{
	return selectImpl(pkg, platform);
}

struct PackageDescriptionNoPlatform {
@safe pure:
	string name;

	SemVer version_;

	string description;

	string homepage;

	string[] authors;

	string copyright;

	string license;

	string systemDependencies;

	DependencyNoPlatform[string] dependencies;

	TargetType targetType;

	UnprocessedPath targetPath;

	string targetName;

	UnprocessedPath workingDirectory;

	UnprocessedPath mainSourceFile;

	string[] dflags; /// Flags passed to the D compiler

	string[] lflags; /// Flags passed to the linker

	string[] libs; /// Librariy names to link against (typically using "-l<name>")

	UnprocessedPath[] copyFiles; /// Files to copy to the target directory

	string[] versions; /// D version identifiers to set

	string[] debugVersions; /// D debug version identifiers to set

	UnprocessedPath[] importPaths;

	UnprocessedPath[] sourcePaths;

	UnprocessedPath[] sourceFiles;

	UnprocessedPath[] excludedSourceFiles;

	UnprocessedPath[] stringImportPaths;

	string[] preGenerateCommands; /// commands executed before creating the description

	string[] postGenerateCommands; /// commands executed after creating the description

	string[] preBuildCommands; /// Commands to execute prior to every build

	string[] postBuildCommands; /// Commands to execute after every build

	string[] preRunCommands; /// Commands to execute prior to every run

	string[] postRunCommands; /// Commands to execute after every run

	string[] ddoxFilterArgs;

	string[] debugVersionFilters;

	string ddoxTool;

	SubPackageNoPlatform[] subPackages;

	BuildRequirement[] buildRequirements;

	SubConfigs subConfigurations;

	string[] versionFilters;

	BuildOptionsNoPlatform buildOptions;

	ToolchainRequirement[Toolchain] toolchainRequirements;

	PackageDescriptionNoPlatform[] configurations;
}

struct SubPackageNoPlatform {
	UnprocessedPath path;
	Nullable!PackageDescriptionNoPlatform inlinePkg;
}

struct BuildOptionsNoPlatform {
	BuildOption[] options;
}

struct DependencyNoPlatform {
@safe pure:
	string name;
	Nullable!VersionSpecifier version_;
	UnprocessedPath path;
	Nullable!bool optional;
	Nullable!bool default_;
}

PackageDescriptionNoPlatform selectImpl(const(PackageDescription) pkg,
		const(Platform[]) platform)
{
	import dud.pkgdescription.helper : isMem;
	PackageDescriptionNoPlatform ret;

	static foreach(mem; FieldNameTuple!PackageDescription) {{
		alias MemType = typeof(__traits(getMember, PackageDescription, mem));
		static if(canFind(
			[ isMem!"name", isMem!"version_", isMem!"description"
			, isMem!"homepage", isMem!"authors", isMem!"copyright"
			, isMem!"license", isMem!"systemDependencies", isMem!"targetType"
			, isMem!"ddoxFilterArgs", isMem!"debugVersionFilters"
			, isMem!"versionFilters", isMem!"toolchainRequirements"
			], mem))
		{
			__traits(getMember, ret, mem) = ddup(__traits(getMember, pkg, mem));
		} else static if(canFind(
			[ isMem!"targetName", isMem!"ddoxTool"
			, isMem!"preGenerateCommands"
			, isMem!"postGenerateCommands", isMem!"preBuildCommands"
			, isMem!"postBuildCommands", isMem!"preRunCommands"
			, isMem!"postRunCommands", isMem!"dflags", isMem!"lflags"
			, isMem!"libs", isMem!"versions", isMem!"targetPath"
			, isMem!"workingDirectory", isMem!"mainSourceFile"
			, isMem!"sourcePaths", isMem!"importPaths"
			, isMem!"copyFiles", isMem!"excludedSourceFiles"
			, isMem!"stringImportPaths", isMem!"sourceFiles"
			, isMem!"debugVersions", isMem!"subPackages"
			, isMem!"dependencies", isMem!"buildRequirements"
			], mem))
		{
			__traits(getMember, ret, mem) = select(
				__traits(getMember, pkg, mem), platform);
		} else static if(canFind(
			[ isMem!"configurations" ],
			mem))
		{
			if(!__traits(getMember, pkg, mem).empty) {
				__traits(getMember, ret, mem) = select(
					__traits(getMember, pkg, mem), platform);
			}
		} else {
			pragma(msg, format("Unhandeled %s", mem));
		}
	}}

	return ret;
}

//
// BuildRequirements
//

BuildRequirement[] select(const(BuildRequirements) brs,
		const(Platform[]) platform)
{
	BuildRequirements brsC = ddup(brs);
	brsC.platforms.sort!((a, b) => a.platforms > b.platforms)();

	auto f = brsC.platforms.filter!(br => isSuperSet(br.platforms, platform));
	return f.empty ? BuildRequirement[].init : f.front.requirements;
}

//
// Dependencies
//

PackageDescriptionNoPlatform[] select(const(PackageDescription[string]) confs,
		const(Platform[]) platform)
{
	import std.traits : fullyQualifiedName;
	import dud.pkgdescription.joining : expandConfiguration;

	// No configuration present, thats okay
	assert(!confs.empty, "This should be called with no configurations"
		~ " as this would mean infinite recursion");

	enforce!ToManyConfigurations(confs.length == 1, format(
		"During Platform resolution only one must be present not '%s'."
		~ " Use the function '%s' to select a Configuration",
		confs.length, fullyQualifiedName!expandConfiguration));

	bool platformMatches = confs.byValue.front.platforms
		.any!(plt => isSuperSet(plt, platform));

	enforce!InvalidPlatfrom(platformMatches, format(
		"Non of the platforms [%(%s|, %)] of configuration '%s'"
		~ " matches specified platform [%(%s|, %)]",
		confs.byValue.front.platforms, confs.byValue.front.name, platform));

	return [select(confs.byValue.front, platform)];
}

//
// Dependencies
//

DependencyNoPlatform select(const(Dependency) sp) {
	DependencyNoPlatform ret;
	ret.name = sp.name;
	ret.path = ddup(sp.path);
	sp.version_.apply!(v => ret.version_ = nullable(ddup(v)));
	sp.optional.apply!((bool op) => ret.optional = nullable(op));
	sp.default_.apply!((bool def) => ret.default_ = nullable(def));
	return ret;
}

DependencyNoPlatform[string] select(const(Dependency[]) deps,
		const(Platform[]) platform)
{
	Dependency[][string] sorted;
	deps.filter!(dep => isSuperSet(dep.platforms, platform))
		.each!((dep) {
			auto d = ddup(dep);
			if(dep.name in sorted) {
				sorted[dep.name] ~= d;
			} else {
				sorted[dep.name] = [d];
			}
		});

	DependencyNoPlatform[string] ret;
	foreach(key, ref values; sorted) {
		values.sort!((a, b) => a.platforms.length > b.platforms.length)();
		enforce(!values.empty, "values was unexceptionally empty");
		ret[key] = select(values.front);
	}

	return ret;
}

//
// SubPackage(s)
//

SubPackageNoPlatform select(const(SubPackage) sp, const(Platform[]) platform) {
	SubPackageNoPlatform ret;
	if(!sp.inlinePkg.isNull()) {
		ret.inlinePkg = nullable(select(sp.inlinePkg.get(), platform));
	} else {
		ret.path = select(sp.path, platform);
	}
	return ret;
}

SubPackageNoPlatform[] select(const(SubPackage[]) sps, const(Platform[]) platform)
{
	return sps.map!(sp => select(sp, platform)).array;

}

//
// Path(s)
//

UnprocessedPath select(const(Path) path, const(Platform[]) platform) {
	PathPlatform[] strs = path.platforms.map!(it => ddup(it)).array;
	strs.sort!((a, b) => a.platforms.length > b.platforms.length)();
	auto superSets = strs.filter!(str => isSuperSet(str.platforms, platform));
	return superSets.empty
		? UnprocessedPath.init
		: superSets.front.path;
}

UnprocessedPath[] select(const(Paths) paths, const(Platform[]) platform) {
	PathsPlatform[] strs = paths.platforms.map!(it => ddup(it)).array;
	strs.sort!((a, b) => a.platforms.length > b.platforms.length)();
	auto superSets = strs.filter!(str => isSuperSet(str.platforms, platform));
	return superSets.empty
		? []
		: superSets.front.paths;
}

//
// String(s)
//

string select(const(String) str, const(Platform[]) platform) {
	StringPlatform[] strs = str.platforms.map!(it => ddup(it)).array;
	strs.sort!((a, b) => a.platforms.length > b.platforms.length)();
	auto superSets = strs.filter!(str => isSuperSet(str.platforms, platform));
	return superSets.empty
		? ""
		: superSets.front.str;
}

string[] select(const(Strings) strs, const(Platform[]) platform) {
	StringsPlatform[] strss = strs.platforms.map!(it => ddup(it)).array;
	strss.sort!((a, b) => a.platforms.length > b.platforms.length)();
	auto superSets = strss.filter!(str => isSuperSet(str.platforms, platform));
	return superSets.empty
		? []
		: superSets.front.strs;
}

int isSuperSet(const(Platform[]) a, const(Platform[]) b) {
	return a.all!(p => canFind(b, p));
}
