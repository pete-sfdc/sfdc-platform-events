trigger Order_ChangeTrigger on Order_Change__e (after insert) {

    // list of fields that we're checking for changes
    List<String> change_fields = new List<String>{
        'OrderStatus__c',
        'OrderID__c',
        'OrderTotal__c'
    };

    if(Trigger.isAfter && Trigger.isInsert) {

        // maps are cooler than GPS
        Map<String,Order_Change__e> oppId_event_map = new Map<String,Order_Change__e>();
        // list of opportunities that will be updated
        List<Opportunity> opps = new List<Opportunity>();

        // loop through events and map by Opp ID
        for(Order_Change__e oc:Trigger.new) {
            oppId_event_map.put(oc.OpportunityID__c,oc);
        }

        // create looping efficiencies
        Order_Change__e temp_oc;
        Boolean has_change = false;

        // loop through opps, find changes
        for(Opportunity opp:[
            SELECT  Id, OrderStatus__c, OrderID__c, OrderTotal__c
            FROM    Opportunity
            WHERE   Id IN:oppId_event_map.keySet()
        ]) {
            // event from map to variable
            temp_oc = oppId_event_map.get(opp.ID);

            // loop through the fields to find changes
            for(String cf:change_fields) {
                if(opp.get(cf) != temp_oc.get(cf)) {
                    // open the gate
                    has_change = true;
                    // change the field's value
                    opp.put(cf, temp_oc.get(cf));
                }
            }

            // if there's a change
            if(has_change) {
                System.debug('Updated ' + opps.size() + ' opportunities');
                // add opp to list
                opps.add(opp);
            }

            // close the gate
            has_change = false;
        }

        // call the garbage man
        temp_oc = null;
        has_change = null;
        oppId_event_map = null;

        // if any opps have change, update them
        if(opps != null && !opps.isEmpty()) {
            update opps;
        }

        // call the garbage man, again
        opps = null;
    }
}
