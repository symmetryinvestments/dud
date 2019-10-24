module dud.sdlang2.treevisitor;

import std.traits : Unqual;
import dud.sdlang2.ast;
import dud.sdlang2.visitor;
import dud.sdlang2.tokenmodule;

@safe:

class TreeVisitor : ConstVisitor {
	import std.stdio : write, writeln;

	alias accept = ConstVisitor.accept;

	int depth;

	this(int d) {
		this.depth = d;
	}

	void genIndent() {
		foreach(i; 0 .. this.depth) {
			write("    ");
		}
	}

	override void accept(const(Root) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Tags) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Tag) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(IDFull) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(IDSuffix) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Values) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Attributes) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(Attribute) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(OptChild) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}

	override void accept(const(TagTerminator) obj) {
		this.genIndent();
		writeln(Unqual!(typeof(obj)).stringof,":", obj.ruleSelection);
		++this.depth;
		super.accept(obj);
		--this.depth;
	}
}
