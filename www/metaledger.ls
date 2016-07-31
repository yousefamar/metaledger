transactions-to-graph = ->
  accounts = {}
  flows    = {}

  for transaction in it
    # TODO: Support more than two postings
    source = transaction.postings[0]
    target = transaction.postings[1]

    # TODO: Support more than one currency
    if source.commodity.value > target.commodity.value
      temp   = source
      source = target
      target = temp

    accounts{}[source.account]
      ..id = source.account
      ..{}balance[source.commodity.currency] ||= 0
      ..balance[source.commodity.currency] += source.commodity.value

    accounts{}[target.account]
      ..id = target.account
      ..{}balance[target.commodity.currency] ||= 0
      ..balance[target.commodity.currency] += target.commodity.value

    flows{}["#{source.account}\n#{target.account}"]
      ..source = source.account
      ..target = target.account
      ..{}sum[source.commodity.currency] ||= 0
      ..sum[source.commodity.currency] += source.commodity.value

  nodes = []
  for ,v of accounts
    nodes.push v

  links = []
  for ,v of flows
    links.push v

  { nodes, links }


$ !->
  svg = d3.select \body
    .style \margin  0
    .style \padding 0
    .style \width   \100%
    .style \height  \100%
    .style \overflow \hidden
    .append \svg:svg
    .style \background-color \#030c22

  width  = window.inner-width
  height = window.inner-height

  window.add-event-listener \resize onresize = !->
    width  := window.inner-width
    height := window.inner-height
    svg
      .attr \width  width
      .attr \height height
    simulation
      ..force \center d3.force-center 0.5 * width, 0.5 * height
      ..restart!

  simulation = d3.force-simulation!
    .force \link d3.force-link!.id -> it.id
    .force \charge d3.force-many-body!.strength -> -100 * it.radius

  onresize!

  <-! $.get \/transactions {}
  graph = transactions-to-graph it

  graph.nodes.for-each ->
    it.radius = Math.max 5 Math.sqrt Math.abs 0.1 * it.balance[\£]
    it.color  = if it.balance[\£] > 0 then \green else if it.balance[\£] < 0 then \red else \#ccc

  svg.append \svg:defs
    .select-all \marker
    .data [ \end ]
    .enter!.append \svg:marker
      .attr \id String
      .attr \viewBox '0 -5 10 10'
      .attr \refX 11
      .attr \markerWidth 6
      .attr \markerHeight 6
      .attr \orient \auto
    .append \svg:path
      .attr \d 'M0,-5L10,0L0,5'

  link = svg.append \svg:g
    .select-all \path
    .data graph.links
    .enter!.append \svg:path
    .attr \class \link
    .attr \marker-end 'url(#end)'

  node = svg.append \svg:g
    .attr \class \nodes
    .select-all \circle
    .data graph.nodes
    .enter!.append \g
      .attr \class \node

  node
    ..call (d3.drag!
      .on \start !->
        unless d3.event.active then simulation.alpha-target 0.3 .restart!
        it.fx = it.x
        it.fy = it.y
      .on \drag !->
        it.fx = d3.event.x
        it.fy = d3.event.y
      .on \end !->
        unless d3.event.active then simulation.alpha-target 0
        it.fx = null
        it.fy = null
    )
    ..append \circle
      .attr \r -> it.radius
      .attr \fill -> it.color
    ..append \text
      .attr \dx 12
      .attr \dy \.35em
      .text -> it.id
    ..append \text
      .attr \class \balance
      .attr \dy -> 0.5 * it.radius
      .attr \text-anchor \middle
      .text -> it.balance[\£].to-fixed 2

  simulation
    ..nodes graph.nodes
      .on \tick !->
        link.attr \d ->
          dx = it.target.x - it.source.x
          dy = it.target.y - it.source.y
          dr = Math.sqrt (dx * dx + dy * dy)
          source-offset-x =  dx * it.source.radius / dr
          source-offset-y =  dy * it.source.radius / dr
          target-offset-x = -dx * it.target.radius / dr
          target-offset-y = -dy * it.target.radius / dr
          # TODO: "End" line at node center
          "M#{it.source.x + source-offset-x},#{it.source.y + source-offset-y}A#dr,#dr -1 0,1 #{it.target.x + target-offset-x},#{it.target.y + target-offset-y}"

        node.attr \transform -> "translate(#{it.x}, #{it.y})"
    ..force \link
      .links graph.links
