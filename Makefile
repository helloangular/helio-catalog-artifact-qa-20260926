.PHONY: build push
build:
	docker build --label org.opencontainers.image.version=$(BUILD_VERSION) --tag $(IMAGE_REPOSITORY):$(BUILD_VERSION) .
push:
	docker push $(IMAGE_REPOSITORY):$(BUILD_VERSION)
