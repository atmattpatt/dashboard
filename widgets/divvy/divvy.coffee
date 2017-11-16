class Dashing.Divvy extends Dashing.Widget
  onData: (data) ->
    if data.success
      $(@node).find(".error").hide()
    else
      $(@node).find(".error").show()
