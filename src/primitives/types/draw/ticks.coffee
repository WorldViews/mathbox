Primitive = require '../../primitive'
Util      = require '../../../util'

class Ticks extends Primitive
  @traits = ['node', 'object', 'style', 'line', 'ticks', 'interval', 'span', 'scale', 'position']

  constructor: (node, context, helpers) ->
    super node, context, helpers

    @tickAxis = @tickNormal = @resolution = @line = null

  make: () ->

    # Prepare data buffer of tick positions
    @resolution = samples = @_helpers.scale.divide ''

    @buffer = @_renderables.make 'dataBuffer',
              width:    samples
              channels: 1

    # Prepare position shader
    positionUniforms =
      tickSize:    @node.attributes['ticks.size']
      tickAxis:    @_attributes.make @_types.vec4()
      tickNormal:  @_attributes.make @_types.vec4()

    @tickAxis   = positionUniforms.tickAxis.value
    @tickNormal = positionUniforms.tickNormal.value

    # Build transform chain
    p = position = @_shaders.shader()
    # Require view transform as callback
    p.require @_helpers.position.pipeline @_shaders.shader()
    # Require buffer sampler as callback
    p.require @buffer.shader @_shaders.shader(), 1
    # Link to tick shader
    p.pipe 'ticks.position', positionUniforms

    # Prepare bound uniforms
    styleUniforms = @_helpers.style.uniforms()
    lineUniforms  = @_helpers.line.uniforms()
    uniforms      = Util.JS.merge lineUniforms, styleUniforms

    # Make line renderable
    @line = @_renderables.make 'line',
              uniforms: uniforms
              samples:  2
              strips:   samples
              position: position

    @_helpers.object.make [@line]
    @_helpers.span.make()

  unmake: () ->
    @line = @tickAxis = @tickNormal = null

    @_helpers.object.unmake()
    @_helpers.span.unmake()

  change: (changed, touched, init) ->
    return @rebuild() if changed['scale.divide']

    if touched['view']     or
       touched['interval'] or
       touched['span']     or
       touched['scale']    or
       init

      # Fetch range along axis
      dimension = @_get 'interval.axis'
      range     = @_helpers.span.get '', dimension

      # Calculate scale along axis
      min   = range.x
      max   = range.y
      ticks = @_helpers.scale.generate '', @buffer, min, max

      Util.Axis.setDimension       @tickAxis,   dimension
      Util.Axis.setDimensionNormal @tickNormal, dimension

      # Clip to number of ticks
      n = ticks.length
      @line.geometry.clip 2, n

module.exports = Ticks