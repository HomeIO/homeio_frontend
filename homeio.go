package main

import (
  //"net/http"
  "github.com/gin-gonic/gin"
  "html/template"
)

func main() {
  r := gin.Default()
  r.Static("/assets", "./assets")
  //r.LoadHTMLGlob("templates/*")
  
  var layoutTemplate = "templates/layout.tmpl"
  //r.SetHTMLTemplate(template.Must(template.ParseFiles("layout.tmpl")))
  
  r.GET("/", func(c *gin.Context) {
    obj := gin.H{"title": "Main website"}
    r.SetHTMLTemplate(template.Must(template.ParseFiles(layoutTemplate, "templates/index.tmpl")))
    c.HTML(200, "layout", obj)
  })

  // Listen and serve on 0.0.0.0:8080
  r.Run(":8080")
}
