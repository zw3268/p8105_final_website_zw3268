// Scroll-driven chart.
// R writes the data into the page as JSON (see the Rmd chunk "scrolly_data").
// This script only draws the dots and moves them when a new text step
// reaches the middle of the screen.

(function () {
  var dataTag = document.getElementById("scrolly-data");
  var svg = document.getElementById("scrolly-chart");
  if (!dataTag || !svg) return;

  var data = JSON.parse(dataTag.textContent);
  var NS = "http://www.w3.org/2000/svg";
  var W = 800, H = 520;
  var margin = { left: 30, right: 30, top: 20, bottom: 56 };

  // positions arrive from R already scaled to 0-1
  function px(v) { return margin.left + v * (W - margin.left - margin.right); }
  function py(v) { return margin.top + v * (H - margin.top - margin.bottom); }

  function add(tag, attrs, text) {
    var node = document.createElementNS(NS, tag);
    Object.keys(attrs).forEach(function (k) { node.setAttribute(k, attrs[k]); });
    if (text !== undefined) node.textContent = text;
    svg.appendChild(node);
    return node;
  }

  // axis
  data.ticks.forEach(function (t) {
    add("line", { x1: px(t.x), x2: px(t.x), y1: margin.top, y2: H - margin.bottom, "class": "tick-line" });
    add("text", { x: px(t.x), y: H - margin.bottom + 20, "text-anchor": "middle", "class": "tick-label" }, t.label);
  });
  add("text", { x: W / 2, y: H - 8, "text-anchor": "middle", "class": "axis-title" }, data.axis_title);

  // one dot per hospital
  var dots = data.points.map(function (p) {
    var dot = add("circle", { r: 6, cx: 0, cy: 0, "class": "dot" });
    var label = document.createElementNS(NS, "title");
    label.textContent = p.name;
    dot.appendChild(label);
    return dot;
  });

  var readout = document.getElementById("scrolly-readout");

  // what each step shows: which columns give x / y, and whether to highlight
  var states = data.states;

  function setState(i) {
    var s = states[Math.max(0, Math.min(i, states.length - 1))];
    data.points.forEach(function (p, k) {
      var dot = dots[k];
      dot.style.transform = "translate(" + px(p[s.x]) + "px," + py(p[s.y]) + "px)";
      dot.classList.toggle("is-high", s.highlight && p.grp === "high");
      dot.classList.toggle("is-low", s.highlight && p.grp === "low");
      dot.classList.toggle("is-faded", s.highlight && p.grp === "mid");
    });
    if (readout) readout.textContent = s.readout;
    svg.setAttribute("data-state", i);
  }

  setState(0);

  var steps = Array.prototype.slice.call(document.querySelectorAll(".scrolly-steps .step"));
  var observer = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (!entry.isIntersecting) return;
      steps.forEach(function (el) { el.classList.toggle("is-active", el === entry.target); });
      setState(steps.indexOf(entry.target));
    });
  }, { rootMargin: "-45% 0px -45% 0px", threshold: 0 });

  steps.forEach(function (el) { observer.observe(el); });
  if (steps.length) steps[0].classList.add("is-active");
})();
