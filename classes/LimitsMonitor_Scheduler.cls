public with sharing class LimitsMonitor_Scheduler implements System.Schedulable {
    
    private Decimal percent;
    public LimitsMonitor_Scheduler(Decimal percent) {

        this.percent = percent;
        
    }
    public void execute(System.SchedulableContext context){
        List<String> limitsForNotification = new List<String>();
        Map<String, OrgLimit> limits = LimitsMonitor_Controller.getThisOrgLimits();
        for(String key : limits.keySet()){

            OrgLimit orgLimit = limits.get(key);
            system.debug(orgLimit.getName() + ' ' + orgLimit.getValue() + ' ' + orgLimit.getLimit());
            if(orgLimit.getLimit() != 0){
                Decimal max = Decimal.valueOf(orgLimit.getLimit());
                Decimal val = Decimal.valueOf(orgLimit.getValue());
                Decimal consumedPercent = val.divide(max, 2);
                if(consumedPercent >= percent){
                    limitsForNotification.add(orgLimit.getName());
                }
            }
        }

        system.debug(limitsForNotification);
        if(!limitsForNotification.isEmpty()){
            // Send Email to Current Logged in User
            sendEmailAlert(limitsForNotification);
        }
    }

    public void sendEmailAlert(List<String> limitsForNotification){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setTargetObjectId(UserInfo.getUserId());
        message.subject = 'Limit Alert';
        
        String plainTextBody = 'Hello Admin, Please be alerted about the following limits crossing '+percent+ '%. Please check Limits Monitor for further details' ;
        String htmlBody = 'Hello Admin, <br/>' + 
                            'Please be alerted about the following limits crossing '+percent+ '%. Please check Limits Monitor App for further details'+
                            '<ul>';


        for(String lim : limitsForNotification){
            htmlBody += '<li>'+ lim + '</lim>';
            plainTextBody += ' ' + lim;
        }
        htmlBody+= '</ul>';
        message.setHtmlBody(htmlBody);
        message.setPlainTextBody(plainTextBody);
        message.setSaveAsActivity(false);

        Messaging.SingleEmailMessage[] messages = 
            new List<Messaging.SingleEmailMessage> {message};
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        if (results[0].success) {
            System.debug('The email was sent successfully.');
        } else {
            System.debug('The email failed to send: '
                + results[0].errors[0].message);
        }  
    }
    
    
}