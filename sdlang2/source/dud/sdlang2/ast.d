module dud.sdlang2.ast;

import dud.sdlang2.tokenmodule;

import dud.sdlang2.visitor;

@safe:

class Node {}

enum RootEnum {
	T,
	E,
}

class Root : Node {
	RootEnum ruleSelection;
	Tags tags;

	this(RootEnum ruleSelection, Tags tags) {
		this.ruleSelection = ruleSelection;
		this.tags = tags;
	}

	this(RootEnum ruleSelection) {
		this.ruleSelection = ruleSelection;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum TagsEnum {
	Tag,
	TagFollow,
}

class Tags : Node {
	TagsEnum ruleSelection;
	Tag tag;
	Tags follow;

	this(TagsEnum ruleSelection, Tag tag) {
		this.ruleSelection = ruleSelection;
		this.tag = tag;
	}

	this(TagsEnum ruleSelection, Tag tag, Tags follow) {
		this.ruleSelection = ruleSelection;
		this.tag = tag;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum TagEnum {
	VAO,
	AO,
	VO,
	VA,
	O,
	A,
	V,
	E,
}

class Tag : Node {
	TagEnum ruleSelection;
	OptChild oc;
	IDFull id;
	Values vals;
	Attributes attrs;

	this(TagEnum ruleSelection, IDFull id, Values vals, Attributes attrs, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.vals = vals;
		this.attrs = attrs;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, IDFull id, Attributes attrs, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.attrs = attrs;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, IDFull id, Values vals, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.vals = vals;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, IDFull id, Values vals, Attributes attrs) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.vals = vals;
		this.attrs = attrs;
	}

	this(TagEnum ruleSelection, IDFull id, OptChild oc) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.oc = oc;
	}

	this(TagEnum ruleSelection, IDFull id, Values vals) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.vals = vals;
	}

	this(TagEnum ruleSelection, IDFull id) {
		this.ruleSelection = ruleSelection;
		this.id = id;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum IDFullEnum {
	L,
	S,
}

class IDFull : Node {
	IDFullEnum ruleSelection;
	IDSuffix suff;
	Token id;

	this(IDFullEnum ruleSelection, Token id, IDSuffix suff) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.suff = suff;
	}

	this(IDFullEnum ruleSelection, Token id) {
		this.ruleSelection = ruleSelection;
		this.id = id;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum IDSuffixEnum {
	C,
}

class IDSuffix : Node {
	IDSuffixEnum ruleSelection;
	Token id;

	this(IDSuffixEnum ruleSelection, Token id) {
		this.ruleSelection = ruleSelection;
		this.id = id;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum ValuesEnum {
	Value,
	ValueFollow,
}

class Values : Node {
	ValuesEnum ruleSelection;
	Token value;
	Values follow;

	this(ValuesEnum ruleSelection, Token value) {
		this.ruleSelection = ruleSelection;
		this.value = value;
	}

	this(ValuesEnum ruleSelection, Token value, Values follow) {
		this.ruleSelection = ruleSelection;
		this.value = value;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum AttributesEnum {
	Attribute,
	AttributeFollow,
}

class Attributes : Node {
	AttributesEnum ruleSelection;
	Attribute attr;
	Attributes follow;

	this(AttributesEnum ruleSelection, Attribute attr) {
		this.ruleSelection = ruleSelection;
		this.attr = attr;
	}

	this(AttributesEnum ruleSelection, Attribute attr, Attributes follow) {
		this.ruleSelection = ruleSelection;
		this.attr = attr;
		this.follow = follow;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum AttributeEnum {
	A,
}

class Attribute : Node {
	AttributeEnum ruleSelection;
	Token value;
	IDFull id;

	this(AttributeEnum ruleSelection, IDFull id, Token value) {
		this.ruleSelection = ruleSelection;
		this.id = id;
		this.value = value;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum OptChildEnum {
	C,
}

class OptChild : Node {
	OptChildEnum ruleSelection;
	Tags tags;

	this(OptChildEnum ruleSelection, Tags tags) {
		this.ruleSelection = ruleSelection;
		this.tags = tags;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

enum TagTerminatorEnum {
	E,
}

class TagTerminator : Node {
	TagTerminatorEnum ruleSelection;

	this(TagTerminatorEnum ruleSelection) {
		this.ruleSelection = ruleSelection;
	}

	void visit(Visitor vis) {
		vis.accept(this);
	}

	void visit(Visitor vis) const {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) {
		vis.accept(this);
	}

	void visit(ConstVisitor vis) const {
		vis.accept(this);
	}
}

