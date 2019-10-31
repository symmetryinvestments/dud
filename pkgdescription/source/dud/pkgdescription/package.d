module dud.pkgdescription;

import std.typecons : Nullable;

public import dud.pkgdescription.path;
public import dud.pkgdescription.versionspecifier;
public import dud.pkgdescription.udas;
public import dud.pkgdescription.json;
public import dud.pkgdescription.sdl;
public import dud.pkgdescription.platform;

import dud.semver;

@safe pure:

enum TargetType {
	autodetect,
	none,
	executable,
	library,
	sourceLibrary,
	dynamicLibrary,
	staticLibrary,
	object
}

/**
	Describes the build settings and meta data of a single package.

	This structure contains the effective build settings and dependencies for
	the selected build platform. This structure is most useful for displaying
	information about a package in an IDE. Use `TargetDescription` instead when
	writing a build-tool.
*/
struct PackageDescription {
	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToSName)("")
	string name; /// Qualified name of the package

	@JSON!(jGetSemVer, semVerToJ)("version")
	@SDL!(sGetSemVer, semVerToS)("version")
	Nullable!SemVer version_; /// Version of the package

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string description;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string homepage;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] authors;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string copyright;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string license;

	@JSON!(jGetDependencies, dependenciesToJ)("")
	@SDL!(sGetDependencies, dependenciesToS)("dependency")
	Dependency[string] dependencies;

	@JSON!(jGetTargetType, targetTypeToJ)("")
	@SDL!(sGetTargetType, targetTypeToS)("")
	TargetType targetType;

	@JSON!(jGetPath, pathToJ)("")
	@SDL!(sGetPath, pathToS)("")
	Path targetPath;

	@JSON!(jGetStringPlatform, stringPlatformToJ)("")
	@SDL!(sGetStringPlatform, stringPlatformToS)("")
	String targetName;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string targetFileName;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string workingDirectory;

	@JSON!(jGetString, stringToJ)("")
	@SDL!(sGetString, stringToS)("")
	string mainSourceFile;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] dflags; /// Flags passed to the D compiler

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] lflags; /// Flags passed to the linker

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] libs; /// Librariy names to link against (typically using "-l<name>")

	@JSON!(jGetPaths, pathsToJ)("")
	@SDL!(sGetPaths, pathsToS)("")
	Paths copyFiles; /// Files to copy to the target directory

	@JSON!(jGetPaths, pathsToJ)("")
	@SDL!(sGetPaths, pathsToS)("")
	Paths extraDependencyFiles; /// Files to check for rebuild dub project

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] versions; /// D version identifiers to set

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] debugVersions; /// D debug version identifiers to set

	@JSON!(jGetPaths, pathsToJ)("")
	@SDL!(sGetPaths, pathsToS)("")
	Paths importPaths;

	@JSON!(jGetPaths, pathsToJ)("")
	@SDL!(sGetPaths, pathsToS)("")
	Paths sourcePaths;

	@JSON!(jGetPaths, pathsToJ)("")
	@SDL!(sGetPaths, pathsToS)("")
	Paths sourceFiles;

	@JSON!(jGetPaths, pathsToJ)("")
	@SDL!(sGetPaths, pathsToS)("")
	Paths excludedSourceFiles;

	@JSON!(jGetPaths, pathsToJ)("")
	@SDL!(sGetPaths, pathsToS)("")
	Paths stringImportPaths;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] preGenerateCommands; /// commands executed before creating the description

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] postGenerateCommands; /// commands executed after creating the description

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] preBuildCommands; /// Commands to execute prior to every build

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] postBuildCommands; /// Commands to execute after every build

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] preRunCommands; /// Commands to execute prior to every run

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] postRunCommands; /// Commands to execute after every run

	@JSON!(jGetPackageDescriptions, packageDescriptionsToJ)("")
	@SDL!(sGetPackageDescriptions, configurationsToS)("configuration")
	PackageDescription[] configurations;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("")
	string[] platforms;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("x:ddoxFilterArgs")
	string[] ddoxFilterArgs;

	@JSON!(jGetStrings, stringsToJ)("")
	@SDL!(sGetStrings, stringsToS)("x:debugVersionFilters")
	string[] debugVersionFilters;

	@JSON!(jGetStringPlatform, stringPlatformToJ)("")
	@SDL!(sGetStringPlatform, stringPlatformToS)("x:ddoxTool")
	String ddoxTool;

	@JSON!(jGetSubPackages, subPackagesToJ)("")
	@SDL!(sGetSubPackage, subPackagesToS)("subPackage")
	SubPackage[] subPackages;

	@JSON!(jGetBuildRequirements, buildRequirementsToJ)("")
	@SDL!(sGetBuildRequirements, buildRequirementsToS)("")
	BuildRequirement[] buildRequirements;

	@JSON!(jGetStringAA, stringAAToJ)("")
	@SDL!(sGetSubConfig, subConfigsToS)("subConfiguration")
	string[string] subConfigurations;

	@JSON!(jGetStringPlatform, stringPlatformToJ)("")
	@SDL!(sGetStringPlatform, stringPlatformToS)("x:versionFilters")
	String versionFilters;
}

enum BuildRequirement {
	allowWarnings,
	silenceWarnings,
	disallowDeprecations,
	silenceDeprecations,
	disallowInlining,
	disallowOptimization,
	requireBoundsCheck,
	requireContracts,
	relaxProperties,
	noDefaultFlags,
}

struct SubPackage {
	Path path;
	Nullable!PackageDescription inlinePkg;
}

struct Dependency {
	import std.typecons : Nullable;
	string name;
	Nullable!VersionSpecifier version_;
	UnprocessedPath path;
	Nullable!bool optional;
	Nullable!bool default_;
}

struct StringPlatform {
	string str;
	Platform[] platforms;
}

struct String {
	StringPlatform[] strs;
}
