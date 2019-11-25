module dud.resolve.providier;

import std.algorithm.iteration : map;
import std.algorithm.searching : find;
import std.array : array, empty, front;
import std.exception : enforce;
import std.json;
import std.format : format;
import dud.pkgdescription : PackageDescription, jsonToPackageDescription;
import dud.semver;
import dud.pkgdescription.versionspecifier : parseVersionSpecifier, VersionSpecifier;

@safe pure:

interface PackageProvidier {
	const(PackageDescription)[] getPackage(string name,
			const(VersionSpecifier) verRange);

	const(PackageDescription) getPackage(string name, string ver);
}

struct DumpFileprovidier {
	// the cache either holds all or non
	PackageDescription[][string] cache;
	JSONValue[string] parsedPackages;

	this(string dumpFileName) {
		import std.file : readText;
		JSONValue dump = parseJSON(readText(dumpFileName));
		enforce(dump.type == JSONType.array);
		foreach(value; dump.arrayNoRef()) {
			enforce(value.type == JSONType.object);
			enforce("name" in value && value["name"].type == JSONType.string);
			string name = value["name"].str();
			this.parsedPackages[name] = value;
		}
	}

	const(PackageDescription)[] getPackage(string name,
			string verRange)
	{
		return getPackage(name, parseVersionSpecifier(verRange));
	}

	const(PackageDescription)[] getPackage(string name,
			const(VersionSpecifier) verRange)
	{
		assert(false);
	}

	const(PackageDescription) getPackage(string name, string ver) {
		auto pkgs = name in this.cache;
		if(pkgs is null) {
			auto ptr = name in parsedPackages;
			enforce(ptr !is null, format(
				"Couldn't find '%s' in dump.json", name));
			this.cache[name] = dumpJSONToPackage(*ptr);
			pkgs = name in this.cache;
		}

		auto f = (*pkgs).find!((it, s) => it.version_.m_version == s)(ver);
		enforce(!f.empty, format("No version '%s' for package '%s' could"
			~ " be found in versions [%s]", name, ver,
			(*pkgs).map!(it => it.version_.m_version)));
		return f.front;
	}
}

private PackageDescription[] dumpJSONToPackage(JSONValue jv) {
	enforce(jv.type == JSONType.array);
	return jv.arrayNoRef()
		.map!((it) {
			auto ptr = "packageDescription" in it;
			enforce(ptr !is null && (*ptr).type == JSONType.object);
			PackageDescription pkg = jsonToPackageDescription(*ptr);
			enforce(pkg.version_.m_version.empty);

			auto ver = "version" in it;
			enforce(ver !is null && (*ver).type == JSONType.string);
			pkg.version_ = SemVer((*ver).str());
			return pkg;
		})
		.array;
}
