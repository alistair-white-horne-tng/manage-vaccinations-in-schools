class AppEmptyListComponent < ViewComponent::Base
  def initialize(text: "No results", title: nil)
    super

    @text = text
    @title = title
  end
end
