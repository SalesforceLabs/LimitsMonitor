public with sharing class LimitsMonitor_Controller {
    
    private static Map<String, String> analyticalLabelMap = new Map<String, String>{
        'AnalyticsExternalDataSizeMB'=>'Analytics External Datasize MB',
        'ConcurrentAsyncGetReportInstances'=>'Concurrent Async Get Report Instances',
        'ConcurrentSyncReportRuns'=>'Concurrent Sync Report Runs',
        'DailyAnalyticsDataflowJobExecutions'=> 'Daily Analytics Dataflow Job Executions',
        'DailyAnalyticsUploadedFilesSizeMB'=> 'Daily Analytics Uploaded Files Size MB',
        'HourlyAsyncReportRuns' => 'Hourly Async Report Runs',
        'HourlyDashboardRefreshes' => 'Hourly Dashboard Refreshes',
        'HourlyDashboardResults' => 'Hourly Dashboard Results',
        'HourlyDashboardStatuses' => 'Hourly Dashboard Statuses',
        'HourlySyncReportRuns'=> 'Hourly Sync Report Runs'
    };

    private static Map<String, String> streamingLabelMap = new Map<String, String>{
        'DailyDurableGenericStreamingApiEvents'=> 'Daily Durable Generic Streaming API Events',
        'DailyDurableStreamingApiEvents'=>'Daily Durable Streaming API Events',
        'DailyGenericStreamingApiEvents'=>'Daily Generic Streaming API Events',
        'DailyStandardVolumePlatformEvents'=> 'Daily Standard Volume Platform Events',
        'DailyStreamingApiEvents' => 'Daily Streaming API Events',
        'DurableStreamingApiConcurrentClients' => 'Durable Streaming API Concurrent Clients',
        'MonthlyPlatformEvents' => 'Monthly Platform Events',
        'StreamingApiConcurrentClients' => 'Streaming API Concurrent Clients'
    };

    private static Map<String, String> otherLabelMap = new Map<String, String>{
        'HourlyLongTermIdMapping'=> 'Hourly Long Term Id Mapping',
        'HourlyODataCallout'=>'Hourly OData Callout',
        'HourlyShortTermIdMapping'=>'Hourly Short Term Id Mapping',
        'ActiveScratchOrgs'=> 'Active Scratch Orgs',
        'DailyAsyncApexExecutions' => 'Daily Async Apex Executions'
    };

    private static Map<String, String> workflowLabelMap = new Map<String, String>{
        'DailyWorkflowEmails'=> 'Daily Workflow Emails',
        'HourlyTimeBasedWorkflow'=>'Hourly Time Based Workflow',
        'MassEmail'=>'Mass Email',
        'SingleEmail'=> 'Single Email'        
    };
    
    public static Map<String, OrgLimit> getThisOrgLimits()
    {
         Map<String, OrgLimit> lm = new Map<String, OrgLimit>();
         if(!Test.isRunningTest()){
             return OrgLimits.getMap();
         }
         return lm;
    }

    private static List<LimitData> getCategorizedData(Map<String, OrgLimit> limitsMap, Map<String, String> categoryMap){
        List<LimitData> catData = new List<LimitData>();
        Integer i=0;
        for(String key : categoryMap.keySet()){
            if(limitsMap.containsKey(key)){
                catData.add(new LimitData(limitsMap.get(key), categoryMap.get(key), i++, 1));
            }
        }
        return catData;
    }

    @AuraEnabled
    public static void scheduleAlert(Decimal percent, string schedTime){
        Time sTime = Time.newInstance(Integer.valueOf(schedTime.split(':')[0]), Integer.valueOf(schedTime.split(':')[1]), 0, 0);
        string schedStr = '0 '+sTime.minute()+' '+sTime.hour()+' * * ?';
        LimitsMonitor_Scheduler SC = new LimitsMonitor_Scheduler(percent); 
        if(!Test.isRunningTest()){
            system.schedule('LimitsMonitorSchedule', schedStr, SC);
        }
    }

    @AuraEnabled(cacheable=true)
    public static AllLimits getOrgLimits(){
        //Make sure your Salesforce instance URL is added in remote site settings
        Map<String, OrgLimit> limitsMap = getThisOrgLimits();
        AllLimits allLimits = new AllLimits();

        allLimits.analyticsLimits = getCategorizedData(limitsMap, analyticalLabelMap);
        allLimits.streamingLimits = getCategorizedData(limitsMap, streamingLabelMap);
        allLimits.workflowLimits = getCategorizedData(limitsMap, workflowLabelMap);
        allLimits.otherLimits = getCategorizedData(limitsMap, otherLabelMap);
       
        if(!limitsMap.isEmpty()){
            allLimits.dailyApiLimit = new LimitData(limitsMap.get('DailyApiRequests'), 'Daily API Request', 0, 0);
            allLimits.dailyBulkApiLimit = new LimitData(limitsMap.get('DailyBulkApiRequests'), 'Daily Bulk API Request', 0, 0);
            allLimits.storageLimit = new LimitData(limitsMap.get('DataStorageMB'), 'Data Storage MB', 0, 0);
            allLimits.fileStorageLimit = new LimitData(limitsMap.get('FileStorageMB'), 'File Storage MB', 0, 0);
        }

        return allLimits;
    }

    @AuraEnabled
    public static List<ObjectLimitData> getObjectLimit(String apiName){
        
        HTTP h = new HTTP();
        HTTPRequest req = new HTTPRequest();
        HttpResponse resp = new HttpResponse();
        
        req.setMethod('GET');
        req.setEndpoint('callout:LimMon_NC/services/data/v45.0/tooling/query/?q=SELECT+Type,+Label,+Remaining,+Max,+EntityDefinitionid+FROM+EntityLimit+where+EntityDefinitionid=\''+apiName+'\'');
        resp = h.send(req);
        
        System.debug(resp.getBody());
        
        if(resp.getStatusCode() == 200 ){
            ObjectLimitResponse limits = (ObjectLimitResponse)JSON.deserialize(resp.getBody(), ObjectLimitResponse.class);
            return limits.records;
        }
       
        return null;
    }
    

    public class AllLimits {
        @AuraEnabled
        public List<LimitData> analyticsLimits;
        @AuraEnabled
        public List<LimitData> streamingLimits;
        @AuraEnabled
        public List<LimitData> workflowLimits;
        @AuraEnabled
        public List<LimitData> otherLimits;
        @AuraEnabled
        public LimitData dailyApiLimit;
        @AuraEnabled
        public LimitData dailyBulkApiLimit;
        @AuraEnabled
        public LimitData storageLimit;
        @AuraEnabled
        public LimitData fileStorageLimit;

    }

    public class ObjectLimitResponse{
        public List<ObjectLimitData> records;
    }

    public class ObjectLimitData{

        @AuraEnabled
        public String Type;
        @AuraEnabled
        public Integer Remaining;
        @AuraEnabled
        public Integer Max;
        @AuraEnabled
        public String Label;
    }

    public class LimitData {

        @AuraEnabled
        public String name;
        @AuraEnabled
        public Integer order;
        @AuraEnabled
        public Decimal score;
        @AuraEnabled
        public Decimal weight;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public Decimal max;
        @AuraEnabled
        public Decimal consumed;
        @AuraEnabled
        public String indication;
        

        public LimitData(OrgLimit lim, String label, Integer order, Decimal weight){
            this.name = lim.getName();
            this.order= order;
            this.weight = weight;
            this.label = label;
            this.max = lim.getLimit();
            this.consumed = lim.getValue();
            this.score = (this.max != 0)? (this.consumed)/this.max:1;
            system.debug(lim.getName());
            system.debug((this.max - this.consumed));
            this.indication = (this.max - this.consumed) +  ' / ' + this.max;
        }
    }
}