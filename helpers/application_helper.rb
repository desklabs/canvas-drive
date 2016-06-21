module ApplicationHelper
  def title(value = nil)
    @title = value if value
    @title ? "Desk.com Drive - #{@title}" : "Desk.com Drive"
  end
  
  def style(value = nil)
    @style = value if value
    @style ? "<link href=\"#{@style}\" rel=\"stylesheet\">" : ""
  end
end