test:
	ruby test.rb


test-up:
	cd test-nginx && docker build -t docker-varnish-test-nginx . && docker run -d --name docker-varnish-test-nginx docker-varnish-test-nginx
	docker build -t docker-varnish-test . && docker run -d --name docker-varnish-test --link docker-varnish-test-nginx:backend -p 8080:80 docker-varnish-test

test-destroy:
	docker kill docker-varnish-test docker-varnish-test-nginx || true
	docker rm docker-varnish-test docker-varnish-test-nginx || true
	docker rmi docker-varnish-test docker-varnish-test-nginx || true

clean: test-destroy

.PHONY: test test-up test-destroy
