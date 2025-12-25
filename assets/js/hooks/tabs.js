export const Tabs = {
  mounted() {
    console.log("[Tabs] Hook mounted on", this.el.id);
    this.el.addEventListener("click", (e) => {
      const button = e.target.closest("[data-tab-target]");
      if (!button) return;

      const tabName = button.getAttribute("data-tab-target");
      console.log("[Tabs] Switching to:", tabName);
      this.activeTab(tabName);
      
      // Notify the server optimistically
      this.pushEvent("switch_tab", { tab: tabName });
    });
  },

  activeTab(tabName) {
    // Update Buttons within this container
    this.el.querySelectorAll("[data-tab-target]").forEach((btn) => {
      const isActive = btn.getAttribute("data-tab-target") === tabName;
      if (isActive) {
        btn.classList.add("bg-white", "dark:bg-slate-700", "text-sky-600", "dark:text-sky-400", "shadow-sm", "font-bold");
        btn.classList.remove("font-medium", "text-slate-500", "hover:text-slate-800", "dark:hover:text-slate-200");
      } else {
        btn.classList.remove("bg-white", "dark:bg-slate-700", "text-sky-600", "dark:text-sky-400", "shadow-sm", "font-bold");
        btn.classList.add("font-medium", "text-slate-500", "hover:text-slate-800", "dark:hover:text-slate-200");
      }
    });

    // Update Sections
    const sections = document.querySelectorAll("[data-tab-section]");
    console.log(`[Tabs] Found ${sections.length} sections for tab: ${tabName}`);
    
    sections.forEach((section) => {
      if (section.getAttribute("data-tab-section") === tabName) {
        section.classList.remove("hidden");
        section.classList.add("animate-slide-in");
      } else {
        section.classList.add("hidden");
        section.classList.remove("animate-slide-in");
      }
    });
  }
};
