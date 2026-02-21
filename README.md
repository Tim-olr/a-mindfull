<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>A Mindfull — README</title>
  <link href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@700;900&family=DM+Serif+Display&family=DM+Sans:wght@300;400;500&display=swap" rel="stylesheet" />
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    :root {
      --bg: #0a0b0f;
      --surface: #12141c;
      --border: #252838;
      --spirit: #b08aff;
      --spirit-dim: rgba(176, 138, 255, 0.12);
      --accent: #7ee8c8;
      --text: #dde3f5;
      --muted: #7c84a8;
      --gold: #f0d080;
      --heading: #f0f4ff;
    }

    html { scroll-behavior: smooth; }

    body {
      background: var(--bg);
      color: var(--text);
      font-family: 'DM Sans', sans-serif;
      font-weight: 300;
      line-height: 1.8;
      overflow-x: hidden;
    }

    /* Starfield background */
    body::before { display: none; }

    /* Ambient glow orbs */
    body::after {
      display: none;
    }

    /* ── LAYOUT ── */
    .wrapper {
      position: relative;
      z-index: 1;
      max-width: 860px;
      margin: 0 auto;
      padding: 0 2rem 6rem;
    }

    /* ── HERO ── */
    .hero {
      text-align: center;
      padding: 5rem 0 4rem;
      position: relative;
    }

    .hero-eyebrow {
      font-family: 'DM Sans', sans-serif;
      font-size: 0.72rem;
      letter-spacing: 0.35em;
      color: var(--accent);
      text-transform: uppercase;
      font-weight: 500;
      margin-bottom: 1.5rem;
    }

    .hero-title {
      font-family: 'Playfair Display', serif;
      font-size: clamp(3.2rem, 9vw, 5.5rem);
      font-weight: 900;
      letter-spacing: -0.02em;
      line-height: 1.05;
      color: var(--heading);
    }

    .hero-sub {
      margin-top: 1.25rem;
      font-size: 1rem;
      color: var(--muted);
      letter-spacing: 0.06em;
      font-family: 'DM Serif Display', serif;
      font-style: italic;
    }

    .badge-row {
      display: flex;
      justify-content: center;
      flex-wrap: wrap;
      gap: 0.6rem;
      margin-top: 2rem;
    }

    .badge { display: inline-flex; align-items: center; gap: 0.35rem; padding: 0.3rem 0.85rem; border-radius: 999px; font-size: 0.72rem; font-family: 'DM Sans', sans-serif; font-weight: 500; letter-spacing: 0.06em; border: 1px solid; }
    .badge-dev  { border-color: rgba(240,208,128,0.5); color: var(--gold);   background: rgba(240,208,128,0.08); }
    .badge-rogue{ border-color: rgba(176,138,255,0.5); color: var(--spirit); background: var(--spirit-dim); }
    .badge-extr { border-color: rgba(126,232,200,0.5); color: var(--accent);  background: rgba(126,232,200,0.07); }

    .divider {
      width: 100%;
      height: 1px;
      background: var(--border);
      margin: 2.5rem 0;
    }

    /* ── SECTIONS ── */
    .section {
      margin-bottom: 3rem;
    }

    .section-label {
      font-family: 'DM Sans', sans-serif;
      font-size: 0.65rem;
      letter-spacing: 0.3em;
      color: var(--accent);
      text-transform: uppercase;
      font-weight: 500;
      margin-bottom: 0.5rem;
    }

    .section-title {
      font-family: 'Playfair Display', serif;
      font-size: 1.6rem;
      font-weight: 700;
      color: var(--heading);
      margin-bottom: 1rem;
      position: relative;
      display: inline-block;
    }

    .section-title::after {
      content: '';
      position: absolute;
      bottom: -5px;
      left: 0;
      width: 100%;
      height: 1px;
      background: var(--spirit);
    }

    .section p {
      color: var(--text);
      font-size: 0.97rem;
      max-width: 700px;
    }

    /* ── CARDS ── */
    .card-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
      gap: 1rem;
      margin-top: 1.25rem;
    }

    .card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 10px;
      padding: 1.4rem 1.5rem;
      position: relative;
      overflow: hidden;
      transition: border-color 0.3s, transform 0.3s;
    }

    .card:hover {
      border-color: var(--spirit);
      transform: translateY(-3px);
    }

    .card::before {
      content: '';
      position: absolute;
      top: 0; left: 0; right: 0;
      height: 2px;
      background: var(--spirit);
      opacity: 0;
      transition: opacity 0.3s;
    }

    .card:hover::before { opacity: 1; }

    .card-icon {
      font-size: 1.6rem;
      margin-bottom: 0.75rem;
      display: block;
    }

    .card-name {
      font-family: 'DM Serif Display', serif;
      font-size: 1rem;
      color: var(--heading);
      margin-bottom: 0.4rem;
    }

    .card-desc {
      font-size: 0.85rem;
      color: var(--muted);
      line-height: 1.65;
    }

    /* ── HOW TO PLAY STEPS ── */
    .steps {
      display: flex;
      flex-direction: column;
      gap: 0;
      margin-top: 1.25rem;
    }

    .step {
      display: flex;
      gap: 1.2rem;
      align-items: flex-start;
      position: relative;
    }

    .step:not(:last-child)::after {
      content: '';
      position: absolute;
      left: 1.05rem;
      top: 2.5rem;
      bottom: -0.5rem;
      width: 1px;
      background: linear-gradient(to bottom, var(--border), transparent);
    }

    .step-num {
      flex-shrink: 0;
      width: 2.2rem;
      height: 2.2rem;
      border-radius: 50%;
      border: 1px solid var(--spirit);
      background: var(--spirit-dim);
      display: flex;
      align-items: center;
      justify-content: center;
      font-family: 'DM Sans', sans-serif;
      font-size: 0.7rem;
      font-weight: 500;
      color: var(--spirit);
      margin-bottom: 1.5rem;
    }

    .step-body { padding-top: 0.2rem; }

    .step-title {
      font-family: 'DM Serif Display', serif;
      font-size: 1rem;
      color: var(--heading);
      margin-bottom: 0.25rem;
    }

    .step-text { font-size: 0.87rem; color: var(--muted); }

    /* ── CTA SECTION ── */
    .cta-block {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 2.5rem 2rem;
      text-align: center;
      position: relative;
      overflow: hidden;
      margin-top: 1.25rem;
    }

    .cta-block::before { display: none; }

    .cta-block p {
      font-size: 0.9rem;
      color: var(--muted);
      margin-bottom: 1.5rem;
      max-width: 500px;
      margin-left: auto;
      margin-right: auto;
    }

    .btn-row {
      display: flex;
      gap: 0.75rem;
      justify-content: center;
      flex-wrap: wrap;
    }

    .status-bar {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 0.5rem;
      padding: 0.6rem 1.25rem;
      background: rgba(240,208,128,0.07);
      border: 1px solid rgba(240,208,128,0.22);
      border-radius: 6px;
      font-size: 0.75rem;
      font-family: 'DM Sans', sans-serif;
      font-weight: 500;
      color: var(--gold);
      letter-spacing: 0.08em;
      margin-bottom: 3rem;
      display: inline-flex;
    }

    .status-dot {
      width: 6px;
      height: 6px;
      border-radius: 50%;
      background: var(--gold);
      animation: pulse 2s infinite;
    }

    .status-wrap {
      display: flex;
      justify-content: center;
    }

    /* ── FOOTER ── */
    footer {
      text-align: center;
      padding-top: 2rem;
      border-top: 1px solid var(--border);
      font-size: 0.75rem;
      color: var(--muted);
      font-family: 'DM Sans', sans-serif;
      letter-spacing: 0.08em;
    }

    footer a {
      color: var(--muted);
      text-decoration: none;
      transition: color 0.2s;
    }

    footer a:hover { color: var(--accent); }

    .btn {
      display: inline-flex;
      align-items: center;
      gap: 0.5rem;
      padding: 0.7rem 1.5rem;
      border-radius: 6px;
      font-family: 'DM Sans', sans-serif;
      font-size: 0.8rem;
      font-weight: 500;
      letter-spacing: 0.08em;
      text-decoration: none;
      transition: all 0.25s;
    }

    .btn-primary {
      background: var(--spirit);
      color: #0a0b0f;
      border: 1px solid transparent;
      box-shadow: none;
    }

    .btn-primary:hover {
      background: #c4a8ff;
      box-shadow: none;
      transform: translateY(-2px);
    }

    .btn-secondary {
      background: transparent;
      color: var(--accent);
      border: 1px solid rgba(126,232,200,0.3);
    }

    .btn-secondary:hover {
      border-color: var(--accent);
      background: rgba(126,232,200,0.07);
      transform: translateY(-2px);
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.3; }
    }
  </style>
