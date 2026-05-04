

This folder is meant to collect all the Stateless and Stateful widgets that are used in the application.
This means that all the UI (reusable)components needs to be placed here. This components will be called later on in
their respective screens forming a final layout to be displayed.

Widgets in this folders are built in a way that could be customed when calling in a screen. Making sure the Widget is 
adjustable to the needs of the screen. The layout remains same as it is the same for all screens but the content also
known as "children" in Flutter can be adjusted.

Each Widget might contain its own model(accroding to OOP rules) ensureing a more structured and readable code.
Follow this structure as some of the widgets needs different sizes and positioning which if included in its model(class)
it can give that extra flexibilty to the widget to be used in multiple screens.

Make sure to follow this implementation structure to ensure quality, consitancy and reusability.