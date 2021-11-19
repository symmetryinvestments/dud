module dud.resolve.assignment;

import dud.resolve.incompatibility;
import dud.resolve.term;

struct Assignment {
	Term term;
	const Incompatibility cause;
	const int decisionLevel;
	const int index;
}
