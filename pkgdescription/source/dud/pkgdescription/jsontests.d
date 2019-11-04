module dud.pkgdescription.jsontests;

import std.array : front;
import std.algorithm.searching : canFind;
import std.conv : to;
import std.json;
import std.stdio;
import std.format : format;

import dud.pkgdescription.json;
import dud.pkgdescription.output;
import dud.semver : SemVer;
import dud.pkgdescription;

unittest {
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
	assert(pkg.targetPath.platforms.front.path.path == "/bin/dud",
		format("%s", pkg.targetPath));
	assert(pkg.configurations.length == 1);
	assert(pkg.dependencies.length == 4, to!string(pkg.dependencies.length));
	assert(pkg.dependencies.canFind!(dep => dep.name == "semver"),
			to!string(pkg.dependencies));
	assert(pkg.dependencies.canFind!(dep => dep.name == "path"),
			to!string(pkg.dependencies));
	assert(pkg.dependencies.canFind!(dep => dep.name == "pkgdescription"),
			to!string(pkg.dependencies));
	assert(pkg.dependencies.canFind!(dep => dep.name == "dmd"),
			to!string(pkg.dependencies));

	JSONValue n = pkg.toJSON();
	JSONValue o = parseJSON(toParse);
	assert(n == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n.toPrettyString()));

	PackageDescription pkgFromJ = jsonToPackageDescription(n);
	assert(pkg == pkgFromJ, format("\nexp:\n%s\ngot:\n%s", pkg, pkgFromJ));
}

unittest {
	import dud.semver : SemVer;
	string toParse = `
{
	"authors": [
		"Robert burner Schadek"
	],
	"copyright": "Copyright © 2019, Symmetry Investments",
	"targetName-posix": "dudposix",
	"targetName-windows": "dudwindows",
}`;

	PackageDescription pkg = jsonToPackageDescription(toParse);
	assert(pkg.targetName.strs.length == 2);
	String s = String(
			[ StringPlatform("dudposix", [Platform.posix])
			, StringPlatform("dudwindows", [Platform.windows])
			]);
	assert(pkg.targetName == s,
		format("\ngot:\n%s\nexp:\n%s", pkg.targetName, s));

	JSONValue n = pkg.toJSON();
	PackageDescription pkgFromJ = jsonToPackageDescription(n);
	assert(pkg == pkgFromJ, format("\nexp:\n%s\ngot:\n%s", pkg, pkgFromJ));
}

unittest {
	string toParse = `
{
	"dependencies" : {
		"semver": { "path" : "../semver", "optional": false, "version" : ">=0.0.1" },
		"path": { "path" : "../path", "default": true },
	},
	"dependencies-posix" : {
		"pkgdescription": { "path" : "../../pkgdescription" },
		"dmd": ">=2.80.0"
	}
}`;

	PackageDescription pkg = jsonToPackageDescription(toParse);

	JSONValue n = pkg.toJSON();
	JSONValue o = parseJSON(toParse);
	assert(n == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n.toPrettyString()));

	PackageDescription pkgFromJ = jsonToPackageDescription(n);
	assert(pkg == pkgFromJ, format("\nexp:\n%s\ngot:\n%s", pkg, pkgFromJ));
	JSONValue n2 = pkgFromJ.toJSON();
	assert(n2 == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n2.toPrettyString()));
}

unittest {
	string toParse = `
{
	"postBuildCommands-windows" : [
		"format C:",
		"install linux"
	],
	"postBuildCommands-linux" : [
		"echo \"You are good\""
	]
}`;

	PackageDescription pkg = jsonToPackageDescription(toParse);

	JSONValue n = pkg.toJSON();
	JSONValue o = parseJSON(toParse);
	assert(n == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n.toPrettyString()));

	PackageDescription pkgFromJ = jsonToPackageDescription(n);
	assert(pkg == pkgFromJ, format("\nexp:\n%s\ngot:\n%s", pkg, pkgFromJ));
	JSONValue n2 = pkgFromJ.toJSON();
	assert(n2 == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n2.toPrettyString()));
}

unittest {
	string toParse = `
{
	"subConfigurations" : {
		"semver": "that",
		"path": "this"
	},

	"subConfigurations-x86_64" : {
		"another" : "crazyConfig"
	},

	"workingDirectory" : "/root",
	"workingDirectory-windows" : "C:"

}`;

	PackageDescription pkg = jsonToPackageDescription(toParse);

	JSONValue n = pkg.toJSON();
	JSONValue o = parseJSON(toParse);
	assert(n == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n.toPrettyString()));

	PackageDescription pkgFromJ = jsonToPackageDescription(n);
	assert(pkg == pkgFromJ, format("\nexp:\n%s\ngot:\n%s", pkg, pkgFromJ));
	JSONValue n2 = pkgFromJ.toJSON();
	assert(n2 == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n2.toPrettyString()));
}
