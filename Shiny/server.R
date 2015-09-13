library(shiny)
library(plotly)
library(reshape2)
library(ggthemes)
library(dplyr)

All <- read.csv("all.csv")
source("plotlyGraphWidget.R")

Sys.setenv("plotly_username"="richarizardd")
Sys.setenv("plotly_api_key"="ve9vfuje4d")
outputDir <- "responses"
mood <- c("Mellow", "Chillin", "Rustled", "Tilted")

saveData <- function(data) {
  # Create a unique file name
  fileName <- sprintf("%s.csv", as.integer(Sys.time()))
  # Write the file to the local system
  write.csv(
    x = data,
    file = file.path(outputDir, fileName), 
    row.names = FALSE, quote = TRUE
  )
}

loadData <- function() {
  # Read all the files into a list
  files <- list.files(outputDir, full.names = TRUE)
  data <- lapply(files, read.csv, stringsAsFactors = FALSE) 
  # Concatenate all data together into one data.frame
  data <- do.call(rbind, data)
  data
}


shinyServer(function(input, output, session) {
  options(mongodb = list(
    "host" = "ds035713.mongolab.com:35713",
    "name" = "bayo",
    "pass" = "1234"
  ))
  databaseName <- "todolist"
  collectionName <- "todolist.gsr"
  
  db <- mongo.create(db = databaseName, host = options()$mongodb$host, 
                     username = options()$mongodb$name, password = options()$mongodb$pass)
  


  # Number of seconds since last update
  output$timeSinceLastUpdate <- renderUI({
    # Trigger this every 5 seconds
    invalidateLater(1000, session)
    p(
      "Data refreshed ",
      round(difftime(Sys.time(), lastUpdateTime(), units="secs")),
      " seconds ago."
    )
  })
  

  # Get time that vehicles locations were updated
  lastUpdateTime <- reactive({
    input$refresh
    UpdateData()
    Sys.time()
  })
  
  UpdateData <- reactive({
    input$refresh # Refresh if button clicked
    validate(
      need(mongo.is.connected(db) == TRUE, "Currently not connected to Mongo DB")
    )
    
    data <- mongo.find.all(db, collectionName, query='{"_id":"sensor_data"}')
    data <- lapply(data, data.frame, stringsAsFactors = FALSE)
    data <- do.call(rbind, data)
    data <- data[ , -1, drop = FALSE]
    print(head(data))
    data
    
  })
  
  
  observeEvent(input$save,{
    saveData(UpdateData())
    outVar()
  })
  
  output$trendPlot <- renderPlotly({
    data <- UpdateData()
    mean1 <- mean(data$voltage)
    mean2 <- mean(data[data$voltage >= mean1,]$voltage)
    mean3 <- mean(data[data$voltage >= mean2,]$voltage)
    data <- cbind(data, mean1 = mean1, mean2 = mean2, mean3 = mean3)
    gg <- ggplot(data, aes(x = time, y = voltage)) + geom_line()
    gg <- gg + geom_ribbon(data = data, aes(x = time, ymin = 0, ymax = mean1), fill = "green", alpha = 0.4)
    gg <- gg + geom_ribbon(data = data, aes(x = time, ymin = mean1, ymax = mean2), fill = "yellow", alpha = 0.4)
    gg <- gg + geom_ribbon(data = data, aes(x = time, ymin = mean2, ymax = mean3), fill = "orange", alpha = 0.4)
    gg <- gg + geom_ribbon(data = data, aes(x = time, ymin = mean3, ymax = max(voltage)), fill = "red", alpha = 0.4)
    p <- ggplotly(gg)
    p
  })
  
  outVar <- reactive({
    filenames <- list.files("responses", pattern="", full.names=TRUE)
    filenames
  })
  
  observe({
    updateSelectInput(session, "savedfiles", choices = outVar())
  })
  
  selectData <- reactive({
    read.csv(input$'savedfiles')
  })
  
  currentMood <- reactive({
    data <- UpdateData()
    lastPoint <- as.numeric(tail(data,1)[1])
    mean1 <- mean(data$voltage)
    mean2 <- mean(data[data$voltage >= mean1,]$voltage)
    mean3 <- mean(data[data$voltage >= mean2,]$voltage)
    
    if (lastPoint > mean1) {
      if (lastPoint > mean2) {
        if (lastPoint > mean3) {
          mood[4]
        } else {
          mood[3]
        }
      } else {
        mood[2]
      }
    } else {
      mood[1]
    }
  })
  
  output$mood <- renderText({
    curr <- currentMood()
    mongo.update(db, collectionName, '{"_id":"currentmood"}',paste('{"mood":"', curr, '"}'))
    curr
  })
  
  output$trendPlotAnalyze <- renderPlotly({
    data <- selectData()
    mean1 <- mean(data$voltage)
    mean2 <- mean(data[data$voltage >= mean1,]$voltage)
    mean3 <- mean(data[data$voltage >= mean2,]$voltage)
    data <- cbind(data, mean1 = mean1, mean2 = mean2, mean3 = mean3)
    gg <- ggplot(data, aes(x = time, y = voltage)) + geom_line()
    gg <- gg + geom_ribbon(data = data, aes(x = time, ymin = 0, ymax = mean1), fill = "green", alpha = 0.4)
    gg <- gg + geom_ribbon(data = data, aes(x = time, ymin = mean1, ymax = mean2), fill = "yellow", alpha = 0.4)
    gg <- gg + geom_ribbon(data = data, aes(x = time, ymin = mean2, ymax = mean3), fill = "orange", alpha = 0.4)
    gg <- gg + geom_ribbon(data = data, aes(x = time, ymin = mean3, ymax = max(voltage)), fill = "red", alpha = 0.4)
    p <- ggplotly(gg)
    p
  })
  
  AllData <- reactive({
    All[All$filename %in% input$filenames,]
    print(4)
  })
  
  output$trendPlot <- renderPlotly({
    input$refresh
    
      df_trend <- AllData()
      
      gg_voltage <- ggplot(df_trend) +
        geom_line(aes(x=time, y=voltage, by=filename, color=filename)) +
        labs(x = "Time (Hours)") +
        labs(y = "Voltage") +
        labs(title = "Galvanic Skin Response Across Days") +
        scale_colour_hue("clarity",l=70, c=150) +
        theme_few()

      p <- ggplotly(gg_voltage)
      p
      
  })
})