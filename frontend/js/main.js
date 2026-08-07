// ===========================================================
// AirSense — main.js (Module 1: Home Page)
// Handles navigation toggle + smooth scroll + demo dial animation
// ===========================================================

document.addEventListener('DOMContentLoaded', () => {
  const navToggle = document.getElementById('navToggle');
  const navLinks = document.querySelector('.nav-links');

  if (navToggle && navLinks) {
    navToggle.addEventListener('click', () => {
      navLinks.classList.toggle('open');
    });
  }

  // Close mobile nav when a link is clicked
  document.querySelectorAll('.nav-links a').forEach(link => {
    link.addEventListener('click', () => navLinks.classList.remove('open'));
  });

  // Simple demo animation on the hero AQI dial
  const dialValue = document.querySelector('.aqi-dial-value');
  if (dialValue) {
    const demoAQI = 78; // placeholder illustrative value
    let current = 0;
    const step = () => {
      current += 3;
      if (current >= demoAQI) {
        dialValue.textContent = demoAQI;
        return;
      }
      dialValue.textContent = current;
      requestAnimationFrame(() => setTimeout(step, 15));
    };
    step();
  }
});
