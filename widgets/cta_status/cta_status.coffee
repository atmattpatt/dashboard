class Dashing.CTAStatus extends Dashing.Widget
  ready: ->
    @node.querySelectorAll("span.route").forEach (span) ->
      span.style.background = "#" + span.getAttribute("route-color")

    target = @node.querySelector("ul")

    observer = new MutationObserver (mutations) ->
      mutations.forEach (mutation) ->
        mutation.addedNodes.forEach (li) ->
          span = li.querySelector("span.route")

          dataObserver = new MutationObserver (dataMutations) ->
            dataMutations.forEach (dataMutation) ->
              if dataMutation.attributeName == "route-color"
                span.style.background = "#" + span.getAttribute("route-color")

          dataObserver.observe(span, attributes: true, childList: false, characterData: false)

    observer.observe(target, attributes: false, childList: true, characterData: false)

  onData: (data) ->
    if data.success
      $(@node).find(".error").hide()
    else
      $(@node).find(".error").show()
