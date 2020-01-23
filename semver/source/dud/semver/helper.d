module dud.semver.helper;

@safe pure:

bool isDigit(const char c) nothrow @nogc {
	return c > 47 && c < 58;
}