</head>
<body>
<div class="wrapper">

  <!-- HERO -->
  <header class="hero">
    <p class="hero-eyebrow">An indie game by one developer</p>
    <h1 class="hero-title">A Mindfull</h1>
    <div class="badge-row">
      <span class="badge badge-dev">🛠 Early Development</span>
      <span class="badge badge-rogue">✦ Roguelike</span>
      <span class="badge badge-extr">⬡ Extraction Shooter</span>
    </div>
  </header>

  <div class="divider"></div>

  <div class="status-wrap">
    <div class="status-bar">
      <span class="status-dot"></span>
      Active development — updates added regularly
    </div>
  </div>

  <!-- ABOUT -->
  <section class="section">
    <p class="section-label">Overview</p>
    <h2 class="section-title">What is A Mindfull?</h2>
    <p>
      A Mindfull is a roguelike extraction shooter built around a unique mechanic: your <strong style="color:#e8f0ff;">spirit</strong>.
      Each run challenges you to loot, fight, and survive — but what sets you apart is your ability to <em>embrace your spirit</em>,
      unlocking powerful abilities that shift the tide of every encounter. Discover upgrades, fill your inventory, and make it back to the extraction point alive.
    </p>
  </section>

  <!-- SPIRIT -->
  <section class="section">
    <p class="section-label">Core Mechanic</p>
    <h2 class="section-title">The Spirit System</h2>
    <div class="card-grid">
      <div class="card">
        <span class="card-icon">🌀</span>
        <div class="card-name">Embracing Your Spirit</div>
        <div class="card-desc">Bring your spirit into the physical world to unlock its power. A high-risk, high-reward stance that defines your playstyle.</div>
      </div>
      <div class="card">
        <span class="card-icon">⚡</span>
        <div class="card-name">Active Ability</div>
        <div class="card-desc">Your spirit's offensive or utility power, triggered on demand while embraced. Use it wisely — timing is everything.</div>
      </div>
      <div class="card">
        <span class="card-icon">🛡</span>
        <div class="card-name">Passive Ability</div>
        <div class="card-desc">A constant boon that applies whenever your spirit is embraced, subtly augmenting your capabilities in the field.</div>
      </div>
    </div>
  </section>

  <!-- HOW TO PLAY -->
  <section class="section">
    <p class="section-label">Gameplay Loop</p>
    <h2 class="section-title">How to Play</h2>
    <div class="steps">
      <div class="step">
        <div class="step-num">01</div>
        <div class="step-body">
          <div class="step-title">Drop In</div>
          <div class="step-text">Enter a run and start exploring. Enemies, loot, and danger await around every corner.</div>
        </div>
      </div>
      <div class="step">
        <div class="step-num">02</div>
        <div class="step-body">
          <div class="step-title">Embrace Your Spirit</div>
          <div class="step-text">Unlock your spirit's active and passive abilities to gain a tactical edge in combat and exploration.</div>
        </div>
      </div>
      <div class="step">
        <div class="step-num">03</div>
        <div class="step-body">
          <div class="step-title">Find Upgrades</div>
          <div class="step-text">Discover roguelike upgrades throughout the run that amplify your spirit, your loadout, and your odds of survival.</div>
        </div>
      </div>
      <div class="step">
        <div class="step-num">04</div>
        <div class="step-body">
          <div class="step-title">Loot &amp; Extract</div>
          <div class="step-text">Fill your inventory with valuable items, then make your way to the extraction point to escape with your haul.</div>
        </div>
      </div>
      <div class="step">
        <div class="step-num">05</div>
        <div class="step-body">
          <div class="step-title">Return to the Hub</div>
          <div class="step-text">All extracted loot carries over. Sell it, craft with it, and gear up for your next run from the hub world.</div>
        </div>
      </div>
    </div>
  </section>

  <!-- CTA -->
  <section class="section">
    <p class="section-label">Get Involved</p>
    <h2 class="section-title">Stay in the Loop</h2>
    <div class="cta-block">
      <p>Follow development progress, vote on features, and see what's coming next on the official Trello board. Have an idea? Reach out — every suggestion is welcome.</p>
      <div class="btn-row">
        <a class="btn btn-primary" href="https://trello.com/b/a87l82Mu" target="_blank">✦ &nbsp;View Trello Board</a>
        <a class="btn btn-secondary" href="mailto:amindfullgame@gmail.com">✉ &nbsp;amindfullgame@gmail.com</a>
      </div>
    </div>
  </section>

  <div class="divider"></div>

  <footer>
    <p>A Mindfull &nbsp;·&nbsp; Early Access &nbsp;·&nbsp; Made with spirit</p>
  </footer>

</div>
</body>
</html>
