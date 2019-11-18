module dud.pkgdescription.joiningtest;

import std.algorithm.searching : canFind;
import std.stdio;
import std.format : format;
import std.typecons : nullable, Nullable;

import dud.pkgdescription;
import dud.pkgdescription.compare;
import dud.pkgdescription.joining;

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
	"subConfigurations" : {
		"doesNotExist" : "noIdea",
		"semver" : "confA",
		"path" : "confB"
	},
	"subConfigurations-posix" : {
		"pkgdescription" : "confC",
		"someStrangeThing" : "args"
	},
	"configurations": [
		{ "name" : "foo"
		, "dependencies" : {
			"semver": { "path" : "../semver", "optional": true, "version" : ">=0.0.3" },
			"path": { "path" : "../path", "default": false }
		}
		, "dependencies-posix" : {
			"pkgdescription": { "path" : "../../pkgdescription"
				, "version" : ">=1.0.0"
			},
			"dmd": ">=2.81.0"
		}
		, "subConfigurations" : {
			"semver" : "confA2",
			"path" : "confB2",
			"dmd" : "newCTFE"
		}
		, "subConfigurations-posix" : {
			"pkgdescription" : "confC2"
		}
		}
	],
	"targetPath" : "/bin/dud"
}`;
	PackageDescription pkg = jsonToPackageDescription(toParse);
	PackageDescription foo = expandConfiguration(pkg, "foo");
	auto deps = [
		depBuild("semver", ">=0.0.3", "../semver", nullable(true)),
		depBuild("path", "../path", Nullable!(bool).init, nullable(false)),
		depBuild("dmd", parseVersionSpecifier(">=2.80.0")),
		depBuild("pkgdescription", "../../pkgdescription"),
		depBuild("pkgdescription", parseVersionSpecifier(">=1.0.0"),
				"../../pkgdescription", Nullable!(bool).init,
				Nullable!(bool).init, [Platform.posix]),
		depBuild("dmd", parseVersionSpecifier(">=2.81.0"),
				"", Nullable!(bool).init,
				Nullable!(bool).init, [Platform.posix])
	];
	foreach(dep; deps) {
		const bool cf = canFind!((g, h) => areEqual(g, h))
			(foo.dependencies, dep);
		assert(cf, format("\n\t%s\nnot in\n%(\t%s\n%)", dep, foo.dependencies));
	}

	assert(foo.dependencies.length == deps.length, format("%s != %s",
		foo.dependencies.length, deps.length));

	string[string] unspecificSubContig =
		[ "semver" : "confA2", "path" : "confB2", "dmd" : "newCTFE"
		, "doesNotExist" : "noIdea"
		];
	assert(foo.subConfigurations.unspecifiedPlatform == unspecificSubContig,
		format("\nexp: %s\ngot: %s", unspecificSubContig,
			foo.subConfigurations.unspecifiedPlatform));

	assert(foo.subConfigurations.configs.length == 1);
	auto key = [Platform.posix];
	assert(key in foo.subConfigurations.configs);
	string[string] posix = foo.subConfigurations.configs[key];
	string[string] posixExp =
		[ "pkgdescription" : "confC2", "someStrangeThing" : "args" ];

	assert(posix == posixExp, format("\nexp: %s\ngot: %s", posixExp, posix));
}

Dependency depBuild(string n, string pa,
		Nullable!bool optional = Nullable!(bool).init,
		Nullable!bool default_ = Nullable!(bool).init,
		Platform[] p = null)
{
	return depBuild(n, Nullable!(VersionSpecifier).init, pa, optional,
		default_, p);
}

Dependency depBuild(string n, string v, string pa,
		Nullable!bool optional = Nullable!(bool).init,
		Nullable!bool default_ = Nullable!(bool).init,
		Platform[] p = null)
{
	return depBuild(n, parseVersionSpecifier(v), pa, optional, default_, p);
}

Dependency depBuild(string n, Nullable!VersionSpecifier v, string pa = "",
		Nullable!bool optional = Nullable!(bool).init,
		Nullable!bool default_ = Nullable!(bool).init,
		Platform[] p = null)
{
	Dependency ret;
	ret.name = n;
	ret.version_ = v;
	ret.path = UnprocessedPath(pa);
	ret.platforms = p;
	ret.optional = optional;
	ret.default_ = default_;
	return ret;
}

