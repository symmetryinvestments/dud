module dud.testdata.inlinetestdatagen;

import std.array : array, empty, front;
import std.algorithm.searching : startsWith;
import std.algorithm.iteration : filter;
import std.exception : enforce;
import std.format : format;
import std.json;
import std.stdio;

import dud.semver.semver;
import dud.semver.parse;
import dud.semver.versionrange;

template ToJSONType(T) {
	import std.traits : isIntegral, isFloatingPoint;
	static if(is(T == string)) {
		enum ToJSONType = JSONType.string;
	} else static if(isIntegral!T) {
		enum ToJSONType = JSONType.integer;
	} else static if(isFloatingPoint!T) {
		enum ToJSONType = JSONType.float_;
	} else {
		static assert(false, T.stringof ~ " not handled");
	}
}

JSONValue getNested(JSONValue j, string[] path) @safe {
	string[] copy = path;
	JSONValue ptr = j;
	while(!copy.empty) {
		enforce(ptr.type == JSONType.object, format(
				"Path '%--(%s.%)' does not consists of objects '%s'"
				, path, j.toPrettyString()));
		if(copy.front !in ptr) {
			return JSONValue(null);
		}

		ptr = ptr[copy.front];
		copy = copy[1 .. $];
	}
	return ptr;
}

T getNested(T)(JSONValue j, string member) @safe {
	enforce(j.type == JSONType.object, format(
			"Trying to get member of name '%s' but JSONValue is of type '%s'"
			, member, j.type));
	enforce(member in j, () @trusted {
			return format(
				"No member of name '%s' found in keys '[%(%s,%)]' JSONValue of '%s' "
				, member
				, j.objectNoRef().keys
				, j.toPrettyString);
		}());

	enum JSONType expJT = ToJSONType!T;
	enforce(j[member].type == expJT, format(
			"Member '%s' expected to have type '%s' but got '%s'\n%s"
			, member, expJT, j[member].type, j.toPrettyString()));

	return j[member].get!T();
}

T getNested(T)(JSONValue j, string[] path) @safe {
	JSONValue acc = j.getNested(path);

	enum JSONType expJT = ToJSONType!T;
	enforce(acc.type == expJT, format(
			"Member '%--(%s.%)' expected to have type '%s' but got '%s'\n%s"
			, path, expJT, acc.type, j.toPrettyString()));

	return acc.get!T();
}

struct DepImpl {
	string name;
	VersionRange ver;
}

alias PackageDep = DepImpl;
alias ToolDep = DepImpl;

struct PackageVersion {
	string name;
	SemVer ver;
	string branchName;

	PackageDep[] pkgDeps;
	ToolDep[] toolDeps;

	PackageVersion[] subPackages;
	PackageVersion[] configurations;
}

