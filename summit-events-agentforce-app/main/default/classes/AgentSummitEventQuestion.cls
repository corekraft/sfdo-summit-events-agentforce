public with sharing class AgentSummitEventQuestion {
  public AgentSummitEventQuestion(String questionName, String questionLabel, String questionType){
    this.questionApiName = questionName;
    this.questionLabel = questionLabel;
    this.questionType = questionType;
  }

  @AuraEnabled
  public string questionApiName {get; set;}
  @AuraEnabled
  public string questionLabel {get; set;}
  @AuraEnabled
  public string questionType {get; set;}

  @InvocableMethod(label='Transform Event to Apex-Defined Data type')
  public static List<AgentSummitQuestionInstance> transformEventToKnownDataType(List<summit__Summit_Events__c> events){
    List<String> fields = new List<String>{
      'Preferred_First_Name',
      'Gender',
      'Title',
      'Company_Organization',
      'Date_Of_Birth',
      'Mailing_Address',
      'Applicant_Type',
      'Relationship_To_Institution',
      'Preferred_Class_Year',
      'Last_Name_As_Student',
      'Dietary_Restrictions'
    };
    List<String> fieldApiNames = new List<String>();
    for (String field: fields){
      fieldApiNames.add(String.format('summit__Ask_{0}__c', new List<String>{field}));
      fieldApiNames.add(String.format('summit__{0}_Label__c', new List<String>{field}));
    }
    List<summit__Summit_Events__c> populatedEvents = (List<summit__Summit_Events__c>) Database.queryWithBinds(
      'SELECT ' + String.join(fieldApiNames, ', ') +' FROM summit__Summit_Events__c WHERE Id IN :events', 
      new Map<String, Object>{'events' => new Map<Id, SObject>(events).keySet()}, 
      System.AccessLevel.SYSTEM_MODE
    );
    List<AgentSummitEventQuestion> questions = new List<AgentSummitEventQuestion>();
    for(summit__Summit_Events__c event: events) {
      questions.add(new AgentSummitEventQuestion('field', (String)event.get('summit__First_Name_Label__c'), 'text'));
      questions.add(new AgentSummitEventQuestion('field', (String)event.get('summit__Last_Name_Label__c'), 'text'));
      questions.add(new AgentSummitEventQuestion('field', (String)event.get('summit__Email_Label__c'),'text'));
      for (String field: fields){
        Boolean shouldAdd = ((String) event.get(String.format('summit__Ask_{0}__c', new List<String>{field}))) == 'Ask and require';
        if (!shouldAdd){
          continue;
        }
        AgentSummitEventQuestion agentSummitEventQ = new AgentSummitEventQuestion(
          'field', 
          (String) event.get(String.format('summit__{0}_Label__c', new List<String>{field})), 
          'text'
        );
        questions.add(agentSummitEventQ);
      }
    }

    AgentSummitQuestionInstance instance = new AgentSummitQuestionInstance();
    instance.question = questions;

    return new List<AgentSummitQuestionInstance>{instance};
  }

  public class AgentSummitQuestionInstance{
    @InvocableVariable(label='Question' description='API, Label and Type for the question to be asked for the registrant')
    public List<AgentSummitEventQuestion> question;
  }
}