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
import dud.semver.semver;
import dud.semver.versionrange;

PackageDescriptionNoPlatform select()(const(PackageDescription) pkg,
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

	string[] versionFilters;

	BuildOption[] buildOptions;

	ToolchainRequirement[Toolchain] toolchainRequirements;

	PackageDescriptionNoPlatform[] configurations;

	string[string] subConfigurations;

	bool opEquals(const(PackageDescriptionNoPlatform) other) const {
		import dud.pkgdescription.compare : areEqual;
		return areEqual(this, other);
	}
}

struct SubPackageNoPlatform {
	UnprocessedPath path;
	Nullable!PackageDescriptionNoPlatform inlinePkg;
}

struct DependencyNoPlatform {
@safe pure:
	string name;
	Nullable!VersionRange version_;
	UnprocessedPath path;
	Nullable!bool optional;
	Nullable!bool default_;
}

PackageDescriptionNoPlatform selectImpl()(const(PackageDescription) pkg,
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
			, isMem!"workingDirectory", isMem!"mainSourceFile"
			, isMem!"targetPath", isMem!"targetName"
			], mem))
		{
			__traits(getMember, ret, mem) = ddup(__traits(getMember, pkg, mem));
		} else static if(canFind(
			[ isMem!"ddoxTool"
			, isMem!"preGenerateCommands"
			, isMem!"postGenerateCommands", isMem!"preBuildCommands"
			, isMem!"postBuildCommands", isMem!"preRunCommands"
			, isMem!"postRunCommands", isMem!"dflags", isMem!"lflags"
			, isMem!"libs", isMem!"versions"
			, isMem!"sourcePaths", isMem!"importPaths"
			, isMem!"copyFiles", isMem!"excludedSourceFiles"
			, isMem!"stringImportPaths", isMem!"sourceFiles"
			, isMem!"debugVersions", isMem!"subPackages"
			, isMem!"dependencies", isMem!"buildRequirements"
			, isMem!"subConfigurations", isMem!"buildOptions"
			], mem))
		{
			__traits(getMember, ret, mem) = select(
				__traits(getMember, pkg, mem), platform);
		} else static if(canFind(
			[ isMem!"configurations", isMem!"buildTypes"]
			, mem))
		{
			enforce(__traits(getMember, pkg, mem).empty,
				() @trusted {
					return format("%s %s", mem, __traits(getMember, pkg, mem));
				}());
		} else static if(canFind([ isMem!"platforms" ] , mem)) {
			// platforms are ignored
		} else {
			assert(false, format("Unhandeld '%s'", mem));
		}
	}}

	return ret;
}

//
// BuildOptions
//

BuildOption[] select(const(BuildOptions) buildOptions,
		const(Platform[]) platform)
{
	auto keys = buildOptions.platforms.byKey()
		.filter!(key => isSuperSet(key, platform))
		.map!(key => ddup(key))
		.array
		.sort!((a, b) => a.length > b.length)();

	BuildOption[] ret = keys.empty
		? BuildOption[].init
		: buildOptions.platforms[keys.front].ddup;

	buildOptions.unspecifiedPlatform
		.each!((op) {
			if(!canFind(ret, op)) {
				ret ~= op;
			}
		});

	return ret;
}
//
// SubConfigurations
//

string[string] select(const(SubConfigs) subConfs,
		const(Platform[]) platform)
{
	auto keys = subConfs.configs.byKey()
		.filter!(key => isSuperSet(key, platform))
		.map!(key => ddup(key))
		.array
		.sort!((a, b) => a.length > b.length)();

	string[string] ret = keys.empty
		? string[string].init
		: subConfs.configs[keys.front].ddup;

	subConfs.unspecifiedPlatform.byKey()
		.each!((key) {
			if(key !in ret) {
				ret[key] = subConfs.unspecifiedPlatform[key].ddup;
			}
		});

	return ret;
}

//
// BuildRequirements
//

BuildRequirement[] select(const(BuildRequirements) brs,
		const(Platform[]) platform)
{
	BuildRequirements brsC = ddup(brs);
	brsC.platforms.sort!((a, b) => a.platforms.length > b.platforms.length)();
	auto f = brsC.platforms.filter!(br => isSuperSet(br.platforms, platform));
	return f.empty ? BuildRequirement[].init : f.front.requirements;
}

//
// Dependencies
//

