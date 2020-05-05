/**
* @description The service layer class for ConsortiumPartner__c which contains utility methods for the object.
*/
public class ConsortiumPartnersService {

    public void updatePartnersOnProjects( List<Consortium_Partner__c> partnersOnProjects, String method ) {

        Set<Id> affectedProjectIds = new Set<Id>();
        Set<Id> affectedAccountIds = new Set<Id>(); 

        for ( Consortium_Partner__c cp : partnersOnProjects ){
            affectedProjectIds.add(cp.Project__c);

            // Only add any consortium partners that actually have accounts.
            if ( String.isNotEmpty(cp.Organisation__c) ) {
                affectedAccountIds.add(cp.Organisation__c);
            }
        }

        Map<ID, Project__c> projectsAffected = new Map<ID, Project__c>(
            [
                SELECT Id, Consortium_Partners__c 
                FROM Project__c
                WHERE Id 
                IN :affectedProjectIds 
            ]
        );

        Map<ID, Account> accountsAffected = new Map<ID, Account>(
            [
                SELECT Id, Name
                FROM Account  
                WHERE Id 
                IN :affectedAccountIds 
            ]
        );

        switch on method {
            when 'insert' {

                // Loop through the partners on the project.
                for ( Consortium_Partner__c partnerOnProject : partnersOnProjects ){

                    // Only do this for partners that have an account assigned.
                    if ( String.isNotEmpty( partnerOnProject.Organisation__c ) ) {

                        // Check if the partners field is not blank
                        if ( String.isNotBlank(projectsAffected.get(partnerOnProject.Project__c).Consortium_Partners__c)) {
                            // If the consortium partners string doesn't contain the Account name.
                            String partnersField = projectsAffected.get(partnerOnProject.Project__c).Consortium_Partners__c;
                            if (! partnersField.contains(accountsAffected.get(partnerOnProject.Organisation__c).Name)) {
                                
                                // Simply append the new name at the end.
                                partnersField = partnersField + '; ' + accountsAffected.get(partnerOnProject.Organisation__c).Name;
                                projectsAffected.get(partnerOnProject.Project__c).Consortium_Partners__c = partnersField;
                                
                            }
                        } else {

                            // If it's blank just add the org name.
                            projectsAffected.get(partnerOnProject.Project__c).Consortium_Partners__c = accountsAffected.get(partnerOnProject.Organisation__c).Name;
                        }
                    }
                }
            }
            when 'delete' {

                // Loop through the partners on the project.
                for ( Consortium_Partner__c partnerOnProject : partnersOnProjects ){

                    // Only do this for partners that have an account assigned.
                    if ( String.isNotEmpty( partnerOnProject.Organisation__c ) ) {

                        // Check if the partners field is not blank
                        if ( String.isNotBlank(projectsAffected.get(partnerOnProject.Project__c).Consortium_Partners__c)) {
                            // If the consortium partners string contains the Account name.
                            String partnersField = projectsAffected.get(partnerOnProject.Project__c).Consortium_Partners__c;
                            if (partnersField.contains(accountsAffected.get(partnerOnProject.Organisation__c).Name)) {

                                // Turn the field into a list and remove the index of the account name.
                                List<String> partnersList = partnersField.split(';');
                                partnersList.remove(partnersList.indexOf(accountsAffected.get(partnerOnProject.Organisation__c).Name));

                                // Convert the list into a string, replace the commas, trim it and assign it as the new value to the Project.
                                projectsAffected.get(partnerOnProject.Project__c).Consortium_Partners__c = partnersList.toString().replace(',',';').removeStart('( ').removeEnd(')');
                                
                            }
                        }
                    }
                }
            }
            when else {
                System.debug('An invalid update method was passed for updatePartnersOnProjects: ' + method );
            }            
        }
        // Update the Projects and allow partial updates.
        Database.update(projectsAffected.values(), false);
    }
}