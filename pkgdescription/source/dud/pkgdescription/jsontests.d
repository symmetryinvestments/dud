module dud.pkgdescription.jsontests;

import std.array : front;
import std.algorithm.searching : canFind;
import std.conv : to;
import std.json;
import std.stdio;
import std.format : format;

import dud.pkgdescription.json;
import dud.pkgdescription.output;
import dud.pkgdescription.helper;
import dud.semver : SemVer;
import dud.pkgdescription;
import dud.pkgdescription.validation;
import dud.pkgdescription.duplicate : ddup = dup;

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
	assert(pkg.targetPath.path == "/bin/dud",
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

	PackageDescription copy = ddup(pkg);
	assert(pkg == copy, format("\nexp:\n%s\ngot:\n%s", pkg, copy));

	validate(copy);
}

unittest {
	import dud.semver : SemVer;
	string toParse = `
{
	"name" : "Foo",
	"authors": [
		"Robert burner Schadek"
	],
	"copyright": "Copyright © 2019, Symmetry Investments",
	"targetName-posix": "dudposix",
	"targetName-windows": "dudwindows"
}`;

	PackageDescription pkg = jsonToPackageDescription(toParse);
	assert(pkg.targetName.platforms.length == 2);
	String s = String(
			[ StringPlatform("dudposix", [Platform.posix])
			, StringPlatform("dudwindows", [Platform.windows])
			]);
	assert(pkg.targetName == s,
		format("\ngot:\n%s\nexp:\n%s", pkg.targetName, s));

	JSONValue n = pkg.toJSON();
	PackageDescription pkgFromJ = jsonToPackageDescription(n);
	assert(pkg == pkgFromJ, format("\nexp:\n%s\ngot:\n%s", pkg, pkgFromJ));

	PackageDescription copy = ddup(pkg);
	assert(pkg == copy, format("\nexp:\n%s\ngot:\n%s", pkg, copy));

	validate(copy);
}

