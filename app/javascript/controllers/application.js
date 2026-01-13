import { Application } from "@hotwired/stimulus";

const application = Application.start();

// Configure Stimulus development experience
application.debug = false;
window.Stimulus = application;

export { application };

// Track which modal link was clicked
window.lastModalTrigger = null;

document.addEventListener("click", (e) => {
  const link = e.target.closest("a[data-turbo-frame='modal']");
  if (link) window.lastModalTrigger = link;
});
