// Site behaviour. No libraries.
//   1. fade blocks in when they enter the screen
//   2. count numbers up from zero
//   3. the hero bill that itemises itself as you scroll
//   4. scroll-driven charts (chart pinned, text steps scroll past)
// All chart data is written into the page by R; nothing is computed here.

(function () {
  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function each(selector, fn, root) {
    Array.prototype.forEach.call((root || document).querySelectorAll(selector), fn);
  }

  function formatNumber(value, decimals, prefix, suffix) {
    return (prefix || "") +
      value.toLocaleString("en-US", { minimumFractionDigits: decimals, maximumFractionDigits: decimals }) +
      (suffix || "");
  }

  /* ---- 1. reveal ---- */
  var revealObserver = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) {
        entry.target.classList.add("is-visible");
        revealObserver.unobserve(entry.target);
      }
    });
  }, { rootMargin: "0px 0px -12% 0px" });
  each(".reveal", function (el) { revealObserver.observe(el); });

  /* ---- 2. count-up: <span data-count="282444" data-prefix="$" data-decimals="0"> ---- */
  function countUp(el) {
    var target = parseFloat(el.getAttribute("data-count"));
    var decimals = parseInt(el.getAttribute("data-decimals") || "0", 10);
    var prefix = el.getAttribute("data-prefix") || "";
    var suffix = el.getAttribute("data-suffix") || "";
    var finalText = formatNumber(target, decimals, prefix, suffix);
    if (reduceMotion || document.hidden) { el.textContent = finalText; return; }
    var start = null, duration = 1400;
    // safety net: always land on the exact final value
    setTimeout(function () { el.textContent = finalText; }, duration + 400);
    function frame(now) {
      if (start === null) start = now;
      var t = Math.min((now - start) / duration, 1);
      var eased = 1 - Math.pow(1 - t, 3);
      el.textContent = formatNumber(target * eased, decimals, prefix, suffix);
      if (t < 1) requestAnimationFrame(frame);
    }
    requestAnimationFrame(frame);
  }
  var countObserver = new IntersectionObserver(function (entries) {
    entries.forEach(function (entry) {
      if (entry.isIntersecting) { countUp(entry.target); countObserver.unobserve(entry.target); }
    });
  }, { threshold: 0.6 });
  each("[data-count]", function (el) { countObserver.observe(el); });

  /* ---- 3. hero bill ---- */
  var hero = document.querySelector(".hero");
  if (hero) {
    var rows = hero.querySelectorAll(".bill-row");
    var foot = hero.querySelector(".bill-foot");

    function clamp(v) { return Math.max(0, Math.min(1, v)); }

    function updateHero() {
      var rect = hero.getBoundingClientRect();
      var travel = rect.height - window.innerHeight;
      var progress = travel > 0 ? clamp(-rect.top / travel) : 1;
      // rows appear one after another over the first 70% of the scroll
      Array.prototype.forEach.call(rows, function (row, i) {
        var from = parseFloat(row.getAttribute("data-from"));
        var to = parseFloat(row.getAttribute("data-to"));
        var local = i === 0 ? clamp(progress / 0.15) : clamp((progress - 0.12 * i) / 0.18);
        if (i > 0) row.style.setProperty("--show", local.toFixed(3));
        var amount = row.querySelector(".amt");
        if (amount) amount.textContent = formatNumber(from + (to - from) * local, 0, "$");
      });
      if (foot) foot.style.setProperty("--foot", clamp((progress - 0.72) / 0.15).toFixed(3));
    }

    // update straight from the scroll event (five rows, cheap) so the bill
    // never depends on animation frames being available
    window.addEventListener("scroll", updateHero, { passive: true });
    window.addEventListener("resize", updateHero);
    updateHero();
  }

  /* ---- 3b. background photographs: the screen in the middle of the window decides ---- */
  var bgLayers = {};
  each(".bg-layer", function (layer) { bgLayers[layer.getAttribute("data-bg")] = layer; });

  function loadLayer(layer) {
    var src = layer.getAttribute("data-src");
    if (src) { layer.style.backgroundImage = "url('" + src + "')"; layer.removeAttribute("data-src"); }
  }

  // Everything that follows the scroll position registers a function here.
  // One scroll listener runs them all, so nothing waits on observers or timers.
  var onScroll = [];

  // the element (out of a list) that the middle of the window is currently inside
  function elementAtMiddle(elements) {
    var middle = window.innerHeight / 2;
    for (var i = 0; i < elements.length; i++) {
      var rect = elements[i].getBoundingClientRect();
      if (rect.top <= middle && rect.bottom > middle) return elements[i];
    }
    return null;
  }

  if (Object.keys(bgLayers).length) {
    var bgSections = Array.prototype.slice.call(document.querySelectorAll("[data-bg]:not(.bg-layer)"));
    var currentBg = null;
    onScroll.push(function () {
      var section = elementAtMiddle(bgSections);
      if (!section) return;
      var name = section.getAttribute("data-bg");
      if (name === currentBg || !bgLayers[name]) return;
      currentBg = name;
      loadLayer(bgLayers[name]);
      Object.keys(bgLayers).forEach(function (key) {
        bgLayers[key].classList.toggle("is-active", key === name);
      });
    });
    // fetch the remaining pictures once the page itself has loaded
    window.addEventListener("load", function () {
      Object.keys(bgLayers).forEach(function (key) { loadLayer(bgLayers[key]); });
    });
  }

  /* ---- 4. scroll-driven charts ---- */
  var NS = "http://www.w3.org/2000/svg";

  function svgNode(tag, attrs, text) {
    var node = document.createElementNS(NS, tag);
    Object.keys(attrs).forEach(function (k) { node.setAttribute(k, attrs[k]); });
    if (text !== undefined && text !== null) node.textContent = text;
    return node;
  }

  each(".scrolly", function (scrolly) {
    var dataTag = scrolly.querySelector('script[type="application/json"]');
    var svg = scrolly.querySelector(".scrolly-chart");
    var readout = scrolly.querySelector(".scrolly-readout");
    if (!dataTag || !svg) return;
    var data = JSON.parse(dataTag.textContent);

    // one layer of guides + labels per state; only the active layer is visible
    var layers = data.states.map(function (state) {
      var layer = svgNode("g", { "class": "layer", opacity: 0 });
      (state.guides || []).forEach(function (g) {
        layer.appendChild(svgNode("line", { x1: g.x1, y1: g.y1, x2: g.x2, y2: g.y2, "class": "guide" }));
      });
      (state.labels || []).forEach(function (l) {
        layer.appendChild(svgNode("text", {
          x: l.x, y: l.y, "text-anchor": l.anchor || "middle",
          "class": "lab" + (l.strong ? " is-strong" : "")
        }, l.text));
      });
      svg.appendChild(layer);
      return layer;
    });

    // the marks (dots or cells) are created once and then moved / recoloured
    var marks = data.marks.map(function (m) {
      var node = m.shape === "rect"
        ? svgNode("rect", { x: 0, y: 0, width: m.w, height: m.h, rx: 1.5, "class": "mark" })
        : svgNode("circle", { cx: 0, cy: 0, r: m.r, "class": "mark" });
      node.appendChild(svgNode("title", {}, m.label));
      svg.appendChild(node);
      return node;
    });

    function setState(i) {
      i = Math.max(0, Math.min(i, data.states.length - 1));
      data.marks.forEach(function (m, k) {
        var s = m.s[i];
        marks[k].style.transform = "translate(" + s.x + "px," + s.y + "px)";
        marks[k].style.fill = s.fill;
        marks[k].style.opacity = s.o;
      });
      layers.forEach(function (layer, k) { layer.setAttribute("opacity", k === i ? 1 : 0); });
      if (readout) readout.textContent = data.states[i].readout || "";
      svg.setAttribute("data-state", i);
    }
    setState(0);

    var steps = Array.prototype.slice.call(scrolly.querySelectorAll(".step"));
    var currentStep = -1;
    onScroll.push(function () {
      var step = elementAtMiddle(steps);
      // between two steps, or above / below the section: keep the nearest end
      var index = step ? steps.indexOf(step) : currentStep;
      if (!step && steps.length) {
        var first = steps[0].getBoundingClientRect();
        var last = steps[steps.length - 1].getBoundingClientRect();
        if (first.top > window.innerHeight / 2) index = 0;
        else if (last.bottom <= window.innerHeight / 2) index = steps.length - 1;
      }
      if (index === currentStep || index < 0) return;
      currentStep = index;
      steps.forEach(function (el, k) { el.classList.toggle("is-active", k === index); });
      setState(index);
    });
  });

  function runScrollHandlers() { onScroll.forEach(function (fn) { fn(); }); }
  window.addEventListener("scroll", runScrollHandlers, { passive: true });
  window.addEventListener("resize", runScrollHandlers);
  runScrollHandlers();
})();
