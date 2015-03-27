package main

import (
  "net/http"
  "github.com/gin-gonic/gin"
  "io/ioutil"
)

func main() {
    r := gin.Default()
    r.Static("/assets", "./assets")
    r.GET("/", func(c *gin.Context) {
        c.String(http.StatusOK, "hello")
    })

   r.GET("/ping", func(c *gin.Context) {
        c.HTML(http.StatusOK, "<script src=\"/main.js\"></script>")
    })

    // Listen and serve on 0.0.0.0:8080
    r.Run(":8080")
}
