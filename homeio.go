package main

import (
  "net/http"
  "github.com/gin-gonic/gin"
  "html/template"
  "net"
  "fmt"
  "bufio"
  "strconv"
  "crypto/md5"
  "encoding/hex"
  "io/ioutil"
)

type PasswordForm struct {
  password string
  name string
}

func checkPassword(hashedPassword string) bool {
  dat, _ := ioutil.ReadFile("password.txt")
  superHashedPassword := string(dat)

  hasher := md5.New()
  hasher.Write([]byte(hashedPassword))
  h := hex.EncodeToString(hasher.Sum(nil))

  if h == superHashedPassword {
    //fmt.Print("password OK\n")    
    return true
  } else {
    return false
  }
}


func getMeasIndexJson() string {
  conn, _ := net.Dial("tcp", "127.0.0.1:2005")
  fmt.Fprintf(conn, "measIndex;\n")
  message, _ := bufio.NewReader(conn).ReadString('\n')
  return message
}

func getMeasShowJson(name string) string {
  conn, _ := net.Dial("tcp", "127.0.0.1:2005")
  fmt.Fprintf(conn, "measShow;" + name + ";\n")
  message, _ := bufio.NewReader(conn).ReadString('\n')
  return message
}

func getMeasRawForTimeJson(name string, from uint64,to uint64) string {
  conn, _ := net.Dial("tcp", "127.0.0.1:2005")
  fmt.Fprintf(conn, "measRawForTime;" + name + ";" + strconv.FormatUint(from, 10) + ";" + strconv.FormatUint(to, 10) + ";\n")
  message, _ := bufio.NewReader(conn).ReadString('\n')
  return message
}

func getMeasRawForIndexJson(name string, from uint64,to uint64) string {
  conn, _ := net.Dial("tcp", "127.0.0.1:2005")
  fmt.Fprintf(conn, "measRawForIndex;" + name + ";" + strconv.FormatUint(from, 10) + ";" + strconv.FormatUint(to, 10) + ";\n")
  message, _ := bufio.NewReader(conn).ReadString('\n')
  return message
}


func getActionIndexJson() string {
  conn, _ := net.Dial("tcp", "127.0.0.1:2005")
  fmt.Fprintf(conn, "actionIndex;\n")
  message, _ := bufio.NewReader(conn).ReadString('\n')
  return message
}

func getActionShowJson(name string) string {
  conn, _ := net.Dial("tcp", "127.0.0.1:2005")
  fmt.Fprintf(conn, "actionShow;" + name + ";\n")
  message, _ := bufio.NewReader(conn).ReadString('\n')
  return message
}

func postActionExecuteJson(name string, hashedPassword string) string {
  if checkPassword(hashedPassword) {
    conn, _ := net.Dial("tcp", "127.0.0.1:2005")
    fmt.Fprintf(conn, "actionExecute;" + name + ";\n")
    message, _ := bufio.NewReader(conn).ReadString('\n')
    return message
  } else {
    return "{\"status\":1,\"action\":\"" + name + "\",\"reason\":\"wrong_password\"}"
  }
}

func getOverseerIndexJson() string {
  conn, _ := net.Dial("tcp", "127.0.0.1:2005")
  fmt.Fprintf(conn, "overseerIndex;\n")
  message, _ := bufio.NewReader(conn).ReadString('\n')
  return message
}

func getOverseerShowJson(name string) string {
  conn, _ := net.Dial("tcp", "127.0.0.1:2005")
  fmt.Fprintf(conn, "overseerShow;" + name + ";\n")
  message, _ := bufio.NewReader(conn).ReadString('\n')
  return message
}



func main() {
  r := gin.Default()
  r.Static("/assets", "./assets")
  r.SetHTMLTemplate(template.Must(template.ParseFiles("assets/templates/layout.tmpl")))

  // home#index
  r.GET("/", func(c *gin.Context) {
    obj := gin.H{}
    c.HTML(http.StatusOK, "layout", obj)
  })

  // home#index - sammy.js
  r.POST("/", func(c *gin.Context) {
    obj := gin.H{}
    c.HTML(http.StatusOK, "layout", obj)
  })

  // API
  // meas#index
  r.GET("/api/meas.json", func(c *gin.Context) {
    c.String(http.StatusOK, getMeasIndexJson())
  })

  // meas#show
  r.GET("/api/meas/:name/.json", func(c *gin.Context) {
    var measName string = c.Params.ByName("name")
    c.String(http.StatusOK, getMeasShowJson(measName))
  })

  // meas#raw_for_time
  r.GET("/api/meas/:name/raw_for_time/:from/:to/.json", func(c *gin.Context) {
    measName := c.Params.ByName("name")
    from, _ := strconv.ParseUint(c.Params.ByName("from"), 10, 64)
    to, _ := strconv.ParseUint(c.Params.ByName("to"), 10, 64)
    c.String(http.StatusOK, getMeasRawForTimeJson(measName, from, to))
  })

  // meas#raw_for_index
  r.GET("/api/meas/:name/raw_for_index/:from/:to/.json", func(c *gin.Context) {
    measName := c.Params.ByName("name")
    from, _ := strconv.ParseUint(c.Params.ByName("from"), 10, 64)
    to, _ := strconv.ParseUint(c.Params.ByName("to"), 10, 64)
    c.String(http.StatusOK, getMeasRawForIndexJson(measName, from, to))
  })


  // actions#index  
  r.GET("/api/actions.json", func(c *gin.Context) {
    c.String(http.StatusOK, getActionIndexJson())
  })

  // actions#show
  r.GET("/api/actions/:name/.json", func(c *gin.Context) {
    var actionName string = c.Params.ByName("name")
    c.String(http.StatusOK, getActionShowJson(actionName))
  })

  // actions#execute
  r.POST("/api/actions/:name/execute.json", func(c *gin.Context) {
    var actionName string = c.Params.ByName("name")
    
    var pf PasswordForm
    c.Bind(&pf)
    c.String(http.StatusOK, postActionExecuteJson(actionName, c.Request.Form.Get("password") ) )
  })


  // overseers#index
  r.GET("/api/overseers.json", func(c *gin.Context) {
    c.String(http.StatusOK, getOverseerIndexJson())
  })

  // overseers#show
  r.GET("/api/overseers/:name/.json", func(c *gin.Context) {
    var overseerName string = c.Params.ByName("name")
    c.String(http.StatusOK, getOverseerShowJson(overseerName))
  })


 
  // Listen and serve on 0.0.0.0:8080
  r.Run(":8080")
}
