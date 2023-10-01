go-deps:
	GO111MODULE=off go get github.com/gin-gonic/gin
	GO111MODULE=off  go get github.com/gin-gonic/contrib/gzip

run:
	GO111MODULE=off go run homeio.go

release:
		GO111MODULE=off GIN_MODE=release go run homeio.go

go-deps-old:
	go get github.com/gin-gonic/gin
	go get github.com/gin-gonic/contrib/gzip

css:
	sass --watch assets/scss/app.scss:assets/scss/app.css --style nested

js:
	coffee -c assets/coffee/*.coffee ;
	while [ true ] ; do \
      inotifywait -e modify assets/coffee/*.coffee ; \
      echo "compiling `date`" ; \
			coffee -c assets/coffee/*.coffee ; \
  done; \
  true

run-old:
	go run homeio.go
