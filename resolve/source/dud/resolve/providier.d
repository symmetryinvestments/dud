module dud.resolve.providier;

import std.algorithm.iteration : map, filter;
import std.algorithm.searching : find;
import std.algorithm.sorting : sort;
import std.array : array, empty, front;
import std.exception : enforce;
import std.json;
import std.format : format;
import dud.pkgdescription : PackageDescription, jsonToPackageDescription;
import dud.semver.semver;
import dud.semver.versionrange;

@safe pure:

interface PackageProvidier {
	const(PackageDescription)[] getPackage(string name,
			const(VersionRange) verRange);

	const(PackageDescription) getPackage(string name, string ver);
}

struct PackageDescriptionVersion {
	PackageDescription pkg;
	VersionRange ver;
}

struct DumpFileProvidier {
	// the cache either holds all or non
	bool isLoaded;
	const string dumpFileName;
	PackageDescriptionVersion[][string] cache;
	JSONValue[string] parsedPackages;

	this(string dumpFileName) {
		this.dumpFileName = dumpFileName;
	}

	private void makeSureIsLoaded() {
		import std.file : readText;
		if(!this.isLoaded) {
			JSONValue dump = parseJSON(readText(this.dumpFileName));
			enforce(dump.type == JSONType.array);
			foreach(value; dump.arrayNoRef()) {
				enforce(value.type == JSONType.object);
				enforce("name" in value && value["name"].type == JSONType.string);
				string name = value["name"].str();
				this.parsedPackages[name] = value;
			}
			this.isLoaded = true;
		}
	}

	const(PackageDescriptionVersion)[] getPackages(string name,
			string verRange)
	{
		return this.getPackages(name, parseVersionRange(verRange));
	}

	const(PackageDescriptionVersion)[] getPackages(string name,
			const(VersionRange) verRange)
	{
		import dud.semver.checks : allowsAny;
		this.makeSureIsLoaded();
		auto pkgs = this.ensurePackageIsInCache(name);
		return (*pkgs)
			.filter!(pkg => !pkg.ver.isBranch())
			.filter!(pkg => allowsAny(verRange, pkg.ver))
			.array;
	}

	PackageDescriptionVersion[]* ensurePackageIsInCache(string name) {
		auto pkgs = name in this.cache;
		if(pkgs is null) {
			auto ptr = name in parsedPackages;
			enforce(ptr !is null, format(
				"Couldn't find '%s' in dump.json", name));
			this.cache[name] = dumpJSONToPackage(*ptr);
			pkgs = name in this.cache;
		}
		return pkgs;
	}

	const(PackageDescription) getPackage(string name, string ver) {
		this.makeSureIsLoaded();
		auto pkgs = this.ensurePackageIsInCache(name);
		const VersionRange vr = parseVersionRange(ver);
		auto f = (*pkgs).find!((it, s) => it.ver == vr)(vr);
		enforce(!f.empty, format("No version '%s' for package '%s' could"
			~ " be found in versions [%s]", name, ver,
			(*pkgs).map!(it => it.ver)));
		return f.front.pkg;
	}
}

private PackageDescriptionVersion[] dumpJSONToPackage(JSONValue jv) {
	enforce(jv.type == JSONType.object, format("Expected object got '%s'",
			jv.type));
	auto vers = "versions" in jv;
	enforce(vers !is null, "Couldn't find versions array");
	enforce((*vers).type == JSONType.array, format("Expected array got '%s'",
			(*vers).type));

	return (*vers).arrayNoRef()
		.map!((it) {
			auto ptr = "packageDescription" in it;
			enforce(ptr !is null && (*ptr).type == JSONType.object);
			PackageDescription pkg = jsonToPackageDescription(*ptr);

			auto ver = "version" in it;
			enforce(ver !is null && (*ver).type == JSONType.string);
			VersionRange vr = parseVersionRange((*ver).str());
			return PackageDescriptionVersion(pkg, vr);
		})
		.array
		.sort!((a, b) => a.ver > b.ver)
		.array;
}
