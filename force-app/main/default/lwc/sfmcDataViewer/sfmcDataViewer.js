import { LightningElement, wire, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

export default class McDataViewer extends LightningElement {
  @track rows = [];
  recordsFound = false;

columns = [
  { label: 'Email',       fieldName: 'Email' },
  { label: 'Opened',      fieldName: 'Opened',  type: 'boolean' },
  { label: 'Clicked',     fieldName: 'Clicked', type: 'boolean' },
  { label: 'Bounced',     fieldName: 'Bounced', type: 'boolean' },
  { label: 'Sent',        fieldName: 'Sent date', type: 'date' }
];

  @wire(CurrentPageReference)
  async setPageRef(pageRef) {
    if (!pageRef) return;
    const recordId = pageRef.state.recordId || pageRef.attributes.recordId;
    try {
      const r = await fetch(
  `https://mc1-5lym458dzjwrq1gt5ln503q0.pub.sfmc-content.com/cdqzw3pl4tb?id=${recordId}`
);
      if (r.ok) {
        const json = await r.json();
        this.rows = json.Emails || [];
        this.recordsFound = this.rows.length > 0;
      }
    } catch (e) {
      /* ignore—leave component blank on error */
    }
  }
}