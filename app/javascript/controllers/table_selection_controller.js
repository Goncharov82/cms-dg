import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["all", "row", "bulk", "apply"]
  toggleAll(){this.rowTargets.forEach(item=>item.checked=this.allTarget.checked);this.sync()}
  sync(){const selected=this.rowTargets.filter(item=>item.checked).length;if(this.hasAllTarget){this.allTarget.checked=this.rowTargets.length>0&&selected===this.rowTargets.length;this.allTarget.indeterminate=selected>0&&selected<this.rowTargets.length}if(this.hasBulkTarget)this.bulkTarget.disabled=selected===0;if(this.hasApplyTarget)this.applyTarget.disabled=selected===0}
}
