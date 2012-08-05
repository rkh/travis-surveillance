VERSION=$(shell ruby -r./lib/travis/surveillance/version -e "puts Travis::Surveillance::VERSION")

PROJECT?=$(notdir $(PWD))
GEM=$(PROJECT)-$(VERSION).gem

.PHONY: package
package: $(GEM)

.PHONY: $(GEM)
$(GEM):
	gem build $(PROJECT).gemspec

.PHONY: install
install: $(GEM)
	gem install $<

.PHONY: publish
publish: $(GEM)
	 gem push $(GEM)
