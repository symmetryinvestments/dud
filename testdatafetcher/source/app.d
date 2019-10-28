import std.algorithm.searching : startsWith, endsWith;
import std.stdio;
import std.json;
import std.file;
import std.format;
import std.string : indexOf;
import std.exception : enforce;

import dubproxy.git;
import dubproxy;
import dubproxy.options;

enum OutDir = "outdir";

DubProxyFile getCodeDlangOrgData() @trusted {
	enum DFN = "dump.json";
	if(exists(DFN)) {
		return fromFile(DFN);
	}
	DubProxyFile dpf = getCodeDlangOrgCopy();
	toFile(dpf, DFN);
	return dpf;
}

string removeRepoPrefix(string url) {
	enum gh = "https://github.com/";
	enum gl = "https://gitlab.com/";
	enum bb = "https://bitbucket.com/";

	foreach(it; [gh, gl, bb]) {
		if(url.startsWith(it)) {
			return url[it.length .. $];
		}
	}
	assert(false, "unhandled " ~ url);
}

string removeUserAndGit(string url) {
	ptrdiff_t s = url.indexOf('/');
	enforce(s != -1, url);
	url = url[s + 1 .. $];
	enum g = ".git";
	enforce(url.endsWith(g), url);
	return url[0 .. $ - g.length];
}

void main() {
	DubProxyOptions options;
	DubProxyFile theData = getCodeDlangOrgData();
	foreach(string key, string value; theData.packages) {
		string less = value.removeRepoPrefix().removeUserAndGit();
		string od = format("%s/%s/", OutDir, less);
		writeln(od);

		cloneBare(value, LocalGit.no, od, options);
	}
}

void infoToJSON(Out)(auto ref Out o, JSONValue info) {
}

void infoToSDL(Out)(auto ref Out o, JSONValue info) {
}
