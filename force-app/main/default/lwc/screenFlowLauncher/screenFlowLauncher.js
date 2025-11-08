// screenFlowLauncher.js
import { LightningElement, api } from 'lwc';

export default class ScreenFlowLauncher extends LightningElement {
  @api flowName;
  @api buttonLabel = 'Start Flow';
  @api buttonStyle = 'brand';           // brand, destructive, success, neutral
  @api recordIdVarName = 'recordId';    // default flow variable name
  @api recordId;                        // populated on record pages

  @api iconName = '';                   // e.g. "utility:delete" or "action:add"
  @api iconPosition = 'left';           // "left" or "right"

  isModalOpen = false;

  openModal() {
    console.log('recordId : ' + this.recordId);
    console.log('📥 screenFlowLauncher inputs:', {
      flowName: this.flowName,
      buttonLabel: this.buttonLabel,
      buttonStyle: this.buttonStyle,
      recordIdVarName: this.recordIdVarName,
      recordId: this.recordId,
      iconName: this.iconName,
      iconPosition: this.iconPosition,
      flowInputs: this.flowInputs
    });
    this.isModalOpen = true;
  }

  closeModal() {
    this.isModalOpen = false;
  }

  handleStatusChange(event) {
    console.log('recordId : ' + this.recordId);
    if (event.detail.status === 'FINISHED') {
      this.closeModal();
    }
  }

  get flowInputs() {
    console.log('name , value ' + this.recordIdVarName + '  :  ' + this.recordId);
    return this.recordId
      ? [{ name: this.recordIdVarName, type: "String", value: this.recordId }]
      : [];
  }

  // get flowInputs() {
  //    return [ {
  //           name: "recordId",
  //           type: "String",
  //           value: this.recordId
  //        } ];
  // }
}