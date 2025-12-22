// Landing Page Logic

export function initLanding() {
  const canvas = document.getElementById('particle-canvas');
  if (!canvas) return; // Exit if not on landing page

  // --- 1. PARTICLE ANIMATION ENGINE (OPTIMIZED) ---
  const ctx = canvas.getContext('2d');
  let width, height;
  let particles = [];
  let animationFrameId;
  let isVisible = true;

  // Configuration
  const particleCount = 60;
  const connectionDistance = 150;
  const mouseDistance = 200;

  let mouse = { x: null, y: null };

  class Particle {
      constructor() {
          this.x = Math.random() * width;
          this.y = Math.random() * height;
          this.vx = (Math.random() - 0.5) * 0.5;
          this.vy = (Math.random() - 0.5) * 0.5;
          this.size = Math.random() * 2 + 1;
          this.color = Math.random() > 0.5 ? 'rgba(56, 189, 248, ' : 'rgba(192, 132, 252, '; // Cyan or Purple
      }

      update() {
          this.x += this.vx;
          this.y += this.vy;

          // Bounce off edges
          if (this.x < 0 || this.x > width) this.vx *= -1;
          if (this.y < 0 || this.y > height) this.vy *= -1;

          // Mouse Interaction
          if (mouse.x != null) {
              let dx = mouse.x - this.x;
              let dy = mouse.y - this.y;
              let distance = Math.sqrt(dx * dx + dy * dy);
              if (distance < mouseDistance) {
                  const forceDirectionX = dx / distance;
                  const forceDirectionY = dy / distance;
                  const force = (mouseDistance - distance) / mouseDistance;
                  const directionX = forceDirectionX * force * 0.5;
                  const directionY = forceDirectionY * force * 0.5;
                  this.vx -= directionX;
                  this.vy -= directionY;
              }
          }
      }

      draw() {
          ctx.beginPath();
          ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
          ctx.fillStyle = this.color + '0.5)';
          ctx.fill();
      }
  }

  function initParticles() {
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
      particles = [];
      for (let i = 0; i < particleCount; i++) {
          particles.push(new Particle());
      }
  }

  function animateParticles() {
      if (!isVisible) return; // Performance optimization

      ctx.clearRect(0, 0, width, height);

      for (let i = 0; i < particles.length; i++) {
          particles[i].update();
          particles[i].draw();

          // Draw connections
          for (let j = i; j < particles.length; j++) {
              let dx = particles[i].x - particles[j].x;
              let dy = particles[i].y - particles[j].y;
              let distance = Math.sqrt(dx*dx + dy*dy);

              if (distance < connectionDistance) {
                  ctx.beginPath();
                  ctx.strokeStyle = `rgba(100, 116, 139, ${1 - distance/connectionDistance})`;
                  ctx.lineWidth = 1;
                  ctx.moveTo(particles[i].x, particles[i].y);
                  ctx.lineTo(particles[j].x, particles[j].y);
                  ctx.stroke();
              }
          }
      }
      animationFrameId = requestAnimationFrame(animateParticles);
  }

  // Visibility API for Performance
  document.addEventListener('visibilitychange', () => {
      if (typeof document.hidden !== "undefined" && document.hidden) {
          isVisible = false;
          cancelAnimationFrame(animationFrameId);
      } else {
          isVisible = true;
          animateParticles();
      }
  });

  window.addEventListener('resize', initParticles);
  window.addEventListener('mousemove', (e) => {
      mouse.x = e.clientX;
      mouse.y = e.clientY;
  });
  window.addEventListener('mouseout', () => {
      mouse.x = null;
      mouse.y = null;
  });

  initParticles();
  animateParticles();

  // --- 2. MOBILE MENU ---
  const menuBtn = document.getElementById('mobile-menu-btn');
  const closeMenuBtn = document.getElementById('close-menu-btn');
  const mobileMenu = document.getElementById('mobile-menu');
  const mobileLinks = document.querySelectorAll('.mobile-link');

  function toggleMenu() {
      if (!mobileMenu) return;
      const isClosed = mobileMenu.classList.contains('translate-x-full');
      if (isClosed) {
          mobileMenu.classList.remove('translate-x-full');
          document.body.style.overflow = 'hidden'; // Prevent scrolling
      } else {
          mobileMenu.classList.add('translate-x-full');
          document.body.style.overflow = '';
      }
  }

  if (menuBtn) menuBtn.addEventListener('click', toggleMenu);
  if (closeMenuBtn) closeMenuBtn.addEventListener('click', toggleMenu);

  mobileLinks.forEach(link => {
      link.addEventListener('click', toggleMenu);
  });

  // --- 3. ACCORDION LOGIC ---
  window.toggleAccordion = function(element) {
      const wasActive = element.classList.contains('active');

      // Close all others
      document.querySelectorAll('.accordion-item').forEach(item => {
          item.classList.remove('active');
      });

      if (!wasActive) {
          element.classList.add('active');
      }
  }

  // --- 4. SCROLL REVEAL ---
  const observerOptions = {
      threshold: 0.1,
      rootMargin: "0px 0px -50px 0px"
  };

  const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
          if (entry.isIntersecting) {
              entry.target.classList.add('active');
              observer.unobserve(entry.target);
          }
      });
  }, observerOptions);

  document.querySelectorAll('.reveal').forEach(el => observer.observe(el));

  // --- 5. NAVBAR SCROLL EFFECT ---
  window.addEventListener('scroll', () => {
      const nav = document.getElementById('navbar');
      if (nav) {
          if (window.scrollY > 50) {
              nav.classList.add('glass-nav');
          } else {
              nav.classList.remove('glass-nav');
          }
      }
  });
}
