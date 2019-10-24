module dud.sdlang2.visitor;

import dud.sdlang2.ast;
import dud.sdlang2.tokenmodule;

class Visitor : ConstVisitor {
@safe pure:

	alias accept = ConstVisitor.accept;

	alias enter = ConstVisitor.enter;

	alias exit = ConstVisitor.exit;


	void enter(Root obj) {}
	void exit(Root obj) {}

	void accept(Root obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case RootEnum.T:
				obj.tags.visit(this);
				break;
			case RootEnum.E:
				break;
		}
		exit(obj);
	}

	void enter(Tags obj) {}
	void exit(Tags obj) {}

	void accept(Tags obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TagsEnum.Tag:
				obj.tag.visit(this);
				break;
			case TagsEnum.TagFollow:
				obj.tag.visit(this);
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(Tag obj) {}
	void exit(Tag obj) {}

	void accept(Tag obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TagEnum.VAO:
				obj.id.visit(this);
				obj.vals.visit(this);
				obj.attrs.visit(this);
				obj.oc.visit(this);
				break;
			case TagEnum.AO:
				obj.id.visit(this);
				obj.attrs.visit(this);
				obj.oc.visit(this);
				break;
			case TagEnum.VO:
				obj.id.visit(this);
				obj.vals.visit(this);
				obj.oc.visit(this);
				break;
			case TagEnum.VA:
				obj.id.visit(this);
				obj.vals.visit(this);
				obj.attrs.visit(this);
				break;
			case TagEnum.O:
				obj.id.visit(this);
				obj.oc.visit(this);
				break;
			case TagEnum.A:
				obj.id.visit(this);
				obj.oc.visit(this);
				break;
			case TagEnum.V:
				obj.id.visit(this);
				obj.vals.visit(this);
				break;
			case TagEnum.E:
				obj.id.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(IDFull obj) {}
	void exit(IDFull obj) {}

	void accept(IDFull obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case IDFullEnum.L:
				obj.id.visit(this);
				obj.suff.visit(this);
				break;
			case IDFullEnum.S:
				obj.id.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(IDSuffix obj) {}
	void exit(IDSuffix obj) {}

	void accept(IDSuffix obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case IDSuffixEnum.C:
				obj.id.visit(this);
				break;
			case IDSuffixEnum.F:
				obj.id.visit(this);
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(Values obj) {}
	void exit(Values obj) {}

	void accept(Values obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ValuesEnum.Value:
				obj.value.visit(this);
				break;
			case ValuesEnum.ValueFollow:
				obj.value.visit(this);
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(Attributes obj) {}
	void exit(Attributes obj) {}

	void accept(Attributes obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case AttributesEnum.Attribute:
				obj.attr.visit(this);
				break;
			case AttributesEnum.AttributeFollow:
				obj.attr.visit(this);
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(Attribute obj) {}
	void exit(Attribute obj) {}

	void accept(Attribute obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case AttributeEnum.A:
				obj.id.visit(this);
				obj.value.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(OptChild obj) {}
	void exit(OptChild obj) {}

	void accept(OptChild obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case OptChildEnum.C:
				obj.tags.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(TagTerminator obj) {}
	void exit(TagTerminator obj) {}

	void accept(TagTerminator obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TagTerminatorEnum.E:
				break;
		}
		exit(obj);
	}
}

class ConstVisitor {
@safe pure:


	void enter(const(Root) obj) {}
	void exit(const(Root) obj) {}

	void accept(const(Root) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case RootEnum.T:
				obj.tags.visit(this);
				break;
			case RootEnum.E:
				break;
		}
		exit(obj);
	}

	void enter(const(Tags) obj) {}
	void exit(const(Tags) obj) {}

	void accept(const(Tags) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TagsEnum.Tag:
				obj.tag.visit(this);
				break;
			case TagsEnum.TagFollow:
				obj.tag.visit(this);
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(Tag) obj) {}
	void exit(const(Tag) obj) {}

	void accept(const(Tag) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TagEnum.VAO:
				obj.id.visit(this);
				obj.vals.visit(this);
				obj.attrs.visit(this);
				obj.oc.visit(this);
				break;
			case TagEnum.AO:
				obj.id.visit(this);
				obj.attrs.visit(this);
				obj.oc.visit(this);
				break;
			case TagEnum.VO:
				obj.id.visit(this);
				obj.vals.visit(this);
				obj.oc.visit(this);
				break;
			case TagEnum.VA:
				obj.id.visit(this);
				obj.vals.visit(this);
				obj.attrs.visit(this);
				break;
			case TagEnum.O:
				obj.id.visit(this);
				obj.oc.visit(this);
				break;
			case TagEnum.A:
				obj.id.visit(this);
				obj.oc.visit(this);
				break;
			case TagEnum.V:
				obj.id.visit(this);
				obj.vals.visit(this);
				break;
			case TagEnum.E:
				obj.id.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(IDFull) obj) {}
	void exit(const(IDFull) obj) {}

	void accept(const(IDFull) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case IDFullEnum.L:
				obj.id.visit(this);
				obj.suff.visit(this);
				break;
			case IDFullEnum.S:
				obj.id.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(IDSuffix) obj) {}
	void exit(const(IDSuffix) obj) {}

	void accept(const(IDSuffix) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case IDSuffixEnum.C:
				obj.id.visit(this);
				break;
			case IDSuffixEnum.F:
				obj.id.visit(this);
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(Values) obj) {}
	void exit(const(Values) obj) {}

	void accept(const(Values) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case ValuesEnum.Value:
				obj.value.visit(this);
				break;
			case ValuesEnum.ValueFollow:
				obj.value.visit(this);
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(Attributes) obj) {}
	void exit(const(Attributes) obj) {}

	void accept(const(Attributes) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case AttributesEnum.Attribute:
				obj.attr.visit(this);
				break;
			case AttributesEnum.AttributeFollow:
				obj.attr.visit(this);
				obj.follow.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(Attribute) obj) {}
	void exit(const(Attribute) obj) {}

	void accept(const(Attribute) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case AttributeEnum.A:
				obj.id.visit(this);
				obj.value.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(OptChild) obj) {}
	void exit(const(OptChild) obj) {}

	void accept(const(OptChild) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case OptChildEnum.C:
				obj.tags.visit(this);
				break;
		}
		exit(obj);
	}

	void enter(const(TagTerminator) obj) {}
	void exit(const(TagTerminator) obj) {}

	void accept(const(TagTerminator) obj) {
		enter(obj);
		final switch(obj.ruleSelection) {
			case TagTerminatorEnum.E:
				break;
		}
		exit(obj);
	}
}

