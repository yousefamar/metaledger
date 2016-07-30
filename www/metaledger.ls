transactions-to-graph = ->
  accounts = {}
  flows    = {}
  nodes = []
  links = []

  for transaction in it
    # TODO: Support more than two postings
    source = transaction.postings[0]
    target = transaction.postings[1]

    # TODO: Support more than one currency
    if source.commodity.value > target.commodity.value
      temp   = source
      source = target
      target = temp

    #accounts{}[
    accounts[source.account] = {}
    accounts[target.account] = {}

    #source.{}balance[postings[0].commodity.currency] ||= 0
    #source.balance += postings[0]
    #children = node.{}children
    unless flows["#{source.account}\n#{target.account}"]?
      links.push do
        source: source.account
        target: target.account

      flows["#{source.account}\n#{target.account}"] = {}

  for k, v of accounts
    nodes.push id: k

  { nodes, links }


$ !->
  svg = d3.select \svg
  width  = +svg.attr \width
  height = +svg.attr \height

  simulation = d3.force-simulation!
    .force \link d3.force-link!.id -> it.id
    .force \charge d3.force-many-body!.strength -1000
    .force \center d3.force-center 0.5 * width, 0.5 * height

  <-! $.get \/transactions {}
  graph = transactions-to-graph it

  svg.append \svg:defs
    .select-all \marker
    .data [ \end ]
    .enter!.append \svg:marker
      .attr \id String
      .attr \viewBox '0 -5 10 10'
      .attr \refX 15
      .attr \refY -1.5
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
      .attr \r 5
      .attr \fill \red
    ..append \text
      .attr \dx 12
      .attr \dy \.35em
      .style \font-size 8
      .text -> it.id

  simulation
    ..nodes graph.nodes
      .on \tick !->
        link.attr \d ->
          dx = it.target.x - it.source.x
          dy = it.target.y - it.source.y
          dr = Math.sqrt (dx * dx + dy * dy)
          "M#{it.source.x},#{it.source.y}A#dr,#dr 0 0,1 #{it.target.x},#{it.target.y}"

        node.attr \transform -> "translate(#{it.x}, #{it.y})"
    ..force \link
      .links graph.links
