const Flash = {
  mounted() {
    this.initTimeout();
  },
  updated() {
    this.initTimeout();
  },
  initTimeout() {
    const key = this.el.dataset.key;
    // Clear any existing timeout to restart the timer if updated
    if (this.timer) clearTimeout(this.timer);
    
    this.timer = setTimeout(() => {
      this.pushEvent("lv:clear-flash", { key: key });
    }, 4000); // Dismiss after 4 seconds
  },
  destroyed() {
    if (this.timer) clearTimeout(this.timer);
  }
}

export { Flash };
