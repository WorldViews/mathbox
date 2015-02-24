ShaderGraph = require '../../vendor/shadergraph/src'

Factory = (snippets) ->
  fetch = (name) ->
    # Built-in library
    s = snippets[name]
    return s if s?

    # Load from <script> tags by ID
    element = document.getElementById name
    if element? and element.tagName == 'SCRIPT'
      return (element.textContent || element.innerText)

    throw "Unknown shader `#{name}`"

  new ShaderGraph fetch,
    autoInspect: true


module.exports = Factory