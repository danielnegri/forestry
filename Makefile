PROJ=forestry
ORG_PATH=github.com/danielnegri
REPO_PATH=$(ORG_PATH)/$(PROJ)

DOCKER_IMAGE=$(PROJ)

$( shell mkdir -p bin )
$( shell mkdir -p release/bin )
$( shell mkdir -p release/images )
$( shell mkdir -p results )

user=$(shell id -u -n)
group=$(shell id -g -n)

export GOBIN=$(PWD)/bin
# Prefer ./bin instead of system packages for things like protoc, where we want
# to use the version the application uses, not whatever a developer has installed.
export PATH=$(GOBIN):$(shell printenv PATH)

export GO111MODULE=on
export GOSUMDB=off

# Version
VERSION ?= $(shell ./scripts/git-version)
COMMIT_HASH ?= $(shell git rev-parse HEAD 2>/dev/null)
BUILD_TIME ?= $(shell date +%FT%T%z)

LD_FLAGS="-s -w -X $(ORG_PATH)/atom-go/version.CommitHash=$(COMMIT_HASH) -X $(ORG_PATH)/atom-go/version.Version=$(VERSION)"

# Inject .env file
-include .env
export $(shell sed 's/=.*//' .env)

build: clean bin/forestry

bin/forestry:
	@echo "Building Forestry: ${COMMIT_HASH}"
	@go install -v -ldflags $(LD_FLAGS) $(REPO_PATH)/cmd/forestry

clean:
	@echo "Cleaning Binary Folders"
	@rm -rf bin/*
	@rm -rf release/*
	@rm -rf results/*

release-binary:
	@echo "Releasing binary files: ${COMMIT_HASH}"
	@go build -race -o release/bin/forestry -v -ldflags $(LD_FLAGS) $(REPO_PATH)/cmd/forestry

revendor:
	@echo "Install dependencies"
	@go get -v ./...
	@go mod vendor

start: build
	@echo "Starting Forestry: Server"
	@bin/forestry serve

.PHONY: docker-image
docker-image: clean
	@echo "Building $(DOCKER_IMAGE) image"
	@docker build -t $(DOCKER_IMAGE) --rm -f Dockerfile .

test:
	@echo "Testing"
	@go test -v --short -race ./...

testcoverage:
	@echo "Testing with coverage"
	@mkdir -p results
	@go test -v $(REPO_PATH)/... | go2xunit -output results/tests.xml
	@gocov test $(REPO_PATH)/... | gocov-xml > results/cobertura-coverage.xml

testrace:
	@echo "Testing with race detection"
	@go test -v --race $(REPO_PATH)/...

vet:
	@echo "Running go tool vet on packages"
	go vet $(REPO_PATH)/...

fmt:
	@echo "Running gofmt on package sources"
	go fmt $(REPO_PATH)/...

lint:
	@echo "Lint"
	go get -v github.com/golang/lint/golint
	for file in $$(find . -name '*.go' | grep -v '\.pb\.go\|\.pb\.gw\.go'); do \
		golint $${file}; \
		if [ -n "$$(golint $${file})" ]; then \
			exit 1; \
		fi; \
	done

testall: testrace vet fmt # testcoverage #lint

.PHONY: fmt \
		lint \
		release-binary \
		revendor \
		test \
		testall \
		testcoverage \
		testrace \
		vet
