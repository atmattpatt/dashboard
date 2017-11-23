class Dashing.CTAAlerts extends Dashing.Widget
  ready: ->
    @node.querySelectorAll("li").forEach (li) ->
      li.style.borderLeftColor = "#" + li.getAttribute("route-color")

    target = @node.querySelector("ul")

    observer = new MutationObserver (mutations) ->
      mutations.forEach (mutation) ->
        mutation.addedNodes.forEach (li) ->
          dataObserver = new MutationObserver (dataMutations) ->
            dataMutations.forEach (dataMutation) ->
              if dataMutation.attributeName == "route-color"
                li.style.borderLeftColor = "#" + li.getAttribute("route-color")

          dataObserver.observe(li, attributes: true, childList: false, characterData: false)

    observer.observe(target, attributes: false, childList: true, characterData: false)
