module dud.pkgdescription.jsontests;

import std.conv : to;
import std.json;
import std.stdio;
import std.format : format;

import dud.pkgdescription.json;
import dud.pkgdescription.output;
import dud.pkgdescription : PackageDescription, TargetType;

unittest {
	import dud.semver : SemVer;
	string toParse = `
{
	"authors": [
		"Robert burner Schadek"
	],
	"copyright": "Copyright © 2019, Symmetry Investments",
	"description": "A dub replacement",
	"license": "LGPL3",
	"version": "1.0.0",
	"targetType": "library",
	"name": "dud",
	"dependencies" : {
		"semver": { "path" : "../semver", "optional": false, "version" : ">=0.0.1" },
		"path": { "path" : "../path", "default": true },
		"pkgdescription": { "path" : "../../pkgdescription" },
		"dmd": ">=2.80.0"
	},
	"configurations": [
		{ "name" : "foo"
		, "targetType" : "executable"
		}
	],
	"targetPath" : "/bin/dud"
}`;

	PackageDescription pkg = jsonToPackageDescription(toParse);
	assert(pkg.description == "A dub replacement", pkg.description);
	assert(pkg.license == "LGPL3", pkg.license);
	assert(pkg.version_ == SemVer("1.0.0"), pkg.version_.toString);
	assert(pkg.targetPath.path == "/bin/dud", pkg.targetPath.path);
	assert(pkg.configurations.length == 1);
	assert(pkg.dependencies.length == 4, to!string(pkg.dependencies.length));
	assert("semver" in pkg.dependencies);
	assert("path" in pkg.dependencies);
	assert("pkgdescription" in pkg.dependencies);
	assert("dmd" in pkg.dependencies);

	JSONValue n = pkg.toJSON();
	JSONValue o = parseJSON(toParse);
	assert(n == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n.toPrettyString()));
}
