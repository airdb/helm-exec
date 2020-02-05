PLUGIN_NAME := helm-kube
REMOTE      := https://github.com/airdb/$(PLUGIN_NAME)

.PHONY: install
install:
	helm plugin install $(REMOTE)

.PHONY: link
link:
	helm plugin install .
