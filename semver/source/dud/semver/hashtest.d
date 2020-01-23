module dud.semver.hashtest;

@safe pure private:
import std.format : format;

import dud.semver.parse;
import dud.semver.semver;

unittest {
	string[][] prs = [
		[], ["foo"], ["1", "2"], ["1", "foo"], ["1", "baz"], ["1", "3"]
	];

	string[][] bs = [
		[], ["somehash"], ["somehash", "morehash", "dmd"]
	];

	SemVer[] semvers;
	foreach(mj; 0 .. 3) {
		foreach(mi; 0 .. 3) {
			foreach(p; 0 .. 3) {
				foreach(pr; prs) {
					foreach(b; bs) {
						semvers ~= SemVer(mj, mi, p, pr, b);
					}
				}
			}
		}
	}

	bool[SemVer] hashes;
	foreach(sv; semvers) {
		assert(sv !in hashes);
		hashes[sv] = true;
		assert(sv in hashes);
	}
}