DependencyNoPlatform select()(const(Dependency) sp) {
	DependencyNoPlatform ret;
	ret.name = sp.name;
	ret.path = ddup(sp.path);
	if(!sp.version_.isNull()) {
		ret.version_ = ddup(sp.version_.get());
	}
	if(!sp.optional.isNull()) {
		ret.optional = sp.optional.get();
	}
	if(!sp.default_.isNull()) {
		ret.default_ = sp.default_.get();
	}
	return ret;
}

DependencyNoPlatform[string] select()(const(Dependency[]) deps,
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

SubPackageNoPlatform select()(const(SubPackage) sp, const(Platform[]) platform) {
	SubPackageNoPlatform ret;
	if(!sp.inlinePkg.isNull()) {
		ret.inlinePkg.opAssign(select(sp.inlinePkg.get(), platform));
	} else {
		ret.path = select(sp.path, platform);
	}
	return ret;
}

SubPackageNoPlatform[] select()(const(SubPackage[]) sps, const(Platform[]) platform)
{
	return sps.map!(sp => select(sp, platform)).array;

}

//
// Path(s)
//

UnprocessedPath select(const(Path) path, const(Platform[]) platform) {
	PathPlatform[] pth = path.platforms.map!(it => ddup(it)).array;
	auto superSets = selectLargestSuperset(pth, platform);
	return superSets.empty
		? UnprocessedPath.init
		: superSets.front.path;
}

UnprocessedPath[] select(const(Paths) paths, const(Platform[]) platform) {
	PathsPlatform[] pths = paths.platforms.map!(it => ddup(it)).array;
	auto superSets = selectLargestSuperset(pths, platform);
	return superSets.empty
		? []
		: superSets.front.paths;
}

//
// String(s)
//

string select(const(String) str, const(Platform[]) platform) {
	StringPlatform[] strs = str.platforms.map!(it => ddup(it)).array;
	auto superSets = selectLargestSuperset(strs, platform);
	return superSets.empty
		? ""
		: superSets.front.str;
}

string[] select(const(Strings) strs, const(Platform[]) platform) {
	StringsPlatform[] strss = strs.platforms.map!(it => ddup(it)).array;
	auto superSets = selectLargestSuperset(strss, platform);
	return superSets.empty
		? []
		: superSets.front.strs;
}

//
// Helper
//

auto selectLargestSuperset(T)(ref T ts,
		const(Platform[]) platform)
{
	ts.sort!((a, b) => a.platforms.length > b.platforms.length)();
	auto superSets = ts.filter!(it => isSuperSet(it.platforms, platform));
	return superSets;
}

unittest {
	struct Test {
		int value;
		Platform[] platforms;
	}

	{
		Test[] tests =
			[ Test(0, []), Test(1, [Platform.posix]), Test(2, [Platform.windows])
			, Test(3, [Platform.posix, Platform.x86_64, Platform.dmd])
			, Test(4, [Platform.posix, Platform.x86_64, Platform.gdc])
			];

		auto a = selectLargestSuperset(tests, []);
		assert(!a.empty);
		assert(a.front.value == 0);

		a = selectLargestSuperset(tests, [Platform.posix]);
		assert(!a.empty);
		assert(a.front.value == 1);
	}
	{
		Test[] tests =
			[ Test(1, [Platform.posix]), Test(2, [Platform.windows])
			, Test(3, [Platform.posix, Platform.x86_64, Platform.dmd])
			, Test(4, [Platform.posix, Platform.x86_64, Platform.gdc])
			];

		auto a = selectLargestSuperset(tests, [Platform.osx, Platform.x86_64]);
		assert(a.empty, format("%s", a.front.value));

		a = selectLargestSuperset(tests,
			[Platform.posix, Platform.x86_64, Platform.dmd]);
		assert(!a.empty);
		assert(a.front.value == 3);

		a = selectLargestSuperset(tests,
			[Platform.posix, Platform.x86_64, Platform.gdc]);
		assert(!a.empty);
		assert(a.front.value == 4);

		a = selectLargestSuperset(tests,
			[Platform.posix, Platform.x86_64, Platform.gdc, Platform.d_avx2]);
		assert(!a.empty);
		assert(a.front.value == 4);
	}
}

bool isSuperSet(const(Platform[]) a, const(Platform[]) b) {
	return a.all!(p => canFind(b, p));
}

unittest {
	auto a = [ Platform.posix, Platform.x86_64 ];
	auto b = [ Platform.posix, Platform.x86_64, Platform.d_avx2 ];

	assert( isSuperSet(a, b));
	assert(!isSuperSet(b, a));
}

