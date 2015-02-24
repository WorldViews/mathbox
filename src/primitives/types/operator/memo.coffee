Operator = require './operator'
Util     = require '../../../util'

class Memo extends Operator
  @traits = ['node', 'bind', 'operator', 'source', 'index', 'texture', 'memo']

  sourceShader: (shader) -> @memo.shaderAbsolute shader, 1

  make: () ->
    super
    return unless @bind.source?

    # Listen for updates
    @_listen 'root', 'root.update', @update

    # Read sampling parameters
    minFilter = @_get 'texture.minFilter'
    magFilter = @_get 'texture.magFilter'
    type      = @_get 'texture.type'

    # Fetch geometry dimensions
    dims   = @bind.source.getDimensions()
    {items, width, height, depth} = dims

    # Prepare memoization RTT
    @memo = @_renderables.make 'memo',
              items:     items
              width:     width
              height:    height
              depth:     depth
              minFilter: minFilter
              magFilter: magFilter
              type:      type

    # Build shader to remap data (do it after RTT creation to allow feedback)
    operator = @_shaders.shader()
    @bind.source.sourceShader operator

    # Make screen renderable inside RTT scene
    @compose = @_renderables.make 'memoScreen',
                 map:    operator
                 items:  items
                 width:  width
                 height: height
                 depth:  depth
    @memo.adopt @compose

    # DEBUG
    #dbg = @_renderables.make 'debug',
    #        map: @memo.read()
    #scene = @_inherit 'scene'
    #scene.adopt dbg

  unmake: () ->
    super

    if @bind.source?
      @memo.unadopt @compose
      @memo.dispose()

      @memo = @compose = null

  update: () ->
    @memo?.render()

  resize: () ->
    return unless @bind.source?

    # Fetch geometry dimensions
    dims   = @bind.source.getActive()
    {width, height, depth} = dims

    # Cover only part of the RTT viewport
    @compose.cover width, height, depth

    super

  change: (changed, touched, init) ->
    return @rebuild() if touched['texture'] or
                         touched['operator']


module.exports = Memo
