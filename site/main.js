(() => {
  "use strict";
  const WA_NUMBER = "254115446363";
  const EMAIL = "jose.githaiga.njoroge@gmail.com";
  const DEFAULT_MSG = "Hi Joseph, I found your website and I'd like to talk about a project.";
  const waUrl = (text) => `https://wa.me/${WA_NUMBER}?text=${encodeURIComponent(text || DEFAULT_MSG)}`;
  const $ = (s, r = document) => r.querySelector(s);
  const $$ = (s, r = document) => [...r.querySelectorAll(s)];
  const reduce = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const finePointer = matchMedia("(hover: hover) and (pointer: fine)").matches;

  // ---------- WhatsApp links everywhere
  $$(".wa-link").forEach((a) => { a.href = waUrl(a.dataset.wa); a.target = "_blank"; a.rel = "noopener"; });

  // ---------- client reviews: paste each client's own words (with their OK). Empty quotes stay hidden.
  const REVIEWS = [
    { name: "Rose", role: "RN, BScN · Golden Years Home Health", quote: "" },
    { name: "Penninah", role: "CNA · Harmony Living House", quote: "" },
    { name: "Filmer", role: "CEO · Filmax Jambo Tours", quote: "" },
    { name: "Felix", role: "Groove Tax Services", quote: "" },
  ];
  const grid = $("#review-grid");
  REVIEWS.filter((r) => r.quote.trim()).forEach((r) => {
    const card = document.createElement("article");
    card.className = "review";
    card.innerHTML = `<div><div class="rv-stars">★★★★★</div><blockquote></blockquote></div><div class="rv-who"><span class="rv-av"></span><div><strong></strong><span></span></div></div>`;
    card.querySelector("blockquote").textContent = r.quote;
    card.querySelector(".rv-av").textContent = r.name[0];
    card.querySelector(".rv-who strong").textContent = r.name;
    card.querySelector(".rv-who div span").textContent = r.role;
    grid.append(card);
  });

  // ---------- menu overlay
  const menuBtn = $("#menu-btn"), overlay = $("#overlay");
  const setMenu = (open) => {
    overlay.classList.toggle("open", open);
    overlay.setAttribute("aria-hidden", String(!open));
    menuBtn.setAttribute("aria-expanded", String(open));
    document.body.style.overflow = open ? "hidden" : "";
  };
  menuBtn.addEventListener("click", () => setMenu(!overlay.classList.contains("open")));
  overlay.addEventListener("click", (e) => { if (e.target.closest("a")) setMenu(false); });
  addEventListener("keydown", (e) => { if (e.key === "Escape") setMenu(false); });

  // ---------- clock (Pacific – where most clients are)
  const clock = $("#clock");
  const tick = () => { clock.textContent = new Date().toLocaleTimeString("en-US", { timeZone: "America/Los_Angeles", hour: "2-digit", minute: "2-digit", second: "2-digit" }); };
  tick(); setInterval(tick, 1000);
  $("#year").textContent = new Date().getFullYear();

  // ---------- rotating words in the hero
  const words = ["care-management systems", "referral & booking flows", "data dashboards", "staff & billing tools"];
  const rot = $("#rotator");
  if (!reduce) {
    let wi = 0;
    setInterval(() => { wi = (wi + 1) % words.length; rot.innerHTML = `<span>${words[wi].replace("&", "&amp;")}</span>`; }, 2600);
  }

  // ---------- drawn rolling hills
  function rand(seed) { return () => { seed = (seed * 16807) % 2147483647; return (seed - 1) / 2147483646; }; }
  function hillsSvg(kind) {
    const r = rand(kind.length * 7919 + 13), W = 1440, H = 300, id = "h" + kind;
    let dots = "";
    for (let i = 0; i < 220; i++) {
      const x = r() * W, y = 210 + r() * 90, s = 0.8 + r() * 2.2;
      const c = r() > 0.85 ? "#f4d36b" : r() > 0.7 ? "#f2b7c6" : "#ffffff";
      dots += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${s.toFixed(1)}" fill="${c}" opacity="${(0.55 + r() * 0.45).toFixed(2)}"/>`;
    }
    const sun = kind === "gallery" ? "" : `<rect width="${W}" height="${H}" fill="url(#${id}s)"/>`;
    return `<svg viewBox="0 0 ${W} ${H}" preserveAspectRatio="none" aria-hidden="true"><defs>
      <linearGradient id="${id}a" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d8e39a"/><stop offset="1" stop-color="#93b54c"/></linearGradient>
      <linearGradient id="${id}b" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#a9c858"/><stop offset=".6" stop-color="#6f9a2e"/><stop offset="1" stop-color="#4c7420"/></linearGradient>
      <linearGradient id="${id}c" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7ea83a"/><stop offset="1" stop-color="#3b5f18"/></linearGradient>
      <radialGradient id="${id}s" cx=".75" cy=".1" r=".6"><stop offset="0" stop-color="#fff6c9" stop-opacity=".75"/><stop offset="1" stop-color="#fff6c9" stop-opacity="0"/></radialGradient></defs>
      <path d="M0 150 C180 90 320 80 470 120 S760 170 900 110 S1200 60 1440 120 V300 H0Z" fill="url(#${id}a)"/>
      <path d="M0 200 C200 130 380 140 560 175 S880 230 1060 160 S1320 120 1440 170 V300 H0Z" fill="url(#${id}b)"/>
      <path d="M0 250 C240 200 420 215 640 240 S1000 280 1200 225 S1380 210 1440 230 V300 H0Z" fill="url(#${id}c)"/>${sun}${dots}</svg>`;
  }
  $$("[data-hills]").forEach((el) => { el.innerHTML = hillsSvg(el.dataset.hills); });

  // ---------- split headings into words for the reveal
  $$(".split").forEach((el) => {
    const parts = el.textContent.trim().split(/\s+/);
    el.innerHTML = parts.map((w, i) => `<span class="w"><span style="--i:${i}">${w.replace(/&/g, "&amp;").replace(/</g, "&lt;")}</span></span>`).join(" ");
  });

  // ---------- reveal on scroll + counters
  const revealTargets = $$(".p-card, .whyj-hero, .whyj-card, .svc, .step, .c-info, .c-form, .review, .stack, .work-hint, .demo-note");
  revealTargets.forEach((t, i) => { t.classList.add("reveal"); t.style.transitionDelay = (i % 3) * 90 + "ms"; });
  const countUp = (el) => {
    const end = +el.dataset.count, t0 = performance.now();
    const step = (t) => { const p = Math.min(1, (t - t0) / 1200); el.textContent = Math.round(end * (1 - Math.pow(1 - p, 3))); if (p < 1) requestAnimationFrame(step); };
    requestAnimationFrame(step);
  };
  if ("IntersectionObserver" in window && !reduce) {
    const io = new IntersectionObserver((entries) => {
      entries.forEach((en) => {
        if (!en.isIntersecting) return;
        en.target.classList.add("in");
        if (en.target.dataset.count) countUp(en.target);
        if (en.target.id === "fan") en.target.classList.add("open");
        io.unobserve(en.target);
      });
    }, { threshold: 0.15, rootMargin: "0px 0px -6% 0px" });
    [...revealTargets, ...$$(".split"), ...$$("[data-count]"), $("#fan")].forEach((t) => io.observe(t));
  } else {
    $$(".reveal, .split").forEach((t) => t.classList.add("in"));
    $("#fan").classList.add("open");
  }

  // ---------- project cards: scroll the real screenshot on hover, 3D tilt
  $$(".p-card").forEach((card) => {
    const shot = card.querySelector(".p-shot");
    if (!shot) return;
    const img = shot.querySelector("img");
    const measure = () => {
      const shift = Math.min(0, shot.clientHeight - img.clientHeight);
      img.style.setProperty("--shift", shift + "px");
      img.style.setProperty("--dur", Math.max(1.2, -shift / 110).toFixed(1) + "s");
    };
    if (img.complete) measure(); else img.addEventListener("load", measure);
    addEventListener("resize", measure);
    if (!finePointer || reduce) return;
    card.addEventListener("mousemove", (e) => {
      const r = card.getBoundingClientRect();
      const x = (e.clientX - r.left) / r.width - 0.5, y = (e.clientY - r.top) / r.height - 0.5;
      card.style.transform = `perspective(900px) rotateX(${(-y * 6).toFixed(2)}deg) rotateY(${(x * 8).toFixed(2)}deg) translateY(-6px)`;
    });
    card.addEventListener("mouseleave", () => { card.style.transform = ""; });
  });

  // ---------- spotlight cards follow the cursor
  $$(".spotlight").forEach((el) => el.addEventListener("pointermove", (e) => {
    const r = el.getBoundingClientRect();
    el.style.setProperty("--mx", e.clientX - r.left + "px");
    el.style.setProperty("--my", e.clientY - r.top + "px");
  }));

  // ---------- magnetic buttons
  if (finePointer && !reduce) {
    $$(".magnetic").forEach((b) => {
      b.addEventListener("mousemove", (e) => {
        const r = b.getBoundingClientRect();
        b.style.transform = `translate(${((e.clientX - r.left) / r.width - 0.5) * 12}px, ${((e.clientY - r.top) / r.height - 0.5) * 10}px)`;
      });
      b.addEventListener("mouseleave", () => { b.style.transform = ""; });
    });
  }

  // ---------- cursor glow + hero card parallax
  const glow = $("#cursor-glow"), heroCards = $$(".h-card");
  let mx = innerWidth / 2, my = innerHeight / 3, gx = mx, gy = my;
  if (finePointer && !reduce) {
    document.body.classList.add("has-pointer");
    addEventListener("pointermove", (e) => { mx = e.clientX; my = e.clientY; }, { passive: true });
  }

  // ---------- scroll-driven effects (one rAF loop)
  const nav = $("#nav"), progress = $("#progress"), hills = $(".hills-hero"), waFloat = $(".wa-float");
  const navSection = $("#nav-section"), sections = $$("[data-label]");
  const steps = $("#steps"), fill = $("#steps-fill"), stepEls = $$(".step");
  let lastY = scrollY;
  function frame() {
    const y = scrollY, max = document.documentElement.scrollHeight - innerHeight;
    progress.style.transform = `scaleX(${max > 0 ? y / max : 0})`;
    // nav hides while scrolling down, comes back on the way up
    if (!overlay.classList.contains("open")) {
      if (y > 200 && y > lastY + 2) nav.classList.add("hide");
      else if (y < lastY - 2 || y <= 200) nav.classList.remove("hide");
    }
    lastY = y;
    waFloat.classList.toggle("show", y > innerHeight * 0.6);
    if (!reduce) {
      if (y < innerHeight * 1.2) hills.style.transform = `translateY(${(y * 0.25).toFixed(1)}px)`;
      gx += (mx - gx) * 0.12; gy += (my - gy) * 0.12;
      glow.style.left = gx + "px"; glow.style.top = gy + "px";
      if (y < innerHeight * 1.2) {
        const px = mx / innerWidth - 0.5, py = my / innerHeight - 0.5;
        heroCards.forEach((c, i) => {
          const d = i ? 26 : 16, base = i ? "rotate(7deg) translate(-18px, 0px)" : "rotate(-8deg) translate(18px, 18px)";
          c.style.transform = `${base} translate(${(px * d).toFixed(1)}px, ${(py * d - y * (i ? 0.12 : 0.06)).toFixed(1)}px)`;
        });
      }
    }
    // current section label in the nav pill
    let current = "";
    for (const s of sections) { const r = s.getBoundingClientRect(); if (r.top < innerHeight * 0.4 && r.bottom > innerHeight * 0.4) current = s.dataset.label; }
    const label = current ? "· " + current : "";
    if (navSection.textContent !== label) { navSection.textContent = label; navSection.classList.toggle("on", !!current); }
    // process line fills as you scroll through it
    const sr = steps.getBoundingClientRect();
    const p = Math.max(0, Math.min(1, (innerHeight * 0.8 - sr.top) / (sr.height + innerHeight * 0.25)));
    fill.style.width = (p * 100).toFixed(1) + "%";
    stepEls.forEach((s, i) => s.classList.toggle("on", p >= (i + 0.15) / stepEls.length));
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);

  // ---------- contact form → WhatsApp or email
  const form = $("#contact-form");
  let via = "wa";
  $$("button[type=submit]", form).forEach((b) => b.addEventListener("click", () => { via = b.dataset.via; }));
  form.addEventListener("submit", (e) => {
    e.preventDefault();
    const d = Object.fromEntries(new FormData(form));
    const lines = [`Hi Joseph, my name is ${d.name}${d.facility ? ` from ${d.facility}` : ""}.`, "", d.message, d.email ? `\nMy email: ${d.email}` : ""].join("\n").trim();
    if (via === "email") {
      location.href = `mailto:${EMAIL}?subject=${encodeURIComponent(`Project enquiry${d.facility ? " — " + d.facility : ""}`)}&body=${encodeURIComponent(lines)}`;
    } else window.open(waUrl(lines), "_blank", "noopener");
  });
})();
