/**
 * Created by ca on 10/10/24.
 */
DFJ_CPRServices

import { LightningElement, api } from 'lwc';
import DFJ_Logo from "@salesforce/resourceUrl/DinFamiliejurist_Logo_Crop";
import getCPRData from '@salesforce/apex/DFJ_CPRService.getCPRData';

export default class DFJ_CPRServices extends LightningElement {
    logo = DFJ_Logo;
    cprNumber='';
    cprResponseData = {};
    isDisplayData = false;
    isError = false;
    @api recordId;

    errorMessage = '';
    handleCPRInput(event){
        this.cprNumber = event.target.value;
    }

    handleSubmit(){
        getCPRData({recId : this.recordId , cprNumber : this.cprNumber}).then(result=>{
            if(result.statusCode=='200'){
                this.isDisplayData = true;
                this.isError = false;
                this.cprResponseData = result;
            }else{
                this.errorMessage = result.statusCode ;
                this.isDisplayData = false;
                this.isError = true;
            }
        })
    }

    handleKeyDown(event) {
        if (event.key === 'Enter') {
            this.handleSubmit();
        }
    }
}