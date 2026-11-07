ifneq (,$(wildcard .env))
include .env
export
endif

POSTGRES_USER ?= mdvai
POSTGRES_DB   ?= model_data_verify_ai
POSTGRES_PORT ?= 5433
COMPOSE       ?= docker compose

.PHONY: help up down reset psql logs session1 session2 check run scenario

help:
	@echo "make up                 start Postgres"
	@echo "make psql               open psql"
	@echo "make check LAB=01       run a chapter check"
	@echo "make scenario LAB=05    run a two-session transaction scenario"
	@echo "make scenario LAB=09    run a dump and restore test"
	@echo "make run FILE=path.sql  run a SQL file"
	@echo "make reset              destroy the volume and rebuild from seed"
	@echo "make logs               follow the database log"
	@echo "make down               stop the container"

up:
	$(COMPOSE) up -d --wait

down:
	$(COMPOSE) down

reset:
	$(COMPOSE) down -v
	$(COMPOSE) up -d --wait

psql:
	$(COMPOSE) exec postgres psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

session1 session2: psql

logs:
	$(COMPOSE) logs -f postgres

check: up
	@set -eu; \
	file=$$(ls checks/$(LAB)-*.sql 2>/dev/null | head -1); \
	if [ -z "$$file" ]; then \
	  echo "No check for LAB=$(LAB). Try LAB=01, 02, 03, 04, 06, 07, 08, 10 or 11. For 05 or 09 use make scenario."; \
	  exit 1; \
	fi; \
	echo "Running $$file"; \
	$(COMPOSE) exec -T postgres psql -v ON_ERROR_STOP=1 \
	  -U $(POSTGRES_USER) -d $(POSTGRES_DB) < "$$file"

run:
	@set -eu; \
	if [ -z "$(FILE)" ]; then \
	  echo "Usage: make run FILE=solutions/06-migration.sql"; \
	  exit 1; \
	fi; \
	$(COMPOSE) exec -T postgres psql -v ON_ERROR_STOP=1 \
	  -U $(POSTGRES_USER) -d $(POSTGRES_DB) < "$(FILE)"

scenario: up
	@set -eu; \
	file=$$(ls scenarios/$(LAB)-*.sh 2>/dev/null | head -1); \
	if [ -z "$$file" ]; then \
	  echo "No scenario for LAB=$(LAB). Try LAB=05 or 09."; \
	  exit 1; \
	fi; \
	echo "Running $$file"; \
	bash "$$file"
