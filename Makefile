SHELL = /bin/bash

REQUIRED = docker docker-compose
K := $(foreach exec,$(REQUIRED),\
        $(if $(shell which $(exec)),OK,$(error "$(exec) not found. Please install first.")))

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
	@docker compose up -d

## down		Stop the dev-proxy.
.PHONY: down
down:
	@docker-compose down

## teardown	Cleanup everything.
.PHONY: teardown
teardown: down
	@docker network rm dev-proxy

## logs		Tail dev-proxy logs.
.PHONY: logs
logs:
	@docker-compose logs -f

## setup		Onetime setup for the dev-proxy.
.PHONY: setup
setup:
	@docker network create dev-proxy >/dev/null 2>&1 || echo "Network already created"
	@mkdir -p certs/
	@mkcert -install
	@if [ -f "certs/local-cert.pem" ] && [ -f "certs/local-key.pem" ]; then \
		echo "Certificate for '$$domain' already present."; \
	else \
		mkcert -cert-file certs/local-cert.pem -key-file certs/local-key.pem localhost 127.0.0.1 ::1; \
	fi
	@make .install-domains
	@echo "Setup complete."
	@echo
	@echo "Please add the domain mapping to /etc/hosts or setup dnsmasq."

## add		Add a new domain to the dev-proxy.
.PHONY: add
add:
	source install_domain
	install_domain $$domain
	@echo "$$domain" >> domains

PHONY: .install-domains
.install-domains:
	@if [ -f "domains" ]; then \
		source install_domain; \
		while read -r domain; do \
			install_domain $$domain; \
		done < domains; \
	else \
		echo "No domains defined"; \
	fi
