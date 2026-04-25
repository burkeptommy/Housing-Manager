/* Chez — shared interaction script.
 *
 * Single responsibility: scroll-reveal animations via IntersectionObserver.
 * Honors prefers-reduced-motion (no-op when the user opts out).
 * Auto-runs on DOMContentLoaded; safe to load with <script defer>.
 *
 * Usage:
 *   <div class="reveal">...</div>             <- single fade-in
 *   <ul class="reveal-stagger">...</ul>       <- children fade in 80ms apart
 *
 * Both classes hide the element until the IntersectionObserver flips
 * `is-visible`. CSS handles the actual animation.
 */

(function () {
  if (typeof window === "undefined" || !("IntersectionObserver" in window)) return;

  const prefersReduced =
    window.matchMedia &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function reveal(el) {
    el.classList.add("is-visible");
  }

  function init() {
    const targets = document.querySelectorAll(".reveal, .reveal-stagger");
    if (!targets.length) return;

    if (prefersReduced) {
      targets.forEach(reveal);
      return;
    }

    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          reveal(entry.target);
          io.unobserve(entry.target);
        });
      },
      {
        threshold: 0.12,
        rootMargin: "0px 0px -8% 0px",
      }
    );

    targets.forEach((el) => io.observe(el));
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
