# Docker image information
DOCKER_IMAGE_NAMES :=
DOCKER_IMAGE_TAGS :=
DOCKER_IMAGE_ARCHIVE_NAME :=
DOCKER_IMAGE_BUILD_ARGS_ENV_FILE :=

# Docker container information
DOCKER_CONTAINER_NAME :=
DOCKER_CONTAINER_NETWORK :=
DOCKER_CONTAINER_PORTS :=
DOCKER_CONTAINER_SHELL :=
DOCKER_CONTAINER_RUN_ENV_FILE :=

SHELL := /bin/bash
.SHELLFLAGS := -ec

.PHONY: build push save load rmi run rund run_shell exec_shell kill logs logsf rm start stop


define _LOAD_DOCKERRC :=
	if [[ -f "~/.dockerrc" ]]; then \
		source "~/.dockerrc"; \
	fi; \
	if [[ -f "$(CURDIR)/.dockerrc" ]]; then \
		source "~/.dockerrc";  \
	fi
endef

define _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES :=
	if [[ ! -z "$(DOCKER_IMAGE_NAMES)" ]]; then \
		DOCKER_IMAGE_NAMES=($(DOCKER_IMAGE_NAMES)); \
	else \
		DOCKER_IMAGE_NAMES=("$$(basename $(CURDIR) | sed 's/[^a-z0-9]\+/-/g')"); \
	fi; \
	if [[ ! -z "$(DOCKER_IMAGE_TAGS)" ]]; then \
		DOCKER_IMAGE_TAGS=($(DOCKER_IMAGE_TAGS)); \
	else \
		DOCKER_IMAGE_TAGS=("latest"); \
	fi
endef

define _SET_DOCKER_FULL_IMAGE_NAMES_VARIABLES :=
	DOCKER_FULL_IMAGE_NAMES=(); \
	for DOCKER_IMAGE_NAME in $${DOCKER_IMAGE_NAMES[@]}; do \
		for DOCKER_IMAGE_TAG in $${DOCKER_IMAGE_TAGS[@]}; do \
			DOCKER_FULL_IMAGE_NAMES+=("$${DOCKER_IMAGE_NAME}:$${DOCKER_IMAGE_TAG}"); \
		done; \
	done; \
	DOCKER_FULL_IMAGE_NAME="$${DOCKER_FULL_IMAGE_NAMES[0]}"
endef

define _SET_DOCKER_IMAGE_ARCHIVE_NAME_VARIABLE :=
	if [[ ! -z "$(DOCKER_IMAGE_ARCHIVE_NAME)" ]]; then \
		DOCKER_IMAGE_ARCHIVE_NAME="$(DOCKER_IMAGE_ARCHIVE_NAME)"; \
	else \
		DOCKER_IMAGE_ARCHIVE_NAME="$$("$${DOCKER_FULL_IMAGE_NAME}" | sed 's/[^a-z0-9]\+/-/g').tar.xz"; \
	fi
endef

define _SET_DOCKER_CONTAINER_NAME_VARIABLE :=
	if [[ ! -z "$(DOCKER_CONTAINER_NAME)" ]]; then \
		DOCKER_CONTAINER_NAME="$(DOCKER_CONTAINER_NAME)"; \
	else \
		DOCKER_CONTAINER_NAME="$$("$${DOCKER_IMAGE_NAMES[0]}" | sed 's/[^a-z0-9]\+/-/g')"; \
	fi
endef

define _SET_DOCKER_CONTAINER_NETWORK_VARIABLE :=
	if [[ ! -z "$(DOCKER_CONTAINER_NETWORK)" ]]; then \
		DOCKER_CONTAINER_NETWORK="$(DOCKER_CONTAINER_NETWORK)"; \
	else \
		DOCKER_CONTAINER_NETWORK="$${DOCKER_CONTAINER_NAME}"; \
	fi
endef

define _SET_DOCKER_CONTAINER_PORTS_VARIABLE :=
	if [[ ! -z "$(DOCKER_CONTAINER_PORTS)" ]]; then \
		DOCKER_CONTAINER_PORTS=($(DOCKER_CONTAINER_PORTS)); \
	else \
		DOCKER_CONTAINER_PORTS=(); \
	fi
endef

