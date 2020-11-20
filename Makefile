VERSION = 1.1.1
IMAGE = cyclops:$(VERSION)

MANAGER_BIN = cyclops
CLI_BIN = kubectl-cycle
OBSERVER_BIN = observer

TARGET_OS = $(firstword $(subst /, ,$(TARGETPLATFORM)))
TARGET_ARCH = $(lastword $(subst /, ,$(TARGETPLATFORM)))

.PHONY: build-manager build-observer build-cli install-cli build docker build-manager-linux build-observer-linux build-cli-linux build-linux docker-save local srcclr
.DEFAULT_GOAL := build

install-cli:
	GOOS=$(TARGET_OS) GOARCH=$(TARGET_ARCH) go build -o ${GOPATH}/bin/${CLI_BIN} -ldflags="-X main.version=${VERSION}" cmd/cli/main.go

build-observer:
	GOOS=$(TARGET_OS) GOARCH=$(TARGET_ARCH) go build -o bin/${OBSERVER_BIN} -ldflags="-X main.version=${VERSION}" cmd/observer/main.go

build-manager:
	GOOS=$(TARGET_OS) GOARCH=$(TARGET_ARCH) go build -o bin/${MANAGER_BIN} -ldflags="-X main.version=${VERSION}" cmd/manager/main.go

build-cli:
	GOOS=$(TARGET_OS) GOARCH=$(TARGET_ARCH) go build -o bin/${CLI_BIN} -ldflags="-X main.version=${VERSION}" cmd/cli/main.go

build: build-manager build-cli build-observer

build-manager-linux:
	CGO_ENABLED=0 GOOS=$(TARGET_OS) GOARCH=$(TARGET_ARCH) go build -a -installsuffix cgo -o bin/linux/${MANAGER_BIN} -ldflags="-X main.version=${VERSION}" cmd/manager/main.go

build-cli-linux:
	CGO_ENABLED=0 GOOS=$(TARGET_OS) GOARCH=$(TARGET_ARCH) go build -a -installsuffix cgo -o bin/linux/${CLI_BIN} -ldflags="-X main.version=${VERSION}" cmd/cli/main.go

build-observer-linux:
	CGO_ENABLED=0 GOOS=$(TARGET_OS) GOARCH=$(TARGET_ARCH) go build -a -installsuffix cgo -o bin/linux/${OBSERVER_BIN} -ldflags="-X main.version=${VERSION}" cmd/observer/main.go

build-linux: build-manager-linux build-cli-linux build-observer-linux

clean:
	rm -f bin/${MANAGER_BIN}
	rm -f bin/${CLI_BIN}
	rm -f bin/${OBSERVER_BIN}
	rm -f bin/linux/${MANAGER_BIN}
	rm -f bin/linux/${CLI_BIN}
	rm -f bin/linux/${OBSERVER_BIN}


test:
	go test -cover ./pkg/...
	go test -cover ./cmd/...

lint:
	golangci-lint run

docker:
	docker build -t $(IMAGE) .

install-operator-sdk:
	mkdir -p $(GOPATH)/src/github.com/operator-framework
	-cd $(GOPATH)/src/github.com/operator-framework && git clone https://github.com/operator-framework/operator-sdk
	git -C $(GOPATH)/src/github.com/operator-framework/operator-sdk checkout master
	$(MAKE) -C $(GOPATH)/src/github.com/operator-framework/operator-sdk tidy
	$(MAKE) -C $(GOPATH)/src/github.com/operator-framework/operator-sdk install

# See https://sdk.operatorframework.io/docs/golang/quickstart/
generate-crds:
	mkdir -p build deploy/crds
	touch build/Dockerfile
	operator-sdk generate k8s
	operator-sdk generate crds --crd-version v1
	rm -rf build/