unittest {
	string toParse = `
{
	"name" : "Foo",
	"dependencies" : {
		"semver": { "path" : "../semver", "optional": false, "version" : ">=0.0.1" },
		"path": { "path" : "../path", "default": true }
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

	PackageDescription copy = ddup(pkg);
	assert(pkg == copy, format("\nexp:\n%s\ngot:\n%s", pkg, copy));

	validate(copy);
}

unittest {
	string toParse = `
{
	"name" : "Foo",
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

	PackageDescription copy = ddup(pkg);
	assert(pkg == copy, format("\nexp:\n%s\ngot:\n%s", pkg, copy));

	validate(copy);
}

unittest {
	string toParse = `
{
	"name" : "Foo",
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

	PackageDescription copy = ddup(pkg);
	assert(pkg == copy, format("\nexp:\n%s\ngot:\n%s", pkg, copy));

	validate(copy);
}

unittest {
	string toParse = `
{
	"name" : "Foo",
	"buildRequirements" : [ "allowWarnings", "disallowDeprecations" ]
}
`;

	PackageDescription pkg = jsonToPackageDescription(toParse);
	JSONValue n = toJSON(pkg);
	JSONValue o = parseJSON(toParse);
	assert(n == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n.toPrettyString()));

	PackageDescription pkgFromJ = jsonToPackageDescription(n);
	assert(pkg == pkgFromJ, format("\nexp:\n%s\ngot:\n%s", pkg, pkgFromJ));
	JSONValue n2 = pkgFromJ.toJSON();
	assert(n2 == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n2.toPrettyString()));

	PackageDescription copy = ddup(pkg);
	assert(pkg == copy, format("\nexp:\n%s\ngot:\n%s", pkg, copy));

	validate(copy);
}

unittest {
	string toParse = `
{
	"name" : "Foo",
	"buildOptions" : [ "verbose" ],
	"buildOptions-posix" : [ "inline", "property"],
	"buildOptions-windows" : ["betterC" ]
}
`;

	PackageDescription pkg = jsonToPackageDescription(toParse);
	JSONValue n = toJSON(pkg);
	JSONValue o = parseJSON(toParse);
	assert(n == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n.toPrettyString()));

	PackageDescription pkgFromJ = jsonToPackageDescription(n);
	assert(pkg == pkgFromJ, format("\nexp:\n%s\ngot:\n%s", pkg, pkgFromJ));
	JSONValue n2 = pkgFromJ.toJSON();
	assert(n2 == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n2.toPrettyString()));

	PackageDescription copy = ddup(pkg);
	assert(pkg == copy, format("\nexp:\n%s\ngot:\n%s", pkg, copy));

	validate(copy);
}

unittest {
	string toParse = `
{
	"name" : "Foo",
	"subPackages" : [
		{
			"name" : "sub1"
		}
		, {
			"name" : "sub2",
			"targetType" : "executable"
		}
		, "../some/sub/package"

	]
}
`;

	PackageDescription pkg = jsonToPackageDescription(toParse);
	assert(pkg.subPackages.length == 3);
	assert(pkg.subPackages[0].inlinePkg.get().name == "sub1",
			pkg.subPackages[0].inlinePkg.get().name);
	assert(pkg.subPackages[1].inlinePkg.get().name == "sub2",
			pkg.subPackages[1].inlinePkg.get().name);
	JSONValue n = toJSON(pkg);
	JSONValue o = parseJSON(toParse);
	assert(n == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n.toPrettyString()));

	PackageDescription pkgFromJ = jsonToPackageDescription(n);
	assert(pkg == pkgFromJ, format("\nexp:\n%s\ngot:\n%s", pkg, pkgFromJ));
	JSONValue n2 = pkgFromJ.toJSON();
	assert(n2 == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n2.toPrettyString()));

	PackageDescription copy = ddup(pkg);
	assert(pkg == copy, format("\nexp:\n%s\ngot:\n%s", pkg, copy));

	validate(copy);
}

unittest {
	string toParse = `
{
    "authors": [
        "Guillaume Piolat",
        "Andrej Mitrovic",
        "Sean M. Costello (Hilbert transformer)"
    ],
    "copyright": "Steinberg",
    "description": "Audio plugins framework. VST client + host, AU client, UI widgets.",
    "homepage": "http:\/\/github.com\/p0nce\/dplug\/",
    "license": "VST",
    "name": "dplug",
    "subPackages": [
        {
            "dependencies": {
                "gfm:core": "~>6.0"
            },
            "importPaths": [
                "core"
            ],
            "name": "core",
            "sourcePaths": [
                "core\/dplug\/core"
            ]
        },
        {
            "dependencies": {
                "dplug:core": "*",
                "gfm:math": "~>6.0"
            },
            "importPaths": [
                "dsp"
            ],
            "name": "dsp",
            "sourcePaths": [
                "dsp\/dplug\/dsp"
            ]
        },
        {
            "dependencies": {
                "dplug:core": "*"
            },
            "importPaths": [
                "client"
            ],
            "name": "client",
            "sourcePaths": [
                "client\/dplug\/client"
            ]
        },
        {
            "dependencies": {
                "derelict-util": "~>2.0",
                "dplug:core": "*",
                "dplug:vst": "*"
            },
            "importPaths": [
                "host"
            ],
            "name": "host",
            "sourcePaths": [
                "host\/dplug\/host"
            ]
        },
        {
            "dependencies": {
                "dplug:client": "*"
            },
            "importPaths": [
                "vst"
            ],
            "name": "vst",
            "sourcePaths": [
                "vst\/dplug\/vst"
            ]
        },
        {
            "dependencies": {
                "dplug:client": "*"
            },
            "dependencies-osx": {
                "derelict-carbon": "~>0.0",
                "derelict-cocoa": "~>0.0"
            },
            "importPaths": [
                "au"
            ],
            "name": "au",
            "sourcePaths": [
                "au\/dplug\/au"
            ]
        },
        {
            "dependencies": {
                "ae-graphics": "~>0.0",
                "dplug:core": "*",
                "gfm:core": "~>6.0",
                "gfm:math": "~>6.0"
            },
            "dependencies-osx": {
                "derelict-carbon": "~>0.0",
                "derelict-cocoa": "~>0.0"
            },
            "importPaths": [
                "window"
            ],
            "importPaths-windows": [
                "platforms\/windows"
            ],
            "libs-windows": [
                "gdi32",
                "user32"
            ],
            "name": "window",
            "sourcePaths": [
                "window\/dplug\/window"
            ],
            "sourcePaths-windows": [
                "platforms\/windows"
            ]
        },
        {
            "dependencies": {
                "ae-graphics": "~>0.0",
                "dplug:client": "*",
                "dplug:core": "*",
                "dplug:window": "*",
                "gfm:math": "~>6.0",
                "imageformats": "~>6.0"
            },
            "importPaths": [
                "gui"
            ],
            "name": "gui",
            "sourcePaths": [
                "gui\/dplug\/gui"
            ]
        }
    ],
    "targetType": "none",
    "version": "2.0.65"
}
`;

	PackageDescription pkg = jsonToPackageDescription(toParse);
	JSONValue n = toJSON(pkg);
	JSONValue o = parseJSON(toParse);
	assert(n == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n.toPrettyString()));

	PackageDescription pkgFromJ = jsonToPackageDescription(n);
	assert(pkg == pkgFromJ, format("\nexp:\n%s\ngot:\n%s\n\n%s", pkg, pkgFromJ,
		pkgCompare(pkg, pkgFromJ)
	));
	JSONValue n2 = pkgFromJ.toJSON();
	assert(n2 == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n2.toPrettyString()));

	PackageDescription copy = ddup(pkg);
	assert(pkg == copy, format("\nexp:\n%s\ngot:\n%s", pkg, copy));

	validate(copy);
}

unittest {
	string toParse = `
{
	"name" : "Foo",
	"-ddoxTool" : "ddoxFoo"
}
`;

	PackageDescription pkg = jsonToPackageDescription(toParse);
	assert(pkg.ddoxTool.platforms.front.str == "ddoxFoo");
	JSONValue n = toJSON(pkg);
	JSONValue o = parseJSON(toParse);
	assert(n == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n.toPrettyString()));

	PackageDescription pkgFromJ = jsonToPackageDescription(n);
	assert(pkg == pkgFromJ, format("\nexp:\n%s\ngot:\n%s\n\n%s", pkg, pkgFromJ,
		pkgCompare(pkg, pkgFromJ)
	));
	JSONValue n2 = pkgFromJ.toJSON();
	assert(n2 == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n2.toPrettyString()));

	PackageDescription copy = ddup(pkg);
	assert(pkg == copy, format("\nexp:\n%s\ngot:\n%s", pkg, copy));

	validate(copy);
}

unittest {
	string toParse = `
{
	"name" : "Foo",
	"toolchainRequirements" : {
		"dud" : ">=1.0.0"
	}
}
`;

	PackageDescription pkg = jsonToPackageDescription(toParse);
	JSONValue n = toJSON(pkg);
	JSONValue o = parseJSON(toParse);
	assert(n == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n.toPrettyString()));

	PackageDescription pkgFromJ = jsonToPackageDescription(n);
	assert(pkg == pkgFromJ, format("\nexp:\n%s\ngot:\n%s\n\n%s", pkg, pkgFromJ,
		pkgCompare(pkg, pkgFromJ)
	));
	JSONValue n2 = pkgFromJ.toJSON();
	assert(n2 == o, format("\nexp:\n%s\ngot:\n%s", o.toPrettyString(),
		n2.toPrettyString()));

	PackageDescription copy = ddup(pkg);
	assert(pkg == copy, format("\nexp:\n%s\ngot:\n%s", pkg, copy));

	validate(copy);
}

unittest {
	string toParse = `
{
	"name" : "Foo",
    "configurations": [
        {
            "name": "winapi",
            "platforms": [
                "windows-x86_64",
                "windows-x86_mscoff"
            ],
            "targetType": "library",
            "versions": [
                "EventcoreWinAPIDriver"
            ]
        },
        {
            "name": "select",
            "platforms": [
                "posix",
                "windows-x86_64",
                "windows-x86_mscoff"
            ]
		},
        {
            "name": "epoll",
            "platforms": [
                "linux"
            ],
            "targetType": "library",
            "versions": [
                "EventcoreEpollDriver"
            ]
        }
	]
}
`;

	PackageDescription pkg = jsonToPackageDescription(toParse);
	JSONValue n = toJSON(pkg);
	//JSONValue o = parseJSON(toParse);

	PackageDescription pkgFromJ = jsonToPackageDescription(n);
	assert(pkg == pkgFromJ, format("\nexp:\n%s\ngot:\n%s\n\n%s", pkg, pkgFromJ,
		pkgCompare(pkg, pkgFromJ)
	));
	JSONValue n2 = pkgFromJ.toJSON();

	PackageDescription copy = ddup(pkg);
	assert(pkg == copy, format("\nexp:\n%s\ngot:\n%s", pkg, copy));

	validate(copy);
}

unittest {
	string toParse = `
{
	"name" : "Foo",
    "toolchainRequirements": {
        "ldc": ">=1.15.0"
    },
    "version": "~master"
}

`;

	PackageDescription pkg = jsonToPackageDescription(toParse);
	PackageDescription copy = ddup(pkg);
	assert(pkg == copy, format("\nexp:\n%s\ngot:\n%s", pkg, copy));

	validate(copy);
}

unittest {
	string toParse = `
{
	"name" : "Foo",
    "buildTypes": {
        "release": {}
    }
}
`;

	PackageDescription pkg = jsonToPackageDescription(toParse);
	JSONValue copy = toJSON(pkg);
	PackageDescription pkg2 = jsonToPackageDescription(copy);
	assert(pkg == pkg2, format("\nexp:\n%s\ngot:\n%s", pkg, copy));

	validate(pkg2);
}
