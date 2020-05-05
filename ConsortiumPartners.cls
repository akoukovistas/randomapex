/**
* @description Domain layer class for Consortium_Partner__c .
*/
public class ConsortiumPartners extends fflib_SObjectDomain {

    static final string INSERT_PARTNERS_ON_PROJECT_METHOD = 'insert';
    static final string DELETE_PARTNERS_ON_PROJECT_METHOD = 'delete';

    public ConsortiumPartners(List<Consortium_Partner__c> sObjectList) {
        super(sObjectList);
    }
    
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new ConsortiumPartners(sObjectList);
        }
    }

    /**
     * @description handles all the actions that should fire from a before insert trigger
     */
    public override void onBeforeInsert() {

        ConsortiumPartnersService cps = new ConsortiumPartnersService();
        List<Consortium_Partner__c> partnersOnProjects = new List<Consortium_Partner__c>();

        for (Consortium_Partner__c consortiumPartnerObj : (List<Consortium_Partner__c>)  trigger.new ) {
            if ( String.isNotEmpty(consortiumPartnerObj.Project__c)) {
                partnersOnProjects.add(consortiumPartnerObj);
            }
        }

        // Only apply this logic to any Consortium Partners that have a project set.
        if ( partnersOnProjects.size() > 0 ){
            cps.updatePartnersOnProjects( partnersOnProjects, INSERT_PARTNERS_ON_PROJECT_METHOD );
        }
    }

    /**
     * @description handles all the actions that should fire from a before update trigger
     */
    public override void onBeforeUpdate(Map<Id,Sobject> existingRecords) {

        ConsortiumPartnersService cps = new ConsortiumPartnersService();
        List<Consortium_Partner__c> partnersAddToProjects = new List<Consortium_Partner__c>();
        List<Consortium_Partner__c> partnersRemoveFromProjects = new List<Consortium_Partner__c>();
        Map<Id, Consortium_Partner__c> oldPartnersMap = ( Map<Id, Consortium_Partner__c>) Trigger.oldMap;
        Boolean projectChanged, organisationChanged;

        for (Consortium_Partner__c consortiumPartnerObj : (List<Consortium_Partner__c>) Trigger.new ) {

            // If it has a Project assigned.
            if (String.isNotBlank(consortiumPartnerObj.Project__c)) {            
                
                projectChanged = oldPartnersMap.get(consortiumPartnerObj.Id).Project__c != consortiumPartnerObj.Project__c;
                organisationChanged = oldPartnersMap.get(consortiumPartnerObj.Id).Organisation__c != consortiumPartnerObj.Organisation__c;

                // If anything changed, update it, otherwise do nothing.
                if (projectChanged || organisationChanged) {
                    
                    // Only mark the partner for removal if it used to have a project set.
                    if ( String.isNotBlank(oldPartnersMap.get(consortiumPartnerObj.Id).Project__c)) {
                        partnersRemoveFromProjects.add(oldPartnersMap.get(consortiumPartnerObj.Id));
                    }
                    partnersAddToProjects.add(consortiumPartnerObj);
                
                }
            } 
            else {

                // If it doesn't have a project assigned but it used to
                if (String.isNotEmpty(oldPartnersMap.get(consortiumPartnerObj.Id).Project__c) ) {
                    partnersRemoveFromProjects.add(oldPartnersMap.get(consortiumPartnerObj.Id));
                }
            }
        }

        // Only apply this logic to any Consortium Partners that have a project set.
        if ( partnersRemoveFromProjects.size() > 0 ){
            cps.updatePartnersOnProjects( partnersRemoveFromProjects, DELETE_PARTNERS_ON_PROJECT_METHOD );
        }
        if ( partnersAddToProjects.size() > 0 ){
            cps.updatePartnersOnProjects( partnersAddToProjects, INSERT_PARTNERS_ON_PROJECT_METHOD );
        }
    }

    /**
     * @description handles all the actions that should fire from an after delete trigger
     */
    public override void onAfterDelete() {

        ConsortiumPartnersService cps = new ConsortiumPartnersService();
        List<Consortium_Partner__c> partnersOnProjects = new List<Consortium_Partner__c>();

        for (Consortium_Partner__c consortiumPartnerObj : (List<Consortium_Partner__c>)  trigger.old ) {            
            if ( String.isNotEmpty(consortiumPartnerObj.Project__c)) {
                partnersOnProjects.add(consortiumPartnerObj);
            }
        }

        // Only apply this logic to any Consortium Partners that have a project set.
        if ( partnersOnProjects.size() > 0 ){
            cps.updatePartnersOnProjects( partnersOnProjects, DELETE_PARTNERS_ON_PROJECT_METHOD );
        }
    }
}