PackageVersion toPackageVersion(JSONValue j, string prefix = "") @trusted {
	PackageVersion ret;
	JSONValue ver = j.getNested(["version"]);
	if(ver.type == JSONType.string) {
		string verStr = ver.get!string();
		if(verStr.startsWith("~")) {
			ret.branchName = verStr;
		} else if(!verStr.empty) {
			ret.ver = verStr.parseSemVer();
		}
	}

	JSONValue nameJ = j.getNested([prefix, "name"].filter!(i => !i.empty).array);
	if(nameJ.type == JSONType.string) {
		ret.name = nameJ.get!string();
	}

	auto deps = j.getNested([prefix, "dependencies"].filter!(i => !i.empty).array);
	if(deps.type == JSONType.object) {
		foreach(string key, JSONValue value; deps.objectNoRef()) {
			PackageDep pd;
			pd.name = key;
			if(value.type == JSONType.string) {
				string s = value.get!string();
				if(s.startsWith("v")) {
					continue;
				}
				pd.ver = s.parseVersionRange();
				ret.pkgDeps ~= pd;
			} else {
				writefln("dep %s %s", key, value.toString());
			}
		}
	} else if(deps.type != JSONType.null_) {
		assert(false, deps.toPrettyString());
	}

	auto toolChain = j.getNested([prefix, "toolchainRequirements"]
			.filter!(i => !i.empty)
			.array);

	if(toolChain.type == JSONType.object) {
		foreach(string key, JSONValue value; toolChain.objectNoRef()) {
			ToolDep td;
			td.name = key;
			if(value.type == JSONType.string) {
				td.ver = value.get!string().parseVersionRange();
				ret.toolDeps ~= td;
			} else {
				writefln("tool %s %s", key, value.toString());
			}
		}
	} else if(toolChain.type != JSONType.null_) {
		assert(false, deps.toPrettyString());
	}

	auto subPackages = j.getNested([prefix, "subPackages"]
			.filter!(i => !i.empty)
			.array);

	if(subPackages.type == JSONType.array) {
		foreach(JSONValue value; subPackages.arrayNoRef()) {
			ret.subPackages ~= toPackageVersion(value);
		}
	}

	auto configurations = j.getNested([prefix, "configurations"]
			.filter!(i => !i.empty)
			.array);
	if(configurations.type == JSONType.array) {
		foreach(JSONValue value; configurations.arrayNoRef()) {
			ret.configurations ~= toPackageVersion(value);
		}
	}

	return ret;
}

unittest {
	JSONValue jv = parseJSON(
`
{
    "packageDescription": {
        "authors": [
            "Thomas Stuart Bockman"
        ],
        "buildOptions": [
            "ignoreUnknownPragmas"
        ],
        "copyright": "Copyright © 2015, Thomas Stuart Bockman",
        "description": "Checked integer math types and operations.",
        "license": "BSL-1.0",
        "name": "checkedint",
        "subPackages": [
            {
                "authors": [
                    "Thomas Stuart Bockman"
                ],
                "buildOptions": [
                    "ignoreUnknownPragmas"
                ],
                "copyright": "Copyright © 2015, Thomas Stuart Bockman",
                "dependencies": {
                    "checkedint": ">=0.0.0"
                },
                "description": "Exhaustive tests for the checkedint package. Verifies correctness and measures performance.",
                "license": "BSL-1.0",
                "mainSourceFile": "source\/package.d",
                "name": "tests",
                "path": ".\/tests\/",
                "targetType": "executable"
            }
        ],
        "targetType": "library",
        "toolchainRequirements": {
            "frontend": ">=2.71.0"
        }
    },
    "version": "2.2.1"
}`);
	PackageVersion pv = toPackageVersion(jv, "packageDescription");
	writeln(pv);
}

unittest {
	JSONValue jv = parseJSON(
`
	{
	    "packageDescription": {
	        "authors": [
	            "Andrej Petrović"
	        ],
	        "configurations": [
	            {
	                "name": "library",
	                "targetType": "library"
	            },
	            {
	                "dependencies": {
	                    "imageformats": "7.0.2",
	                    "silly": "1.0.2"
	                },
	                "name": "unittest",
	                "targetType": "library"
	            }
	        ],
	        "description": "A D language implementation of https:\/\/github.com\/KdotJPG\/OpenSimplex2",
	        "license": "public domain",
	        "name": "open-simplex-2"
	    },
	    "version": "1.0.1"
}`);
	PackageVersion pv = toPackageVersion(jv, "packageDescription");
	writeln(pv);
}

struct Package {
	string name;
	PackageVersion[] versions;
}

Package toPackage(JSONValue jv) {
	Package ret;
	ret.name = jv.getNested!string("name");

	auto versions = jv.getNested(["versions"]);
	if(versions.type == JSONType.array) {
		foreach(JSONValue value; versions.arrayNoRef()) {
			try {
				ret.versions ~= value.toPackageVersion("packageDescription");
			} catch(Exception e) {
				writeln(e.toString());
			}
		}
	}
	return ret;
}

