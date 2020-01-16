global class scheduledBatchableCompliance implements Schedulable {
     global void execute(SchedulableContext sc) {
      		BatchBlankUpdateCompliance b = new BatchBlankUpdateCompliance();
      		database.executebatch(b);
     }
}