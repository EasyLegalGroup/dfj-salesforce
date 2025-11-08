trigger checkProductForPromotionTrigger on OrderItem(after insert,after update,after delete) {
     if((Trigger.isAfter && Trigger.isInsert) || (Trigger.isAfter && Trigger.isUpdate)){
		 checkProductForPromotion.setPromotionalOrder(Trigger.new);
	 }
	 if(Trigger.isAfter && Trigger.isDelete){
		 checkProductForPromotion.setPromotionalOrder(Trigger.old);
	 }
}