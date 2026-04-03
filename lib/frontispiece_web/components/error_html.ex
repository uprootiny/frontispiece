defmodule FrontispieceWeb.ErrorHTML do
  @moduledoc "Error page renderer."

  use FrontispieceWeb, :html

  @spec render(String.t(), map()) :: String.t()
  def render(template, _assigns) do
    Phoenix.Controller.status_message_from_template(template)
  end
end
