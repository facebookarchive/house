{i, p, img, span, a, button, input, iframe, textarea, div, pre, table, tbody, tr, td, ul, li, svg, circle, path} = React.DOM
log = if /debug/.test(window.location.search)
  (-> console.log.apply(console, arguments))
else
  ->

# generates colors, with various hues
colors = []
for h in [10..360] by 25
  colors.push("hsla(#{h}, 85%, 65%, 0.5)")
colors = _.shuffle(colors)
color_pointer = 0
color_map = {}
get_color = (id) ->
  # already assigned a color to this id?
  if (c = color_map[id])
    return c

  # assign a color for this id
  c = colors[color_pointer]
  color_pointer = (color_pointer + 1) % colors.length
  color_map[id] = c

  return c
Wit.color = color = (e) -> get_color(e.wisp+(e.role||''))
selection_class = 'hilight'

is_mode = (m) ->
  (that) ->
    that.props?.mode == m

selection_mode = is_mode('selection')
copy_mode      = is_mode('copy')
edit_mode      = is_mode('edit')

Wit.Tagged = React.createClass
  # Public API
  clear: ->
    $(@getDOMNode()).find(".#{selection_class}").removeClass(selection_class)
  select_all: ->
    e = @getDOMNode()

    r = document.createRange()
    r.setStart(e, 0)
    r.setEnd(e, e.children.length)

    s = window.getSelection()
    s.removeAllRanges()
    s.addRange(r)
  focus: ->
    @refs['rootspan']?.getDOMNode().focus?()

  # Internals
  displayName: 'Tagged'
  getDefaultProps: ->
    onEdit: ->
  componentDidMount: ->
    rootNode = @getDOMNode()
    if x = @getMouseUpContainer()
      $(x).on 'mouseup', (e) =>
        @handleMouseUp(e)

    f = (e) =>
      log 'Copy event', e
      setTimeout => @handleCopy()
      document.removeEventListener f
      yes

    document.addEventListener 'copy', f
  hasMouseUpContainer: ->
    selection_mode(@) && _(f = @props.container).isFunction()
  getMouseUpContainer: ->
    if @hasMouseUpContainer()
      @props.container().getDOMNode()
    else
      null
  handleMouseUp: (e) ->
    if selection_mode(@)
      @handleSelection(e)
  handleSelection: (e) ->
    elem = $(@getDOMNode())

    selection = window.getSelection()
    if selection.type != 'Range'
      log "Selection was not Range but #{selection.type}"
      return
    e.stopPropagation()

    # let's highlight the selected area
    sel_anchor = selection.anchorNode
    sel_focus = selection.focusNode
    sel_range = selection.getRangeAt(0)

    # determine if selection is right-to-left
    common_ancestor = sel_range.commonAncestorContainer
    anchor_index = $(common_ancestor).children().has(sel_anchor).add(sel_anchor).first().index()
    focus_index = $(common_ancestor).children().has(sel_focus).add(sel_focus).first().index()
    right_to_left = focus_index < anchor_index
    if right_to_left
      [sel_anchor, sel_focus] = [sel_focus, sel_anchor]

    # restrain selection to elem
    contained_in = (node, jq) ->
      $node = $(node)
      $node.parent().is(jq) || $node.parentsUntil(jq).last().parent().is(jq)

    # determine start span
    if not contained_in(sel_anchor, elem)
      start_span = elem.children('.tagged').first()
    else
      start_span = $(sel_anchor).parentsUntil(elem)
      start_span.splice(0, 0, sel_anchor)
      start_span = start_span.last()

    # determine end span
    if not contained_in(sel_focus, elem)
      end_span = elem.children('.tagged').last()
    else
      end_span = $(sel_focus).parentsUntil(elem)
      end_span.splice(0, 0, sel_focus)
      end_span.last()
      end_span = end_span.last()

    # determine start, end and body of selection
    start = start_span.index()
    body  = selection.toString()
    end   = body.length + start

    # test if it's a valid selection
    if not (end == (end_span.index() + 1))
      log '[ERROR] end and end_span differed', end, end_span.index() + 1
      return

    # normalize selection
    new_range = document.createRange()
    new_range.setStart(elem[0], start)
    new_range.setEnd(elem[0], end)
    selection.removeAllRanges()
    selection.addRange(new_range)

    # discard previous highlight
    @clear()

    # do the highlight
    if start_span[0] != end_span[0]
      start_span.nextUntil(end_span).add(start_span).add(end_span).addClass(selection_class)
    else
      start_span.addClass(selection_class)
    selection.removeAllRanges()

    @props.onSelection(start: start, end: end, body: $.trim(body))
  handleCopy: ->
    window.getSelection().removeAllRanges()
    if _.isFunction(f = @props.onCopy)
      f()
  render: ->
    children = _(@props.phrase || '').map (c) ->
      ['tagged', c, {}]

    children = _(@props.tags).reduce (acc, t) ->
      if _(t.start).isNumber() && _(t.end).isNumber()
        pre  = acc.slice(0, t.start)
        post = acc.slice(t.end)
        mid  = _(acc.slice(t.start, t.end)).map (c) ->
          [cl, body, style] = c
          style['background-color'] = color(t)
          [cl + ' tagged-ok ' + t.wisp, body, style]

        acc  = [].concat(pre, mid, post)
      acc
    , children

    children = _(children).map (c, i) ->
      [cl, body, style] = c
      (span
        key: "span#{i}"
        className: cl
        style: style
        body)

    sp_attrs =
      ref: 'rootspan'
      className: @props.className

    if @props.contentEditable
      sp_attrs.contentEditable = true
      cancel = false # shared variable between 2 handlers...
      sp_attrs.onBlur = (e) =>
        t = e.target
        if cancel
          cancel = false
          @props.onEdit(null)
        else
          @props.onEdit(t.value || t.textContent || t.innerText)
      sp_attrs.onKeyDown = (e) =>
        switch e.which
          when 27 # esc
            e.preventDefault()
            cancel = true
            t = e.target
            t.blur()
          when 13 # enter
            e.preventDefault()
            t = e.target
            t.blur()
      children = @props.phrase

    if not @hasMouseUpContainer()
      sp_attrs.onMouseUp = @handleMouseUp

    (span sp_attrs, children)
