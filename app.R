##########################################
# Disney Attractions Height Restrictions #
# Shiny App                              #
# Developed by Adam Bushman              #
##########################################


library('shiny')
library('tidyverse')
library('reactablefmtr')

data <- read.csv('attraction-heights.csv')

# UI Definition
ui <- fluidPage(
  h2("Height Restrictions for Disney Park Attractions", align = "center"),
  br(),

  fluidRow(
    column(12,
           fluidRow(
             column(
               width = 3,
               align = "center",
               selectInput("location_u",
                           "Amusement Park Location",
                           unique(data$location))
             ),
             column(
               width = 3,
               align = "center",
               numericInput("height_u",
                            "Child's Height (in)",
                            value = 40,
                            min = 25,
                            max = 60,
                            step = 1)
             ),
             column(
               width = 3,
               align = "center",
               selectInput("display_u",
                           "Display Attractions",
                           c("All" = "all", "Too Short" = "red", "Tall Enough" = "darkgreen"))
             ),
             column(
               width = 3,
               align = "center",
               selectInput("type_u",
                           "Attraction Type",
                           c("All" = "all", unique(data$type)))
             )
           ),

           br(),

           fluidRow(
             column(width = 5,
                    plotOutput("totals")

             ),
             column(width = 7,
                    reactableOutput("attractions")
             )
           )
    )
  )
)


# Server Logic
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
          labs(title = paste("Attraction Totals by Park", input$location_u, sep = " | "),
               fill = "") +
          theme_minimal() +
          theme(
            legend.position = "top",
            legend.justification = "center",
            plot.title = element_text(hjust = 0.5),
            axis.text.y = element_blank(),
            axis.title = element_blank(),
            axis.text.x = element_text(face = "bold")
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
            defaultPageSize = 10,
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
