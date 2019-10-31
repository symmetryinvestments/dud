module dud.pkgdescription.path;

import dud.pkgdescription.platform;

struct UnprocessedPath {
	string path;
}

/** Just some string that things he is a path.
*/
struct Path {
	PathPlatform[] platforms;
}

struct PathPlatform {
	UnprocessedPath path;
	Platform[] platforms;
}

struct Paths {
	PathsPlatform[] platforms;
}

struct PathsPlatform {
	UnprocessedPath[] paths;
	Platform[] platforms;
}
