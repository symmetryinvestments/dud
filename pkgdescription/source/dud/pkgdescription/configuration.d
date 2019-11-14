module dud.pkgdescription.configuration;

import std.array : array, empty, front;
import std.algorithm.searching : canFind, find;
import std.algorithm.sorting : sort;
import std.algorithm.iteration : uniq, filter, each;
import std.exception : enforce;
import std.format : format;
import std.traits : FieldNameTuple;
import std.typecons : nullable, Nullable;

import dud.pkgdescription;
import dud.pkgdescription.exception;
import dud.pkgdescription.compare;
import dud.pkgdescription.duplicate;

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

PackageDescription expandConfiguration(const PackageDescription pkg, string confName)
{
	PackageDescription ret = dud.pkgdescription.duplicate.dup(pkg);
	ret.configurations = [];

	const(PackageDescription) conf = findConfiguration(pkg, confName);

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

	return ret;
}

const(PackageDescription) findConfiguration(const PackageDescription pkg,
	string confName)
{
	auto ret = find!((a, b) => a.name == b)(pkg.configurations, confName);
	enforce!UnknownConfiguration(!ret.empty,
		format("'%s' is a unknown configuration of package '%s'", pkg.name));
	return ret.front;
}

Dependency dup(const(Dependency) old) {
	Dependency ret;
	ret.name = dud.pkgdescription.duplicate.dup(old.name);
	if(!old.version_.isNull()) {
		ret.version_ = nullable(
			dud.pkgdescription.duplicate.dup(old.version_.get()));
	}
	ret.platforms = dud.pkgdescription.duplicate.dup(old.platforms);
	ret.path = dud.pkgdescription.duplicate.dup(old.path);
	if(!old.default_.isNull()) {
		ret.default_ = nullable(old.default_.get());
	}
	if(!old.optional.isNull()) {
		ret.optional = nullable(old.optional.get());
	}
	return ret;
}

Dependency[] join(const(Dependency[]) a, const(Dependency[]) b) {
	Dependency[] ret;
	a.filter!(dep => !canFind!((g, h) => g.name == h)(b, dep.name))
		.each!(dep => ret ~= dud.pkgdescription.duplicate.dup(dep));
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
