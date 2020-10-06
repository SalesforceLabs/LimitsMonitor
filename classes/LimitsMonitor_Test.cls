@isTest
private class LimitsMonitor_Test {
    
    @IsTest
    static void testGetOrgLimits(){
        
        User u = [SELECT id from User where Profile.Name = 'System Administrator' limit 1];
        system.runAs(u){
            Test.startTest();
                LimitsMonitor_Controller.getOrgLimits();
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetObjectLimits(){
            
        Test.setMock(HttpCalloutMock.class, new LimitsMonitor_WebServiceMock());
        LimitsMonitor_Controller.getObjectLimit('Account');
                
    }

    @IsTest
    static void testSchedule(){

        User u = [SELECT id from User where Profile.Name = 'System Administrator' limit 1];
        system.runAs(u){
            Test.startTest();
            LimitsMonitor_Controller.scheduleAlert(5.0, '02:00:22:00');
            Test.stopTest();
        }
    }

    @IsTest
    static void testScheduler(){

        User u = [SELECT id from User where Profile.Name = 'System Administrator' limit 1];
        system.runAs(u){
            Test.startTest();
            string schedStr = '0 10 10 * * ?';
            LimitsMonitor_Scheduler SC = new LimitsMonitor_Scheduler(0.0); 
            system.schedule('TestLimitMonitorSchedule', schedStr, SC);
            Test.stopTest();
            SC.sendEmailAlert(new List<String>{'FileStorageDB'});
        }

    }
}