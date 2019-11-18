module dud.pkgdescription.platformselection;

import std.typecons : Nullable;

import dud.pkgdescription;
import dud.pkgdescription.path;
import dud.pkgdescription.exception;

struct PackageDescriptionNoPlatform {
@safe pure:
	string name; /// Qualified name of the package

	SemVer version_; /// Version of the package

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
