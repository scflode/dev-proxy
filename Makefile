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

## setup		Onetime setup for the dev-proxy. `make setup`
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

## add		Add a new domain to the dev-proxy. `make add domain="my.localhost"`
.PHONY: add
add:
	@scripts/install_domain $$domain
	@echo "$$domain" >> domains
	@echo "$$domain added successfully"

## remove		Remove a domain from the dev-proxy.`make remove domain="my.localhost"`
.PHONY: remove
remove:
	@scripts/uninstall_domain $$domain
	@cp domains _domains
	@sed "s/$$domain//g" _domains | grep -v "^$$" > domains || echo ""
	@rm _domains
	@echo "$$domain removed successfully"

PHONY: .install-domains
.install-domains:
	@if [ -f "domains" ]; then \
		while read -r domain; do \
			scripts/install_domain $$domain; \
		done < domains; \
	else \
		echo "No domains defined"; \
	fi

## add-network	Add a new network to the dev-proxy. `make add-network network="my_network"`
.PHONY: add-network
add-network:
	@echo "$$network" >> networks
	@echo
	@echo "Network $$network added successfully"
	@make down up

## remove-network	Remove a network to the dev-proxy. `make remove-network network="my_network"`
.PHONY: remove-network
remove-network:
	@cp networks _networks
	@sed "s/$$network//g" _networks | grep -v "^$$" > networks || echo ""
	@rm _networks
	@echo "Network $$network removed successfully"
	@make down up

