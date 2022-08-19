-- (c) 2009-2011 John MacFarlane. Released under MIT license.
-- See the file LICENSE in the source for details.

--- dzslides writer for lunamark.
-- dzslides is a lightweight HTML5 slide engine by Paul Rouget:
-- <https://github.com/paulrouget/dzslides>.
-- This writer extends [lunamark.writer.html5].

local M = {}

local html5 = require("lunamark.writer.html5")

--- Returns a new dzslides writer.
-- `options` is as in `lunamark.writer.html5`. However,
-- `options.slides` is ignored and set to `true`.
-- For a list of fields, see [lunamark.writer.generic].
function M.new(options)
  options = options or {}
  options.slides = true
  local DZSlides = html5.new(options)

  DZSlides.template = [===[
<!DOCTYPE html>
<head>
<meta charset="utf-8">
<title>$title</title>
</head>
$if{ title }[=[
<section>
  <h1>$title</h1>
</section>
]=]
$body
<!-- Your Style -->
<!-- Define the style of you presentation -->

<!-- Maybe a font from http://www.google.com/webfonts ? -->
<link href='http://fonts.googleapis.com/css?family=Oswald' rel='stylesheet'>

<style>
  html { background-color: black; }
  body { background-color: white; }
  /* A section is a slide. Its size is 800x600, and this will never change */
  section {
      /* The font from Google */
      font-family: 'Oswald', arial, serif;
      font-size: 2em;
      padding-left: 1em;
  }
  h1, h2, h3 {
      margin-top: 50px;
      text-align: center;
  }
  ul {
      margin-left: 40px;
  }
  a { color: #FF0066; } a:hover { text-decoration: underline; }
  footer { position: absolute; bottom: 50px; right: 50px; }

  .images {
    margin: 20px;
    text-align: center;
  }

  /* Transition effect */
  /* Feel free to change the transition effect for original
     animations. See here:
     https://developer.mozilla.org/en/CSS/CSS_transitions
     How to use CSS3 Transitions: */
  section {
      -moz-transition: left 400ms linear 0s;
      -webkit-transition: left 400ms linear 0s;
      -ms-transition: left 400ms linear 0s;
      transition: left 400ms linear 0s;
  }

  /* Before */
  section { left: -150%; }
  /* Now */
  section[aria-selected] { left: 0; }
  /* After */
  section[aria-selected] ~ section { left: +150%; }

  /* Increment with lists */
  .incremental > * { opacity: 1; }
  .incremental > *[aria-selected] { color: red; opacity: 1; }
  .incremental > *[aria-selected] ~ * { opacity: 0.2; }
  /* Increment with images */
  .incremental > img[aria-selected] { box-shadow: 0 0 10px #000 }

</style>


<!-- {{{{ *****************  DZSlides CORE 2.0b1 *************************** -->
<!-- *********************************************************************** -->
<!-- *********************************************************************** -->
<!-- *********************************************************************** -->
<!-- *********************************************************************** -->

<!-- This block of code is not supposed to be edited, but if you want to change the behavior of the slides,
     feel free to hack it ;) -->

<!-- Default Style -->
<style>
  * { margin: 0; padding: 0; }
  details { display: none; }
  body {
    width: 800px; height: 600px;
    margin-left: -400px; margin-top: -300px;
    position: absolute; top: 50%; left: 50%;
    overflow: hidden;
  }
  html {
    overflow: hidden;
  }
  section {
    position: absolute;
    pointer-events: none;
    width: 95%; height: 100%;
  }
  section[aria-selected] { pointer-events: auto; }
  body { display: none; }
  body.loaded { display: block; }
  .incremental {visibility: hidden}
  .incremental[active] {visibility: visible}
</style>

<script>
  var friendWindows = [];
  var idx, step;
  var slides;

  /* main() */

  window.onload = function() {
    slides = document.querySelectorAll("body > section");
    onhashchange();
    document.body.className = "loaded";
    setupTouchEvents();
    onresize();
  }

  /* Handle keys */

  window.onkeydown = function(e) {
    // Don't intercept keyboard shortcuts
    if (e.altKey || e.ctrlKey || e.metaKey || e.shiftKey) {
      return;
    }
    if ( e.keyCode == 37 // left arrow
      || e.keyCode == 38 // up arrow
      || e.keyCode == 33 // page up
    ) {
      e.preventDefault();
      back();
    }
    if ( e.keyCode == 39 // right arrow
      || e.keyCode == 40 // down arrow
      || e.keyCode == 34 // page down
    ) {
      e.preventDefault();
      forward();
    }
    if (e.keyCode == 35) { // end
      e.preventDefault();
      end();
    }
    if (e.keyCode == 36) { // home
      e.preventDefault();
      start();
    }

    if ( e.keyCode == 32) { // space
        e.preventDefault();
        toggleContent();
    }
  }

  /* Touch Events */

  function setupTouchEvents() {
    var orgX, newX;
    var tracking = false;

    var db = document.body;
    db.addEventListener("touchstart", start, false);
    db.addEventListener("touchmove", move, false);

    function start(e) {
      e.preventDefault();
      tracking = true;
      orgX = e.changedTouches[0].pageX;
    }

    function move(e) {
      if (!tracking) return;
      newX = e.changedTouches[0].pageX;
      if (orgX - newX > 100) {
        tracking = false;
        forward();
      } else {
        if (orgX - newX < -100) {
          tracking = false;
          back();
        }
      }
    }
  }

  /* Adapt the size of the slides to the window */

  window.onresize = function() {
    var db = document.body;
    var sx = db.clientWidth / window.innerWidth;
    var sy = db.clientHeight / window.innerHeight;
    var transform = "scale(" + (1/Math.max(sx, sy)) + ")";
    db.style.MozTransform = transform;
    db.style.WebkitTransform = transform;
    db.style.OTransform = transform;
    db.style.msTransform = transform;
    db.style.transform = transform;
  }
  function getDetails(idx) {
    var s = document.querySelector("section:nth-of-type("+ idx +")");
    var d = s.querySelector("details");
    return d?d.innerHTML:"";
  }
  window.onmessage = function(e) {
    var msg = e.data;
    var win = e.source;
    if (msg === "register") {
      friendWindows.push(win);
      win.postMessage(JSON.stringify({method: "registered", title: document.title, count: slides.length}), "*");
      win.postMessage(JSON.stringify({method: "newslide", details: getDetails(idx), idx: idx}), "*");
      return;
    }
    if (msg === "back") back();
    if (msg === "forward") forward();
    if (msg === "toggleContent") toggleContent();
    // setSlide(42)
    var r = /setSlide\((\d+)\)/.exec(msg);
    if (r) {
        setSlide(r[1]);
    }
  }

  /* If a Video is present in this new slide, play it.
     If a Video is present in the previous slide, stop it. */

  function toggleContent() {
    var s = document.querySelector("section[aria-selected]");
    if (s) {
        var video = s.querySelector("video");
        if (video) {
            if (video.ended || video.paused) {
                video.play();
            } else {
                video.pause();
            }
        }
    }
  }

  /* If the user change the slide number in the URL bar, jump
     to this slide. */

  function setCursor(aIdx, aStep) {
    aStep = (aStep != 0 && typeof aStep !== "undefined") ? "." + aStep : "";
    window.location.hash = "#" + aIdx + aStep;
  }
  window.onhashchange = function(e) {
    var cursor = window.location.hash.split("#"), newidx = 1, newstep = 0;
    if (cursor.length == 2) {
      newidx = ~~cursor[1].split(".")[0];
      newstep = ~~cursor[1].split(".")[1];
    }
    if (newidx != idx) setSlide(newidx);
    setIncremental(newstep);
  }

  /* Slide controls */

  function back() {
    if (idx == 1 && step == 0) return;
    if (step == 0)
      setCursor(idx - 1, slides[idx - 2].querySelectorAll('.incremental > *').length);
    else
      setCursor(idx, step - 1);
  }
  function forward() {
    if (idx >= slides.length && step >= slides[idx - 1].querySelectorAll('.incremental > *').length) return;
    if (step >= slides[idx - 1].querySelectorAll('.incremental > *').length)
      setCursor(idx + 1, 0);
    else
      setCursor(idx, step + 1);
  }
  function start() {
    setCursor(1, 0);
  }
  function end() {
    var lastIdx = slides.length;
    var lastStep = slides[lastIdx - 1].querySelectorAll('.incremental > *').length;
    setCursor(lastIdx, lastStep);
  }

  function setSlide(aIdx) {
    idx = aIdx;
    var old = document.querySelector("section[aria-selected]");
    var next = document.querySelector("section:nth-of-type("+ idx +")");
    if (old) {
      old.removeAttribute("aria-selected");
      var video = old.querySelector("video");
      if (video) { video.pause(); }
    }
    if (next) {
      next.setAttribute("aria-selected", "true");
      var video = next.querySelector("video");
      if (video) { video.play(); }
    } else {
      idx = 0;
      for (var i = 0, l = slides.length; i < l; i++) {
          if (slides[i].hasAttribute("aria-selected")) {
              idx = i + 1;
          }
      }
    }
    for (var i = 0, l = friendWindows.length; i < l; i++) {
        friendWindows[i].postMessage(JSON.stringify({method: "newslide", details: getDetails(idx), idx: idx}), "*");
    }
  }
  function setIncremental(aStep) {
    step = aStep;
    var old = slides[idx-1].querySelector('.incremental > *[aria-selected]');
    if (old)
      old.removeAttribute('aria-selected');
    var incrementals = slides[idx-1].querySelectorAll('.incremental');
    if (step == 0) {
      for (var i = 0; i < incrementals.length; i++) {
        incrementals[i].removeAttribute('active');
      }
      return;
    }
    var next = slides[idx-1].querySelectorAll('.incremental > *')[step-1];
    if (next) {
      next.setAttribute('aria-selected', true);
      next.parentNode.setAttribute('active', true);
      var found = false;
      for (var i = 0; i < incrementals.length; i++) {
        if (incrementals[i] != next.parentNode)
          if (found)
            incrementals[i].removeAttribute('active');
          else
            incrementals[i].setAttribute('active', true);
        else
          found = true;
      }
    } else {
      setCursor(idx, 0);
    }
    return next;
  }
</script>
<!-- vim: set fdm=marker: }}} -->
]===]

  return DZSlides
end

return M
