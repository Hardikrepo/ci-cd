const buildInfo = document.getElementById("build-info");
if (buildInfo) {
  buildInfo.textContent = new Date().toISOString();
}

const revealTargets = document.querySelectorAll(".card, .pipeline-step, .diagram-node");

if ("IntersectionObserver" in window) {
  revealTargets.forEach((el) => {
    el.style.opacity = "0";
    el.style.transform = "translateY(8px)";
    el.style.transition = "opacity 0.5s ease, transform 0.5s ease";
  });

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.style.opacity = "1";
          entry.target.style.transform = "translateY(0)";
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.15 }
  );

  revealTargets.forEach((el) => observer.observe(el));
}
