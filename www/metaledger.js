// Generated by LiveScript 1.5.0
(function(){
  var transactionsToGraph;
  transactionsToGraph = function(it){
    var accounts, flows, i$, len$, transaction, source, target, temp, x$, key$, ref$, y$, z$, nodes, v, links;
    accounts = {};
    flows = {};
    for (i$ = 0, len$ = it.length; i$ < len$; ++i$) {
      transaction = it[i$];
      source = transaction.postings[0];
      target = transaction.postings[1];
      if (source.commodity.value > target.commodity.value) {
        temp = source;
        source = target;
        target = temp;
      }
      x$ = accounts[key$ = source.account] || (accounts[key$] = {});
      x$.id = source.account;
      (ref$ = x$.balance || (x$.balance = {}))[key$ = source.commodity.currency] || (ref$[key$] = 0);
      x$.balance[source.commodity.currency] += source.commodity.value;
      y$ = accounts[key$ = target.account] || (accounts[key$] = {});
      y$.id = target.account;
      (ref$ = y$.balance || (y$.balance = {}))[key$ = target.commodity.currency] || (ref$[key$] = 0);
      y$.balance[target.commodity.currency] += target.commodity.value;
      z$ = flows[key$ = source.account + "\n" + target.account] || (flows[key$] = {});
      z$.source = source.account;
      z$.target = target.account;
      (ref$ = z$.sum || (z$.sum = {}))[key$ = source.commodity.currency] || (ref$[key$] = 0);
      z$.sum[source.commodity.currency] += source.commodity.value;
    }
    nodes = [];
    for (i$ in accounts) {
      v = accounts[i$];
      nodes.push(v);
    }
    links = [];
    for (i$ in flows) {
      v = flows[i$];
      links.push(v);
    }
    return {
      nodes: nodes,
      links: links
    };
  };
  $(function(){
    var svg, width, height, simulation;
    svg = d3.select('svg');
    width = +svg.attr('width');
    height = +svg.attr('height');
    simulation = d3.forceSimulation().force('link', d3.forceLink().id(function(it){
      return it.id;
    })).force('charge', d3.forceManyBody().strength(function(it){
      return -200 * it.radius;
    })).force('center', d3.forceCenter(0.5 * width, 0.5 * height));
    $.get('/transactions', {}, function(it){
      var graph, link, node, x$, y$;
      graph = transactionsToGraph(it);
      graph.nodes.forEach(function(it){
        it.radius = Math.max(5, Math.sqrt(Math.abs(0.1 * it.balance['£'])));
        return it.color = it.balance['£'] > 0
          ? 'green'
          : it.balance['£'] < 0 ? 'red' : '#ccc';
      });
      svg.append('svg:defs').selectAll('marker').data(['end']).enter().append('svg:marker').attr('id', String).attr('viewBox', '0 -5 10 10').attr('refX', 12).attr('markerWidth', 6).attr('markerHeight', 6).attr('orient', 'auto').append('svg:path').attr('d', 'M0,-5L10,0L0,5');
      link = svg.append('svg:g').selectAll('path').data(graph.links).enter().append('svg:path').attr('class', 'link').attr('marker-end', 'url(#end)');
      node = svg.append('svg:g').attr('class', 'nodes').selectAll('circle').data(graph.nodes).enter().append('g').attr('class', 'node');
      x$ = node;
      x$.call(d3.drag().on('start', function(it){
        if (!d3.event.active) {
          simulation.alphaTarget(0.3).restart();
        }
        it.fx = it.x;
        it.fy = it.y;
      }).on('drag', function(it){
        it.fx = d3.event.x;
        it.fy = d3.event.y;
      }).on('end', function(it){
        if (!d3.event.active) {
          simulation.alphaTarget(0);
        }
        it.fx = null;
        it.fy = null;
      }));
      x$.append('circle').attr('r', function(it){
        return it.radius;
      }).attr('fill', function(it){
        return it.color;
      });
      x$.append('text').attr('dx', 12).attr('dy', '.35em').style('font-size', 8).text(function(it){
        return it.id + ' ' + it.balance['£'].toFixed(2);
      });
      y$ = simulation;
      y$.nodes(graph.nodes).on('tick', function(){
        link.attr('d', function(it){
          var dx, dy, dr, sourceOffsetX, sourceOffsetY, targetOffsetX, targetOffsetY;
          dx = it.target.x - it.source.x;
          dy = it.target.y - it.source.y;
          dr = Math.sqrt(dx * dx + dy * dy);
          sourceOffsetX = dx * it.source.radius / dr;
          sourceOffsetY = dy * it.source.radius / dr;
          targetOffsetX = -dx * it.target.radius / dr;
          targetOffsetY = -dy * it.target.radius / dr;
          return "M" + (it.source.x + sourceOffsetX) + "," + (it.source.y + sourceOffsetY) + "A" + dr + "," + dr + " -1 0,1 " + (it.target.x + targetOffsetX) + "," + (it.target.y + targetOffsetY);
        });
        node.attr('transform', function(it){
          return "translate(" + it.x + ", " + it.y + ")";
        });
      });
      y$.force('link').links(graph.links);
    });
  });
}).call(this);
