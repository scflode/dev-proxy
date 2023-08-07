SHELL = /bin/bash

REQUIRED = docker
K := $(foreach exec,$(REQUIRED),\
        $(if $(shell which $(exec)),OK,$(error "$(exec) not found. Please install first.")))

CONTAINER_NAME = dev_proxy

default: help

## Targets for the dev-proxy

##
## General
## -------
##

## help		Print commands help.
.PHONY: help
help: Makefile
	@sed -n 's/^##//p' $<

## up		Start the dev-proxy.
.PHONY: up
up:
	@scripts/start

## down		Stop the dev-proxy.
.PHONY: down
down:
	@echo "Shutting down dev-proxy"
	@docker kill $(CONTAINER_NAME) >/dev/null 2>&1 || echo "Already stopped"
	@docker rm $(CONTAINER_NAME) >/dev/null 2>&1 || echo "Already removed"

## logs		Tail dev-proxy logs.
.PHONY: logs
logs:
	@docker logs -f $(CONTAINER_NAME)

## setup		Onetime setup for the dev-proxy. 
## 		`make setup`
.PHONY: setup
setup:
	@mkdir -p certs/
	@mkcert -install
	@if [ -f "certs/local-cert.pem" ] && [ -f "certs/local-key.pem" ]; then \
		echo "Certificate for 'localhost' already present."; \
	else \
		mkcert -cert-file certs/local-cert.pem -key-file certs/local-key.pem localhost 127.0.0.1 ::1; \
	fi
	@make .install-domains
	@echo "Setup complete."
	@echo
	@echo "Please add the domain mapping to /etc/hosts or setup dnsmasq."

## add		Add a new domain and network to the dev-proxy.
##		`make add domain="my.localhost"`
.PHONY: add
add:
	$(call check_defined, domain, domain name)
	$(call check_defined, network, network name)
	@scripts/install_domain $$domain
	@scripts/install_network $$network
	@make down up

## remove		Remove a domain and network from the dev-proxy.
##		`make remove domain="my.localhost" network="my_network"`
.PHONY: remove
remove:
	$(call check_defined, domain, domain name)
	$(call check_defined, network, network name)
	@scripts/uninstall_domain $$domain
	@scripts/install_network $$network
	@make down up

##
## Helpers
## -------
##

## print-service	Print the boilerplate for a service definition.
##		`make print-service domain="app.my-domain.localhost" project="my_app" service="app" network="my_network" port="4000"`
.PHONY: print-service
print-service:
	$(call check_defined, domain, domain name)
	$(call check_defined, project, project name)
	$(call check_defined, service, service name)
	$(call check_defined, network, network name)
	@scripts/print_service_scaffold $$domain $$project $$service $$network $$port

## print-database	Print the boilerplate for a database definition.
##		`make print-database domain="db.my-app.localhost" project="my_app" service="db" network="my_network" port="4000"`
.PHONY: print-database
print-database:
	$(call check_defined, domain, domain name)
	$(call check_defined, project, project name)
	$(call check_defined, service, service name)
	$(call check_defined, network, network name)
	@scripts/print_database_scaffold $$domain $$project $$service $$network $$port

PHONY: .install-domains
.install-domains:
	@if [ -f "domains" ]; then \
		while read -r domain; do \
			scripts/install_domain $$domain; \
		done < domains; \
	else \
		echo "No domains defined"; \
	fi

# Check that given variables are set and all have non-empty values,
# die with an error otherwise.
#
# Params:
#   1. Variable name(s) to test.
#   2. (optional) Error message to print.
# see https://stackoverflow.com/questions/10858261/how-to-abort-makefile-if-variable-not-set
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
      $(error Undefined $1$(if $2, ($2))))
