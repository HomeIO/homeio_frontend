package main

import (
  "net/http"
  "github.com/gin-gonic/gin"
  "html/template"
  
  "net"
  "fmt"
  "bufio"
)

func getMeasDetailsJson() string {
  conn, _ := net.Dial("tcp", "127.0.0.1:2005")
  fmt.Fprintf(conn, "measDetails;\n")
  message, _ := bufio.NewReader(conn).ReadString('\n')
  return message
}

func getActionDetailsJson() string {
  conn, _ := net.Dial("tcp", "127.0.0.1:2005")
  fmt.Fprintf(conn, "actionDetails;\n")
  message, _ := bufio.NewReader(conn).ReadString('\n')
  return message
}

func getOverseerDetailsJson() string {
  conn, _ := net.Dial("tcp", "127.0.0.1:2005")
  fmt.Fprintf(conn, "overseerDetails;\n")
  message, _ := bufio.NewReader(conn).ReadString('\n')
  return message
}

func main() {
  var measDetailsString string = getMeasDetailsJson()
  var actionDetailsString string = getActionDetailsJson()
  var overseerDetailsString string = getOverseerDetailsJson()
  
  r := gin.Default()
  r.Static("/assets", "./assets")
  r.SetHTMLTemplate(template.Must(template.ParseFiles("templates/layout.tmpl")))
  
  r.GET("/", func(c *gin.Context) {
    obj := gin.H{"title": "Main website"}
    
    c.HTML(http.StatusOK, "layout", obj)
  })

  r.GET("/measDetails.json", func(c *gin.Context) {
    c.String(http.StatusOK, measDetailsString)
  })
  
  r.GET("/actionDetails.json", func(c *gin.Context) {
    c.String(http.StatusOK, actionDetailsString)
  })

  r.GET("/overseerDetails.json", func(c *gin.Context) {
    c.String(http.StatusOK, overseerDetailsString)
  })
  
  
  r.POST("/reload", func(c *gin.Context) {
    measDetailsString = getMeasDetailsJson()
    actionDetailsString = getActionDetailsJson()
    overseerDetailsString = getOverseerDetailsJson()
    c.String(http.StatusOK, "{}")
  })

  
  // Listen and serve on 0.0.0.0:8080
  r.Run(":8080")
}
