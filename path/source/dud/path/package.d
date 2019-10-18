module dub.path;

/** Just some string that things he is a path.
*/
struct Path {
	string path;
}

/** An absolute path that is tailerd for the used OS.
*/
struct AbsoluteNativePath {
	string path;
}

struct CombinedPath {
	Path path;
	AbsoluteNativePath absPath;
}
