build:
	@[ "$(BUILD_RUBY_VERSION)" ] || ( echo "!! BUILD_RUBY_VERSION is not set"; exit 1 )
	docker build -t skopciewski/devenv-ruby:$(BUILD_RUBY_VERSION) . --build-arg BUILD_RUBY_VERSION=$(BUILD_RUBY_VERSION)
.PHONY: build

push:
	@[ "$(BUILD_RUBY_VERSION)" ] || ( echo "!! BUILD_RUBY_VERSION is not set"; exit 1 )
	docker push skopciewski/devenv-ruby:$(BUILD_RUBY_VERSION)
.PHONY: deploy

push_all:
	docker push skopciewski/devenv-ruby
.PHONY: deploy_all
