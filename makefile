go-deps:
	go get github.com/gin-gonic/gin

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

run:
	go run homeio.go

release:
	GIN_MODE=release	go run homeio.go
