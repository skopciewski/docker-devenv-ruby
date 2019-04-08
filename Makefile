build: build-2.5 build-2.6
.PHONY: build

build-2.5:
	docker build -t skopciewski/devenv-ruby:2.5 . --build-arg BUILD_RUBY_VERSION=2.5
.PHONY: build-2.5

build-2.6:
	docker build -t skopciewski/devenv-ruby:2.6 . --build-arg BUILD_RUBY_VERSION=2.6
.PHONY: build-2.6

deploy:
	docker push skopciewski/devenv-ruby
.PHONY: deploy
