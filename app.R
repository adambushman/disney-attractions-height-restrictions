##########################################
# Disney Attractions Height Restrictions #
# Shiny App                              #
# Developed by Adam Bushman              #
##########################################


library('shiny')
library('tidyverse')
library('reactablefmtr')

data <- read.csv('attraction-heights.csv')

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Disney Parks & Attractions"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            selectInput("location_u",
                        "Amusement Park Location",
                        unique(data$location)),
            numericInput("height_u",
                        "Child's Height (in)",
                        value = 40,
                        min = 25,
                        max = 60,
                        step = 1),
            selectInput("display_u",
                        "Display Attractions",
                        c("All" = "all", "Too Short" = "red", "Tall Enough" = "darkgreen")),
            selectInput("type_u",
                        "Attraction Type",
                        c("All" = "all", unique(data$type)))
        ),

        # Show a plot of the generated distribution
        mainPanel(
          plotOutput("totals"),
          reactableOutput("attractions")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$totals <- renderPlot({
      data %>%
        filter(location == input$location_u) %>%
        filter(
          if(input$type_u == "all") {
            type %in% unique(data$type)
          }
          else {
            type == input$type_u
          }
        ) %>%
        mutate(result_u = ifelse(height_in <= input$height_u, "Tall Enough", "Too Short"),
               result_u = factor(result_u, levels = c("Too Short", "Tall Enough"))) %>%
        count(park, result_u) %>%
        arrange(park, desc(result_u)) %>%
        group_by(park) %>%
        mutate(label_y = cumsum(n) - 0.5 * n) %>%
          ggplot(aes(park, n)) +
          geom_bar(aes(fill = result_u), stat = "identity", position = "stack") +
          geom_label(aes(y = label_y, label = n)) +
          scale_fill_manual(values = c("red", "darkgreen")) +
          labs(title = "Attraction Totals by Park",
               fill = "") +
          theme_minimal() +
          theme(
            legend.position = "top",
            legend.justification = "left",
            axis.text.y = element_blank(),
            axis.title = element_blank()
          )
    })

    output$attractions <- renderReactable({
        data %>%
          filter(location == input$location_u) %>%
          select(park, type, attraction, height_in) %>%
          mutate(height_col = ifelse(.$height_in <= input$height_u, "darkgreen", "red")) %>%
          filter(
            if(input$display_u == "all") {
              height_col %in% c("darkgreen", "red")
            }
            else {
              height_col == input$display_u
            }
          ) %>%
        filter(
          if(input$type_u == "all") {
            type %in% unique(data$type)
          }
          else {
            type == input$type_u
          }
        ) %>%
          reactable(
            pagination = FALSE,
            columns = list(
              height_in = colDef(
                cell = pill_buttons(., color_ref = "height_col", opacity = 0.7)
              ),
              height_col = colDef(show = FALSE)
            )
          )
    })
}

# Run the application
shinyApp(ui = ui, server = server)
