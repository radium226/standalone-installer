BUILD_FOLDER_PATH = package-build

PYPY_VERSION = 3.5-7.0.0
PYPY_URL = https://bitbucket.org/squeaky/portable-pypy/downloads/pypy$(PYPY_VERSION)-linux_x86_64-portable.tar.bz2
PYPY_FOLDER_PATH = $(BUILD_FOLDER_PATH)/pypy

$(BUILD_FOLDER_PATH):
	mkdir -p "$(BUILD_FOLDER_PATH)"

$(BUILD_FOLDER_PATH)/vendors: $(BUILD_FOLDER_PATH)
	mkdir -p "$(BUILD_FOLDER_PATH)/vendors"

$(BUILD_FOLDER_PATH)/vendors/pypy.tar.bz2: $(BUILD_FOLDER_PATH)/vendors
	cd "$(BUILD_FOLDER_PATH)/vendors" ; \
	test -f "./pypy.tar.bz2" || \
	 	wget "$(PYPY_URL)" \
			-O "./pypy.tar.bz2"

$(BUILD_FOLDER_PATH)/vendors/pypy: $(BUILD_FOLDER_PATH)/vendors/pypy.tar.bz2
	cd "$(BUILD_FOLDER_PATH)/vendors" ; \
	mkdir -p "./pypy" ; \
	tar \
		-C "./pypy" \
		--strip-component=1 \
		-xf "./pypy.tar.bz2"

$(BUILD_FOLDER_PATH)/virtualenv: $(BUILD_FOLDER_PATH)/vendors/pypy
	cd "$(BUILD_FOLDER_PATH)" ; \
	./vendors/pypy/bin/virtualenv-pypy "./virtualenv"

$(BUILD_FOLDER_PATH)/vendors/wheels: $(BUILD_FOLDER_PATH)/virtualenv
	cd "$(BUILD_FOLDER_PATH)" ; \
	mkdir "./vendors/wheels" ; \
	source "./virtualenv/bin/activate" ; \
	cd "./vendors/wheels" ; \
	pip download \
		-r "../../../requirements.txt"

$(BUILD_FOLDER_PATH)/ansible: $(BUILD_FOLDER_PATH)
	cp -r "./ansible" "$(BUILD_FOLDER_PATH)/ansible"

$(BUILD_FOLDER_PATH)/provision-HEAD: $(BUILD_FOLDER_PATH)
	cp -r "./provision-HEAD" "$(BUILD_FOLDER_PATH)/provision-HEAD"

$(BUILD_FOLDER_PATH)/archive.tar.gz: $(BUILD_FOLDER_PATH)/ansible $(BUILD_FOLDER_PATH)/vendors/wheels $(BUILD_FOLDER_PATH)/vendors/pypy
	cd "$(BUILD_FOLDER_PATH)" ; \
	tar -czf "./archive.tar.gz" \
		"./ansible" \
		"./vendors/pypy" \
		"./vendors/wheels"

$(BUILD_FOLDER_PATH)/archive.tar.gz.base64: $(BUILD_FOLDER_PATH)/archive.tar.gz
	cd "$(BUILD_FOLDER_PATH)" ; \
	cat "./archive.tar.gz" | base64 >"./archive.tar.gz.base64"

$(BUILD_FOLDER_PATH)/provision: $(BUILD_FOLDER_PATH)/provision-HEAD $(BUILD_FOLDER_PATH)/archive.tar.gz.base64
	cd "$(BUILD_FOLDER_PATH)" ; \
	cat "./provision-HEAD" "./archive.tar.gz.base64" >"./provision" ; \
	chmod +x "./provision"

.PHONY: package
package: $(BUILD_FOLDER_PATH)/provision

.PHONY: clean
clean:
	rm -Rf "$(BUILD_FOLDER_PATH)"
