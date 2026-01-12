// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import * as bootstrap from "bootstrap";
import "controllers";

// Make Bootstrap available globally for dropdown, collapse, etc.
window.bootstrap = bootstrap;
