library(shiny)
library(plotly)
library(reshape2)
library(rmongodb)
library(shinydashboard)

All <- read.csv("all.csv")
Sys.setenv("plotly_username"="richarizardd")
Sys.setenv("plotly_api_key"="ve9vfuje4d")

outputDir <- "responses"
saveData <- function(data) {
  # Create a unique file name
  fileName <- sprintf("%s_%s.csv", as.integer(Sys.time()), digest::digest(data))
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



header <- dashboardHeader(
  title = "Stressbuster"
)

sidebar <- dashboardSidebar(
  sidebarMenu(
    menuItem("Live", tabName = "live", icon = icon("th")),
    menuItem("Graph", tabName = "graph", icon = icon("dashboard")),
    menuItem("History", tabName = "history", icon = icon("th")),
    menuItem("Extra", tabName = "extra", icon = icon("th"))
  )
)

body <- dashboardBody(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),
  tabItems(
    # First Tab Item
    tabItem(tabName = "live",
            fluidRow(
              HTML("<iframe frameborder=\"0\" seamless=\"seamless\" scrolling=\"no\" src=\"https://plot.ly/~abalabazn/46/\" width=\"100%\" height=\"500\"> </iframe>")
            )
    ),
    
    # Second Tab Item
    tabItem(tabName = "graph",
            fluidRow(
              column(width = 9,
                     box(width = NULL, solidHeader = TRUE,
                         plotlyOutput("trendPlot")
                     )
              ),
              
              column(width = 3,
                     box(width = NULL, status = "warning",
                         selectInput("interval", "Refresh interval",
                                     choices = c(
                                       "5 seconds" = 5,
                                       "30 seconds" = 30,
                                       "1 minutes" = 60,
                                       "2 minutes" = 120,
                                       "3 minutes" = 180,
                                       "No Refresh" = "no"
                                     )
                         )
                     ),
                     uiOutput("timeSinceLastUpdate"),
                     actionButton("refresh", "Refresh now"),
                     actionButton("save", "Save"),
                     textOutput("mood")
              )
            )
    ),
    
    # Third Tab Item
    tabItem(tabName = "history",
            sidebarLayout(
              fluidRow(
                selectInput('savedfiles', "Saved Files:", "")
              ),
              fluidRow(
                plotlyOutput("trendPlotAnalyze")
              )
            )
    ),
    
    # Fourth Tab Item
    tabItem(tabName = "extra",
            sidebarLayout(
              fluidRow(
                selectizeInput("filenames",
                               "Saved Files",
                               choices = unique(All$filename),
                               multiple = T,
                               options = list(maxItems = 5,
                                              placeholder = 'Select a name')
                )
              ),
              fluidRow(
                plotlyOutput("trendPlot")
              )
            )
            
    )
  )
  
)
  

dashboardPage(skin='blue',
              header,
              sidebar,
              body
)


