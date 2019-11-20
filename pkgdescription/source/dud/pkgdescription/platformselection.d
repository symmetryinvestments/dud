module dud.pkgdescription.platformselection;

import std.array : array, empty, front;
import std.algorithm.iteration : each, map, filter;
import std.algorithm.searching : canFind, all;
import std.algorithm.sorting : sort;
import std.typecons : Nullable;
import std.traits : FieldNameTuple;
import std.format;

import dud.pkgdescription;
import dud.pkgdescription.path;
import dud.semver;
import dud.pkgdescription.exception;
import dud.pkgdescription.duplicate : ddup = dup;

PackageDescriptionNoPlatform selectPlatform(const(PackageDescription) pkg,
		const(Platform[]) platform)
{
	return selectPlatformImpl(pkg, platform);
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

	DependencyNoPlatform[] dependencies;

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

	SubPackage[] subPackages;

	BuildRequirement[] buildRequirements;

	SubConfigs subConfigurations;

	string[] versionFilters;

	BuildOptionsNoPlatform buildOptions;

	ToolchainRequirement[Toolchain] toolchainRequirements;
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

PackageDescriptionNoPlatform selectPlatformImpl(const(PackageDescription) pkg,
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
			], mem))
		{
			__traits(getMember, ret, mem) = select(
				__traits(getMember, pkg, mem), platform);
		} else {
			pragma(msg, format("Unhandeled %s", mem));
		}
	}}

	return ret;
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