unittest {
	JSONValue jv = parseJSON(
`{
        "name": "vibenews",
        "repository": {
            "kind": "github",
            "project": "vibenews"
        },
        "versions": [
            {
                "packageDescription": {
                    "authors": [
                        "Sönke Ludwig"
                    ],
                    "copyright": "Copyright (c) 2012-2018 Sönke Ludwig",
                    "dependencies": {
                        "antispam": "~>0.1.2",
                        "userman": "~>0.4.0",
                        "vibe-d": ">=0.8.0 <0.10.0-0"
                    },
                    "description": "Combined web forum and NNTP server implementation for stand-alone newsgroups",
                    "homepage": "https:\/\/github.com\/rejectedsoftware\/vibenews",
                    "license": "AGPL-3.0",
                    "name": "vibenews"
                },
                "version": "~master"
            },
            {
                "packageDescription": {
                    "authors": [
                        "Sönke Ludwig"
                    ],
                    "copyright": "Copyright (c) 2012-2014 Sönke Ludwig",
                    "dependencies": {
                        "antispam": "~>0.0.5",
                        "userman": "~>0.2.3",
                        "vibe-d": "~>0.7.22"
                    },
                    "description": "Combined web forum and NNTP server implementation for stand-alone newsgroups",
                    "homepage": "https:\/\/github.com\/rejectedsoftware\/vibenews",
                    "license": "AGPL-3.0",
                    "name": "vibenews",
                    "versions": [
                        "VibeDefaultMain"
                    ]
                },
                "version": "0.6.7"
            }
        ]
    }`);
	Package pv = toPackage(jv);
	writeln(pv);
}

Package[string] toPackages(JSONValue jv) {
	Package[string] ret;
	foreach(JSONValue it; jv.arrayNoRef()) {
		Package p = toPackage(it);
		enforce(p.name !in ret, p.name);
		ret[p.name] = p;
	}
	return ret;
}

unittest {
	JSONValue jv = parseJSON(
`[ {
        "name": "vibenews",
        "repository": {
            "kind": "github",
            "project": "vibenews"
        },
        "versions": [
            {
                "packageDescription": {
                    "authors": [
                        "Sönke Ludwig"
                    ],
                    "copyright": "Copyright (c) 2012-2014 Sönke Ludwig",
                    "dependencies": {
                        "antispam": "~>0.0.5",
                        "userman": "~>0.2.3",
                        "vibe-d": "~>0.7.22"
                    },
                    "description": "Combined web forum and NNTP server implementation for stand-alone newsgroups",
                    "homepage": "https:\/\/github.com\/rejectedsoftware\/vibenews",
                    "license": "AGPL-3.0",
                    "name": "vibenews",
                    "versions": [
                        "VibeDefaultMain"
                    ]
                },
                "version": "0.6.7"
            }
        ]
}
, {
        "name": "vibelog",
        "repository": {
            "kind": "github",
            "project": "vibelog"
        },
        "versions": [
            {
                "packageDescription": {
                    "authors": [
                        "Sönke Ludwig"
                    ],
                    "configurations": [
                        {
                            "name": "standalone",
                            "targetType": "executable",
                            "versions": [
                                "VibeDefaultMain"
                            ]
                        },
                        {
                            "excludedSourceFiles": [
                                "source\/app.d"
                            ],
                            "name": "library",
                            "targetType": "library"
                        }
                    ],
                    "dependencies": {
                        "diskuto": "~>1.5",
                        "stringex": "~>0.1.0",
                        "vibe-d": ">=0.7.31 <0.10.0"
                    },
                    "description": "A light-weight embeddable blog implementation",
                    "homepage": "https:\/\/github.com\/rejectedsoftware\/vibelog",
                    "license": "AGPL-3.0",
                    "name": "vibelog"
                },
                "version": "~master"
            }
		]
	}
]`);
	Package[string] pkgs = toPackages(jv);
}