define _SET_DOCKER_CONTAINER_SHELL_VARIABLE :=
	if [[ ! -z "$(DOCKER_CONTAINER_SHELL)" ]]; then \
		DOCKER_CONTAINER_SHELL="$(DOCKER_CONTAINER_SHELL)"; \
	else \
		DOCKER_CONTAINER_SHELL="/bin/bash"; \
	fi
endef


define _SET_DOCKER_IMAGE_BUILD_ARGS_ENV_FILE :=
	if [[ ! -z "$(DOCKER_IMAGE_BUILD_ARGS_ENV_FILE)" ]]; then \
		DOCKER_IMAGE_BUILD_ARGS_ENV_FILE="$(DOCKER_IMAGE_BUILD_ARGS_ENV_FILE)"; \
	else \
		DOCKER_IMAGE_BUILD_ARGS_ENV_FILE="build.env"; \
	fi
endef

define _READ_DOCKER_IMAGE_BUILD_ARGS_ENV_FILE :=
	if [[ -f "$(CURDIR)/$${DOCKER_IMAGE_BUILD_ARGS_ENV_FILE}" ]]; then \
		cat "$(CURDIR)/$${DOCKER_IMAGE_BUILD_ARGS_ENV_FILE}" | \
			envsubst | \
			while read -r LINE; do \
  				DOCKER_IMAGE_BUILD_ARGS+=("--build-arg" "$${LINE}"); \
			done; \
	fi
endef


define _SET_DOCKER_CONTAINER_RUN_ENV_FILE :=
	if [[ ! -z "$(DOCKER_CONTAINER_RUN_ENV_FILE)" ]]; then \
		DOCKER_CONTAINER_RUN_ENV_FILE="$(DOCKER_CONTAINER_RUN_ENV_FILE)"; \
	else \
		DOCKER_CONTAINER_RUN_ENV_FILE="run.env"; \
	fi
endef

define _READ_DOCKER_CONTAINER_RUN_ENV_FILE :=
	if [[ -f "$(CURDIR)/$${DOCKER_CONTAINER_RUN_ENV_FILE}" ]]; then \
		cat "$(CURDIR)/$${DOCKER_CONTAINER_RUN_ENV_FILE}" | \
			envsubst | \
			while read -r LINE; do \
  				DOCKER_CONTAINER_RUN_ARGS+=("--build-arg" "$${LINE}"); \
			done; \
	fi
endef

all: build

build:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_FULL_IMAGE_NAMES_VARIABLES); \
	$(call _SET_DOCKER_IMAGE_BUILD_ARGS_ENV_FILE); \
	DOCKER_IMAGE_BUILD_ARGS=("--compress" "--force-rm" "--pull" "--rm"); \
	for DOCKER_FULL_IMAGE_NAME in $${DOCKER_FULL_IMAGE_NAMES[@]}; do \
		DOCKER_IMAGE_BUILD_ARGS+=("--tag" "$${DOCKER_FULL_IMAGE_NAME}"); \
	done; \
	$(call _READ_DOCKER_IMAGE_BUILD_ARGS_ENV_FILE); \
	DOCKER_IMAGE_BUILD_ARGS+=("$(CURDIR)"); \
	docker image build "$${DOCKER_IMAGE_BUILD_ARGS[@]}"

push:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_FULL_IMAGE_NAMES_VARIABLES); \
	DOCKER_IMAGE_PUSH_ARGS=(); \
	for DOCKER_FULL_IMAGE_NAME in $${DOCKER_FULL_IMAGE_NAMES[@]}; do \
		DOCKER_IMAGE_PUSH_ARGS+=("$${DOCKER_FULL_IMAGE_NAME}"); \
	done; \
	docker push "$${DOCKER_IMAGE_PUSH_ARGS[@]}"


save:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_FULL_IMAGE_NAMES_VARIABLES); \
	$(call _SET_DOCKER_IMAGE_ARCHIVE_NAME_VARIABLE); \
	DOCKER_IMAGE_SAVE_ARGS=("$${DOCKER_FULL_IMAGE_NAME}"); \
	XZ_ARGS=("--compress" "--extreme" "-9" "--force"); \
	docker save "$${DOCKER_IMAGE_SAVE_ARGS[@]}" |\
		xz "$${XZ_ARGS[@]}" > \
		"$(CURDIR)/$${DOCKER_IMAGE_ARCHIVE_NAME}"

load:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_FULL_IMAGE_NAMES_VARIABLES); \
	$(call _SET_DOCKER_IMAGE_ARCHIVE_NAME_VARIABLE); \
	DOCKER_IMAGE_LOAD_ARGS=("--input" "$${DOCKER_IMAGE_ARCHIVE_NAME}"); \
	docker load "$${DOCKER_IMAGE_LOAD_ARGS[@]}"

rmi:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_FULL_IMAGE_NAMES_VARIABLES); \
	DOCKER_IMAGE_RM_ARGS=("--force"); \
	for DOCKER_FULL_IMAGE_NAME in $${DOCKER_FULL_IMAGE_NAMES[@]}; do \
		DOCKER_IMAGE_RM_ARGS+=("$${DOCKER_FULL_IMAGE_NAME}"); \
	done; \
	docker image rm "$${DOCKER_IMAGE_RM_ARGS[@]}"

run:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_FULL_IMAGE_NAMES_VARIABLES); \
	$(call _SET_DOCKER_CONTAINER_NAME_VARIABLE); \
	$(call _SET_DOCKER_CONTAINER_NETWORK_VARIABLE); \
	$(call _SET_DOCKER_CONTAINER_PORTS_VARIABLE); \
	$(call _SET_DOCKER_CONTAINER_RUN_ENV_FILE); \
	DOCKER_CONTAINER_RUN_ARGS=("--interactive" "--tty" "--rm"); \
	DOCKER_CONTAINER_RUN_ARGS+=("--name" "$${DOCKER_CONTAINER_NAME}"); \
	DOCKER_CONTAINER_RUN_ARGS+=("--network" "$${DOCKER_CONTAINER_NETWORK}"); \
	for DOCKER_CONTAINER_PORT in $${DOCKER_CONTAINER_PORTS[@]}; do \
		DOCKER_CONTAINER_RUN_ARGS+=("--publish" "$${DOCKER_CONTAINER_PORT}"); \
	done; \
	$(call _READ_DOCKER_CONTAINER_RUN_ENV_FILE); \
	DOCKER_CONTAINER_RUN_ARGS+=("$${DOCKER_FULL_IMAGE_NAME}"); \
	if ! docker network inspect "$${DOCKER_CONTAINER_NETWORK}"; then \
		docker network create "$${DOCKER_CONTAINER_NETWORK}"; \
	fi; \
	if docker container inspect "$${DOCKER_CONTAINER_NAME}"; then \
		docker container rm --force "$${DOCKER_CONTAINER_NAME}"; \
	fi; \
	docker container run "$${DOCKER_CONTAINER_RUN_ARGS[@]}"

rund:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_FULL_IMAGE_NAMES_VARIABLES); \
	$(call _SET_DOCKER_CONTAINER_NAME_VARIABLE); \
	$(call _SET_DOCKER_CONTAINER_NETWORK_VARIABLE); \
	$(call _SET_DOCKER_CONTAINER_PORTS_VARIABLE); \
	$(call _SET_DOCKER_CONTAINER_RUN_ENV_FILE); \
	DOCKER_CONTAINER_RUN_ARGS=("--detach" "--rm"); \
	DOCKER_CONTAINER_RUN_ARGS+=("--name" "$${DOCKER_CONTAINER_NAME}"); \
	DOCKER_CONTAINER_RUN_ARGS+=("--network" "$${DOCKER_CONTAINER_NETWORK}"); \
	for DOCKER_CONTAINER_PORT in $${DOCKER_CONTAINER_PORTS[@]}; do \
		DOCKER_CONTAINER_RUN_ARGS+=("--publish" "$${DOCKER_CONTAINER_PORT}"); \
	done; \
	$(call _READ_DOCKER_CONTAINER_RUN_ENV_FILE); \
	DOCKER_CONTAINER_RUN_ARGS+=("$${DOCKER_FULL_IMAGE_NAME}"); \
	if ! docker network inspect "$${DOCKER_CONTAINER_NETWORK}"; then \
		docker network create "$${DOCKER_CONTAINER_NETWORK}"; \
	fi; \
	if docker container inspect "$${DOCKER_CONTAINER_NAME}"; then \
		docker container rm --force "$${DOCKER_CONTAINER_NAME}"; \
	fi; \
	docker container run "$${DOCKER_CONTAINER_RUN_ARGS[@]}"


