export default class BaseComponent {
  constructor(container) {
    // Prevent duplicate instantiation
    if (typeof container.dataset.ref !== 'undefined') {
      return BaseComponent.refs[container.dataset.ref];
    }
    
    this.container = container;
    this.ref = Math.random().toString(36).substr(2, 9);
    BaseComponent.refs[this.ref] = this;
    container.dataset.ref = this.ref;
    
    this.init();
  }
  
  init() {
    // Override in subclasses
  }
  
  render() {
    // Override in subclasses
  }
  
  destroy() {
    delete BaseComponent.refs[this.ref];
    delete this.container.dataset.ref;
  }
}

BaseComponent.refs = {};
