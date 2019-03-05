BUILD_FOLDER = ./build
VERSION = 1.0

$(BUILD_FOLDER):
	mkdir -p "$(BUILD_FOLDER)"

$(BUILD_FOLDER)/bootstrap.sh: $(BUILD_FOLDER)
	cp "./installer/bootstrap.sh" "$(BUILD_FOLDER)/bootstrap.sh"

$(BUILD_FOLDER)/install.sh: $(BUILD_FOLDER)/bootstrap.sh $(BUILD_FOLDER)/data.tar.gz.base64
	cd "$(BUILD_FOLDER)" ; \
	cat "./bootstrap.sh" "./data.tar.gz.base64" >"./install.sh" ; \
	chmod +x "./install.sh"

$(BUILD_FOLDER)/templates:
	if [[ ! -d "$(BUILD_FOLDER)/templates" ]]; then \
		mkdir -p "$(BUILD_FOLDER)/templates" ; \
		find "./installer/templates" -type "f" -exec cp "{}" "$(BUILD_FOLDER)/templates" \; ; \
	fi

$(BUILD_FOLDER)/files: $(BUILD_FOLDER)
	if [[ ! -d "$(BUILD_FOLDER)/files" ]]; then \
		mkdir -p "$(BUILD_FOLDER)/files" ; \
		find "./installer/files" -type "f" -exec cp "{}" "$(BUILD_FOLDER)/files" \; ; \
	fi

$(BUILD_FOLDER)/variables: $(BUILD_FOLDER)
	if [[ ! -d "$(BUILD_FOLDER)/variables" ]]; then \
		mkdir -p "$(BUILD_FOLDER)/variables" ; \
		find "./installer/variables" -type "f" -exec cp "{}" "$(BUILD_FOLDER)/variables" \; ; \
	fi

$(BUILD_FOLDER)/hooks: $(BUILD_FOLDER)
	if [[ ! -d "$(BUILD_FOLDER)/hooks" ]]; then \
		mkdir -p "$(BUILD_FOLDER)/hooks" ; \
		find "./installer/hooks" -type "f" -exec cp "{}" "$(BUILD_FOLDER)/hooks" \; ; \
	fi

$(BUILD_FOLDER)/data.tar.gz.base64: $(BUILD_FOLDER)/data.tar.gz
	cat "$(BUILD_FOLDER)/data.tar.gz" | base64 >"$(BUILD_FOLDER)/data.tar.gz.base64"

$(BUILD_FOLDER)/data.tar.gz: $(BUILD_FOLDER)/variables $(BUILD_FOLDER)/files $(BUILD_FOLDER)/hooks
	cd "$(BUILD_FOLDER)" && \
	tar -cvzf "./data.tar.gz" \
		"./variables" \
		"./files" \
		"./hooks"

.PHONY: installer-clean
installer-clean:
	test -d "$(BUILD_FOLDER)" && rm -Rf "$(BUILD_FOLDER)" || true

.PHONY: installer
installer: $(BUILD_FOLDER)/install.sh