run_shell:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_FULL_IMAGE_NAMES_VARIABLES); \
	$(call _SET_DOCKER_CONTAINER_NAME_VARIABLE); \
	$(call _SET_DOCKER_CONTAINER_NETWORK_VARIABLE); \
	$(call _SET_DOCKER_CONTAINER_PORTS_VARIABLE); \
	$(call _SET_DOCKER_CONTAINER_RUN_ENV_FILE); \
	$(call _SET_DOCKER_CONTAINER_SHELL_VARIABLE); \
	DOCKER_CONTAINER_RUN_ARGS=("--interactive" "--tty" "--rm"); \
	DOCKER_CONTAINER_RUN_ARGS+=("--name" "$${DOCKER_CONTAINER_NAME}"); \
	DOCKER_CONTAINER_RUN_ARGS+=("--network" "$${DOCKER_CONTAINER_NETWORK}"); \
	for DOCKER_CONTAINER_PORT in $${DOCKER_CONTAINER_PORTS[@]}; do \
		DOCKER_CONTAINER_RUN_ARGS+=("--publish" "$${DOCKER_CONTAINER_PORT}"); \
	done; \
	$(call _READ_DOCKER_CONTAINER_RUN_ENV_FILE); \
	DOCKER_CONTAINER_RUN_ARGS+=("$${DOCKER_FULL_IMAGE_NAME}" "$${DOCKER_CONTAINER_SHELL}"); \
	if ! docker network inspect "$${DOCKER_CONTAINER_NETWORK}"; then \
		docker network create "$${DOCKER_CONTAINER_NETWORK}"; \
	fi; \
	if docker container inspect "$${DOCKER_CONTAINER_NAME}"; then \
		docker container rm --force "$${DOCKER_CONTAINER_NAME}"; \
	fi; \
	docker container run "$${DOCKER_CONTAINER_RUN_ARGS[@]}"

exec_shell:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_CONTAINER_NAME_VARIABLE); \
	$(call _SET_DOCKER_CONTAINER_SHELL_VARIABLE); \
	DOCKER_CONTAINER_EXEC_ARGS=("--interactive" "--tty"); \
	DOCKER_CONTAINER_EXEC_ARGS+=("$${DOCKER_CONTAINER_NAME}"); \
	DOCKER_CONTAINER_EXEC_ARGS+=("$${DOCKER_CONTAINER_SHELL}"); \
	docker container exec "$${DOCKER_CONTAINER_EXEC_ARGS[@]}"

kill:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_CONTAINER_NAME_VARIABLE); \
	DOCKER_CONTAINER_KILL_ARGS=("$${DOCKER_CONTAINER_NAME}"); \
	docker container kill "$${DOCKER_CONTAINER_KILL_ARGS[@]}"

logs:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_CONTAINER_NAME_VARIABLE); \
	DOCKER_CONTAINER_LOGS_ARGS=("$${DOCKER_CONTAINER_NAME}"); \
	docker container logs "$${DOCKER_CONTAINER_LOGS_ARGS[@]}"

logsf:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_CONTAINER_NAME_VARIABLE); \
	DOCKER_CONTAINER_LOGS_ARGS=("--follow" "$${DOCKER_CONTAINER_NAME}"); \
	docker container logs "$${DOCKER_CONTAINER_LOGS_ARGS[@]}"

rm:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_CONTAINER_NAME_VARIABLE); \
	DOCKER_CONTAINER_RM_ARGS=("--force" "--volumes" "$${DOCKER_CONTAINER_NAME}"); \
	docker container rm "$${DOCKER_CONTAINER_RM_ARGS[@]}"

start:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_CONTAINER_NAME_VARIABLE); \
	DOCKER_CONTAINER_START_ARGS=("$${DOCKER_CONTAINER_NAME}"); \
	docker container start "$${DOCKER_CONTAINER_START_ARGS[@]}"

stop:
	set -euxo pipefail; \
	$(call _LOAD_DOCKERRC); \
	$(call _SET_DOCKER_IMAGE_NAMES_AND_TAGS_VARIABLES); \
	$(call _SET_DOCKER_CONTAINER_NAME_VARIABLE); \
	DOCKER_CONTAINER_STOP_ARGS=("$${DOCKER_CONTAINER_NAME}"); \
	docker container stop "$${DOCKER_CONTAINER_STOP_ARGS[@]}"
