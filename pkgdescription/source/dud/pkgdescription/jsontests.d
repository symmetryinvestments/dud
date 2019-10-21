module dud.pkgdescription.jsontests;

import dud.pkgdescription.json;
import dud.pkgdescription : PackageDescription, TargetType;

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
		"semver": { "path" : "semver", "optional": false, "version" : ">=0.0.1" },
		"path": { "path" : "path", "default": true },
		"pkgdescription": { "path" : "pkgdescription" },
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
}
