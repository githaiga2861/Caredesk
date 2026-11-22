(() => {
  "use strict";
  const WA_NUMBER = "254115446363";
  const EMAIL = "jose.githaiga.njoroge@gmail.com";
  const DEFAULT_MSG = "Hi Joseph, I found your website and I'd like to talk about a project for our facility.";
  const waUrl = (text) => `https://wa.me/${WA_NUMBER}?text=${encodeURIComponent(text || DEFAULT_MSG)}`;

  // ---------- WhatsApp links everywhere
  document.querySelectorAll(".wa-link").forEach((a) => {
    a.href = waUrl(a.dataset.wa);
    a.target = "_blank";
    a.rel = "noopener";
  });

  // ---------- menu
  const menuBtn = document.getElementById("menu-btn");
  const menu = document.getElementById("menu");
  menuBtn.addEventListener("click", () => {
    const open = menu.hidden;
    menu.hidden = !open;
    menuBtn.setAttribute("aria-expanded", String(open));
  });
  menu.addEventListener("click", (e) => { if (e.target.tagName === "A") menu.hidden = true; });
  document.addEventListener("click", (e) => { if (!menu.hidden && !e.target.closest(".nav")) menu.hidden = true; });

  // ---------- live Pacific clock (most clients are in Washington State)
  const clock = document.getElementById("clock");
  const tick = () => {
    clock.textContent = new Date().toLocaleTimeString("en-US", { timeZone: "America/Los_Angeles", hour: "2-digit", minute: "2-digit", second: "2-digit" });
  };
  tick(); setInterval(tick, 1000);
  document.getElementById("year").textContent = new Date().getFullYear();

  // ---------- rolling hills (drawn, no photos)
  function rand(seed) { return () => { seed = (seed * 16807) % 2147483647; return (seed - 1) / 2147483646; }; }
  function hillsSvg(kind) {
    const r = rand(kind.length * 7919 + 13);
    const W = 1440, H = 300;
    const flowers = kind === "hero" || kind === "foot" || kind === "gallery";
    let dots = "";
    if (flowers) {
      for (let i = 0; i < 220; i++) {
        const x = r() * W, y = 210 + r() * 90, s = 0.8 + r() * 2.2;
        const c = r() > 0.85 ? "#f4d36b" : r() > 0.7 ? "#f2b7c6" : "#ffffff";
        dots += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${s.toFixed(1)}" fill="${c}" opacity="${(0.55 + r() * 0.45).toFixed(2)}"/>`;
      }
    }
    const id = "h" + kind;
    return `<svg viewBox="0 0 ${W} ${H}" preserveAspectRatio="none" aria-hidden="true">
      <defs>
        <linearGradient id="${id}a" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#d8e39a"/><stop offset="1" stop-color="#93b54c"/></linearGradient>
        <linearGradient id="${id}b" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#a9c858"/><stop offset=".6" stop-color="#6f9a2e"/><stop offset="1" stop-color="#4c7420"/></linearGradient>
        <linearGradient id="${id}c" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7ea83a"/><stop offset="1" stop-color="#3b5f18"/></linearGradient>
        <radialGradient id="${id}s" cx=".75" cy=".1" r=".6"><stop offset="0" stop-color="#fff6c9" stop-opacity=".75"/><stop offset="1" stop-color="#fff6c9" stop-opacity="0"/></radialGradient>
      </defs>
      <path d="M0 150 C180 90 320 80 470 120 S760 170 900 110 S1200 60 1440 120 V300 H0Z" fill="url(#${id}a)"/>
      <path d="M0 200 C200 130 380 140 560 175 S880 230 1060 160 S1320 120 1440 170 V300 H0Z" fill="url(#${id}b)"/>
      <path d="M0 250 C240 200 420 215 640 240 S1000 280 1200 225 S1380 210 1440 230 V300 H0Z" fill="url(#${id}c)"/>
      ${kind === "band" || kind === "gallery" ? "" : `<rect width="${W}" height="${H}" fill="url(#${id}s)"/>`}
      ${dots}
    </svg>`;
  }
  document.querySelectorAll("[data-hills]").forEach((el) => { el.innerHTML = hillsSvg(el.dataset.hills); });

  // ---------- client reviews
  // Paste each client's own words into `quote` (with their OK). Cards with an empty quote stay hidden.
  const REVIEWS = [
    { name: "Rose", role: "RN, BScN · Golden Years Home Health", quote: "" },
    { name: "Penninah", role: "CNA · Harmony Living House", quote: "" },
    { name: "Filmer", role: "CEO · Filmax Jambo Tours", quote: "" },
    { name: "Felix", role: "Groove Tax Services", quote: "" },
  ];
  const grid = document.getElementById("review-grid");
  REVIEWS.filter((r) => r.quote.trim()).forEach((r) => {
    const card = document.createElement("article");
    card.className = "review";
    card.innerHTML = `<div><div class="rv-stars">★★★★★</div><blockquote></blockquote></div>
      <div class="rv-who"><span class="rv-av"></span><div><strong></strong><span></span></div></div>`;
    card.querySelector("blockquote").textContent = r.quote;
    card.querySelector(".rv-av").textContent = r.name[0];
    card.querySelector(".rv-who strong").textContent = r.name;
    card.querySelector(".rv-who div span").textContent = r.role;
    grid.append(card);
  });

  // ---------- "Demo" project cards prefill the contact form
  const form = document.getElementById("contact-form");
  document.querySelectorAll("[data-demo]").forEach((a) => {
    a.addEventListener("click", () => {
      form.message.value = `I'd like a demo of ${a.dataset.demo}.`;
      setTimeout(() => form.name.focus(), 500);
    });
  });

  // ---------- contact form → WhatsApp or email
  let via = "wa";
  form.querySelectorAll("button[type=submit]").forEach((b) => b.addEventListener("click", () => { via = b.dataset.via; }));
  form.addEventListener("submit", (e) => {
    e.preventDefault();
    const d = Object.fromEntries(new FormData(form));
    const lines = [
      `Hi Joseph, my name is ${d.name}${d.facility ? ` from ${d.facility}` : ""}.`,
      "",
      d.message,
      d.email ? `\nMy email: ${d.email}` : "",
    ].join("\n").trim();
    if (via === "email") {
      const subject = `Website / system enquiry${d.facility ? " — " + d.facility : ""}`;
      location.href = `mailto:${EMAIL}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(lines)}`;
    } else {
      window.open(waUrl(lines), "_blank", "noopener");
    }
  });

  document.getElementById("foot-form").addEventListener("submit", (e) => {
    e.preventDefault();
    const v = e.target.querySelector("input").value.trim();
    location.href = `mailto:${EMAIL}?subject=${encodeURIComponent("Website enquiry")}&body=${encodeURIComponent("Hi Joseph,\n\nPlease get in touch" + (v ? " at " + v : "") + ".\n")}`;
  });

  // ---------- reveal on scroll
  const targets = document.querySelectorAll(".review, .about-text, .a-card, .p-card, .svc, .timeline li, .tool, .why-card, .c-info, .c-form, .sec-head");
  if ("IntersectionObserver" in window) {
    const io = new IntersectionObserver((entries) => {
      entries.forEach((en) => { if (en.isIntersecting) { en.target.classList.add("in"); io.unobserve(en.target); } });
    }, { threshold: 0.12 });
    targets.forEach((t, i) => { t.classList.add("reveal"); t.style.transitionDelay = (i % 3) * 80 + "ms"; io.observe(t); });
  }
})();
