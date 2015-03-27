package main

import (
  "net/http"
  "github.com/gin-gonic/gin"
  "html/template"
  
  "net"
  "fmt"
  "bufio"
  //"os"
  
  //"encoding/json"
)

func main() {
  r := gin.Default()
  r.Static("/assets", "./assets")
  
  r.GET("/", func(c *gin.Context) {
    obj := gin.H{"title": "Main website"}
    r.SetHTMLTemplate(template.Must(template.ParseFiles("templates/layout.tmpl", "templates/index.tmpl")))
    c.HTML(http.StatusOK, "layout", obj)
  })

  r.GET("/payload.json", func(c *gin.Context) {
    conn, _ := net.Dial("tcp", "127.0.0.1:2005")
    fmt.Fprintf(conn, "measDetails;\n")
    message, _ := bufio.NewReader(conn).ReadString('\n')
    c.String(http.StatusOK, message)
  })

  
  // Listen and serve on 0.0.0.0:8080
  r.Run(":8080")
}
